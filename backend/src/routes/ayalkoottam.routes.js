const router = require('express').Router();
const { body } = require('express-validator');
const { validate } = require('../middleware/validate');
const { authenticate, authorize } = require('../middleware/auth');
const { orgScope } = require('../middleware/orgScope');
const ctrl = require('../controllers/ayalkoottam.controller');

router.use(authenticate, orgScope);

// Dropdown list (no pagination — for member creation forms etc.)
router.get('/all', authorize('admin', 'super_admin'), ctrl.listAll);

// Office-bearers directory (president/secretary of every ayalkoottam)
router.get('/leaders', authorize('admin', 'super_admin'), ctrl.leaders);

// CRUD
router.post(
  '/',
  authorize('admin', 'super_admin'),
  [body('name').notEmpty().trim()],
  validate,
  ctrl.create
);

router.get('/', authorize('admin', 'super_admin'), ctrl.list);
router.get('/:id', authorize('admin', 'super_admin'), ctrl.getById);

router.put(
  '/:id',
  authorize('admin', 'super_admin'),
  [body('name').optional().trim()],
  validate,
  ctrl.update
);

router.put('/:id/deactivate', authorize('admin', 'super_admin'), ctrl.deactivate);

module.exports = router;
