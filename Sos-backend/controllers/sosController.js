// controllers/sosController.js — SOS CRUD, voice submission, routing, and analyze-route
const multer = require('multer');
const path = require('path');

const SOSAlert = require('../models/SOSAlert');
const SOSHistory = require('../models/SOSHistory');
const { formatCsvTime, appendSosCsvRow, removeSosFromCsv, readSosCsvIdsSet, ensureSosCsvFile } = require('../services/csvService');
const { computeFloodProbNear, haversineKm, interpolatePoints, segmentPlan } = require('../services/floodService');
const { fetchUrgencyScore, fetchRouteAnalysis } = require('../services/aiService');

// ─── Multer (file upload) ────────────────────────────────────────────────────
const upload = multer({
    storage: multer.diskStorage({
        destination: (req, file, cb) => cb(null, path.join(__dirname, '..', 'uploads')),
        filename:    (req, file, cb) => cb(null, Date.now() + '-' + file.originalname)
    })
});

// ─── Static data ─────────────────────────────────────────────────────────────
const SHELTERS = [
    { name: 'UBND Thị xã Hoàng Mai',              lat: 19.3400, lon: 105.7100 },
    { name: 'Trường THPT Hoàng Mai',               lat: 19.3312, lon: 105.7165 },
    { name: 'Trung tâm Y tế Thị xã Hoàng Mai',    lat: 19.3450, lon: 105.7050 },
    { name: 'Trường THCS Quỳnh Lộc',              lat: 19.3550, lon: 105.7200 },
    { name: 'Sân vận động Thị xã Hoàng Mai',       lat: 19.3380, lon: 105.7120 },
    { name: 'UBND Phường Quỳnh Thiện',            lat: 19.3280, lon: 105.7080 },
];

const RESCUE_BASE = { name: 'Hạt CHCN Hoàng Mai - Nghệ An', lat: 19.3500, lon: 105.7020 };

// ─── Backfill CSV on startup ─────────────────────────────────────────────────
async function backfillSosCsvFromMongo() {
    try {
        ensureSosCsvFile();
        const existingIds = readSosCsvIdsSet();
        const alerts = await SOSAlert.find().sort({ created_at: -1 }).lean();
        for (const a of alerts) {
            let csv_id = a.csv_id;
            if (!csv_id) {
                const suffix = String(Date.now()).slice(-6) + String(Math.floor(Math.random() * 1000)).padStart(3, '0');
                csv_id = `SOS${suffix}`;
                await SOSAlert.updateOne({ _id: a._id }, { $set: { csv_id } });
            }
            if (existingIds.has(csv_id)) continue;
            appendSosCsvRow({
                id: csv_id,
                time: formatCsvTime(a.created_at ? new Date(a.created_at) : new Date()),
                lat: a.lat ?? '', lon: a.lon ?? '', note: a.message ?? '',
                status: a.assigned_drone ? "in_progress" : "open",
                people_count: a.people_count ?? '',
                priority_score: '', priority_level: '', flood_prob_near: '', time_selected: ''
            });
            existingIds.add(csv_id);
        }
    } catch (e) {
        console.error("backfill csv failed:", e);
    }
}

// ─── Controllers ─────────────────────────────────────────────────────────────

/** GET /api/sos */
exports.getAll = async (req, res) => {
    const alerts = await SOSAlert.find().sort({ created_at: -1 });
    res.json(alerts.map(a => ({
        id: a._id, name: a.name, phone: a.phone, latitude: a.lat, longitude: a.lon,
        waterLevel: a.water_level, peopleCount: a.people_count, status: a.status,
        message: a.message, createdAt: a.created_at
    })));
};

/** POST /api/sos/voice — Gửi SOS (có hoặc không có audio) */
exports.voiceUploadMiddleware = (req, res, next) => {
    if (!req.is('multipart/form-data')) return next();
    upload.single('audio')(req, res, (err) => {
        if (err) return res.status(500).json({ success: false });
        return next();
    });
};

