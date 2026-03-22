// routes/sosRoutes.js
const express = require('express');
const router = express.Router();
const sosController = require('../controllers/sosController');

// GET /api/sos — Lấy danh sách SOS đang mở
router.get('/', sosController.getAll);

// POST /api/sos/voice — Gửi SOS (multipart audio hoặc JSON)
router.post('/voice', sosController.voiceUploadMiddleware, sosController.voiceSos);

// POST /api/sos/route — Phân tích tuyến đường flood-aware
router.post('/route', sosController.route);

// GET /api/sos/analyze-route?lat=&lon= — Legacy endpoint
router.get('/analyze-route', sosController.analyzeRoute);

// PUT /api/sos/:id/resolve — Đánh dấu đã cứu
router.put('/:id/resolve', sosController.resolve);

// DELETE /api/sos/:id — Xóa SOS
router.delete('/:id', sosController.remove);

module.exports = router;
