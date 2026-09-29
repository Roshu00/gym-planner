-- Minimal stand-in for Supabase's auth schema and roles, so migrations and
-- RLS policies can be tested on plain Postgres (tool/test_db.sh).
-- Never run this against a Supabase project; Supabase provides the real ones.
create schema if not exists auth;

create table if not exists auth.users (
  id uuid primary key,
  email text,
  is_anonymous boolean not null default false
);

-- Same contract as Supabase: the JWT claims arrive as request settings.
create or replace function auth.jwt() returns jsonb language sql stable as $$
  select coalesce(nullif(current_setting('request.jwt.claims', true), ''), '{}')::jsonb;
$$;

create or replace function auth.uid() returns uuid language sql stable as $$
  select nullif((select auth.jwt()) ->> 'sub', '')::uuid;
$$;

do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then create role anon nologin; end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then create role authenticated nologin; end if;
end;
$$;

grant usage on schema auth to anon, authenticated;
grant execute on all functions in schema auth to anon, authenticated;
