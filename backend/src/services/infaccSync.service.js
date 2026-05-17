const https = require('https');
const http = require('http');
const { URL } = require('url');
const db = require('../config/database');

const INFACC_BASE = 'https://app.infacc.org/backend/web';
const MEMBER_URL = `${INFACC_BASE}/member/index`;
const LOGIN_URL = `${INFACC_BASE}/site/login`;
const TOTAL_PAGES = 50;

// ─── HTTP helpers ───

function httpsRequest(url, options = {}) {
  return new Promise((resolve, reject) => {
    const parsed = new URL(url);
    const reqOpts = {
      hostname: parsed.hostname,
      path: parsed.pathname + parsed.search,
      method: options.method || 'GET',
      headers: { 'User-Agent': 'Mozilla/5.0', ...options.headers },
    };

    const req = https.request(reqOpts, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve({ statusCode: res.statusCode, headers: res.headers, body: data }));
    });
    req.on('error', reject);
    if (options.body) req.write(options.body);
    req.end();
  });
}

function extractCookies(headers) {
  const setCookies = headers['set-cookie'] || [];
  const cookies = {};
  setCookies.forEach(c => {
    const match = c.match(/^([^=]+)=([^;]*)/);
    if (match) cookies[match[1]] = match[2];
  });
  return cookies;
}

function cookieString(cookieObj) {
  return Object.entries(cookieObj).map(([k, v]) => `${k}=${v}`).join('; ');
}

// ─── INFACC Login ───

async function loginToInfacc(phone, password) {
  // Step 1: GET login page to get CSRF token
  const loginPage = await httpsRequest(LOGIN_URL);
  const csrfMatch = loginPage.body.match(/name="csrf-token"\s+content="([^"]+)"/);
  const csrfInput = loginPage.body.match(/name="_csrf-backend"\s+value="([^"]+)"/);
  // Also try input field pattern
  const csrfInputAlt = loginPage.body.match(/"_csrf-backend"\s*value="([^"]+)"/);

  const csrf = csrfInput ? csrfInput[1] : (csrfInputAlt ? csrfInputAlt[1] : (csrfMatch ? csrfMatch[1] : ''));

  const pageCookies = extractCookies(loginPage.headers);

  // Step 2: POST login form
  const formData = [
    `_csrf-backend=${encodeURIComponent(csrf)}`,
    `LoginForm[username]=${encodeURIComponent(phone)}`,
    `LoginForm[password]=${encodeURIComponent(password)}`,
    `LoginForm[rememberMe]=1`,
  ].join('&');

  const loginRes = await httpsRequest(LOGIN_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Cookie': cookieString(pageCookies),
      'Referer': LOGIN_URL,
    },
    body: formData,
  });

  // Successful login = redirect (302)
  const newCookies = { ...pageCookies, ...extractCookies(loginRes.headers) };

  // Verify by fetching member page
  const testPage = await httpsRequest(`${MEMBER_URL}?page=1`, {
    headers: { 'Cookie': cookieString(newCookies) },
  });

  if (testPage.body.includes('login-form') || testPage.body.includes('Sign in') || testPage.statusCode === 302) {
    return null; // Login failed
  }

  return cookieString(newCookies);
}

// ─── Data fetching ───

function fetchPage(page, cookie) {
  return new Promise((resolve, reject) => {
    const url = `${MEMBER_URL}?page=${page}`;
    https.get(url, {
      headers: { 'Cookie': cookie, 'User-Agent': 'Mozilla/5.0' }
    }, (res) => {
      if (res.statusCode === 302 || res.statusCode === 301) {
        return reject(new Error('SESSION_EXPIRED'));
      }
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (data.includes('login-form') || data.includes('Sign in')) {
          return reject(new Error('SESSION_EXPIRED'));
        }
        resolve(data);
      });
    }).on('error', reject);
  });
}

