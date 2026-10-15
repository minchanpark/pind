create table private.external_api_daily_total (
  kind text not null, day date not null, requests integer not null default 0,
  primary key(kind,day)
);
create table private.external_api_daily_user (
  kind text not null, day date not null, user_id uuid not null, requests integer not null default 0,
  primary key(kind,day,user_id)
);
create table private.external_api_minute_user (
  kind text not null, minute timestamptz not null, user_id uuid not null, requests integer not null default 0,
  primary key(kind,minute,user_id)
);
revoke all on private.external_api_daily_total,private.external_api_daily_user,private.external_api_minute_user from public,anon,authenticated;
grant all on private.external_api_daily_total,private.external_api_daily_user,private.external_api_minute_user to service_role;

create function public.take_external_request_budget(
  p_user_id uuid,p_kind text,p_user_limit integer default 60,p_total_limit integer default 3000,
  p_minute_limit integer default 10
) returns void language plpgsql security definer set search_path='' as $$
declare affected integer; d date:= (now() at time zone 'UTC')::date;
  m timestamptz:=date_trunc('minute',now());
begin
  if p_user_id is null or p_kind not in ('agent','walking') or
      p_user_limit is null or p_user_limit<1 or p_total_limit is null or p_total_limit<1 or
      p_minute_limit is null or p_minute_limit<1 then raise exception 'EXTERNAL_BUDGET_DISABLED'; end if;
  -- Fixed lock order: total, user/day, user/minute. Failed calls roll back all counters.
  insert into private.external_api_daily_total(kind,day) values(p_kind,d) on conflict do nothing;
  update private.external_api_daily_total set requests=requests+1
    where kind=p_kind and day=d and requests<p_total_limit;
  get diagnostics affected=row_count;
  if affected=0 then raise exception 'EXTERNAL_DAILY_LIMIT'; end if;
  insert into private.external_api_daily_user(kind,day,user_id) values(p_kind,d,p_user_id) on conflict do nothing;
  update private.external_api_daily_user set requests=requests+1
    where kind=p_kind and day=d and user_id=p_user_id and requests<p_user_limit;
  get diagnostics affected=row_count;
  if affected=0 then raise exception 'EXTERNAL_USER_LIMIT'; end if;
  insert into private.external_api_minute_user(kind,minute,user_id) values(p_kind,m,p_user_id) on conflict do nothing;
  update private.external_api_minute_user set requests=requests+1
    where kind=p_kind and minute=m and user_id=p_user_id and requests<p_minute_limit;
  get diagnostics affected=row_count;
  if affected=0 then raise exception 'EXTERNAL_MINUTE_LIMIT'; end if;
  delete from private.external_api_minute_user where minute<now()-interval '1 day';
  delete from private.external_api_daily_user where day<d-7;
  delete from private.external_api_daily_total where day<d-7;
end; $$;
revoke all on function public.take_external_request_budget(uuid,text,integer,integer,integer) from public,anon,authenticated;
grant execute on function public.take_external_request_budget(uuid,text,integer,integer,integer) to service_role;
