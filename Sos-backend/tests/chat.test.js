// tests/chat.test.js — Jest + Supertest tests for /api/chat
'use strict';

const request = require('supertest');
const express = require('express');
const chatRoutes = require('../routes/chatRoutes');

const app = express();
app.use(express.json());
app.use('/api/chat', chatRoutes);

describe('POST /api/chat', () => {
    it('greets user with xin chào', async () => {
        const res = await request(app)
            .post('/api/chat')
            .send({ message: 'xin chào' });

        expect(res.status).toBe(200);
        expect(res.body.success).toBe(true);
        expect(res.body.reply).toContain('FloodSOS');
    });

    it('returns police number for 113 keyword', async () => {
        const res = await request(app)
            .post('/api/chat')
            .send({ message: '113' });

        expect(res.body.reply).toContain('113');
    });

    it('returns ambulance for 115 keyword', async () => {
        const res = await request(app)
            .post('/api/chat')
            .send({ message: '115' });

        expect(res.body.reply).toContain('115');
    });

    it('returns SOS instruction for sos keyword', async () => {
        const res = await request(app)
            .post('/api/chat')
            .send({ message: 'sos' });

        expect(res.body.reply).toContain('SOS');
    });

    it('returns fallback for unknown message', async () => {
        const res = await request(app)
            .post('/api/chat')
            .send({ message: 'gibberish xyz 999' });

        expect(res.status).toBe(200);
        expect(res.body.success).toBe(true);
        expect(res.body.reply).toBeDefined();
    });

    it('handles missing message field gracefully', async () => {
        const res = await request(app)
            .post('/api/chat')
            .send({});

        expect(res.status).toBe(200);
        expect(res.body.success).toBe(true);
    });
});
