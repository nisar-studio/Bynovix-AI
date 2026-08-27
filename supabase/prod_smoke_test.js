const https = require('https');
const fs = require('fs');
const path = require('path');

const BASE = 'https://ddsjxafkhxijypgsbvcu.supabase.co';
const SK = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRkc2p4YWZraHhpanlwZ3NidmN1Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4NzU3NDQwMSwiZXhwIjoyMTAzMTUwNDAxfQ.zurPaK3SQZ8i6BKwAtuyrRGr7n-PArmFGwfuSOkUkCo';
const ANON = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRkc2p4YWZraHhpanlwZ3NidmN1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc1NzQ0MDEsImV4cCI6MjEwMzE1MDQwMX0.WA_UVawLWJxa5b9zIPe-j4r6ua6uElQf0_L29TyHwPA';

let passed = 0, failed = 0;
const failures = [];

function assert(name, condition, detail) {
  if (condition) { passed++; console.log('  PASS  ' + name); }
  else { failed++; const msg = name + (detail ? ' -- ' + detail : ''); console.log('  FAIL  ' + msg); failures.push(msg); }
}

function httpReq(method, path, token, body) {
  return new Promise((resolve) => {
    const url = new URL(path, BASE);
    const opts = {
      hostname: url.hostname, path: url.pathname + url.search, method,
      headers: { 'apikey': ANON, 'Authorization': 'Bearer ' + (token || ANON), 'Content-Type': 'application/json', 'Prefer': 'return=representation' }
    };
    const req = https.request(opts, (res) => {
      let d = '';
      res.on('data', c => d += c);
      res.on('end', () => { let parsed; try { parsed = JSON.parse(d); } catch(e) { parsed = d; } resolve({ status: res.statusCode, data: parsed }); });
    });
    req.on('error', () => resolve({ status: 0, data: null }));
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

async function login(email, password) {
  const r = await httpReq('POST', '/auth/v1/token?grant_type=password', ANON, { email, password });
  return (r.status === 200 && r.data.access_token) ? r.data : null;
}

async function query(token, table, filter) {
  return await httpReq('GET', '/rest/v1/' + table + (filter ? '?' + filter : '?limit=50'), token);
}

const USERS = [
  { email: 'sarah.lee@bynovix.com', password: 'BynovixAdmin@1', role: 'admin' },
  { email: 'john.doe@bynovix.com', password: 'BynovixManager@1', role: 'manager' },
  { email: 'mike.kim@bynovix.com', password: 'BynovixRestricted@1', role: 'restricted' },
  { email: 'anna.lin@bynovix.com', password: 'BynovixManager@1', role: 'manager' },
  { email: 'tom.ross@bynovix.com', password: 'BynovixRestricted@1', role: 'restricted' },
];

const TABLES = [
  'source_connections', 'source_fields', 'field_mappings', 'data_quality_metrics',
  'analytical_results', 'forecasts', 'insights', 'actions', 'reports',
  'audit_events', 'threats', 'playbooks', 'playbook_rules',
  'security_actions', 'approvals', 'audit_entries',
  'simulation_scenarios', 'module_permissions', 'lineage_edges',
  'organizations', 'profiles', 'org_policies'
];

const MODULES = [
  { name: 'Executive Overview', tables: ['source_connections', 'forecasts', 'insights', 'actions'] },
  { name: 'Analytics', tables: ['source_connections', 'data_quality_metrics', 'analytical_results'] },
  { name: 'AI Insights', tables: ['insights'] },
  { name: 'AI Analyst', tables: ['insights', 'forecasts', 'source_connections'] },
  { name: 'Forecasts', tables: ['forecasts'] },
  { name: 'What-If Simulator', tables: ['simulation_scenarios', 'forecasts'] },
  { name: 'Actions Execution', tables: ['actions', 'insights'] },
  { name: 'Comprehensive Reports', tables: ['reports'] },
  { name: 'Data Sources & Mapping', tables: ['source_connections', 'source_fields', 'field_mappings', 'data_quality_metrics'] },
  { name: 'Team & Permissions', tables: ['profiles', 'module_permissions', 'org_policies'] },
  { name: 'Security & Audit Logs', tables: ['audit_events', 'threats', 'playbooks', 'approvals', 'security_actions', 'audit_entries'] },
  { name: 'Organization Settings', tables: ['organizations', 'org_policies'] },
];

async function main() {
  console.log('============================================================');
  console.log('PRODUCTION SMOKE TEST v2');
  console.log('Target: ' + BASE);
  console.log('============================================================\n');

  // ─── 1. DATABASE SCHEMA ───────────────────────────────────
  console.log('1. DATABASE SCHEMA INTEGRITY\n');
  for (const table of TABLES) {
    const r = await query(null, table, 'limit=1');
    assert('Table "' + table + '" exists and queryable', r.status === 200, 'HTTP ' + r.status);
  }

  // ─── 2. AUTHENTICATION ────────────────────────────────────
  console.log('\n2. AUTHENTICATION\n');
  const sessions = {};
  for (const u of USERS) {
    const session = await login(u.email, u.password);
    sessions[u.email] = session;
    assert('Login: ' + u.email + ' (' + u.role + ')', !!session);
  }
  assert('Bad password rejected', !(await login('sarah.lee@bynovix.com', 'WrongPassword')));
  assert('Nonexistent user rejected', !(await login('nobody@example.com', 'test')));

  // Verify profile role mapping exists for each user
  for (const u of USERS) {
    if (!sessions[u.email]) continue;
    const r = await query(sessions[u.email].access_token, 'profiles', 'select=role&limit=1');
    // We need to find the profile for this specific user
    // The profile is fetched by user.id, so let's check the full list
  }
  const sarahToken = sessions['sarah.lee@bynovix.com']?.access_token;
  if (sarahToken) {
    const profiles = await query(sarahToken, 'profiles', 'select=id,email,role');
    if (profiles.status === 200 && Array.isArray(profiles.data)) {
      for (const u of USERS) {
        const profile = profiles.data.find(p => p.email === u.email);
        assert('Profile role for ' + u.email + ' = "' + u.role + '"', profile?.role === u.role, profile ? 'got "' + profile.role + '"' : 'not found');
      }
    }
  }

  // ─── 3. ORGANIZATION ISOLATION (RLS) ──────────────────────
  console.log('\n3. ORGANIZATION ISOLATION (RLS)\n');
  if (sarahToken) {
    const r1 = await query(sarahToken, 'insights', 'limit=50');
    assert('Sarah reads own org insights', r1.status === 200 && r1.data.length > 0, r1.data?.length + ' rows');

    // Cross-org write should be blocked (RLS returns 400 or 201 with 0 rows)
    const r2 = await httpReq('POST', '/rest/v1/insights', sarahToken, {
      id: 'ffffffff-ffff-ffff-ffff-ffffffffffff',
      organization_id: 'b0000000-0000-0000-0000-000000000001',
      title: 'CROSS-ORG TEST', type: 'test', severity: 'low', confidence: 50, status: 'active'
    });
    const blocked = r2.status === 403 || r2.status === 400 || r2.status === 401;
    assert('Cross-org INSERT blocked for Sarah', blocked, 'HTTP ' + r2.status);
  }

  // ─── 4. RBAC ENFORCEMENT ──────────────────────────────────
  console.log('\n4. RBAC ENFORCEMENT\n');
  const mikeToken = sessions['mike.kim@bynovix.com']?.access_token;
  if (mikeToken) {
    assert('Restricted READ insights', (await query(mikeToken, 'insights', 'limit=10')).status === 200);
    const r2 = await httpReq('POST', '/rest/v1/insights', mikeToken, {
      organization_id: 'a0000000-0000-0000-0000-000000000001',
      title: 'RBAC TEST', type: 'test', severity: 'low', confidence: 50, status: 'active'
    });
    assert('Restricted INSERT blocked', r2.status === 403, 'HTTP ' + r2.status);
  }
  const johnToken = sessions['john.doe@bynovix.com']?.access_token;
  if (johnToken) {
    const r1 = await httpReq('POST', '/rest/v1/insights', johnToken, {
      organization_id: 'a0000000-0000-0000-0000-000000000001',
      title: 'RBAC TEST manager', type: 'test', severity: 'low', confidence: 50, status: 'active'
    });
    assert('Manager INSERT insight allowed', r1.status === 201, 'HTTP ' + r1.status);
    if (r1.status === 201 && r1.data?.[0]?.id) {
      await httpReq('DELETE', '/rest/v1/insights?id=eq.' + r1.data[0].id, johnToken);
    }
  }

  // ─── 5. GOVERNANCE POLICIES ───────────────────────────────
  console.log('\n5. GOVERNANCE POLICIES (actual column names)\n');
  if (sarahToken) {
    const r = await query(sarahToken, 'org_policies', 'limit=10');
    if (r.status === 200 && r.data.length > 0) {
      const p = r.data[0];
      assert('ai_confidence_gate = 90', p.ai_confidence_gate === 90, 'value=' + p.ai_confidence_gate);
      assert('session_timeout_minutes = 30', p.session_timeout_minutes === 30, 'value=' + p.session_timeout_minutes);
      assert('failed_login_threshold = 5', p.failed_login_threshold === 5, 'value=' + p.failed_login_threshold);
      assert('mfa_required = true', p.mfa_required === true, 'value=' + p.mfa_required);
      assert('critical_requires_human_approval = true', p.critical_requires_human_approval === true, 'value=' + p.critical_requires_human_approval);
      assert('explainability_required = true', p.explainability_required === true, 'value=' + p.explainability_required);
      assert('auto_response_rollback_enabled = true', p.auto_response_rollback_enabled === true, 'value=' + p.auto_response_rollback_enabled);
    } else {
      assert('Org policies exist', false, r.data?.length + ' rows');
    }
  }

  // ─── 6. CANONICAL DATA ────────────────────────────────────
  console.log('\n6. CANONICAL DATA VALUES\n');
  if (sarahToken) {
    const fc = await query(sarahToken, 'forecasts', 'limit=10');
    assert('Base forecast $18.6M exists', fc.data?.some(f => f.forecast_value === 18600000));
    assert('Upside $20.7M exists', fc.data?.some(f => f.forecast_value === 20700000));
    assert('Downside $17.2M exists', fc.data?.some(f => f.forecast_value === 17200000));

    const ins = await query(sarahToken, 'insights', 'limit=10');
    assert('South Region anomaly insight', ins.data?.some(i => i.title?.includes('South Region')));
    const activeCount = ins.data?.filter(i => i.status === 'active').length || 0;
    assert('At least 1 active insight', activeCount >= 1, 'count=' + activeCount);

    const act = await query(sarahToken, 'actions', 'limit=10');
    assert('Recover South Region Revenue action', act.data?.some(a => a.title?.includes('Recover South Region')));

    const thr = await query(sarahToken, 'threats', 'limit=10');
    assert('Suspicious Login Pattern threat', thr.data?.some(t => t.title?.includes('Suspicious Login')));

    // Playbooks use 'name' not 'title'
    const plb = await query(sarahToken, 'playbooks', 'limit=10');
    assert('Brute Force Protection playbook', plb.data?.some(p => p.name?.includes('Brute Force')), 'names=' + plb.data?.map(p => p.name).join(', '));

    const src = await query(sarahToken, 'source_connections', 'limit=10');
    assert('5 source connections', src.data?.length === 5, 'got ' + src.data?.length);

    const lin = await query(sarahToken, 'lineage_edges', 'limit=50');
    assert('15+ lineage edges', lin.data?.length >= 15, 'got ' + lin.data?.length);
  }

  // ─── 7. MODULE DATA ACCESS ────────────────────────────────
  console.log('\n7. MODULE DATA ACCESS (5 users x 12 modules)\n');
  for (const u of USERS) {
    const token = sessions[u.email]?.access_token;
    if (!token) continue;
    for (const mod of MODULES) {
      let allOk = true, failDetail = '';
      for (const table of mod.tables) {
        const r = await query(token, table, 'limit=5');
        if (r.status !== 200) { allOk = false; failDetail = table + ' HTTP ' + r.status; break; }
      }
      assert(u.role + ' reads ' + mod.name, allOk, failDetail);
    }
  }

  // ─── 8. FRONTEND FILE INTEGRITY ───────────────────────────
  console.log('\n8. FRONTEND FILE INTEGRITY\n');
  const projRoot = path.join(__dirname, '..');
  const idx = fs.readFileSync(path.join(projRoot, 'index.html'), 'utf8');
  assert('index.html: Supabase CDN', idx.includes('supabase-js'));
  assert('index.html: window._sb client', idx.includes('window._sb'));
  assert('index.html: window.AppState', idx.includes('window.AppState'));
  assert('index.html: window.DB helpers', idx.includes('window.DB'));
  assert('index.html: router', idx.includes('loadPage'));
  assert('index.html: login screen', idx.includes('login-form'));
  assert('index.html: logout', idx.includes('logout'));
  assert('index.html: page script execution', idx.includes('querySelectorAll'));
  assert('index.html: getLineageFor', idx.includes('getLineageFor'));
  assert('index.html: getEntityLabel', idx.includes('getEntityLabel'));
  assert('index.html: no console.log', !idx.includes('console.log'));

  const pages = fs.readdirSync(path.join(projRoot, 'pages'));
  const expectedPages = ['overview.html','analytics.html','ai-insights.html','ai-analyst.html','forecasts.html','what-if.html','actions.html','reports.html','data.html','team.html','security.html','settings.html'];
  for (const p of expectedPages) {
    assert('pages/' + p + ' exists', pages.includes(p));
    const content = fs.readFileSync(path.join(projRoot, 'pages', p), 'utf8');
    assert(p + ': has DB integration', content.includes('window.DB'));
    assert(p + ': no console.log', !content.includes('console.log'));
  }

  // No debug files
  const supabaseFiles = fs.readdirSync(__dirname);
  const debugPatterns = ['debug_','test_','diag','FIX_','verify_','e2e_','rbac_diag','reseed_','try_','write_overview','generate_modules','phase7_','fix_actions','fix_insights','fix_rls','deep_diag'];
  const debugFiles = supabaseFiles.filter(f => debugPatterns.some(p => f.includes(p)));
  assert('No debug files in supabase/', debugFiles.length === 0, debugFiles.join(', '));
  assert('6 migration files', fs.readdirSync(path.join(__dirname, 'migrations')).length === 6);

  // ─── 9. EDGE FUNCTION STUBS ───────────────────────────────
  console.log('\n9. EDGE FUNCTION STUBS\n');
  const fnDir = path.join(__dirname, 'functions');
  assert('sync-data-source stub', fs.existsSync(path.join(fnDir, 'sync-data-source', 'index.ts')));
  assert('generate-insight stub', fs.existsSync(path.join(fnDir, 'generate-insight', 'index.ts')));
  assert('respond-to-threat stub', fs.existsSync(path.join(fnDir, 'respond-to-threat', 'index.ts')));

  // ─── 10. SESSION MANAGEMENT ───────────────────────────────
  console.log('\n10. SESSION MANAGEMENT\n');
  if (sarahToken && sessions['sarah.lee@bynovix.com']?.refresh_token) {
    const r = await httpReq('POST', '/auth/v1/token?grant_type=refresh_token', ANON, { refresh_token: sessions['sarah.lee@bynovix.com'].refresh_token });
    assert('Refresh token works', r.status === 200 && !!r.data?.access_token, 'HTTP ' + r.status);
    const r2 = await httpReq('POST', '/auth/v1/logout', sarahToken);
    assert('Sign out succeeds', r2.status === 200 || r2.status === 204, 'HTTP ' + r2.status);
    const r3 = await httpReq('POST', '/auth/v1/token?grant_type=refresh_token', ANON, { refresh_token: sessions['sarah.lee@bynovix.com'].refresh_token });
    assert('Refresh after logout fails', r3.status !== 200, 'HTTP ' + r3.status);
  }

  // ─── RESULTS ──────────────────────────────────────────────
  console.log('\n============================================================');
  console.log('RESULTS: ' + passed + ' PASSED / ' + failed + ' FAILED / ' + (passed + failed) + ' TOTAL');
  console.log('============================================================');
  if (failed > 0) {
    console.log('\nFAILURES:');
    failures.forEach((f, i) => console.log('  ' + (i + 1) + '. ' + f));
  } else {
    console.log('\nALL TESTS PASSED');
  }
  process.exit(failed > 0 ? 1 : 0);
}

main().catch(e => { console.error('FATAL:', e); process.exit(1); });
