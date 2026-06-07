const router = require('express').Router();
const { body, query } = require('express-validator');
const { validate } = require('../middleware/validate');
const { authenticate, authorize } = require('../middleware/auth');
const { orgScope } = require('../middleware/orgScope');
const ctrl = require('../controllers/weeklyCollection.controller');

router.use(authenticate, orgScope);

// ─── Consolidated report ──────────────────────────────────────
router.get(
  '/consolidated',
  authorize('admin', 'super_admin'),
  [query('group_by').optional().isIn(['week', 'month'])],
  validate,
  ctrl.consolidated
);

// ─── Entries ──────────────────────────────────────────────────
router.post(
  '/',
  authorize('admin', 'super_admin'),
  [
    body('ayalkoottam_id').isInt(),
    body('week_start_date').isISO8601(),
    body('deposit').optional().isFloat({ min: 0 }),
    body('withdrawal').optional().isFloat({ min: 0 }),
    body('loan').optional().isFloat({ min: 0 }),
    body('loan_repayment').optional().isFloat({ min: 0 }),
    body('adjustment').optional().isFloat({ min: 0 }),
    body('note').optional().trim(),
  ],
  validate,
  ctrl.upsert
);

router.get('/', authorize('admin', 'super_admin'), ctrl.list);
router.get('/balance/:ayalkoottam_id', authorize('admin', 'super_admin'), ctrl.getBalance);
router.get('/:id', authorize('admin', 'super_admin'), ctrl.getById);
router.put('/:id', authorize('admin', 'super_admin'), ctrl.update);
router.delete('/:id', authorize('admin', 'super_admin'), ctrl.remove);

module.exports = router;
