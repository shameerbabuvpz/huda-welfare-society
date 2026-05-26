exports.up = async function (knex) {
  // Add current_role column to users table
  const hasCurrentRole = await knex.schema.hasColumn('users', 'current_role');
  if (!hasCurrentRole) {
    await knex.schema.alterTable('users', (t) => {
      t.enu('current_role', ['super_admin', 'admin', 'member']).notNullable().defaultTo(knex.raw('role'));
    });
  }

  // Create user_roles junction table for users with multiple roles
  const hasUserRoles = await knex.schema.hasTable('user_roles');
  if (!hasUserRoles) {
    await knex.schema.createTable('user_roles', (t) => {
      t.increments('id').primary();
      t.integer('user_id').unsigned().notNullable().references('id').inTable('users').onDelete('CASCADE');
      t.integer('organization_id').unsigned().references('id').inTable('organizations').onDelete('CASCADE');
      t.enu('role', ['super_admin', 'admin', 'member']).notNullable();
      t.timestamps(true, true);
      t.unique(['user_id', 'organization_id', 'role']);
    });
  }
};

exports.down = async function (knex) {
  const hasUserRoles = await knex.schema.hasTable('user_roles');
  if (hasUserRoles) {
    await knex.schema.dropTable('user_roles');
  }

  const hasCurrentRole = await knex.schema.hasColumn('users', 'current_role');
  if (hasCurrentRole) {
    await knex.schema.alterTable('users', (t) => {
      t.dropColumn('current_role');
    });
  }
};
