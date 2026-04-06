// server.js — Entry point (Refactored: MVC structure)
console.log("🚀 SERVER ĐANG KHỞI ĐỘNG...");

require('dotenv').config();
const express = require('express');
const path    = require('path');
const fs      = require('fs');
const http    = require('http');

const connectDB      = require('./config/db');
const authRoutes     = require('./routes/authRoutes');
const sosRoutes      = require('./routes/sosRoutes');
const chatRoutes     = require('./routes/chatRoutes');
const socketManager  = require('./config/socketManager');
const { backfillSosCsvFromMongo } = require('./controllers/sosController');

const app    = express();
const server = http.createServer(app);
const PORT   = process.env.PORT || 3002;

// ─── Middleware ───────────────────────────────────────────────────────────────
app.use(require('cors')());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Ensure uploads directory exists
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir);

// ─── Routes ───────────────────────────────────────────────────────────────────
app.use('/api/auth', authRoutes);
app.use('/api/sos',  sosRoutes);
app.use('/api/chat', chatRoutes);

// ─── Flood Zones proxy → priority_api.py ─────────────────────────────────────
// Docker: FLOOD_ZONES_URL=http://priority-api:8765/flood-zones
// Local:  fallback http://127.0.0.1:8765/flood-zones
const FLOOD_ZONES_URL = process.env.FLOOD_ZONES_URL || 'http://127.0.0.1:8765/flood-zones';

app.get('/api/flood-zones', async (req, res) => {
    try {
        const response = await fetch(FLOOD_ZONES_URL, {
            signal: AbortSignal.timeout(8000),
        });
        if (!response.ok) throw new Error(`Python API: ${response.status}`);
        const data = await response.json();
        res.json(data);
    } catch (err) {
        console.warn('[flood-zones] Python API unavailable:', err.message);
        res.json([]);
    }
});

// ─── Database + Startup ───────────────────────────────────────────────────────
connectDB().then(async () => {
    await backfillSosCsvFromMongo();
});

// Khởi tạo Socket.io trước khi listen
socketManager.init(server);

server.listen(PORT, '0.0.0.0', () =>
    console.log(`✅ Server chạy tại http://0.0.0.0:${PORT}`)
);