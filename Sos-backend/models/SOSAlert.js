// models/SOSAlert.js — Active SOS alert schema
const mongoose = require('mongoose');

const SOSAlertSchema = new mongoose.Schema({
    lat: Number,
    lon: Number,
    phone: String,
    name: String,
    water_level: String,
    people_count: String,
    status: { type: String, default: 'pending' },
    message: String,
    audio: String,
    created_at: { type: Date, default: Date.now },
    assigned_drone: { type: String, default: null },
    // Id dùng để đồng bộ tới sos_signals.csv
    csv_id: { type: String, default: null },
    // ── Community Rescue P2P ──────────────────────────────────────────────────
    // true nếu người dùng không thể tự sơ tán và cần hàng xóm hỗ trợ
    needs_help: { type: Boolean, default: false },
    // 'can_walk' | 'needs_carry' | 'bedridden'
    mobility_status: { type: String, default: 'can_walk' },
});

module.exports = mongoose.model('SOSAlert', SOSAlertSchema);
