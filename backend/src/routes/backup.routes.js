const router = require('express').Router();
const multer = require('multer');
const { authenticate, authorize } = require('../middleware/auth');
const ctrl = require('../controllers/backup.controller');

// Backup/restore operate on the whole database — restrict to super_admin.
router.use(authenticate, authorize('super_admin'));

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 200 * 1024 * 1024 },
});

router.get('/download', ctrl.download);
router.post('/restore', upload.single('file'), ctrl.restore);

module.exports = router;
