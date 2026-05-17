const path = require('path');
const fs = require('fs');
const multer = require('multer');
const { v4: uuidv4 } = require('uuid');
const ApiError = require('../utils/ApiError');
const { uploadsRoot } = require('../config/uploads');

const offersDir = path.join(uploadsRoot, 'privilege-offers');
fs.mkdirSync(offersDir, { recursive: true });

const allowedExtensions = new Set(['.jpg', '.jpeg', '.png', '.webp']);

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, offersDir),
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname || '').toLowerCase();
    const safeExt = allowedExtensions.has(ext) ? ext : '.jpg';
    cb(null, `${Date.now()}-${uuidv4()}${safeExt}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const ext = path.extname(file.originalname || '').toLowerCase();
    if (!allowedExtensions.has(ext)) {
      cb(ApiError.badRequest('Only JPG, PNG, or WEBP images are allowed'));
      return;
    }
    cb(null, true);
  },
});

// Accepts two optional files: 'logo' and 'image'
const offerImageUpload = upload.fields([
  { name: 'logo', maxCount: 1 },
  { name: 'image', maxCount: 1 },
]);

function handleOfferUpload(req, res, next) {
  offerImageUpload(req, res, (err) => {
    if (!err) {
      next();
      return;
    }
    if (err instanceof multer.MulterError && err.code === 'LIMIT_FILE_SIZE') {
      next(ApiError.badRequest('Image must be 5 MB or smaller'));
      return;
    }
    next(err);
  });
}

module.exports = { handleOfferUpload, offersDir };
