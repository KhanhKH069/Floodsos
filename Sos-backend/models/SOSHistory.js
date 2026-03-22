// models/SOSHistory.js — Archived (resolved/deleted) SOS history schema
const mongoose = require('mongoose');

const SOSHistorySchema = new mongoose.Schema({
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
    resolved_at: { type: Date, default: Date.now },
    resolved_action: { type: String, default: 'unknown' }, // resolve | delete
    assigned_drone: { type: String, default: null },
    csv_id: { type: String, default: null },
    // flood_prob tại điểm gần nhất của SOS — dùng để train model ML priority/urgency.
    flood_prob_near: { type: Number, default: null }
});

module.exports = mongoose.model('SOSHistory', SOSHistorySchema);
