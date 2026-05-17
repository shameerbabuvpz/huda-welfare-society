const router = require('express').Router();
const { authenticate, authorize } = require('../middleware/auth');
const { orgScope } = require('../middleware/orgScope');
const ctrl = require('../controllers/export.controller');

router.use(authenticate, authorize('admin', 'super_admin'), orgScope);

// Members export
router.get('/members/excel', ctrl.membersExcel);
router.get('/members/pdf', ctrl.membersPdf);

// Kuri export
router.get('/kuri/:groupId/excel', ctrl.kuriExcel);
router.get('/kuri/:groupId/pdf', ctrl.kuriPdf);

// Kaneev export
router.get('/kaneev/excel', ctrl.kaneevExcel);
router.get('/kaneev/pdf', ctrl.kaneevPdf);

// Finance export
router.get('/finance/excel', ctrl.financeExcel);
router.get('/finance/pdf', ctrl.financePdf);

module.exports = router;
