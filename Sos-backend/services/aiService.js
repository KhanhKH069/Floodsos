// services/aiService.js — Calls to Priority API and Routing API (Python FastAPI)
const PRIORITY_API_URL = process.env.PRIORITY_API_URL || 'http://127.0.0.1:8765/predict';
const ROUTING_API_URL  = process.env.ROUTING_API_URL  || 'http://127.0.0.1:8766/route';

/**
 * Gọi priority_api.py để lấy urgency_prob của SOS.
 * Trả về { urgency_prob, is_urgent } hoặc null nếu service chưa chạy.
 */
async function fetchUrgencyScore({ lat, lon, flood_prob_near, people_count = 1, status = 'open' }) {
    try {
        const controller = new AbortController();
        const timer = setTimeout(() => controller.abort(), 3000);
        const res = await fetch(PRIORITY_API_URL, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ lat, lon, flood_prob_near, people_count, status }),
            signal: controller.signal
        });
        clearTimeout(timer);
        if (res.ok) return await res.json();
    } catch (_) { /* service không chạy — bỏ qua */ }
    return null;
}

/**
 * Gọi routing_api.py để phân tích tuyến đường có tính toán ngập.
 * Trả về đối tượng RouteResponse hoặc null nếu service chưa chạy.
 */
async function fetchRouteAnalysis({ lat, lon }) {
    try {
        const controller = new AbortController();
        const timer = setTimeout(() => controller.abort(), 8000); // OSM có thể chậm hơn
        const res = await fetch(ROUTING_API_URL, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ lat, lon }),
            signal: controller.signal
        });
        clearTimeout(timer);
        if (res.ok) return await res.json();
    } catch (_) { /* service không chạy — bỏ qua */ }
    return null;
}

module.exports = { fetchUrgencyScore, fetchRouteAnalysis };
