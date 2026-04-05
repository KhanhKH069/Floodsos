const mongoose = require('mongoose');

const SOSAlertSchema = new mongoose.Schema({
    lat: Number, lon: Number, phone: String, name: String, 
    water_level: String, people_count: String, 
    status: { type: String, default: 'pending' },
    message: String, audio: String, 
    created_at: { type: Date, default: Date.now },
    assigned_drone: { type: String, default: null }
});

module.exports = mongoose.model('SOSAlert', SOSAlertSchema);
