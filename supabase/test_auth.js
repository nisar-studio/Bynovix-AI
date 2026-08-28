const https = require('https');

const SUPABASE_URL = 'https://ddsjxafkhxijypgsbvcu.supabase.co';
const ANON = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRkc2p4YWZraHhpanlwZ3NidmN1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc1NzQ0MDEsImV4cCI6MjEwMzE1MDQwMX0.WA_UVawLWJxa5b9zIPe-j4r6ua6uElQf0_L29TyHwPA';

function request(method, path, body, headers = {}) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, SUPABASE_URL);
    const opts = {
      hostname: url.hostname,
      port: 443,
      path: url.pathname + url.search,
      method,
      headers: { 'Content-Type': 'application/json', ...headers }
    };
    const req = https.request(opts, (res) => {
      let data = '';
      res.on('data', c => data += c);
      res.on('end', () => resolve({ status: res.statusCode, body: data }));
    });
    req.on('error', reject);
    req.setTimeout(10000, () => { req.destroy(); reject(new Error('timeout')); });
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

(async () => {
  console.log('=== Step 1: Login as sarah.lee@bynovix.com ===');
  const loginResp = await request('POST', '/auth/v1/token?grant_type=password', {
    email: 'sarah.lee@bynovix.com',
    password: 'BynovixAdmin2024!'
  }, { 'apikey': ANON });
  
  if (loginResp.status !== 200) {
    console.log('LOGIN FAILED:', loginResp.status, loginResp.body.substring(0, 200));
    return;
  }
  
  const loginData = JSON.parse(loginResp.body);
  const JWT = loginData.access_token;
  const userId = loginData.user?.id;
  console.log('Login OK. User ID:', userId);
  
  console.log('\n=== Step 2: Query profiles (as authenticated user) ===');
  const profilesResp = await request('GET', '/rest/v1/profiles?select=id,email,role,organization_id&id=eq.' + userId, null, {
    'apikey': ANON,
    'Authorization': 'Bearer ' + JWT
  });
  console.log('Status:', profilesResp.status);
  console.log('Body:', profilesResp.body.substring(0, 500));
  
  console.log('\n=== Step 3: Query forecasts (as authenticated user) ===');
  const forecastResp = await request('GET', '/rest/v1/forecasts?select=id,forecast_value,confidence&limit=3', null, {
    'apikey': ANON,
    'Authorization': 'Bearer ' + JWT
  });
  console.log('Status:', forecastResp.status);
  console.log('Body:', forecastResp.body.substring(0, 500));
  
  console.log('\n=== Step 4: Query insights ===');
  const insightsResp = await request('GET', '/rest/v1/insights?select=id,title,status&limit=3', null, {
    'apikey': ANON,
    'Authorization': 'Bearer ' + JWT
  });
  console.log('Status:', insightsResp.status);
  console.log('Body:', insightsResp.body.substring(0, 500));
  
  console.log('\n=== Step 5: Query source_connections ===');
  const sourcesResp = await request('GET', '/rest/v1/source_connections?select=id,name,status&limit=3', null, {
    'apikey': ANON,
    'Authorization': 'Bearer ' + JWT
  });
  console.log('Status:', sourcesResp.status);
  console.log('Body:', sourcesResp.body.substring(0, 500));
  
  console.log('\n=== Step 6: Query actions ===');
  const actionsResp = await request('GET', '/rest/v1/actions?select=id,title,status&limit=3', null, {
    'apikey': ANON,
    'Authorization': 'Bearer ' + JWT
  });
  console.log('Status:', actionsResp.status);
  console.log('Body:', actionsResp.body.substring(0, 500));
  
  console.log('\n=== Step 7: Query threats ===');
  const threatsResp = await request('GET', '/rest/v1/threats?select=id,title,status&limit=3', null, {
    'apikey': ANON,
    'Authorization': 'Bearer ' + JWT
  });
  console.log('Status:', threatsResp.status);
  console.log('Body:', threatsResp.body.substring(0, 500));
})();
