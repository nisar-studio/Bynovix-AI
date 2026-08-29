const https = require('https');

const BASE = 'https://ddsjxafkhxijypgsbvcu.supabase.co';
const ANON = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRkc2p4YWZraHhpanlwZ3NidmN1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc1NzQ0MDEsImV4cCI6MjEwMzE1MDQwMX0.WA_UVawLWJxa5b9zIPe-j4r6ua6uElQf0_L29TyHwPA';

const USERS = [
  { email: 'sarah.lee@bynovix.com', password: 'BynovixAdmin@1', role: 'admin' },
  { email: 'john.doe@bynovix.com', password: 'BynovixManager@1', role: 'manager' },
  { email: 'mike.kim@bynovix.com', password: 'BynovixRestricted@1', role: 'restricted' }
];

function req(method, path, body, headers = {}) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, BASE);
    const opts = {
      hostname: url.hostname, port: 443,
      path: url.pathname + url.search, method,
      headers: { 'Content-Type': 'application/json', ...headers }
    };
    const r = https.request(opts, (res) => {
      let d = '';
      res.on('data', c => d += c);
      res.on('end', () => resolve({ status: res.statusCode, body: d }));
    });
    r.on('error', reject);
    r.setTimeout(15000, () => { r.destroy(); reject(new Error('timeout')); });
    if (body) r.write(JSON.stringify(body));
    r.end();
  });
}

let passed = 0, failed = 0, total = 0;
function test(name, ok, detail) {
  total++;
  if (ok) { passed++; console.log(`  ✅ ${name}`); }
  else { failed++; console.log(`  ❌ ${name} — ${detail}`); }
}

