# Place detail local SQL verification

`detail_bootstrap.sql` is an **isolated vanilla PostgreSQL harness**, not an Auth/Storage installation or remote seed. Do not run it against a Supabase project. The scenario creates local fake user IDs inside a transaction and rolls them back.

Run in a fresh, unexposed development container (no host port, no production keys):

```sh
docker run -d --name pind-detail-sql -e POSTGRES_HOST_AUTH_METHOD=trust postgres:17-alpine
docker exec -i pind-detail-sql psql -U postgres -v ON_ERROR_STOP=1 < supabase/tests/detail_bootstrap.sql
for migration in supabase/migrations/*.sql; do
  docker exec -i pind-detail-sql psql -U postgres -v ON_ERROR_STOP=1 < "$migration" || exit 1
done
docker exec -i pind-detail-sql psql -U postgres -v ON_ERROR_STOP=1 < supabase/tests/place_detail_context.sql
docker stop pind-detail-sql
```

Wait for `docker exec pind-detail-sql pg_isready -U postgres` before setup. Use a fresh container/database for each full migration run. The assertions can be repeated because fixture writes roll back. Covers accepted/pending/removed relations, private posts/ratings, owner isolation, saved state and RPC grants. No actual email/password accounts are created.
