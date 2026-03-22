// tests/auth.test.js — Jest + Supertest tests for /api/auth
'use strict';

const request = require('supertest');
const express = require('express');
const authRoutes = require('../routes/authRoutes');

// Simple test app without DB
const app = express();
app.use(express.json());
app.use('/api/auth', authRoutes);

// Set test credentials so authController reads from env
process.env.ADMIN_USERNAME = 'admin';
process.env.ADMIN_PASSWORD = 'admin123';

describe('POST /api/auth/login', () => {
    it('returns success with valid credentials', async () => {
        const res = await request(app)
            .post('/api/auth/login')
            .send({ username: 'admin', password: 'admin123' });

        expect(res.status).toBe(200);
        expect(res.body.success).toBe(true);
        expect(res.body.token).toBeDefined();
        expect(res.body.role).toBe('admin');
    });

    it('returns 401 with wrong password', async () => {
        const res = await request(app)
            .post('/api/auth/login')
            .send({ username: 'admin', password: 'wrong' });

        expect(res.status).toBe(401);
        expect(res.body.success).toBe(false);
    });

    it('returns 401 with wrong username', async () => {
        const res = await request(app)
            .post('/api/auth/login')
            .send({ username: 'hacker', password: 'admin123' });

        expect(res.status).toBe(401);
        expect(res.body.success).toBe(false);
    });

    it('returns 401 with empty body', async () => {
        const res = await request(app)
            .post('/api/auth/login')
            .send({});

        expect(res.status).toBe(401);
    });
});
