// routes/sosRoutes.js
const express = require('express');
const router = express.Router();
const sosController = require('../controllers/sosController');

// GET /api/sos — Lấy danh sách SOS đang mở
router.get('/', sosController.getAll);

// POST /api/sos/voice — Gửi SOS (multipart audio hoặc JSON)
router.post('/voice', sosController.voiceUploadMiddleware, sosController.voiceSos);

// Cập nhật trạng thái 'safe' (resolve)
router.post('/:id/resolve', sosController.resolve);

// Delete SOS Alert from Database
router.post('/delete/:id', sosController.remove);

// Phân tích lộ trình an toàn từ điểm bắt đầu đến điểm kết thúc
router.post('/route', sosController.route);

// 🔥 Đồng bộ tracking khi có mạng trở lại
router.post('/tracking/sync', sosController.syncTrackingOffline);

// GET /api/sos/analyze-route?lat=&lon= — Legacy endpoint
router.get('/analyze-route', sosController.analyzeRoute);

// PUT /api/sos/:id/resolve — Đánh dấu đã cứu
router.put('/:id/resolve', sosController.resolve);

// DELETE /api/sos/:id — Xóa SOS
router.delete('/:id', sosController.remove);

// ── Community Rescue (P2P) ───────────────────────────────────────────────────
// POST /api/sos/:id/volunteer/accept  — Volunteer nhận nhiệm vụ
router.post('/:id/volunteer/accept', sosController.volunteerAccept);

// POST /api/sos/:id/volunteer/arrive  — Volunteer đã đến nơi nạn nhân
router.post('/:id/volunteer/arrive', sosController.volunteerArrive);

// POST /api/sos/:id/volunteer/complete — Volunteer đã đưa đến nơi an toàn
router.post('/:id/volunteer/complete', sosController.volunteerComplete);

module.exports = router;
