const router = require('express').Router();

router.use('/auth', require('./auth.routes'));
router.use('/organizations', require('./organization.routes'));
router.use('/ayalkoottams', require('./ayalkoottam.routes'));
router.use('/members', require('./member.routes'));
router.use('/privilege-cards', require('./privilegeCard.routes'));
router.use('/privilege-offers', require('./privilegeOffer.routes'));
router.use('/assets', require('./asset.routes'));
router.use('/kuri', require('./kuri.routes'));
router.use('/kaneev', require('./kaneev.routes'));
router.use('/notifications', require('./notification.routes'));
router.use('/reports', require('./report.routes'));
router.use('/export', require('./export.routes'));
router.use('/finance', require('./finance.routes'));
router.use('/admins', require('./admin.routes'));
router.use('/banners', require('./banner.routes'));
router.use('/infacc-sync', require('./infaccSync.routes'));

module.exports = router;
