exports.up = function (knex) {
  return knex.schema.createTable('app_settings', (table) => {
    table.increments('id');
    table.integer('organization_id').references('id').inTable('organizations').onDelete('CASCADE');
    table.string('key').notNullable();
    table.text('value');
    table.timestamp('updated_at').defaultTo(knex.fn.now());
    table.unique(['organization_id', 'key']);
  });
};

exports.down = function (knex) {
  return knex.schema.dropTableIfExists('app_settings');
};
