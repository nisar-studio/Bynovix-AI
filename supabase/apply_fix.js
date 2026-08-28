const https = require('https');

const SK = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRkc2p4YWZraHhpanlwZ3NidmN1Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4NzU3NDQwMSwiZXhwIjoyMTAzMTUwNDAxfQ.zurPaK3SQZ8i6BKwAtuyrRGr7n-PArmFGwfuSOkUkCo';
const PROJECT_REF = 'ddsjxafkhxijypgsbvcu';

function request(method, path, body, headers = {}) {
  return new Promise((resolve, reject) => {
    const opts = {
      hostname: 'api.supabase.com',
      port: 443,
      path: path,
      method,
      headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + SK, ...headers }
    };
    const req = https.request(opts, (res) => {
      let data = '';
      res.on('data', c => data += c);
      res.on('end', () => resolve({ status: res.statusCode, body: data }));
    });
    req.on('error', reject);
    req.setTimeout(15000, () => { req.destroy(); reject(new Error('timeout')); });
    if (body) req.write(typeof body === 'string' ? body : JSON.stringify(body));
    req.end();
  });
}

(async () => {
  console.log('=== Try Management API: list projects ===');
  try {
    const resp = await request('GET', '/v1/projects');
    console.log('Status:', resp.status);
    console.log('Body:', resp.body.substring(0, 500));
  } catch(e) {
    console.log('Error:', e.message);
  }

  // Try direct SQL via the SQL endpoint
  console.log('\n=== Try SQL API: check RLS policies on profiles ===');
  const sqlQuery = "SELECT policyname, cmd, qual FROM pg_policies WHERE tablename = 'profiles' ORDER BY policyname";
  try {
    const resp = await request('POST', `/pg_rest/`, {
      query: sqlQuery
    });
    console.log('Status:', resp.status);
    console.log('Body:', resp.body.substring(0, 500));
  } catch(e) {
    console.log('Error:', e.message);
  }

  // Try the built-in SQL API
  console.log('\n=== Try SQL endpoint ===');
  try {
    const resp = await request('POST', `/rest/v1/rpc/query`, {
      q: sqlQuery
    });
    console.log('Status:', resp.status);
    console.log('Body:', resp.body.substring(0, 500));
  } catch(e) {
    console.log('Error:', e.message);
  }

  // Test: Can we use the service role to query profiles directly via the REST API?
  console.log('\n=== Test: Query all profiles via service role ===');
  try {
    const resp = await request('GET', `/rest/v1/profiles?select=id,email,role,organization_id&limit=10`, null, {
      'apikey': SK
    });
    console.log('Status:', resp.status);
    console.log('Body:', resp.body.substring(0, 500));
  } catch(e) {
    console.log('Error:', e.message);
  }
})();
