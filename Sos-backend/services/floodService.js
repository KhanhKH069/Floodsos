// services/floodService.js — Flood probability calculation utilities
const path = require('path');
const fs = require('fs');

const FLOOD_PROB_CSV_PATH = path.join(__dirname, '..', '..', '..', 'Gop_app', 'realtime_outputs', 'flood_point_probability_rt.csv');

// OpenWeatherMap API key — fallback khi Streamlit CSV chưa tồn tại.
const OPENWEATHER_KEY = process.env.OPENWEATHER_KEY || '3e3ec7e28ca89e66bac0a9ef59e5ab81';

/**
 * Lấy lượng mưa (mm/h) từ OWM rồi chuyển sang xác suất ngập.
 *   rain_1h < 5mm   → 0.05  (mưa nhẹ / khô)
 *   rain_1h < 15mm  → 0.20
 *   rain_1h < 30mm  → 0.45
 *   rain_1h < 50mm  → 0.70
 *   rain_1h >= 50mm → 0.90  (mưa lớn, khả năng ngập cao)
 * Fallback 0.10 nếu API bị lỗi.
 */
async function floodProbFromWeather(lat, lon) {
    try {
        const url = `https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&appid=${OPENWEATHER_KEY}&units=metric`;
        const controller = new AbortController();
        const timer = setTimeout(() => controller.abort(), 4000);
        const res = await fetch(url, { signal: controller.signal });
        clearTimeout(timer);

        if (!res.ok) return 0.10;
        const data = await res.json();
        const rainMm = data?.rain?.['1h'] ?? data?.rain?.['3h'] / 3 ?? 0;

        if (rainMm < 5)  return 0.05;
        if (rainMm < 15) return 0.20;
        if (rainMm < 30) return 0.45;
        if (rainMm < 50) return 0.70;
        return 0.90;
    } catch (_) {
        return 0.10;
    }
}

/**
 * Compute flood_prob_near for a given (lat, lon) by finding the nearest
 * point in flood_point_probability_rt.csv using squared Euclidean distance.
 * Fallback: ước lượng flood_prob từ lượng mưa OpenWeatherMap khi CSV không tồn tại.
 */
async function computeFloodProbNear(lat, lon) {
    try {
        if (fs.existsSync(FLOOD_PROB_CSV_PATH)) {
            const text = fs.readFileSync(FLOOD_PROB_CSV_PATH, { encoding: 'utf8' });
            const lines = text.split(/\r?\n/);

            if (lines.length >= 2) {
                const header = lines[0].split(',');
                const latIdx = header.indexOf('lat');
                const lonIdx = header.indexOf('lon');
                const probIdx = header.indexOf('flood_prob');

                if (latIdx >= 0 && lonIdx >= 0 && probIdx >= 0) {
                    let bestDist2 = Infinity, bestProb = null;
                    for (let i = 1; i < lines.length; i++) {
                        const line = lines[i];
                        if (!line || line.trim().length === 0) continue;
                        const cols = line.split(',');
                        if (cols.length <= Math.max(latIdx, lonIdx, probIdx)) continue;
                        const pLat = parseFloat(cols[latIdx]);
                        const pLon = parseFloat(cols[lonIdx]);
                        const pProb = parseFloat(cols[probIdx]);
                        if (isNaN(pLat) || isNaN(pLon) || isNaN(pProb)) continue;
                        const d2 = (pLat - lat) ** 2 + (pLon - lon) ** 2;
                        if (d2 < bestDist2) { bestDist2 = d2; bestProb = pProb; }
                    }
                    if (bestProb !== null) return bestProb;
                }
            }
        }

        return await floodProbFromWeather(lat, lon);
    } catch (e) {
        console.error('computeFloodProbNear failed:', e.message);
        return 0.1;
    }
}

/** Khoảng cách Haversine, trả về km. */
function haversineKm(lat1, lon1, lat2, lon2) {
    const R = 6371;
    const toRad = (d) => d * Math.PI / 180;
    const dLat = toRad(lat2 - lat1);
    const dLon = toRad(lon2 - lon1);
    const a = Math.sin(dLat / 2) ** 2 +
        Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/** Chia tuyến từ A → B thành (numSegments + 1) waypoints đều nhau. */
function interpolatePoints(lat1, lon1, lat2, lon2, numSegments) {
    const pts = [];
    for (let i = 0; i <= numSegments; i++) {
        const t = i / numSegments;
        pts.push({ lat: lat1 + (lat2 - lat1) * t, lon: lon1 + (lon2 - lon1) * t });
    }
    return pts;
}

/** Đưa ra kế hoạch ứng phó theo flood_prob. */
function segmentPlan(prob) {
    if (prob < 0.4) return { level: 'low',    emoji: '🚗', plan: 'Xe cứu trợ / đi bộ an toàn' };
    if (prob < 0.65) return { level: 'medium', emoji: '🚤', plan: 'Thuyền nhỏ hoặc bè cứu sinh' };
    return             { level: 'high',   emoji: '🛥️',  plan: 'Thuyền máy công suất cao / trực thăng' };
}

module.exports = {
    computeFloodProbNear,
    haversineKm,
    interpolatePoints,
    segmentPlan,
};
