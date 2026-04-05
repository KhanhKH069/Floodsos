const SOSAlert = require('../models/SOSAlert');
const FloodReport = require('../models/FloodReport');
const { DRONE_BASES, GLOBAL_DRONES, RESCUE_TEAMS, SHELTERS } = require('../data/mockData');

// 1. LOGIN
exports.login = (req, res) => {
    const { username, password } = req.body;
    if (username === 'admin' && password === 'admin123') {
        res.json({ success: true, token: 'admin-secret-token', role: 'admin' });
    } else {
        res.status(401).json({ success: false, message: 'Sai tài khoản/mật khẩu' });
    }
};

// 2. CHATBOT
exports.chat = (req, res) => {
    const userMsg = req.body.message ? req.body.message.toLowerCase() : "";
    let reply = "Xin lỗi, tôi chưa hiểu ý bạn.";

    if (userMsg.includes('xin chào') || userMsg.includes('hi')) reply = "Chào bạn! Tôi là trợ lý ảo FloodSOS.";
    else if (userMsg.includes('công an') || userMsg.includes('113')) reply = "👮 Số Cảnh sát phản ứng nhanh: 113";
    else if (userMsg.includes('cứu thương') || userMsg.includes('115')) reply = "🚑 Cấp cứu Y tế: 115";
    else if (userMsg.includes('cứu hỏa') || userMsg.includes('114')) reply = "🚒 Cứu hỏa: 114";
    else if (userMsg.includes('sos')) reply = "🚨 Hãy bấm nút ĐỎ ngoài màn hình chính để gửi SOS!";

    res.json({ success: true, reply: reply });
};

// 3. XÁC NHẬN CỨU -> XÓA SOS
exports.resolveSOS = async (req, res) => {
    try {
        const { id } = req.params;
        const alert = await SOSAlert.findById(id);
        if (alert && alert.assigned_drone) {
            const drone = GLOBAL_DRONES.find(d => d.id === alert.assigned_drone);
            if (drone) {
                drone.status = 'idle';
                drone.targetId = null;
                if (DRONE_BASES[drone.id]) {
                    drone.lat = DRONE_BASES[drone.id].lat;
                    drone.lon = DRONE_BASES[drone.id].lon;
                }
            }
        }
        await SOSAlert.findByIdAndDelete(id);
        req.app.get('io').emit('sos_updated');
        res.json({ success: true });
    } catch (e) { res.status(500).json({ success: false }); }
};

exports.getDrones = (req, res) => res.json(GLOBAL_DRONES);

exports.resetDrones = (req, res) => {
    GLOBAL_DRONES.forEach(d => {
        d.lat = DRONE_BASES[d.id].lat;
        d.lon = DRONE_BASES[d.id].lon;
        d.status = 'idle';
        d.targetId = null;
    });
    req.app.get('io').emit('drones_updated');
    res.json({ success: true });
};

exports.getSOS = async (req, res) => {
    const alerts = await SOSAlert.find().sort({ created_at: -1 });
    res.json(alerts.map(a => ({
        id: a._id, name: a.name, phone: a.phone, latitude: a.lat, longitude: a.lon,
        waterLevel: a.water_level, peopleCount: a.people_count, status: a.status, 
        message: a.message, createdAt: a.created_at, assigned_drone: a.assigned_drone
    })));
};

exports.deleteSOS = async (req, res) => {
    await SOSAlert.findByIdAndDelete(req.params.id);
    req.app.get('io').emit('sos_updated');
    res.status(200).json({ success: true });
};

exports.getTeams = (req, res) => res.json(RESCUE_TEAMS);
exports.getShelters = (req, res) => res.json(SHELTERS);

exports.dispatchSOS = async (req, res) => {
    try {
        const { id } = req.params;
        const { teamId } = req.body;
        
        const alert = await SOSAlert.findById(id);
        if (!alert) return res.status(404).json({ success: false, message: 'SOS not found' });
        
        const team = RESCUE_TEAMS.find(t => t.id === teamId);
        if (team) {
            team.status = 'busy';
            team.targetId = id;
            team.lat = alert.lat; 
            team.lon = alert.lon;
        }

        alert.status = 'dispatched'; 
        await alert.save();
        
        req.app.get('io').emit('teams_updated');
        req.app.get('io').emit('sos_updated');
        res.json({ success: true, team });
    } catch (e) {
        res.status(500).json({ success: false });
    }
};

