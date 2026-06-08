require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const routes = require('./routes');
const { errorHandler } = require('./middleware/errorHandler');
const { uploadsRoot } = require('./config/uploads');

const app = express();

app.set('trust proxy', 1);

// Security & parsing
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(morgan('combined'));

// Health check
app.get('/health', (_req, res) => res.json({ status: 'ok', version: 'v2026-06-08a' }));

// Static uploads
app.use('/uploads', express.static(uploadsRoot, {
  setHeaders: (res) => {
    res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
  },
}));

// API routes
app.use('/api/v1', routes);

// Global error handler
app.use(errorHandler);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

module.exports = app;
