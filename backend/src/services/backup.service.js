const { Client } = require('pg');
const db = require('../config/database');
const ApiError = require('../utils/ApiError');

// pg's escapeLiteral / escapeIdentifier are pure-string helpers that work
// without an active connection. Reuse a single (unconnected) client instance.
const pgEscaper = new Client();

function escapeLiteral(value) {
  return pgEscaper.escapeLiteral(value);
}

function quoteIdent(name) {
  return pgEscaper.escapeIdentifier(name);
}

async function listBaseTables() {
  const result = await db.raw(`
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
    ORDER BY table_name
  `);
  return result.rows.map((r) => r.table_name);
}

async function listColumns(table) {
  const result = await db.raw(
    `
    SELECT column_name, column_default
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = ?
    ORDER BY ordinal_position
  `,
    [table]
  );
  return result.rows;
}

/**
 * Generate a self-contained, portable SQL dump of the entire database.
 *
 * Every value is selected as ::text and emitted as a string literal; on
 * restore PostgreSQL coerces the unknown-typed literal back into the column
 * type, giving a faithful round-trip without per-type formatting.
 *
 * The script wraps everything in a single transaction and disables FK
 * triggers (session_replication_role = replica) so insert order and circular
 * foreign keys do not matter.
 */
async function generateSqlDump() {
  const tables = await listBaseTables();
  if (tables.length === 0) {
    throw ApiError.internal('No tables found to back up');
  }

  const lines = [];
  lines.push('-- Ayalkoottam database backup');
  lines.push(`-- Generated: ${new Date().toISOString()}`);
  lines.push(`-- Tables: ${tables.length}`);
  lines.push('-- Restore with the in-app Restore feature or: psql "<DATABASE_URL>" -f <file>.sql');
  lines.push('');
  lines.push('BEGIN;');
  lines.push('SET session_replication_role = replica;');
  lines.push('');
  lines.push(`TRUNCATE ${tables.map(quoteIdent).join(', ')} RESTART IDENTITY CASCADE;`);
  lines.push('');

  const sequenceResets = [];

  for (const table of tables) {
    const columns = await listColumns(table);
    const columnNames = columns.map((c) => c.column_name);

    const selectList = columnNames
      .map((c) => `${quoteIdent(c)}::text AS ${quoteIdent(c)}`)
      .join(', ');
    const dataResult = await db.raw(`SELECT ${selectList} FROM ${quoteIdent(table)}`);
    const rows = dataResult.rows;

    if (rows.length > 0) {
      lines.push(`-- ${table} (${rows.length} rows)`);
      const columnList = columnNames.map(quoteIdent).join(', ');
      const BATCH = 500;
      for (let i = 0; i < rows.length; i += BATCH) {
        const batch = rows.slice(i, i + BATCH);
        const valuesSql = batch
          .map((row) => {
            const vals = columnNames.map((c) => {
              const v = row[c];
              return v === null || v === undefined ? 'NULL' : escapeLiteral(v);
            });
            return `  (${vals.join(', ')})`;
          })
          .join(',\n');
        lines.push(`INSERT INTO ${quoteIdent(table)} (${columnList}) VALUES\n${valuesSql};`);
      }
      lines.push('');
    }

    // Reset sequences for serial / auto-increment columns
    for (const col of columns) {
      if (col.column_default && col.column_default.startsWith('nextval(')) {
        const colIdent = quoteIdent(col.column_name);
        const tableIdent = quoteIdent(table);
        sequenceResets.push(
          `SELECT setval(pg_get_serial_sequence(${escapeLiteral(table)}, ${escapeLiteral(
            col.column_name
          )}), GREATEST((SELECT COALESCE(MAX(${colIdent}), 0) FROM ${tableIdent}), 1), (SELECT COUNT(*) > 0 FROM ${tableIdent}));`
        );
      }
    }
  }

  if (sequenceResets.length > 0) {
    lines.push('-- Reset auto-increment sequences');
    lines.push(...sequenceResets);
    lines.push('');
  }

  lines.push('SET session_replication_role = DEFAULT;');
  lines.push('COMMIT;');
  lines.push('');

  return lines.join('\n');
}

/**
 * Restore the database from a SQL dump produced by generateSqlDump().
 * The dump already wraps itself in BEGIN/COMMIT, so a failure rolls back
 * cleanly and leaves the existing data untouched.
 */
async function restoreFromSql(sqlText) {
  if (typeof sqlText !== 'string' || sqlText.trim().length === 0) {
    throw ApiError.badRequest('Backup file is empty');
  }
  const looksValid =
    sqlText.includes('BEGIN;') &&
    sqlText.includes('COMMIT;') &&
    /TRUNCATE\s/i.test(sqlText) &&
    /INSERT INTO\s/i.test(sqlText);
  if (!looksValid) {
    throw ApiError.badRequest('File does not look like a valid Ayalkoottam backup');
  }

  await db.raw(sqlText);

  const tables = await listBaseTables();
  let totalRows = 0;
  for (const table of tables) {
    const r = await db.raw(`SELECT COUNT(*)::int AS c FROM ${quoteIdent(table)}`);
    totalRows += r.rows[0].c;
  }
  return { tables: tables.length, totalRows };
}

module.exports = { generateSqlDump, restoreFromSql };
