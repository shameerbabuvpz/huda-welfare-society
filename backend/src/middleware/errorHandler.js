const ApiError = require('../utils/ApiError');

function errorHandler(err, _req, res, _next) {
  if (err instanceof ApiError) {
    return res.status(err.statusCode).json({
      error: {
        code: err.statusCode,
        message: err.message,
        details: err.details || null,
      },
    });
  }

  console.error('Unhandled error:', err);
  res.status(500).json({
    error: {
      code: 500,
      message: 'Internal server error',
    },
  });
}

module.exports = { errorHandler };
