const jwt = require('jsonwebtoken');
const db = require('../config/database');
const ApiError = require('../utils/ApiError');

/**
 * Middleware to verify a member request.
 * Accepts either:
 *   - a legacy member token (type: 'member', memberId), or
 *   - a standard user token (userId, role: 'member')
 * Sets req.member = { id, organizationId }
 */
const memberAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return next(new ApiError(401, 'No token provided'));
    }

    const token = authHeader.slice(7); // Remove 'Bearer ' prefix
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'dev-secret');

    // Legacy member token
    if (decoded.type === 'member' && decoded.memberId) {
      req.member = {
        id: decoded.memberId,
        organizationId: decoded.organizationId,
      };
      return next();
    }

    // Standard user token with member role
    if (decoded.userId) {
      const user = await db('users').where({ id: decoded.userId, status: 'active' }).first();
      if (!user) {
        return next(new ApiError(401, 'User not found or inactive'));
      }

      const member = await db('members')
        .where(function () {
          this.where({ user_id: user.id });
          if (user.phone) this.orWhere({ phone: user.phone });
        })
        .where({ organization_id: user.organization_id, status: 'active' })
        .first();

      if (!member) {
        return next(new ApiError(404, 'Member profile not found'));
      }

      req.member = {
        id: member.id,
        organizationId: member.organization_id,
      };
      return next();
    }

    return next(new ApiError(401, 'Invalid token type'));
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return next(new ApiError(401, 'Token expired'));
    }
    if (err.name === 'JsonWebTokenError') {
      return next(new ApiError(401, 'Invalid token'));
    }
    next(err);
  }
};

module.exports = memberAuth;
