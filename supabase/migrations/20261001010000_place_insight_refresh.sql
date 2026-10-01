-- Insights refresh as soon as a post is published, hidden or deleted, and a
-- failed refresh no longer holds the claim: it records why and frees the place
-- for a retry after a minute.
create extension if not exists pg_net with schema extensions;

alter table public.place_insights
  add column last_error text,
  add column failed_at timestamptz;

create or replace function public.claim_place_insight(p_place_id bigint)
returns boolean language sql security invoker set search_path='' as $$
  insert into public.place_insights(place_id,claimed_at) values(p_place_id,now())
  on conflict(place_id) do update set claimed_at=now()
    where (public.place_insights.claimed_at is null
      or public.place_insights.claimed_at < now()-interval '2 minutes')
      and (public.place_insights.failed_at is null
      or public.place_insights.failed_at < now()-interval '1 minute')
  returning true;
$$;

-- Asks the places function to refresh one place. Needs Vault secrets
-- `project_url` and `service_role_key`; without them (local, CI) it does nothing.
-- The HTTP call goes out after commit, so a rolled-back post sends nothing.
create function public.request_place_insight(p_place_id bigint)
returns void language plpgsql security definer set search_path='' as $$
declare url text; key text;
begin
  select decrypted_secret into url from vault.decrypted_secrets where name='project_url';
  select decrypted_secret into key from vault.decrypted_secrets where name='service_role_key';
  if url is null or key is null then return; end if;
  perform net.http_post(
    url := url || '/functions/v1/places',
    headers := jsonb_build_object('Content-Type','application/json','Authorization','Bearer ' || key),
    body := jsonb_build_object('refreshInsight',p_place_id));
exception when others then
  -- Never fail a post over its summary; the detail request still retries.
  raise warning 'request_place_insight(%) failed: %', p_place_id, sqlerrm;
end;
$$;
revoke all on function public.request_place_insight(bigint) from public,anon,authenticated;

create function public.posts_refresh_insight()
returns trigger language plpgsql security definer set search_path='' as $$
begin
  if tg_op <> 'INSERT' and old.is_public and old.status='published' then
    perform public.request_place_insight(old.place_id);
  end if;
  if tg_op <> 'DELETE' and new.is_public and new.status='published'
     and (tg_op='INSERT' or new.place_id is distinct from old.place_id
       or not (old.is_public and old.status='published')) then
    perform public.request_place_insight(new.place_id);
  end if;
  return null;
end;
$$;
revoke all on function public.posts_refresh_insight() from public,anon,authenticated;

create trigger posts_refresh_insight
  after insert or delete or update of is_public,status,place_id,body,ratings on public.posts
  for each row execute function public.posts_refresh_insight();