exports.voiceSos = async (req, res) => {
    try {
        const lat = parseFloat(req.body.lat || req.body.latitude);
        const lon = parseFloat(req.body.lon || req.body.longitude);

        const csv_id = `SOS${String(Date.now()).slice(-6)}${String(Math.floor(Math.random() * 1000)).padStart(3, '0')}`;
        const newAlert = new SOSAlert({
            lat, lon, phone: req.body.phone, name: req.body.name,
            water_level: req.body.water_level, people_count: req.body.people_count,
            message: req.body.message, status: 'warning',
            assigned_drone: null, csv_id,
            audio: req.file ? req.file.filename : null
        });
        await newAlert.save();

        const floodProbNear = await computeFloodProbNear(lat, lon);
        const peopleCount = parseFloat(req.body.people_count) || 1;
        const urgency = await fetchUrgencyScore({ lat, lon, flood_prob_near: floodProbNear, people_count: peopleCount, status: 'open' });
        const urgencyProb = urgency ? urgency.urgency_prob : '';
        const isUrgent   = urgency ? (urgency.is_urgent ? 'urgent' : 'normal') : '';

        appendSosCsvRow({
            id: csv_id,
            time: formatCsvTime(newAlert.created_at),
            lat: newAlert.lat, lon: newAlert.lon,
            note: newAlert.message ?? '',
            status: 'open',
            people_count: newAlert.people_count ?? '',
            priority_score: urgencyProb,
            priority_level: isUrgent,
            flood_prob_near: floodProbNear ?? '',
            time_selected: ''
        });

        res.status(200).json({ success: true, urgency_prob: urgencyProb, is_urgent: urgency?.is_urgent ?? null });
    } catch (e) { res.status(500).json({ success: false }); }
};

/** PUT /api/sos/:id/resolve */
exports.resolve = async (req, res) => {
    try {
        const { id } = req.params;
        const alert = await SOSAlert.findById(id);
        const csvIdToRemove = alert?.csv_id || String(alert?._id || id);
        if (alert) {
            const floodProbNear = await computeFloodProbNear(alert.lat, alert.lon);
            await SOSHistory.create({
                lat: alert.lat, lon: alert.lon, phone: alert.phone, name: alert.name,
                water_level: alert.water_level, people_count: alert.people_count,
                status: alert.status, message: alert.message, audio: alert.audio,
                created_at: alert.created_at, resolved_at: new Date(),
                resolved_action: 'resolve', assigned_drone: alert.assigned_drone,
                csv_id: alert.csv_id, flood_prob_near: floodProbNear
            });
        }
        await SOSAlert.findByIdAndDelete(id);
        removeSosFromCsv(csvIdToRemove);
        res.json({ success: true });
    } catch (e) { res.status(500).json({ success: false }); }
};

/** DELETE /api/sos/:id */
exports.remove = async (req, res) => {
    const alert = await SOSAlert.findById(req.params.id);
    const csvIdToRemove = alert?.csv_id || String(alert?._id || req.params.id);
    if (alert) {
        const floodProbNear = await computeFloodProbNear(alert.lat, alert.lon);
        await SOSHistory.create({
            lat: alert.lat, lon: alert.lon, phone: alert.phone, name: alert.name,
            water_level: alert.water_level, people_count: alert.people_count,
            status: alert.status, message: alert.message, audio: alert.audio,
            created_at: alert.created_at, resolved_at: new Date(),
            resolved_action: 'delete', assigned_drone: alert.assigned_drone,
            csv_id: alert.csv_id, flood_prob_near: floodProbNear
        });
    }
    await SOSAlert.findByIdAndDelete(req.params.id);
    removeSosFromCsv(csvIdToRemove);
    res.status(200).json({ success: true });
};

