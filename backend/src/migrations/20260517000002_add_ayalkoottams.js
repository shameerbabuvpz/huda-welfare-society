exports.up = async function (knex) {
  // ── Ayalkoottams (neighborhood groups under organization) ──
  await knex.schema.createTable('ayalkoottams', (t) => {
    t.increments('id').primary();
    t.integer('organization_id').unsigned().notNullable().references('id').inTable('organizations').onDelete('CASCADE');
    t.string('name').notNullable();
    t.string('code').notNullable();
    t.string('president');
    t.string('secretary');
    t.string('ward_number');
    t.text('address');
    t.string('phone');
    t.enu('status', ['active', 'inactive']).defaultTo('active');
    t.integer('created_by').unsigned().references('id').inTable('users');
    t.integer('updated_by').unsigned().references('id').inTable('users');
    t.timestamps(true, true);
    t.unique(['organization_id', 'code']);
  });

  // ── Add ayalkoottam_id to members ──
  await knex.schema.alterTable('members', (t) => {
    t.integer('ayalkoottam_id').unsigned().references('id').inTable('ayalkoottams').onDelete('SET NULL').after('organization_id');
  });
};

exports.down = async function (knex) {
  await knex.schema.alterTable('members', (t) => {
    t.dropColumn('ayalkoottam_id');
  });
  await knex.schema.dropTableIfExists('ayalkoottams');
};
