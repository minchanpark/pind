-- Isolated PostgreSQL harness only. The image provides Auth roles and auth.uid;
-- these minimal Storage tables exercise SQL/RLS, not the Storage HTTP service.
create schema if not exists storage;
create or replace function auth.jwt() returns jsonb language sql stable as $$
  select coalesce(nullif(current_setting('request.jwt.claims',true),''),'{}')::jsonb
$$;
create table storage.buckets (
  id text primary key, name text not null, public boolean not null default false,
  file_size_limit bigint, allowed_mime_types text[]
);
create table storage.objects (
  id uuid primary key default gen_random_uuid(), bucket_id text references storage.buckets(id),
  name text not null, owner_id text, metadata jsonb, unique(bucket_id,name)
);
alter table storage.objects enable row level security;
grant usage on schema storage to authenticated,service_role;
grant select,insert,update,delete on storage.objects to authenticated,service_role;
create function storage.foldername(name text) returns text[] language sql immutable as $$
  select (string_to_array(name,'/'))[1:array_length(string_to_array(name,'/'),1)-1]
$$;
