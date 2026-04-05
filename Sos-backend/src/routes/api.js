const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const apiController = require('../controllers/apiController');

const upload = multer({ storage: multer.diskStorage({
    destination: (req, file, cb) => cb(null, 'uploads/'),
    filename: (req, file, cb) => cb(null, Date.now() + '-' + file.originalname)
})});

// 1. LOGIN
router.post('/auth/login', apiController.login);

// 2. CHATBOT
router.post('/chat', apiController.chat);

// 3. DRONES
router.get('/drones', apiController.getDrones);
router.post('/drones/reset', apiController.resetDrones);

// 4. SOS
router.get('/sos', apiController.getSOS);
router.delete('/sos/:id', apiController.deleteSOS);
router.put('/sos/:id/resolve', apiController.resolveSOS);
router.post('/sos/:id/dispatch', apiController.dispatchSOS);
router.post('/sos/voice', upload.single('audio'), apiController.postVoiceSOS);

// 5. REPORTS
router.get('/reports', apiController.getReports);
router.post('/reports', apiController.postReport);
router.get('/predict_flood', apiController.getPredictFlood);

// 6. TEAMS & SHELTERS
router.get('/teams', apiController.getTeams);
router.get('/shelters', apiController.getShelters);

module.exports = router;
