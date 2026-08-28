import urllib.request
import json
import os

SITE_ID = 'f6f68ea5-b920-416b-a522-ee48e6f74b77'
TOKEN = 'nfp_kpQzfQKbRKg6CUAJWSQtJ3hSJ6LY662nf08e'
BASE = 'https://api.netlify.com/api/v1'

def deploy_file(filepath, deploy_path):
    with open(filepath, 'rb') as f:
        data = f.read()
    req = urllib.request.Request(
        f'{BASE}/sites/{SITE_ID}/deploys/{deploy_id}/files{deploy_path}',
        data=data,
        headers={
            'Authorization': f'Bearer {TOKEN}',
            'Content-Type': 'application/octet-stream'
        },
        method='PUT'
    )
    try:
        resp = urllib.request.urlopen(req)
        return True
    except urllib.error.HTTPError as e:
        print(f'  Error {e.code}: {e.read().decode()[:200]}')
        return False

# Step 1: Create deploy
req = urllib.request.Request(
    f'{BASE}/sites/{SITE_ID}/deploys',
    data=json.dumps({'files': {}, 'branch': 'main'}).encode(),
    headers={
        'Authorization': f'Bearer {TOKEN}',
        'Content-Type': 'application/json'
    },
    method='POST'
)
resp = urllib.request.urlopen(req)
deploy_info = json.loads(resp.read())
deploy_id = deploy_info['id']
print(f'Deploy created: {deploy_id}')

# Step 2: Deploy files
frontend_dir = os.path.join(os.path.dirname(__file__), 'frontend')
files = []
for root, dirs, filenames in os.walk(frontend_dir):
    for f in filenames:
        if not f.startswith('.') and f != 'Thumbs.db':
            full_path = os.path.join(root, f)
            deploy_path = '/' + os.path.relpath(full_path, frontend_dir).replace('\\', '/')
            files.append((full_path, deploy_path))

print(f'Deploying {len(files)} files...')
for full_path, deploy_path in files:
    size = os.path.getsize(full_path)
    print(f'  {deploy_path} ({size} bytes)', end=' -> ')
    ok = deploy_file(full_path, deploy_path)
    if ok:
        print('OK')
    else:
        print('FAILED')

# Step 3: Finalize
req = urllib.request.Request(
    f'{BASE}/sites/{SITE_ID}/deploys/{deploy_id}',
    headers={'Authorization': f'Bearer {TOKEN}'},
    method='PATCH'
)
resp = urllib.request.urlopen(req)
result = json.loads(resp.read())
print(f'\nDeploy finalized. Status: {result.get("state")}, URL: https://bynovix-ai.netlify.app')
