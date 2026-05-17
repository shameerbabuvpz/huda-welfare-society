exports.up = async function (knex) {
  // Add condition_on_return to track what state asset was in when returned
  await knex.schema.alterTable('asset_transactions', (t) => {
    t.enu('condition_on_return', ['working', 'damaged', 'missing']).nullable();
    t.integer('returned_by').unsigned().references('id').inTable('users').nullable();
    t.text('issue_remarks').nullable();
  });

  // Ensure asset status constraint includes all states
  await knex.raw(`
    ALTER TABLE assets DROP CONSTRAINT IF EXISTS assets_status_check;
    ALTER TABLE assets ADD CONSTRAINT assets_status_check 
      CHECK (status IN ('available', 'issued', 'retired', 'damaged', 'missing'));
  `);

  // Update asset_transactions status to include more states
  await knex.raw(`
    ALTER TABLE asset_transactions DROP CONSTRAINT IF EXISTS asset_transactions_status_check;
    ALTER TABLE asset_transactions ADD CONSTRAINT asset_transactions_status_check 
      CHECK (status IN ('issued', 'returned', 'returned_damaged', 'returned_missing', 'overdue'));
  `);
};

exports.down = async function (knex) {
  await knex.schema.alterTable('asset_transactions', (t) => {
    t.dropColumn('condition_on_return');
    t.dropColumn('returned_by');
    t.dropColumn('issue_remarks');
  });

  await knex.raw(`
    ALTER TABLE asset_transactions DROP CONSTRAINT IF EXISTS asset_transactions_status_check;
    ALTER TABLE asset_transactions ADD CONSTRAINT asset_transactions_status_check 
      CHECK (status IN ('issued', 'returned'));
  `);
};
