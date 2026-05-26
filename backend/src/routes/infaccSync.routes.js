const router = require('express').Router();
const { authenticate, authorize } = require('../middleware/auth');
const { orgScope } = require('../middleware/orgScope');
const controller = require('../controllers/infaccSync.controller');

router.use(authenticate, orgScope);

router.get('/status', authorize('admin', 'super_admin'), controller.getStatus);
router.post('/credentials', authorize('admin', 'super_admin'), controller.setCredentials);
router.post('/preview', authorize('admin', 'super_admin'), controller.preview);
router.post('/sync', authorize('admin', 'super_admin'), controller.sync);

module.exports = router;
