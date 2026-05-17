const router = require('express').Router();
const { body } = require('express-validator');
const { validate } = require('../middleware/validate');
const { authenticate, authorize } = require('../middleware/auth');
const { orgScope } = require('../middleware/orgScope');
const ctrl = require('../controllers/kaneev.controller');

router.use(authenticate, orgScope);

// Member self-service
router.get('/my-kaneev', authorize('member'), ctrl.myKaneev);

// Admin – single group (auto-created)
router.get('/group', authorize('admin', 'super_admin', 'member'), ctrl.getGroup);
router.put('/group', authorize('admin', 'super_admin'), ctrl.updateGroup);

// Admin – members
router.post(
  '/members',
  authorize('admin', 'super_admin'),
  [body('member_id').isInt()],
  validate,
  ctrl.addMember
);
router.delete('/members/:memberId', authorize('admin', 'super_admin'), ctrl.removeMember);

// Admin – donations
router.post(
  '/donations',
  authorize('admin', 'super_admin'),
  [body('member_id').isInt(), body('month_number').isInt({ min: 1 })],
  validate,
  ctrl.recordDonation
);
router.get('/donations', authorize('admin', 'super_admin'), ctrl.getDonations);

// Admin – recipients
router.post(
  '/recipients',
  authorize('admin', 'super_admin'),
  [body('member_id').isInt(), body('month_number').isInt({ min: 1 })],
  validate,
  ctrl.selectRecipient
);
router.get('/recipients', authorize('admin', 'super_admin'), ctrl.recipientHistory);

// Admin – balance
router.get('/balance', authorize('admin', 'super_admin'), ctrl.getBalanceHistory);

module.exports = router;
