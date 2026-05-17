const router = require('express').Router();
const { body } = require('express-validator');
const { validate } = require('../middleware/validate');
const { authenticate, authorize } = require('../middleware/auth');
const { orgScope } = require('../middleware/orgScope');
const ctrl = require('../controllers/notification.controller');

router.use(authenticate, orgScope);

// Member self-service
router.get('/my-notifications', authorize('member'), ctrl.myNotifications);

// Admin
router.post(
  '/',
  authorize('admin', 'super_admin'),
  [body('title').notEmpty().trim(), body('body').notEmpty()],
  validate,
  ctrl.send
);

router.get('/', authorize('admin', 'super_admin'), ctrl.list);
router.get('/:id/logs', authorize('admin', 'super_admin'), ctrl.deliveryLogs);

module.exports = router;