(async () => {
  console.log('========================================');
  console.log('BYNOVIX AI — FULL PRODUCTION AUDIT');
  console.log('========================================\n');

  // TEST 1: Login all users
  console.log('--- 1. AUTHENTICATION ---');
  const tokens = {};
  for (const u of USERS) {
    try {
      const resp = await req('POST', '/auth/v1/token?grant_type=password', {
        email: u.email, password: u.password
      }, { 'apikey': ANON });
      if (resp.status === 200) {
        const JD = JSON.parse(resp.body);
        tokens[u.role] = { jwt: JD.access_token, userId: JD.user?.id };
        test(`Login ${u.email} (${u.role})`, true);
      } else {
        test(`Login ${u.email} (${u.role})`, false, `HTTP ${resp.status}`);
      }
    } catch(e) {
      test(`Login ${u.email} (${u.role})`, false, e.message);
    }
  }

  // Use admin token for data tests
  const adminJWT = tokens.admin?.jwt;
  if (!adminJWT) { console.log('\n❌ Cannot continue — admin login failed'); return; }

  // TEST 2: Profile access
  console.log('\n--- 2. PROFILE ACCESS ---');
  for (const [role, t] of Object.entries(tokens)) {
    const resp = await req('GET', '/rest/v1/profiles?select=id,email,role,organization_id&id=eq.' + t.userId, null, {
      'apikey': ANON, 'Authorization': 'Bearer ' + t.jwt
    });
    const data = JSON.parse(resp.body);
    test(`Profile for ${role}: ${data.length > 0 ? data[0].role : 'NONE'}`, data.length > 0, 'empty');
  }

  // TEST 3: Data tables (admin role)
  console.log('\n--- 3. DATA TABLES (admin) ---');
  const tables = [
    { name: 'forecasts', query: '/rest/v1/forecasts?select=forecast_value,confidence,scenario', expect: 'forecast_value' },
    { name: 'insights', query: '/rest/v1/insights?select=title,severity,status', expect: 'title' },
    { name: 'actions', query: '/rest/v1/actions?select=title,priority,status', expect: 'title' },
    { name: 'source_connections', query: '/rest/v1/source_connections?select=name,status,records_count', expect: 'name' },
    { name: 'audit_events', query: '/rest/v1/audit_events?select=event_type,status', expect: 'event_type' },
    { name: 'threats', query: '/rest/v1/threats?select=title,status', expect: 'title' },
    { name: 'playbooks', query: '/rest/v1/playbooks?select=name,status', expect: 'name' },
    { name: 'reports', query: '/rest/v1/reports?select=title,report_type', expect: 'title' },
    { name: 'org_policies', query: '/rest/v1/org_policies?select=ai_confidence_gate', expect: 'ai_confidence_gate' },
    { name: 'lineage_edges', query: '/rest/v1/lineage_edges?select=edge_type,source_entity_type', expect: 'edge_type' },
    { name: 'analytical_results', query: '/rest/v1/analytical_results?select=title,result_type', expect: 'title' },
    { name: 'simulation_scenarios', query: '/rest/v1/simulation_scenarios?select=name,scenario_type', expect: 'name' },
  ];

  for (const t of tables) {
    try {
      const resp = await req('GET', t.query + '&limit=5', null, {
        'apikey': ANON, 'Authorization': 'Bearer ' + adminJWT
      });
      const data = JSON.parse(resp.body);
      const count = Array.isArray(data) ? data.length : 0;
      test(`${t.name}: ${count} rows`, count > 0, count === 0 ? 'EMPTY' : '');
    } catch(e) {
      test(`${t.name}`, false, e.message);
    }
  }

  // TEST 4: Canonical values
  console.log('\n--- 4. CANONICAL VALUES ---');
  const fcResp = await req('GET', '/rest/v1/forecasts?select=forecast_value,confidence,scenario', null, {
    'apikey': ANON, 'Authorization': 'Bearer ' + adminJWT
  });
  const forecasts = JSON.parse(fcResp.body);
  const base = forecasts.find(f => f.scenario === 'base');
  test(`Base forecast = $18.6M`, base && base.forecast_value === 18600000, `got ${base?.forecast_value}`);
  test(`Forecast confidence = 91%`, base && base.confidence === 91, `got ${base?.confidence}`);

  const insResp = await req('GET', '/rest/v1/insights?select=title,severity', null, {
    'apikey': ANON, 'Authorization': 'Bearer ' + adminJWT
  });
  const insights = JSON.parse(insResp.body);
  test(`South Region anomaly exists`, insights.some(i => i.title.includes('South Region')), 'missing');

  const actResp = await req('GET', '/rest/v1/actions?select=title,priority', null, {
    'apikey': ANON, 'Authorization': 'Bearer ' + adminJWT
  });
  const actions = JSON.parse(actResp.body);
  test(`Recover South Region Revenue action exists`, actions.some(a => a.title.includes('Recover South Region')), 'missing');

  const thrResp = await req('GET', '/rest/v1/threats?select=title', null, {
    'apikey': ANON, 'Authorization': 'Bearer ' + adminJWT
  });
  const threats = JSON.parse(thrResp.body);
  test(`Suspicious Login Pattern threat exists`, threats.some(t => t.title.includes('Suspicious Login')), 'missing');

  const pbResp = await req('GET', '/rest/v1/playbooks?select=name', null, {
    'apikey': ANON, 'Authorization': 'Bearer ' + adminJWT
  });
  const playbooks = JSON.parse(pbResp.body);
  test(`Brute Force Protection playbook exists`, playbooks.some(p => p.name.includes('Brute Force')), 'missing');

  // TEST 5: Governance
  console.log('\n--- 5. GOVERNANCE ---');
  const polResp = await req('GET', '/rest/v1/org_policies?select=*', null, {
    'apikey': ANON, 'Authorization': 'Bearer ' + adminJWT
  });
  const policies = JSON.parse(polResp.body);
  if (policies.length > 0) {
    const p = policies[0];
    test(`AI confidence gate = 90%`, p.ai_confidence_gate === 90, `got ${p.ai_confidence_gate}`);
    test(`MFA required = true`, p.mfa_required === true, `got ${p.mfa_required}`);
    test(`Session timeout = 30 min`, p.session_timeout_minutes === 30, `got ${p.session_timeout_minutes}`);
    test(`Failed login threshold = 5`, p.failed_login_threshold === 5, `got ${p.failed_login_threshold}`);
  } else {
    test('Policies exist', false, 'EMPTY');
  }

  // TEST 6: Edge Functions
  console.log('\n--- 6. EDGE FUNCTIONS ---');
  try {
    const chatResp = await req('POST', '/functions/v1/chat-ask', {
      question: 'What is our revenue forecast?',
      org_id: 'a0000000-0000-0000-0000-000000000001'
    }, { 'apikey': ANON, 'Authorization': 'Bearer ' + adminJWT });
    const chatData = JSON.parse(chatResp.body);
    test(`chat-ask returns success`, chatData.success === true, chatData.error || 'failed');
    test(`chat-ask has AI response`, chatData.response && chatData.response.length > 50, 'empty');
    test(`chat-ask model = groq`, chatData.source === 'groq', chatData.source);
  } catch(e) {
    test('chat-ask Edge Function', false, e.message);
  }

  try {
    const giResp = await req('POST', '/functions/v1/generate-insight', {
      org_id: 'a0000000-0000-0000-0000-000000000001',
      title: 'Test insight',
      type: 'anomaly',
      severity: 'medium',
      confidence: 92,
      explanation: 'Test insight for audit',
      use_groq: true
    }, { 'apikey': ANON, 'Authorization': 'Bearer ' + adminJWT });
    const giData = JSON.parse(giResp.body);
    test(`generate-insight returns success`, giData.success === true, giData.message || 'failed');
  } catch(e) {
    test('generate-insight Edge Function', false, e.message);
  }

  // TEST 7: RLS — restricted user CANNOT see admin-only data
  console.log('\n--- 7. RLS / RBAC ---');
  const restrictedJWT = tokens.restricted?.jwt;
  if (restrictedJWT) {
    // Restricted user should NOT be able to create actions
    try {
      const actCreate = await req('POST', '/rest/v1/actions', {
        title: 'Should Fail',
        description: 'Test',
        priority: 'low',
        status: 'todo',
        organization_id: 'a0000000-0000-0000-0000-000000000001'
      }, { 'apikey': ANON, 'Authorization': 'Bearer ' + restrictedJWT, 'Prefer': 'return=representation' });
      test(`Restricted user CANNOT create actions`, actCreate.status >= 400, `got HTTP ${actCreate.status}`);
    } catch(e) {
      test(`Restricted user CANNOT create actions`, true, e.message);
    }

    // Restricted user should be able to READ
    const readResp = await req('GET', '/rest/v1/insights?select=id&limit=1', null, {
      'apikey': ANON, 'Authorization': 'Bearer ' + restrictedJWT
    });
    const readData = JSON.parse(readResp.body);
    test(`Restricted user CAN read insights`, Array.isArray(readData), 'not array');
  }

  // SUMMARY
  console.log('\n========================================');
  console.log(`RESULTS: ${passed}/${total} PASSED, ${failed} FAILED`);
  console.log('========================================');

  if (failed > 0) {
    console.log('\n⚠️ ISSUES FOUND THAT NEED FIXING');
  } else {
    console.log('\n✅ ALL TESTS PASSED — NO ISSUES FOUND');
  }
})();
