const mongoose = require('mongoose');

const FloodReportSchema = new mongoose.Schema({
    lat: Number, lon: Number,
    severity: String, // 'low', 'medium', 'critical'
    description: String,
    created_at: { type: Date, default: Date.now }
});

module.exports = mongoose.model('FloodReport', FloodReportSchema);
