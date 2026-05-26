const router = require('express').Router();
const memberAuthController = require('../controllers/memberAuth.controller');
const { authenticate, authorize } = require('../middleware/auth');
const { orgScope } = require('../middleware/orgScope');
const memberAuth = require('../middleware/memberAuth');

// Public member login (no auth required)
router.post('/login', memberAuthController.loginWithCode);

// Member-authenticated routes (requires valid member token)
router.post('/change-code', memberAuth, memberAuthController.changeCode);
router.get('/profile', memberAuth, memberAuthController.getProfile);

// Admin routes for managing member codes
router.post('/reset-code', authenticate, authorize('admin', 'super_admin'), orgScope, memberAuthController.resetCodeToDefault);
router.get('/code-status/:memberId', authenticate, authorize('admin', 'super_admin'), orgScope, memberAuthController.getCodeStatus);

module.exports = router;
