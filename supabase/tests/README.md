# Local SQL verification

Run the current catalog, social and post suites in disposable Supabase PostgreSQL:

```sh
python3 scripts/test_post_sql.py
```

Docker is required. The script creates a unique container without a host port, applies every migration in order, runs transaction-based suites and concurrent rating checks, then removes its own container. It uses `public.ecr.aws/supabase/postgres:17.6.1.132`, matching the PostgreSQL 17.6 backend baseline. It never connects to the linked project or reads production credentials.

`post_storage_bootstrap.sql` supplies minimal Storage tables and JWT claims for SQL policy checks. The older `detail_bootstrap.sql` is retained for historical vanilla PostgreSQL tests and does not support the newer post migration. Neither bootstrap is a production installation.

- `public_first_places.sql`: catalog IDs, public visibility, RPC privileges and Google budgets.
- `place_detail_context.sql`: followed/follower/unfollowed users, private visits/ratings, owner isolation and save idempotency.
- `follows_taste.sql`: taste weights (50/30/20 start, own and saved-place ratings on the user's priorities), match %, recommendations, profile search, follow RLS and grants.
- `published_posts_map.sql`: unposted restaurants remain searchable; published-only filtering precedes the nearby limit; hide/delete removes the last pin; uploaded media belongs to the author; anonymous writes are rejected; ratings/photos/posts are atomic; v3 ratings accept exactly three allowlisted priority criteria with integer 1–5 scores; retry creates one post/visit. Media RLS allows published readers and rejects another author's upload/attachment.

SQL fixtures roll back. These checks do not validate the Storage HTTP service, physical photo picker, OAuth login, or Google map rendering.

- `place_rating_stats.sql`: stored public averages/counts, shared detail/profile RPC data, private/public transitions, edit/delete/move/cascade, transaction rollback, RLS and backfill/recovery. The runner also checks simultaneous rating inserts, updates and deletes in its disposable container.
