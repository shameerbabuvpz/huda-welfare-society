const router = require('express').Router();
const { authenticate, authorize } = require('../middleware/auth');
const { orgScope } = require('../middleware/orgScope');
const ctrl = require('../controllers/report.controller');

router.use(authenticate, authorize('admin', 'super_admin'), orgScope);

router.get('/members', ctrl.memberSummary);
router.get('/assets', ctrl.assetSummary);
router.get('/kuri/:groupId/collections', ctrl.kuriCollectionSummary);
router.get('/kuri/:groupId/payouts', ctrl.kuriPayoutHistory);
router.get('/notifications', ctrl.notificationSummary);

module.exports = router;
