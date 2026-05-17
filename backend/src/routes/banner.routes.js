const router = require('express').Router();
const { authenticate, authorize } = require('../middleware/auth');
const { orgScope } = require('../middleware/orgScope');
const { handleBannerUpload } = require('../middleware/bannerUpload');
const ctrl = require('../controllers/banner.controller');

router.use(authenticate, orgScope);

// ── Member ──
router.get('/active', authorize('member', 'admin', 'super_admin'), ctrl.listActive);

// ── Admin ──
router.get('/', authorize('admin', 'super_admin'), ctrl.list);
router.post('/', authorize('admin', 'super_admin'), handleBannerUpload, ctrl.create);
router.get('/:id', authorize('admin', 'super_admin'), ctrl.getById);
router.put('/:id', authorize('admin', 'super_admin'), handleBannerUpload, ctrl.update);
router.delete('/:id', authorize('admin', 'super_admin'), ctrl.delete);

module.exports = router;
