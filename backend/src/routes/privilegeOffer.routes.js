const router = require('express').Router();
const { authenticate, authorize } = require('../middleware/auth');
const { orgScope } = require('../middleware/orgScope');
const { handleOfferUpload } = require('../middleware/offerImageUpload');
const ctrl = require('../controllers/privilegeOffer.controller');

router.use(authenticate, orgScope);

// ── Member ──
router.get('/active', authorize('member', 'admin', 'super_admin'), ctrl.listActive);
router.post('/redeem', authorize('member'), ctrl.redeem);
router.get('/my-redemptions', authorize('member'), ctrl.myRedemptions);

// ── Admin ──
router.get('/', authorize('admin', 'super_admin'), ctrl.list);
router.post('/', authorize('admin', 'super_admin'), handleOfferUpload, ctrl.create);
router.get('/:id', authorize('admin', 'super_admin'), ctrl.getById);
router.put('/:id', authorize('admin', 'super_admin'), handleOfferUpload, ctrl.update);
router.delete('/:id', authorize('admin', 'super_admin'), ctrl.delete);

module.exports = router;
