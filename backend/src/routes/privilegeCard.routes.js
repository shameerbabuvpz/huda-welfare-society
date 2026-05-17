const router = require('express').Router();
const { authenticate, authorize } = require('../middleware/auth');
const { orgScope } = require('../middleware/orgScope');
const ctrl = require('../controllers/privilegeCard.controller');

router.use(authenticate, orgScope);

// Member self-service
router.get('/my-card', authorize('member'), ctrl.getMyCard);

// Admin
router.post('/:memberId/generate', authorize('admin', 'super_admin'), ctrl.generate);
router.get('/:memberId', authorize('admin', 'super_admin'), ctrl.getByMember);
router.put('/:cardId/revoke', authorize('admin', 'super_admin'), ctrl.revoke);

module.exports = router;
