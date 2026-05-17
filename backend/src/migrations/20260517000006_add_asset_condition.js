exports.up = async function (knex) {
  // Drop the existing enum constraint and recreate with more values
  await knex.raw(`
    ALTER TABLE assets DROP CONSTRAINT IF EXISTS assets_status_check;
    ALTER TABLE assets ADD CONSTRAINT assets_status_check 
      CHECK (status IN ('available', 'issued', 'retired', 'damaged', 'missing'));
  `);
  // Add condition column
  await knex.schema.alterTable('assets', (t) => {
    t.enu('condition', ['working', 'damaged', 'missing']).defaultTo('working');
  });
};

exports.down = async function (knex) {
  await knex.schema.alterTable('assets', (t) => {
    t.dropColumn('condition');
  });
  await knex.raw(`
    ALTER TABLE assets DROP CONSTRAINT IF EXISTS assets_status_check;
    ALTER TABLE assets ADD CONSTRAINT assets_status_check 
      CHECK (status IN ('available', 'issued', 'retired'));
  `);
};
