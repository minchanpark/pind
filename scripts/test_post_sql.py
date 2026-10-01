"""Run migrations and post/catalog/social SQL assertions in disposable Postgres."""
import pathlib
import subprocess
import sys
import time
import uuid

ROOT = pathlib.Path(__file__).resolve().parents[1]
CONTAINER = 'pind-post-qa-' + uuid.uuid4().hex[:12]
IMAGE = 'public.ecr.aws/supabase/postgres:17.6.1.132'
MIGRATIONS = sorted((ROOT / 'supabase/migrations').glob('*.sql'))
versions = [path.name.split('_', 1)[0] for path in MIGRATIONS]
if len(set(versions)) != len(versions):
    raise RuntimeError('Migration versions must be unique before running SQL tests')


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
    # The image answers pg_isready from a temporary init server, then restarts.
    # Wait for the entrypoint's "init complete" line before trusting pg_isready.
    for _ in range(120):
        logs = subprocess.run(['docker', 'logs', CONTAINER], capture_output=True)
        started = b'init process complete' in logs.stdout + logs.stderr
        if started and subprocess.run(
                ['docker', 'exec', CONTAINER, 'pg_isready', '-U', 'supabase_admin'],
                capture_output=True).returncode == 0:
            break
        time.sleep(1)
    else:
        raise RuntimeError('Isolated Postgres did not become ready')
    sql(ROOT / 'supabase/tests/post_storage_bootstrap.sql')
    for path in MIGRATIONS:
        sql(path)
    for name in ['public_first_places.sql', 'place_detail_context.sql', 'published_posts_map.sql', 'profile_page.sql', 'discover_feed.sql', 'follows_taste.sql', 'other_profiles.sql', 'saved_places_page.sql', 'place_insight_refresh.sql', 'place_rating_stats.sql', 'nearby_ranking.sql']:
        sql(ROOT / 'supabase/tests' / name)
    concurrent = run(sys.executable, str(ROOT / 'scripts/test_rating_stats_concurrency.py'), CONTAINER)
    print(concurrent.stdout.decode().strip(), flush=True)
except subprocess.CalledProcessError as error:
    print((error.stderr or b'').decode(), flush=True)
    raise
finally:
    subprocess.run(['docker', 'rm', '-f', CONTAINER], capture_output=True)
