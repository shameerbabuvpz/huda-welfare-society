const router = require('express').Router();
const { body } = require('express-validator');
const { validate } = require('../middleware/validate');
const { authenticate, authorize } = require('../middleware/auth');
const { orgScope } = require('../middleware/orgScope');
const ctrl = require('../controllers/finance.controller');

router.use(authenticate, orgScope);

// ─── Categories ───────────────────────────────────────────────
router.post(
  '/categories',
  authorize('admin', 'super_admin'),
  [
    body('name').notEmpty().trim(),
    body('type').isIn(['income', 'expense']),
  ],
  validate,
  ctrl.createCategory
);

router.get('/categories', authorize('admin', 'super_admin'), ctrl.listCategories);
router.delete('/categories/:id', authorize('admin', 'super_admin'), ctrl.deleteCategory);

// ─── Transactions ─────────────────────────────────────────────
router.post(
  '/transactions',
  authorize('admin', 'super_admin'),
  [
    body('category_id').isInt(),
    body('type').isIn(['income', 'expense']),
    body('amount').isFloat({ gt: 0 }),
    body('date').isISO8601(),
    body('description').optional().trim(),
  ],
  validate,
  ctrl.createTransaction
);

router.get('/transactions', authorize('admin', 'super_admin'), ctrl.listTransactions);
router.delete('/transactions/:id', authorize('admin', 'super_admin'), ctrl.deleteTransaction);

// ─── Summary ──────────────────────────────────────────────────
router.get('/summary', authorize('admin', 'super_admin'), ctrl.getSummary);

module.exports = router;
