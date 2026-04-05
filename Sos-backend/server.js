require('dotenv').config();
console.log("🚀 SERVER ĐANG KHỞI ĐỘNG (MVC Refactored)...");

const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const http = require('http');
const { Server } = require('socket.io');
const connectDB = require('./src/config/db');
const apiRoutes = require('./src/routes/api');

const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: '*' } });

// Đặt io vào app để controller gọi req.app.get('io')
app.set('io', io);

// Load cấu hình từ process.env (Sử dụng dotenv)
const PORT = process.env.PORT || 3002;
const MONGO_URI = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/floodsos';

// Kết nối DB
connectDB(MONGO_URI);

// Tự động dọn rác file ghi âm cũ trong uploads (Garbage Collection)
const UPLOADS_DIR = path.join(__dirname, 'uploads');
if (!fs.existsSync(UPLOADS_DIR)){
    fs.mkdirSync(UPLOADS_DIR);
}

const cleanUpOldUploads = () => {
    fs.readdir(UPLOADS_DIR, (err, files) => {
        if (err) return;
        const now = Date.now();
        // Xóa file quá 7 ngày (7 * 24 * 60 * 60 * 1000)
        const SEVEN_DAYS = 7 * 24 * 60 * 60 * 1000;
        files.forEach(file => {
            const filePath = path.join(UPLOADS_DIR, file);
            fs.stat(filePath, (err, stats) => {
                if (!err && (now - stats.mtimeMs > SEVEN_DAYS)) {
                    fs.unlink(filePath, () => {
                        console.log(`🗑️ Đã dọn dẹp file cũ: ${file}`);
                    });
                }
            });
        });
    });
};
// Chạy ngay 1 lần lúc startup và mỗi 24 giờ
cleanUpOldUploads();
setInterval(cleanUpOldUploads, 24 * 60 * 60 * 1000);

io.on('connection', (socket) => {
    console.log('🔗 Client connected to Socket.io: ' + socket.id);
    socket.on('disconnect', () => console.log('❌ Client disconnected: ' + socket.id));
}); 

// Middlewares
app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(UPLOADS_DIR));
app.use(express.static(path.join(__dirname, 'public'))); 

// API Routes
app.use('/api', apiRoutes);

server.listen(PORT, '0.0.0.0', () => console.log(`✅ Server chạy port ${PORT}`));