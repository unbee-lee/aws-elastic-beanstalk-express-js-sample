const request = require('supertest');
const app = require('../app');

describe('GET /', () => {
  test('returns the sample response', async () => {
    const response = await request(app).get('/');
    expect(response.statusCode).toBe(200);
    expect(response.text).toBe('Hello World!');
  });
});
