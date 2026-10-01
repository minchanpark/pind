-- Every 5 minutes, re-request insights that failed, are behind their post
-- count, or never got a row (the trigger's request was lost). Busy places are
-- skipped by claim_place_insight as usual.
-- ponytail: 20 places per run; raise the limit if failures pile up faster.
create function public.retry_place_insights()
returns integer language sql security definer set search_path='' as $$
  with posted as (
    select place_id, count(*) n from public.posts
    where is_public and status='published' group by place_id
  ), due as (
    select coalesce(i.place_id,p.place_id) place_id
    from public.place_insights i full join posted p on p.place_id=i.place_id
    where i.place_id is null or i.failed_at is not null
      or i.post_count is distinct from coalesce(p.n,0)
    order by i.failed_at nulls first
    limit 20
  )
  select count(public.request_place_insight(place_id))::integer from due;
$$;
revoke all on function public.retry_place_insights() from public,anon,authenticated;

create extension if not exists pg_cron;
select cron.schedule('retry-place-insights','*/5 * * * *','select public.retry_place_insights()');
