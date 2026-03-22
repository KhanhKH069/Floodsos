// controllers/authController.js — Login logic
const ADMIN_USERNAME = process.env.ADMIN_USERNAME || 'admin';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'admin123';

exports.login = (req, res) => {
    const { username, password } = req.body;
    if (username === ADMIN_USERNAME && password === ADMIN_PASSWORD) {
        res.json({ success: true, token: 'admin-secret-token', role: 'admin' });
    } else {
        res.status(401).json({ success: false, message: 'Sai tài khoản/mật khẩu' });
    }
};
