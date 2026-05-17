const path = require('path');
const multer = require('multer');
const { v4: uuidv4 } = require('uuid');
const ApiError = require('../utils/ApiError');
const { profilePhotosDir } = require('../config/uploads');

const allowedExtensions = new Set(['.jpg', '.jpeg', '.png', '.webp']);

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, profilePhotosDir),
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
}).single('photo');

function profilePhotoUpload(req, res, next) {
  upload(req, res, (err) => {
    if (!err) {
      next();
      return;
    }

    if (err instanceof multer.MulterError && err.code === 'LIMIT_FILE_SIZE') {
      next(ApiError.badRequest('Photo must be 5 MB or smaller'));
      return;
    }

    next(err);
  });
}

module.exports = { profilePhotoUpload };