const knex = require('knex');
const config = require('../../knexfile');

// Return PostgreSQL DATE columns (OID 1082) as plain 'YYYY-MM-DD' strings
// instead of JS Date objects, to avoid timezone shifting the day.
try {
  const pgTypes = require('pg').types;
  pgTypes.setTypeParser(1082, (val) => val);
} catch (_) {
  // pg not available (e.g. sqlite) — safe to ignore
}

const env = process.env.NODE_ENV || 'development';
const db = knex(config[env]);

module.exports = db;
