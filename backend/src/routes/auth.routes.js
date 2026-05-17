const router = require('express').Router();
const { body } = require('express-validator');
const { validate } = require('../middleware/validate');
const authController = require('../controllers/auth.controller');
const { authenticate } = require('../middleware/auth');
const { profilePhotoUpload } = require('../middleware/profilePhotoUpload');

// Phone + OTP auth
router.post(
  '/request-otp',
  [body('phone').matches(/^\d{10}$/).withMessage('Phone must be exactly 10 digits')],
  validate,
  authController.requestOtp
);

router.post(
  '/verify-otp',
  [
    body('phone').matches(/^\d{10}$/).withMessage('Phone must be exactly 10 digits'),
    body('otp').isLength({ min: 4, max: 6 }).withMessage('OTP must be 4-6 digits'),
  ],
  validate,
  authController.verifyOtp
);

router.put('/fcm-token', authenticate, [body('fcm_token').notEmpty()], validate, authController.updateFcmToken);

router.get('/me', authenticate, authController.me);

router.put(
  '/profile',
  authenticate,
  [body('name').optional().isString().trim().isLength({ min: 1, max: 100 })],
  validate,
  authController.updateProfile
);

router.put(
  '/photo',
  authenticate,
  profilePhotoUpload,
  authController.updatePhoto
);

// Get org info for the authenticated user
router.get('/org-info', authenticate, authController.getOrgInfo);

module.exports = router;