function parseMembers(html) {
  const members = [];
  const rowRegex = /<tr[^>]*data-key="[^"]*"[^>]*>([\s\S]*?)<\/tr>/g;
  let rowMatch;

  while ((rowMatch = rowRegex.exec(html)) !== null) {
    const row = rowMatch[1];
    const cells = [];
    const cellRegex = /<td[^>]*>([\s\S]*?)<\/td>/g;
    let cellMatch;
    while ((cellMatch = cellRegex.exec(row)) !== null) {
      cells.push(cellMatch[1]);
    }

    if (cells.length < 5) continue;

    const usernameText = cells[2].replace(/<[^>]+>/g, '').trim();
    const phoneMatch = usernameText.match(/(\d{10})/);
    const nameMatch = usernameText.match(/\[\s*(.+?)\s*\]/);
    const memberIdText = cells[3].replace(/<[^>]+>/g, '').trim();
    const nhgText = cells[4].replace(/<[^>]+>/g, '').trim();
    const nhgCodeMatch = nhgText.match(/\[\s*(PKD\/[\d\/]+)\s*\]/);
    const nhgName = nhgText.replace(/\[.*?\]/, '').trim();
    const photoMatch = cells[1].match(/file=([^"&]+)/);

    members.push({
      phone: phoneMatch ? phoneMatch[1] : '',
      name: nameMatch ? nameMatch[1].trim() : '',
      memberId: memberIdText,
      nhgName,
      nhgCode: nhgCodeMatch ? nhgCodeMatch[1] : '',
      photo: photoMatch ? `https://app.infacc.org/backend/web/resizes/index?type=user&size=0_0&file=${photoMatch[1]}` : ''
    });
  }

  return members;
}

const infaccSyncService = {
  async getCredentials(orgId) {
    const phone = await db('app_settings').where({ organization_id: orgId, key: 'infacc_phone' }).first();
    const password = await db('app_settings').where({ organization_id: orgId, key: 'infacc_password' }).first();
    return { phone: phone?.value, password: password?.value };
  },

  async setCredentials(orgId, phone, password) {
    for (const [key, value] of [['infacc_phone', phone], ['infacc_password', password]]) {
      const existing = await db('app_settings').where({ organization_id: orgId, key }).first();
      if (existing) {
        await db('app_settings').where({ id: existing.id }).update({ value, updated_at: db.fn.now() });
      } else {
        await db('app_settings').insert({ organization_id: orgId, key, value });
      }
    }
  },

  async getCookie(orgId) {
    const setting = await db('app_settings')
      .where({ organization_id: orgId, key: 'infacc_cookie' })
      .first();
    return setting?.value || null;
  },

  async setCookie(orgId, cookie) {
    const existing = await db('app_settings')
      .where({ organization_id: orgId, key: 'infacc_cookie' })
      .first();
    if (existing) {
      await db('app_settings').where({ id: existing.id }).update({ value: cookie, updated_at: db.fn.now() });
    } else {
      await db('app_settings').insert({ organization_id: orgId, key: 'infacc_cookie', value: cookie });
    }
  },

  async sync(orgId) {
    // Try existing cookie first, then login with credentials
    let cookie = await this.getCookie(orgId);
    let loggedIn = false;

    // Test if existing cookie works
    if (cookie) {
      try {
        await fetchPage(1, cookie);
      } catch {
        cookie = null; // Expired
      }
    }

    // If no valid cookie, login with credentials
    if (!cookie) {
      const creds = await this.getCredentials(orgId);
      if (!creds.phone || !creds.password) {
        return { success: false, error: 'NO_CREDENTIALS', message: 'INFACC credentials not configured. Set phone and password first.' };
      }

      cookie = await loginToInfacc(creds.phone, creds.password);
      if (!cookie) {
        return { success: false, error: 'LOGIN_FAILED', message: 'INFACC login failed. Check phone and password.' };
      }

      // Save the new cookie
      await this.setCookie(orgId, cookie);
      loggedIn = true;
    }

    // Fetch all pages
    const allMembers = [];
    try {
      for (let p = 1; p <= TOTAL_PAGES; p++) {
        try {
          const html = await fetchPage(p, cookie);
          const members = parseMembers(html);
          if (members.length === 0) break;
          allMembers.push(...members);
        } catch (err) {
          if (err.message === 'SESSION_EXPIRED') throw err;
        }
      }
    } catch (err) {
      if (err.message === 'SESSION_EXPIRED') {
        // Try re-login once
        if (!loggedIn) {
          const creds = await this.getCredentials(orgId);
          if (creds.phone && creds.password) {
            cookie = await loginToInfacc(creds.phone, creds.password);
            if (cookie) {
              await this.setCookie(orgId, cookie);
              // Retry from start
              return this.sync(orgId);
            }
          }
        }
        return { success: false, error: 'SESSION_EXPIRED', message: 'INFACC session expired and re-login failed.' };
      }
      return { success: false, error: 'FETCH_ERROR', message: err.message };
    }

    if (allMembers.length === 0) {
      return { success: false, error: 'NO_DATA', message: 'No members found in INFACC.' };
    }

    // Group by NHG
    const nhgMap = {};
    allMembers.forEach(m => {
      const key = m.nhgCode || m.nhgName || 'UNKNOWN';
      if (!nhgMap[key]) {
        nhgMap[key] = { nhgName: m.nhgName, nhgCode: m.nhgCode, members: [] };
      }
      nhgMap[key].members.push(m);
    });
    const nhgGroups = Object.values(nhgMap);

    // Upsert ayalkoottams
    let ayalkoottamsCreated = 0;
    let ayalkoottamsUpdated = 0;
    for (const nhg of nhgGroups) {
      if (!nhg.nhgCode) continue;
      const existing = await db('ayalkoottams').where({ organization_id: orgId, code: nhg.nhgCode }).first();
      if (existing) {
        if (existing.name !== nhg.nhgName) {
          await db('ayalkoottams').where({ id: existing.id }).update({ name: nhg.nhgName, place: nhg.nhgName, updated_at: db.fn.now() });
          ayalkoottamsUpdated++;
        }
      } else {
        await db('ayalkoottams').insert({
          organization_id: orgId,
          name: nhg.nhgName,
          code: nhg.nhgCode,
          place: nhg.nhgName,
          status: 'active',
        });
        ayalkoottamsCreated++;
      }
    }

    // Build code→id map
    const akRows = await db('ayalkoottams').where({ organization_id: orgId }).select('id', 'code');
    const codeToAkId = {};
    akRows.forEach(a => { codeToAkId[a.code] = a.id; });

    // Upsert members
    let membersCreated = 0;
    let membersUpdated = 0;
    for (const m of allMembers) {
      if (!m.phone) continue;
      const akId = codeToAkId[m.nhgCode] || null;

      // Primary match: phone number. Secondary match: member_code (INFACC ID)
      let existing = await db('members').where({ organization_id: orgId, phone: m.phone }).first();
      if (!existing && m.memberId) {
        existing = await db('members').where({ organization_id: orgId, member_code: m.memberId }).first();
      }

      if (existing) {
        const updates = {};
        if (m.name && existing.name !== m.name) updates.name = m.name;
        if (m.memberId && existing.member_code !== m.memberId) updates.member_code = m.memberId;
        if (m.phone && existing.phone !== m.phone) updates.phone = m.phone;
        if (akId && existing.ayalkoottam_id !== akId) updates.ayalkoottam_id = akId;
        if (m.photo && existing.photo_url !== m.photo) updates.photo_url = m.photo;

        if (Object.keys(updates).length > 0) {
          updates.updated_at = db.fn.now();
          await db('members').where({ id: existing.id }).update(updates);
          membersUpdated++;
        }
      } else {
        await db('members').insert({
          organization_id: orgId,
          name: m.name || 'Unknown',
          phone: m.phone,
          member_code: m.memberId || `INFACC-${m.phone}`,
          ayalkoottam_id: akId,
          photo_url: m.photo || null,
          status: 'active',
          join_date: new Date(),
        });
        membersCreated++;
      }
    }

    // Save sync result
    const syncResult = {
      syncedAt: new Date().toISOString(),
      totalFetched: allMembers.length,
      ayalkoottams: { created: ayalkoottamsCreated, updated: ayalkoottamsUpdated, total: nhgGroups.length },
      members: { created: membersCreated, updated: membersUpdated, total: allMembers.length },
    };

    const existingSyncTime = await db('app_settings').where({ organization_id: orgId, key: 'infacc_last_sync' }).first();
    if (existingSyncTime) {
      await db('app_settings').where({ id: existingSyncTime.id }).update({ value: JSON.stringify(syncResult), updated_at: db.fn.now() });
    } else {
      await db('app_settings').insert({ organization_id: orgId, key: 'infacc_last_sync', value: JSON.stringify(syncResult) });
    }

    return { success: true, ...syncResult };
  },

  async getLastSync(orgId) {
    const setting = await db('app_settings').where({ organization_id: orgId, key: 'infacc_last_sync' }).first();
    if (!setting) return null;
    try { return JSON.parse(setting.value); } catch { return null; }
  },
};

module.exports = infaccSyncService;
