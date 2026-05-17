exports.up = function (knex) {
  return knex.schema.createTable('banners', (table) => {
    table.increments('id').primary();
    table.integer('organization_id').unsigned().notNullable()
      .references('id').inTable('organizations').onDelete('CASCADE');
    table.string('title').notNullable();
    table.string('image_url').notNullable();
    table.integer('sort_order').defaultTo(0);
    table.boolean('is_active').defaultTo(true);
    table.integer('created_by').unsigned().references('id').inTable('users');
    table.integer('updated_by').unsigned().references('id').inTable('users');
    table.timestamps(true, true);
  });
};

exports.down = function (knex) {
  return knex.schema.dropTableIfExists('banners');
};
