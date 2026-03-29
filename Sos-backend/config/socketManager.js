// config/socketManager.js
const socketIo = require('socket.io');

let io;

// Cấu trúc tạm lưu vị trí cuối cùng của mọi thiết bị
// key: deviceId, value: { name, role, lat, lon, speed, battery, timestamp }
const activeTrackers = new Map();

module.exports = {
  init: (server) => {
    io = socketIo(server, {
      cors: {
        origin: "*",
        methods: ["GET", "POST"]
      }
    });

    console.log("🔌 Socket.IO đã được khởi tạo!");

    io.on('connection', (socket) => {
      console.log(`📡 Client kết nối: ${socket.id}`);

      // 1. Nhận cập nhật vị trí trực tiếp từ app (Người dùng / Cứu hộ)
      socket.on('location_update', (data) => {
        // data: { deviceId, name, role, lat, lon, speed, battery, timestamp }
        if (!data || !data.deviceId) return;

        // Lưu vào bộ nhớ tạm
        activeTrackers.set(data.deviceId, {
          ...data,
          lastSeen: Date.now()
        });

        // Broadcast CHỈ cho các admin (để tiết kiệm băng thông)
        // Hiện tại ta phát lại event tracking_update tới tất cả mọi người
        io.emit('tracking_update', data);
      });

      // 2. Client báo mất mạng (Offline mode)
      socket.on('disconnect', () => {
        console.log(`❌ Client ngắt kết nối: ${socket.id}`);
        // Không xóa device ngay lập tức vì họ có thể chỉ rớt mạng tạm thời
        // Admin map có thể xám màu marker nếu lastSeen quá lâu
      });
    });

    return io;
  },

  getIo: () => {
    if (!io) {
      throw new Error("Socket.io chưa được khởi tạo!");
    }
    return io;
  },

  getActiveTrackers: () => activeTrackers
};
