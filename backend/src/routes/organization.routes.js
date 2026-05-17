const router = require('express').Router();
const path = require('path');
const multer = require('multer');
const { body } = require('express-validator');
const { validate } = require('../middleware/validate');
const { authenticate, authorize } = require('../middleware/auth');
const ctrl = require('../controllers/organization.controller');
const { orgLogosDir } = require('../config/uploads');

// Multer config for org logo
const logoStorage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, orgLogosDir),
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname) || '.png';
    cb(null, `org-${Date.now()}${ext}`);
  },
});
const logoUpload = multer({
  storage: logoStorage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    if (file.mimetype.startsWith('image/')) cb(null, true);
    else cb(new Error('Only image files are allowed'));
  },
}).single('logo');

router.use(authenticate);
router.use(authorize('super_admin'));

router.post(
  '/',
  [
    body('name').notEmpty().trim(),
    body('place').optional().trim(),
  ],
  validate,
  ctrl.create
);

router.get('/', ctrl.list);
router.get('/:id', ctrl.getById);

router.put(
  '/:id',
  [
    body('name').optional().trim(),
    body('place').optional().trim(),
  ],
  validate,
  ctrl.update
);

router.put('/:id/logo', logoUpload, ctrl.uploadLogo);

router.put('/:id/deactivate', ctrl.deactivate);

// Admin user management for an org
router.post(
  '/:id/admins',
  [
    body('phone').matches(/^\d{10}$/).withMessage('Phone must be 10 digits'),
    body('name').optional().trim(),
  ],
  validate,
  ctrl.addAdmin
);

router.get('/:id/admins', ctrl.listAdmins);

module.exports = router;
