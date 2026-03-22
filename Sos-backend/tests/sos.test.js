// tests/sos.test.js — Jest + Supertest tests for /api/sos (stateless routes only)
// Note: Routes that require MongoDB are tested via mocking
'use strict';

const request = require('supertest');
const express = require('express');

// ─── Mock dependencies that touch MongoDB/CSV/filesystem ─────────────────────
jest.mock('../models/SOSAlert', () => ({
    find: jest.fn().mockReturnValue({
        sort: jest.fn().mockResolvedValue([])
    }),
}));
jest.mock('../models/SOSHistory', () => ({
    create: jest.fn().mockResolvedValue({}),
}));
jest.mock('../services/csvService', () => ({
    formatCsvTime: jest.fn(() => '2024-01-01 00:00:00'),
    appendSosCsvRow: jest.fn(),
    removeSosFromCsv: jest.fn(),
    readSosCsvIdsSet: jest.fn(() => new Set()),
    ensureSosCsvFile: jest.fn(),
}));
jest.mock('../services/floodService', () => ({
    computeFloodProbNear: jest.fn().mockResolvedValue(0.25),
    haversineKm: jest.fn(() => 1.5),
    interpolatePoints: jest.fn(() => [
        { lat: 19.34, lon: 105.71 },
        { lat: 19.345, lon: 105.715 },
    ]),
    segmentPlan: jest.fn(() => ({ level: 'low', emoji: '🚗', plan: 'Xe cứu trợ' })),
}));
jest.mock('../services/aiService', () => ({
    fetchUrgencyScore: jest.fn().mockResolvedValue({ urgency_prob: 0.4, is_urgent: false }),
    fetchRouteAnalysis: jest.fn().mockResolvedValue(null), // simulate service offline
}));

const sosRoutes = require('../routes/sosRoutes');
const app = express();
app.use(express.json());
app.use('/api/sos', sosRoutes);

// ─── Tests ────────────────────────────────────────────────────────────────────

describe('GET /api/sos', () => {
    it('returns an array (empty when no SOS)', async () => {
        const res = await request(app).get('/api/sos');
        expect(res.status).toBe(200);
        expect(Array.isArray(res.body)).toBe(true);
    });
});

describe('POST /api/sos/route', () => {
    it('returns unavailable fallback when routing_api is offline', async () => {
        const res = await request(app)
            .post('/api/sos/route')
            .send({ lat: 19.34, lon: 105.71 });

        expect(res.status).toBe(200);
        expect(res.body.mode).toBe('unavailable');
    });

    it('returns 400 when lat/lon missing', async () => {
        const res = await request(app)
            .post('/api/sos/route')
            .send({});

        expect(res.status).toBe(400);
        expect(res.body.error).toBeDefined();
    });
});

describe('GET /api/sos/analyze-route', () => {
    it('returns low flood_level self-evacuation route (mocked prob = 0.25)', async () => {
        const res = await request(app)
            .get('/api/sos/analyze-route')
            .query({ lat: 19.34, lon: 105.71 });

        expect(res.status).toBe(200);
        expect(res.body.flood_level).toBe('low');
        expect(res.body.mode).toBe('shelter');
        expect(res.body.shelter).toBeDefined();
    });

    it('returns 400 when lat/lon missing', async () => {
        const res = await request(app)
            .get('/api/sos/analyze-route');

        expect(res.status).toBe(400);
    });
});
