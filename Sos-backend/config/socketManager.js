// config/socketManager.js
const socketIo = require('socket.io');

let io;

// Vị trí tạm theo deviceId (dùng cho SOS broadcast)
// key: deviceId, value: { name, role, lat, lon, speed, battery, timestamp, socketId, lastSeen }
const activeTrackers = new Map();

// ── Haversine: khoảng cách 2 tọa độ (km) ───────────────────────────────────
function haversineKm(lat1, lon1, lat2, lon2) {
    const R = 6371;
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a = Math.sin(dLat / 2) ** 2
        + Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180)
        * Math.sin(dLon / 2) ** 2;
    return 2 * R * Math.asin(Math.sqrt(a));
}

// ── Broadcast SOS tới user trong bán kính radiusM mét ─────────────────────
// Gọi từ sosController khi có SOS mới với needs_help=true
function broadcastNearbySOS(sosData, radiusM = 500) {
    if (!io) return 0;
    const { lat, lon } = sosData;
    if (!lat || !lon) return 0;

    let count = 0;
    const radiusKm = radiusM / 1000;

    activeTrackers.forEach((tracker, deviceId) => {
        // Bỏ qua chính người gửi SOS
        if (deviceId === sosData.deviceId) return;
        // Bỏ qua thiết bị quá cũ (> 5 phút)
        if (Date.now() - tracker.lastSeen > 5 * 60 * 1000) return;
        if (!tracker.lat || !tracker.lon) return;

        const dist = haversineKm(lat, lon, tracker.lat, tracker.lon);
        if (dist <= radiusKm) {
            io.to(tracker.socketId).emit('nearby_sos', {
                ...sosData,
                distanceM: Math.round(dist * 1000),
            });
            count++;
        }
    });

    console.log(`📡 [nearby_sos] Broadcast tới ${count} user trong ${radiusM}m`);
    return count;
}

module.exports = {
    init: (server) => {
        io = socketIo(server, {
            cors: { origin: "*", methods: ["GET", "POST"] }
        });

        console.log("🔌 Socket.IO đã được khởi tạo!");

        io.on('connection', (socket) => {
            console.log(`📡 Client kết nối: ${socket.id}`);

            // 1. Nhận cập nhật vị trí từ app
            socket.on('location_update', (data) => {
                if (!data || !data.deviceId) return;
                activeTrackers.set(data.deviceId, {
                    ...data,
                    socketId: socket.id,
                    lastSeen: Date.now(),
                });
                // Broadcast cho admin map
                io.emit('tracking_update', data);
            });

            // 2. Volunteer báo đang đến (broadcast về cho nạn nhân biết)
            socket.on('volunteer_accepted', (data) => {
                // data: { sosId, volunteerName, volunteerPhone, etaMinutes }
                console.log(`🤝 Volunteer nhận SOS: ${data.sosId}`);
                io.emit('volunteer_update', {
                    ...data,
                    status: 'accepted',
                    timestamp: Date.now(),
                });
            });

            // 3. Volunteer báo đã đến nơi nạn nhân
            socket.on('volunteer_arrived', (data) => {
                io.emit('volunteer_update', { ...data, status: 'arrived' });
            });

            // 4. Volunteer báo hoàn thành (đã đưa đến nơi an toàn)
            socket.on('volunteer_completed', (data) => {
                io.emit('volunteer_update', { ...data, status: 'completed' });
                // Cũng emit SOS resolved để admin map cập nhật
                io.emit('sos_resolved', { sosId: data.sosId });
            });

            // 5. Ngắt kết nối
            socket.on('disconnect', () => {
                console.log(`❌ Client ngắt: ${socket.id}`);
                // Cập nhật socketId = null để biết user offline
                activeTrackers.forEach((tracker, deviceId) => {
                    if (tracker.socketId === socket.id) {
                        activeTrackers.set(deviceId, { ...tracker, socketId: null });
                    }
                });
            });
        });

        return io;
    },

    getIo: () => {
        if (!io) throw new Error("Socket.io chưa được khởi tạo!");
        return io;
    },

    getActiveTrackers: () => activeTrackers,
    broadcastNearbySOS,
    haversineKm,
};
