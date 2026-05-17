const router = require('express').Router();
const { body } = require('express-validator');
const { validate } = require('../middleware/validate');
const { authenticate, authorize } = require('../middleware/auth');
const { orgScope } = require('../middleware/orgScope');
const ctrl = require('../controllers/member.controller');

router.use(authenticate, orgScope);

// Member self-service
router.get('/profile', authorize('member'), ctrl.profile);

// Admin routes
router.post(
  '/',
  authorize('admin', 'super_admin'),
  [
    body('name').notEmpty().trim(),
    body('phone').matches(/^\d{10}$/).withMessage('Phone must be exactly 10 digits'),
    body('email').optional().isEmail(),
    body('designation').optional().isIn(['president', 'secretary']),
  ],
  validate,
  ctrl.create
);

router.get('/', authorize('admin', 'super_admin'), ctrl.list);
router.get('/check-designation', authorize('admin', 'super_admin'), ctrl.checkDesignation);
router.get('/:id', authorize('admin', 'super_admin'), ctrl.getById);

router.put(
  '/:id',
  authorize('admin', 'super_admin'),
  [body('name').optional().trim()],
  validate,
  ctrl.update
);

router.delete('/:id', authorize('admin', 'super_admin'), ctrl.remove);

module.exports = router;