/** POST /api/sos/route — Flood-aware SOS Routing (via routing_api.py) */
exports.route = async (req, res) => {
    const { lat, lon } = req.body || {};
    if (lat === undefined || lon === undefined) {
        return res.status(400).json({ error: 'Thiếu lat/lon' });
    }
    const result = await fetchRouteAnalysis({ lat: Number(lat), lon: Number(lon) });
    if (!result) {
        return res.json({
            flood_level: 'unknown', flood_prob: null, mode: 'unavailable',
            route: [[lat, lon]], segments: [], total_distance_km: 0,
            summary: '⚠️ Dịch vụ phân tích tuyến đường chưa khả dụng. Hãy chạy routing_api.py.',
            shelter: null, rescue_base: null, sos_target: [lat, lon]
        });
    }
    res.json(result);
};

/** GET /api/sos/analyze-route?lat=&lon= — Legacy analyze-route endpoint */
exports.analyzeRoute = async (req, res) => {
    try {
        const lat = parseFloat(req.query.lat);
        const lon = parseFloat(req.query.lon);
        if (isNaN(lat) || isNaN(lon)) {
            return res.status(400).json({ error: 'Thiếu hoặc sai tham số lat/lon' });
        }

        const flood_prob = await computeFloodProbNear(lat, lon) ?? 0.0;
        const flood_level = flood_prob >= 0.5 ? 'high' : 'low';

        if (flood_level === 'low') {
            let nearest = null, minDist = Infinity;
            for (const s of SHELTERS) {
                const d = haversineKm(lat, lon, s.lat, s.lon);
                if (d < minDist) { minDist = d; nearest = s; }
            }
            const waypoints = interpolatePoints(lat, lon, nearest.lat, nearest.lon, 5).map(p => [p.lat, p.lon]);
            return res.json({
                flood_prob: parseFloat(flood_prob.toFixed(4)), flood_level: 'low',
                sos_lat: lat, sos_lon: lon, mode: 'shelter',
                shelter: { name: nearest.name, lat: nearest.lat, lon: nearest.lon, distance_km: parseFloat(minDist.toFixed(2)) },
                route_waypoints: waypoints,
                instruction: `Nguy cơ ngập ${(flood_prob * 100).toFixed(0)}% – mức an toàn. Hãy di chuyển ngay đến điểm trú ẩn gần nhất.`,
            });
        }

        const NUM_SEGMENTS = 3;
        const waypoints = interpolatePoints(RESCUE_BASE.lat, RESCUE_BASE.lon, lat, lon, NUM_SEGMENTS);
        const segments = [];
        for (let i = 0; i < NUM_SEGMENTS; i++) {
            const from = waypoints[i], to = waypoints[i + 1];
            const midLat = (from.lat + to.lat) / 2, midLon = (from.lon + to.lon) / 2;
            const segProb = await computeFloodProbNear(midLat, midLon) ?? 0.0;
            const { level, emoji, plan } = segmentPlan(segProb);
            const distKm = haversineKm(from.lat, from.lon, to.lat, to.lon);
            segments.push({
                id: i + 1,
                from: i === 0 ? RESCUE_BASE.name : `Điểm trung gian ${i}`,
                from_lat: from.lat, from_lon: from.lon,
                to: i === NUM_SEGMENTS - 1 ? 'Vị trí SOS' : `Điểm trung gian ${i + 1}`,
                to_lat: to.lat, to_lon: to.lon,
                distance_km: parseFloat(distKm.toFixed(2)),
                flood_prob: parseFloat(segProb.toFixed(4)), flood_level: level, emoji, plan,
            });
        }
        return res.json({
            flood_prob: parseFloat(flood_prob.toFixed(4)), flood_level: 'high',
            sos_lat: lat, sos_lon: lon, mode: 'rescue',
            rescue_base: RESCUE_BASE, segments,
            route_waypoints: waypoints.map(p => [p.lat, p.lon]),
            instruction: `Nguy cơ ngập ${(flood_prob * 100).toFixed(0)}% – mức nguy hiểm. Đội cứu hộ đang được điều phối theo ${NUM_SEGMENTS} chặng.`,
        });
    } catch (e) {
        console.error('analyze-route error:', e);
        res.status(500).json({ error: 'Lỗi phân tích tuyến đường' });
    }
};

// Export backfill function for use in server.js
exports.backfillSosCsvFromMongo = backfillSosCsvFromMongo;