exports.getReports = async (req, res) => {
    try {
        const reports = await FloodReport.find().sort({ created_at: -1 });
        res.json(reports);
    } catch (e) { res.status(500).json({ success: false }); }
};

exports.postReport = async (req, res) => {
    try {
        const { lat, lon, severity, description } = req.body;
        const newReport = new FloodReport({ lat, lon, severity, description });
        await newReport.save();
        req.app.get('io').emit('report_updated');
        res.json({ success: true, report: newReport });
    } catch (e) { res.status(500).json({ success: false }); }
};

exports.getPredictFlood = async (req, res) => {
    try {
        const reports = await FloodReport.find().sort({ created_at: -1 });
        const alerts = await SOSAlert.find().sort({ created_at: -1 });

        let predictions = [];

        const generateGridPoints = (centerLat, centerLon, count, spacingDeg) => {
            let sideSize = Math.ceil(Math.sqrt(count));
            let startLat = centerLat - (sideSize * spacingDeg) / 2;
            let startLon = centerLon - (sideSize * spacingDeg) / 2;
            let generated = 0;

            for(let i=0; i<sideSize; i++) {
                for(let j=0; j<sideSize; j++) {
                    if (generated >= count) return;
                    let jitterLat = (Math.random() - 0.5) * spacingDeg * 0.6;
                    let jitterLon = (Math.random() - 0.5) * spacingDeg * 0.6;

                    predictions.push({ 
                        lat: startLat + i * spacingDeg + jitterLat, 
                        lon: startLon + j * spacingDeg + jitterLon, 
                        severity: 'predictive' 
                    });
                    generated++;
                }
            }
        };

        const totalTargets = reports.length + alerts.filter(a => a.lat && a.lon).length;
        const totalPointsToGenerate = 450; 

        if (totalTargets > 0) {
            const pointsPerTarget = Math.floor(totalPointsToGenerate / totalTargets);
            reports.forEach(r => generateGridPoints(r.lat, r.lon, pointsPerTarget, 0.01));
            alerts.forEach(a => {
                if (a.lat && a.lon) generateGridPoints(a.lat, a.lon, pointsPerTarget, 0.01);
            });
        } else {
            generateGridPoints(16.4690, 107.5760, totalPointsToGenerate, 0.01);
        }

        res.json(predictions);
    } catch (e) { res.status(500).json({ success: false }); }
};

exports.postVoiceSOS = async (req, res) => {
    try {
        const lat = parseFloat(req.body.lat || req.body.latitude);
        const lon = parseFloat(req.body.lon || req.body.longitude);
        let bestDrone = GLOBAL_DRONES.find(d => d.status === 'idle');
        let assignedId = null;
        if (bestDrone) {
            bestDrone.status = 'busy'; bestDrone.lat = lat; bestDrone.lon = lon; assignedId = bestDrone.id;
        }
        const msg = req.body.message ? req.body.message.toLowerCase() : "";
        let autoStatus = 'warning';
        if (msg.includes('máu') || msg.includes('trẻ em') || msg.includes('trẻ con') || msg.includes('kẹt') || msg.includes('đuối') || msg.includes('cứu gấp')) {
            autoStatus = 'critical';
        }

        const newAlert = new SOSAlert({
            lat, lon, phone: req.body.phone, name: req.body.name,
            water_level: req.body.water_level, people_count: req.body.people_count,
            message: req.body.message, status: autoStatus, assigned_drone: assignedId
        });
        await newAlert.save();
        req.app.get('io').emit('sos_updated'); 
        if (assignedId) req.app.get('io').emit('drones_updated');
        res.status(200).json({ success: true });
    } catch (e) { res.status(500).json({ success: false }); }
};
