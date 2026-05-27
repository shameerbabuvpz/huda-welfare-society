const router = require('express').Router();
const memberAuthController = require('../controllers/memberAuth.controller');
const { authenticate, authorize } = require('../middleware/auth');
const { orgScope } = require('../middleware/orgScope');
const memberAuth = require('../middleware/memberAuth');
const { profilePhotoUpload } = require('../middleware/profilePhotoUpload');

// Public member login (no auth required)
router.post('/login', memberAuthController.loginWithCode);
router.post('/request-otp', memberAuthController.requestPhoneOtp);
router.post('/verify-otp', memberAuthController.verifyPhoneOtp);

// Member-authenticated routes (requires valid member token)
router.post('/change-code', memberAuth, memberAuthController.changeCode);
router.get('/profile', memberAuth, memberAuthController.getProfile);
router.put('/photo', memberAuth, profilePhotoUpload, memberAuthController.updatePhoto);

// Admin routes for managing member codes
router.post('/reset-code', authenticate, authorize('admin', 'super_admin'), orgScope, memberAuthController.resetCodeToDefault);
router.get('/code-status/:memberId', authenticate, authorize('admin', 'super_admin'), orgScope, memberAuthController.getCodeStatus);

module.exports = router;
