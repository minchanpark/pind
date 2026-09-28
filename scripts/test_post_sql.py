"""Run migrations and post/catalog/social SQL assertions in disposable Postgres."""
import pathlib
import subprocess
import time
import uuid

ROOT = pathlib.Path(__file__).resolve().parents[1]
CONTAINER = 'pind-post-qa-' + uuid.uuid4().hex[:12]
IMAGE = 'public.ecr.aws/supabase/postgres:17.6.1.132'


def run(*args, **kwargs):
    return subprocess.run(args, check=True, capture_output=True, **kwargs)


def sql(path):
    result = run('docker', 'exec', '-i', CONTAINER, 'psql', '-U', 'supabase_admin',
                 '-d', 'postgres', '--single-transaction', '-v', 'ON_ERROR_STOP=1',
                 input=path.read_bytes())
    print('PASS:', path.relative_to(ROOT), flush=True)
    return result


try:
    run('docker', 'run', '-d', '--name', CONTAINER, '-e',
        'POSTGRES_PASSWORD=pind-local-qa', IMAGE)
    for _ in range(60):
        if subprocess.run(['docker', 'exec', CONTAINER, 'pg_isready', '-U', 'supabase_admin'],
                          capture_output=True).returncode == 0:
            break
        time.sleep(1)
    else:
        raise RuntimeError('Isolated Postgres did not become ready')
    sql(ROOT / 'supabase/tests/post_storage_bootstrap.sql')
    for path in sorted((ROOT / 'supabase/migrations').glob('*.sql')):
        sql(path)
    for name in ['public_first_places.sql', 'place_detail_context.sql', 'published_posts_map.sql']:
        sql(ROOT / 'supabase/tests' / name)
except subprocess.CalledProcessError as error:
    print((error.stderr or b'').decode(), flush=True)
    raise
finally:
    subprocess.run(['docker', 'rm', '-f', CONTAINER], capture_output=True)
