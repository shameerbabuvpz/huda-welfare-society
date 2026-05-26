exports.up = async function (knex) {
  const hasLoginCode = await knex.schema.hasColumn('members', 'login_code');
  if (!hasLoginCode) {
    await knex.schema.alterTable('members', (t) => {
      t.string('login_code').notNullable().defaultTo('6789');
    });
  }
  const hasCodeChanged = await knex.schema.hasColumn('members', 'code_changed');
  if (!hasCodeChanged) {
    await knex.schema.alterTable('members', (t) => {
      t.boolean('code_changed').notNullable().defaultTo(false);
    });
  }
};

exports.down = async function (knex) {
  const hasLoginCode = await knex.schema.hasColumn('members', 'login_code');
  if (hasLoginCode) {
    await knex.schema.alterTable('members', (t) => {
      t.dropColumn('login_code');
    });
  }
  const hasCodeChanged = await knex.schema.hasColumn('members', 'code_changed');
  if (hasCodeChanged) {
    await knex.schema.alterTable('members', (t) => {
      t.dropColumn('code_changed');
    });
  }
};
