const router = require('express').Router();
const { body } = require('express-validator');
const { validate } = require('../middleware/validate');
const { authenticate, authorize } = require('../middleware/auth');
const { orgScope } = require('../middleware/orgScope');
const ctrl = require('../controllers/asset.controller');

router.use(authenticate, orgScope);

// Member self-service
router.get('/my-assets', authorize('member'), ctrl.myAssets);

// Admin routes
router.get('/stats', authorize('admin', 'super_admin'), ctrl.stats);
router.get('/available', authorize('admin', 'super_admin'), ctrl.listAvailable);
router.get('/issue-register', authorize('admin', 'super_admin'), ctrl.issueRegister);
router.get('/damage-report', authorize('admin', 'super_admin'), ctrl.damageReport);

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

router.post(
  '/:id/issue',
  authorize('admin', 'super_admin'),
  [body('member_id').isInt()],
  validate,
  ctrl.issue
);

router.post(
  '/:id/return',
  authorize('admin', 'super_admin'),
  [body('condition_on_return').optional().isIn(['working', 'damaged', 'missing'])],
  validate,
  ctrl.returnAsset
);

router.get('/:id/history', authorize('admin', 'super_admin'), ctrl.history);

module.exports = router;
