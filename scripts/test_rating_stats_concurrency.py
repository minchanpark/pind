"""Exercise concurrent aggregate updates only inside the disposable SQL harness."""
from concurrent.futures import ThreadPoolExecutor
import subprocess
import sys
import threading

container = sys.argv[1]
if not container.startswith('pind-post-qa-'):
    raise SystemExit('Only an isolated pind-post-qa container is allowed')


def sql(query):
    result = subprocess.run(
        ['docker', 'exec', '-i', container, 'psql', '-U', 'supabase_admin',
         '-d', 'postgres', '-v', 'ON_ERROR_STOP=1'],
        input=query.encode(), capture_output=True,
    )
    if result.returncode:
        raise RuntimeError(result.stderr.decode())


sql("""
insert into auth.users(id) values
 ('a2000000-0000-0000-0000-000000000001'),
 ('a2000000-0000-0000-0000-000000000002');
select public.import_sbiz_places('[{"id":"stats-concurrent","name":"동시 집계",
 "category":"한식","address":"서울","latitude":37.5,"longitude":126.9}]', '2026-10-01');
""")
place = "(select id from public.places where external_place_id='stats-concurrent')"


def concurrent(operations, total, count):
    barrier = threading.Barrier(2)

    def write(operation):
        barrier.wait()
        sql('begin; ' + operation + '; select pg_sleep(0.3); commit;')

    with ThreadPoolExecutor(max_workers=2) as pool:
        list(pool.map(write, operations))
    average = 'average is null' if count == 0 else f'average={total}::numeric/{count}'
    sql(f"""do $$ begin
      assert (select rating_sum={total} and rating_count={count} and {average}
        from public.place_rating_stats where place_id={place} and criterion='taste'),
        'concurrent ratings lost an update';
    end $$;""")


users = [f"'a2000000-0000-0000-0000-00000000000{n}'" for n in (1, 2)]
concurrent([
    f"insert into public.place_ratings(user_id,place_id,criterion,rating) values({u},{place},'taste',{r})"
    for u, r in zip(users, (5, 3))
], 8, 2)
concurrent([
    f"update public.place_ratings set rating={r} where user_id={u} and place_id={place}"
    for u, r in zip(users, (1, 5))
], 6, 2)
concurrent([
    f"delete from public.place_ratings where user_id={u} and place_id={place}"
    for u in users
], 0, 0)
sql(f"delete from public.places where id={place}; delete from auth.users where id in ({','.join(users)});")
print('PASS: simultaneous inserts, updates and deletes preserve aggregate totals', flush=True)
