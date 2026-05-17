const jwt = require('jsonwebtoken');
const db = require('../config/database');
const ApiError = require('../utils/ApiError');

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret';

async function authenticate(req, _res, next) {
  try {
    const header = req.headers.authorization;
    if (!header || !header.startsWith('Bearer ')) {
      throw ApiError.unauthorized('Missing or invalid token');
    }

    const token = header.split(' ')[1];
    const payload = jwt.verify(token, JWT_SECRET);

    const user = await db('users').where({ id: payload.userId, status: 'active' }).first();
    if (!user) throw ApiError.unauthorized('User not found or inactive');

    req.user = {
      id: user.id,
      email: user.email,
      role: user.role,
      organizationId: user.organization_id,
    };

    next();
  } catch (err) {
    if (err instanceof ApiError) return next(err);
    next(ApiError.unauthorized('Invalid token'));
  }
}

function authorize(...roles) {
  return (req, _res, next) => {
    if (!roles.includes(req.user.role)) {
      return next(ApiError.forbidden('Insufficient permissions'));
    }
    next();
  };
}

module.exports = { authenticate, authorize };
