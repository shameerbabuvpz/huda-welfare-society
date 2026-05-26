const jwt = require('jsonwebtoken');
const AppError = require('../utils/AppError');

/**
 * Middleware to verify member JWT token
 * Sets req.member with decoded token data
 */
const memberAuth = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return next(new AppError('No token provided', 401));
    }

    const token = authHeader.slice(7); // Remove 'Bearer ' prefix
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key');

    // Verify this is a member token
    if (decoded.type !== 'member') {
      return next(new AppError('Invalid token type', 401));
    }

    // Set member info in request
    req.member = {
      id: decoded.memberId,
      organizationId: decoded.organizationId,
    };

    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return next(new AppError('Token expired', 401));
    }
    if (err.name === 'JsonWebTokenError') {
      return next(new AppError('Invalid token', 401));
    }
    next(err);
  }
};

module.exports = memberAuth;
