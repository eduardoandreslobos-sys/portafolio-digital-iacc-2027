-- Portafolio Digital 2027 · esquema de Supabase
-- Ejecútalo completo en Supabase → SQL Editor → New query.
-- Es idempotente: puedes volver a ejecutarlo sin perder datos.

-- 1. Documentos de la app (iniciativas, ítems, updates, votos, decisiones, método)
create table if not exists public.docs (
  collection text not null,
  id         text not null,
  data       jsonb not null,
  updated_by uuid default auth.uid(),
  updated_at timestamptz not null default now(),
  primary key (collection, id)
);
alter table public.docs replica identity full;  -- para que el tiempo real informe borrados completos

-- 2. Perfiles visibles (nombre para asignar roles PO, PM, PMO)
create table if not exists public.profiles (
  id    uuid primary key references auth.users on delete cascade,
  name  text,
  email text
);

-- 3. Administradores (por ejemplo, la PMO): pueden cambiar el método de priorización
create table if not exists public.admins (
  user_id uuid primary key references auth.users on delete cascade
);

-- 4. Dominios de correo permitidos. Si la tabla está vacía, entra cualquier usuario autenticado.
create table if not exists public.allowed_domains (
  domain text primary key
);
-- insert into public.allowed_domains values ('iacc.cl') on conflict do nothing;

create or replace function public.is_member() returns boolean
language sql stable security definer set search_path = public as $$
  select auth.uid() is not null and (
    not exists (select 1 from allowed_domains)
    or exists (select 1 from allowed_domains d where lower(auth.jwt() ->> 'email') like '%@' || lower(d.domain))
  );
$$;

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from admins where user_id = auth.uid());
$$;

-- Perfil automático al registrarse
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into profiles (id, email, name)
  values (new.id, new.email, coalesce(new.raw_user_meta_data ->> 'full_name', split_part(new.email, '@', 1)))
  on conflict (id) do nothing;
  return new;
end;
$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- 5. Seguridad a nivel de fila
alter table public.docs enable row level security;
alter table public.profiles enable row level security;
alter table public.admins enable row level security;
alter table public.allowed_domains enable row level security;

drop policy if exists docs_read on public.docs;
create policy docs_read on public.docs for select to authenticated using (public.is_member());

-- Escritura: miembros. Cada persona solo escribe su propio voto; solo administradores cambian el método.
drop policy if exists docs_insert on public.docs;
create policy docs_insert on public.docs for insert to authenticated with check (
  public.is_member()
  and (collection <> 'votes' or id = auth.uid()::text)
  and (collection <> 'settings' or public.is_admin())
);
drop policy if exists docs_update on public.docs;
create policy docs_update on public.docs for update to authenticated
  using (public.is_member() and (collection <> 'votes' or id = auth.uid()::text) and (collection <> 'settings' or public.is_admin()))
  with check (public.is_member() and (collection <> 'votes' or id = auth.uid()::text) and (collection <> 'settings' or public.is_admin()));
-- Borrado: miembros, salvo votos ajenos y método; las decisiones del comité solo las borra un administrador (los demás las revocan).
drop policy if exists docs_delete on public.docs;
create policy docs_delete on public.docs for delete to authenticated using (
  public.is_member()
  and (collection <> 'votes' or id = auth.uid()::text)
  and (collection not in ('settings', 'decisions') or public.is_admin())
);

drop policy if exists profiles_read on public.profiles;
create policy profiles_read on public.profiles for select to authenticated using (public.is_member());
drop policy if exists profiles_insert on public.profiles;
create policy profiles_insert on public.profiles for insert to authenticated with check (id = auth.uid());
drop policy if exists profiles_update on public.profiles;
create policy profiles_update on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists admins_read on public.admins;
create policy admins_read on public.admins for select to authenticated using (public.is_member());

-- 6. Permisos explícitos para la Data API
-- Necesarios si el proyecto se creó con "Automatically expose new tables" desactivado (recomendado).
-- Solo usuarios autenticados; el rol anónimo no recibe acceso a ninguna tabla.
grant usage on schema public to authenticated;
grant select, insert, update, delete on public.docs to authenticated;
grant select, insert, update on public.profiles to authenticated;
grant select on public.admins to authenticated;
revoke all on public.docs, public.profiles, public.admins, public.allowed_domains from anon;
grant execute on function public.is_member() to authenticated;
grant execute on function public.is_admin() to authenticated;

-- 7. Tiempo real
do $$ begin
  alter publication supabase_realtime add table public.docs;
exception when duplicate_object then null; end $$;

-- 8. Para nombrar administradores (después de que esa persona ingrese una vez):
-- insert into public.admins (user_id) select id from auth.users where email = 'pmo@iacc.cl';
