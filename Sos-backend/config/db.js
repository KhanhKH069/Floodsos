// config/db.js — MongoDB connection setup
const mongoose = require('mongoose');

const MONGO_URI = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/floodsos';

async function connectDB() {
    await mongoose.connect(MONGO_URI);
    console.log('✅ MongoDB Connected!');
}

module.exports = connectDB;
