const router = require('express').Router();
const { body } = require('express-validator');
const { validate } = require('../middleware/validate');
const { authenticate, authorize } = require('../middleware/auth');
const { orgScope } = require('../middleware/orgScope');
const ctrl = require('../controllers/admin.controller');

router.use(authenticate, authorize('admin', 'super_admin'), orgScope);

router.get('/', ctrl.list);
router.get('/:id', ctrl.getById);

router.post(
  '/',
  [
    body('name').notEmpty().trim().withMessage('Name is required'),
    body('phone').matches(/^\d{10}$/).withMessage('Phone must be exactly 10 digits'),
    body('email').optional({ nullable: true }).isEmail().withMessage('Invalid email'),
  ],
  validate,
  ctrl.create
);

router.put(
  '/:id',
  [
    body('name').optional().trim(),
    body('phone').optional().matches(/^\d{10}$/).withMessage('Phone must be exactly 10 digits'),
    body('email').optional({ nullable: true }).isEmail().withMessage('Invalid email'),
    body('status').optional().isIn(['active', 'inactive']),
  ],
  validate,
  ctrl.update
);

router.delete('/:id', ctrl.remove);

module.exports = router;
