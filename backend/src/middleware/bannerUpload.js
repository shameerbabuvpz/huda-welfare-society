const path = require('path');
const fs = require('fs');
const multer = require('multer');
const { v4: uuidv4 } = require('uuid');
const ApiError = require('../utils/ApiError');
const { uploadsRoot } = require('../config/uploads');

const bannersDir = path.join(uploadsRoot, 'banners');
fs.mkdirSync(bannersDir, { recursive: true });

const allowedExtensions = new Set(['.jpg', '.jpeg', '.png', '.webp']);

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, bannersDir),
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

const bannerUpload = upload.single('image');

function handleBannerUpload(req, res, next) {
  bannerUpload(req, res, (err) => {
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

module.exports = { handleBannerUpload, bannersDir };
