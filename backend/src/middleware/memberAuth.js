const jwt = require('jsonwebtoken');
const ApiError = require('../utils/ApiError');

/**
 * Middleware to verify member JWT token
 * Sets req.member with decoded token data
 */
const memberAuth = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return next(new ApiError('No token provided', 401));
    }

    const token = authHeader.slice(7); // Remove 'Bearer ' prefix
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key');

    // Verify this is a member token
    if (decoded.type !== 'member') {
      return next(new ApiError('Invalid token type', 401));
    }

    // Set member info in request
    req.member = {
      id: decoded.memberId,
      organizationId: decoded.organizationId,
    };

    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return next(new ApiError('Token expired', 401));
    }
    if (err.name === 'JsonWebTokenError') {
      return next(new ApiError('Invalid token', 401));
    }
    next(err);
  }
};

module.exports = memberAuth;
