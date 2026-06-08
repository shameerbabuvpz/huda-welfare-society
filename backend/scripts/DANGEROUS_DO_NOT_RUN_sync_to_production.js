#!/usr/bin/env node
/**
 * Sync local data (987 members + 53 ayalkoottams) to production DB
 * Only syncs org_id=2 (Hudha Welfare Society, Pottachira)
 */
const localDb = require('../src/config/database');
const knex = require('knex');

const PROD_URL = 'postgresql://postgres:hUhXzPqOZUysDAIBCBpmKLIIPbdUxKVx@viaduct.proxy.rlwy.net:42386/railway';
const ORG_ID = 2;

async function sync() {
  const prodDb = knex({ client: 'pg', connection: PROD_URL });

  try {
    // 1. Get local data
    const localAks = await localDb('ayalkoottams').where({ organization_id: ORG_ID }).select('*');
    const localMembers = await localDb('members').where({ organization_id: ORG_ID }).select('*');
    console.log(`Local: ${localAks.length} ayalkoottams, ${localMembers.length} members`);

    // 2. Clear existing prod data for this org (members first due to FK)
    const delMembers = await prodDb('members').where({ organization_id: ORG_ID }).del();
    const delAks = await prodDb('ayalkoottams').where({ organization_id: ORG_ID }).del();
    console.log(`Cleared prod: ${delMembers} members, ${delAks} ayalkoottams`);

    // 3. Insert ayalkoottams (reset sequences)
    for (const ak of localAks) {
      const { id, ...data } = ak;
      await prodDb('ayalkoottams').insert({ ...data, id });
    }
    console.log(`Inserted ${localAks.length} ayalkoottams`);

    // 4. Insert members in batches of 50
    const batchSize = 50;
    let inserted = 0;
    for (let i = 0; i < localMembers.length; i += batchSize) {
      const batch = localMembers.slice(i, i + batchSize).map(m => {
        const { ...data } = m;
        return data;
      });
      await prodDb('members').insert(batch);
      inserted += batch.length;
      if (inserted % 200 === 0) console.log(`  ... ${inserted} members inserted`);
    }
    console.log(`Inserted ${inserted} members total`);

    // 5. Fix sequences
    const maxAkId = Math.max(...localAks.map(a => a.id));
    const maxMemId = Math.max(...localMembers.map(m => m.id));
    await prodDb.raw(`SELECT setval('ayalkoottams_id_seq', ${maxAkId}, true)`);
    await prodDb.raw(`SELECT setval('members_id_seq', ${maxMemId}, true)`);
    console.log(`Sequences reset: ayalkoottams=${maxAkId}, members=${maxMemId}`);

    // 6. Also clean up test orgs (keep only org 2)
    await prodDb('organizations').whereNot({ id: ORG_ID }).del();
    console.log('Removed test organizations (kept only org 2)');

    // 7. Verify
    const finalMembers = await prodDb('members').where({ organization_id: ORG_ID }).count('* as c');
    const finalAks = await prodDb('ayalkoottams').where({ organization_id: ORG_ID }).count('* as c');
    console.log(`\n✓ Production now: ${finalAks[0].c} ayalkoottams, ${finalMembers[0].c} members`);

  } finally {
    await prodDb.destroy();
    await localDb.destroy();
  }
}

sync().catch(err => {
  console.error('FAILED:', err.message);
  process.exit(1);
});
