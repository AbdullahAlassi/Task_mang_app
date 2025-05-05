const request = require('supertest');
const { app } = require('../app');

describe('Task API Tests', () => {
  test('Assign a user to a task', async () => {
    const res = await request(app)
      .post('/api/tasks/64b8d4f22a1c5e34f814d7e9/assign')
      .send({ userId: '64b8d4f22a1c5e34f814d7e8' })
      .set('Authorization', `Bearer valid_token`);

    expect(res.statusCode).toBe(200);
    expect(res.body.message).toBe('User assigned successfully');
  });
});
