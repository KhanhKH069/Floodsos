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

// ─── Database + Startup ───────────────────────────────────────────────────────
connectDB().then(async () => {
    await backfillSosCsvFromMongo();
});

// Khởi tạo Socket.io trước khi listen
socketManager.init(server);

server.listen(PORT, '0.0.0.0', () =>
    console.log(`✅ Server chạy tại http://0.0.0.0:${PORT}`)
);