const router = require('express').Router();
const { body } = require('express-validator');
const { validate } = require('../middleware/validate');
const { authenticate, authorize } = require('../middleware/auth');
const { orgScope } = require('../middleware/orgScope');
const ctrl = require('../controllers/kuri.controller');

router.use(authenticate, orgScope);

// Member self-service
router.get('/my-kuri', authorize('member'), ctrl.myKuri);

// Admin – groups
router.post(
  '/',
  authorize('admin', 'super_admin'),
  [
    body('name').notEmpty().trim(),
    body('total_members').isInt({ min: 2 }),
    body('monthly_amount').isFloat({ min: 1 }),
    body('duration_months').isInt({ min: 1 }),
    body('start_date').isISO8601(),
  ],
  validate,
  ctrl.createGroup
);

router.get('/', authorize('admin', 'super_admin'), ctrl.listGroups);
router.get('/:id', authorize('admin', 'super_admin', 'member'), ctrl.getGroup);
router.put('/:id', authorize('admin', 'super_admin'), ctrl.updateGroup);
router.delete('/:id', authorize('admin', 'super_admin'), ctrl.deleteGroup);

// Admin – members
router.post(
  '/:id/members',
  authorize('admin', 'super_admin'),
  [body('member_id').isInt()],
  validate,
  ctrl.addMember
);
router.post(
  '/:id/guests',
  authorize('admin', 'super_admin'),
  [body('name').notEmpty().trim(), body('phone').optional().trim()],
  validate,
  ctrl.addGuestMember
);
router.delete('/:id/members/:memberId', authorize('admin', 'super_admin'), ctrl.removeMember);

// Admin – collections
router.post(
  '/:id/collections',
  authorize('admin', 'super_admin'),
  [body('member_id').isInt(), body('month_number').isInt({ min: 1 })],
  validate,
  ctrl.recordCollection
);
router.get('/:id/collections', authorize('admin', 'super_admin'), ctrl.getCollections);

// Admin – winners
router.post(
  '/:id/winners',
  authorize('admin', 'super_admin'),
  [body('member_id').isInt(), body('month_number').isInt({ min: 1 })],
  validate,
  ctrl.selectWinner
);
router.get('/:id/winners', authorize('admin', 'super_admin', 'member'), ctrl.winnerHistory);

// Admin – payouts
router.post(
  '/:id/payouts',
  authorize('admin', 'super_admin'),
  [body('winner_id').isInt(), body('amount').isFloat({ min: 0 })],
  validate,
  ctrl.recordPayout
);

module.exports = router;
