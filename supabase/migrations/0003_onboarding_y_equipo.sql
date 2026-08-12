-- ============================================================
-- El Corral — Alta de organización e invitaciones al equipo
-- ============================================================

-- Código corto para invitar gente al criadero.
alter table organizaciones
  add column codigo_invita text unique not null default encode(gen_random_bytes(4), 'hex');

-- Un usuario recién registrado crea su criadero y queda como dueño.
create or replace function crear_organizacion(p_nombre text, p_mi_nombre text) returns uuid
language plpgsql volatile security definer set search_path = public as
$$
declare v_org uuid;
begin
  if exists (select 1 from perfiles where user_id = auth.uid()) then
    raise exception 'Ya pertenecés a una organización.';
  end if;
  insert into organizaciones (nombre) values (p_nombre) returning id into v_org;
  insert into perfiles (user_id, organizacion_id, rol, nombre)
    values (auth.uid(), v_org, 'dueno', p_mi_nombre);
  return v_org;
end;
$$;

-- Un usuario recién registrado se suma a un criadero existente con el código.
-- Si el criadero todavía no tiene miembros, queda como dueño; si no, entra
-- como petisero y el dueño le cambia el rol después.
create or replace function unirse_a_organizacion(p_codigo text, p_mi_nombre text) returns uuid
language plpgsql volatile security definer set search_path = public as
$$
declare
  v_org uuid;
  v_rol text;
begin
  if exists (select 1 from perfiles where user_id = auth.uid()) then
    raise exception 'Ya pertenecés a una organización.';
  end if;
  select id into v_org from organizaciones where codigo_invita = p_codigo;
  if v_org is null then
    raise exception 'Ese código de invitación no existe.';
  end if;
  select case when exists (select 1 from perfiles where organizacion_id = v_org)
              then 'petisero' else 'dueno' end into v_rol;
  insert into perfiles (user_id, organizacion_id, rol, nombre)
    values (auth.uid(), v_org, v_rol, p_mi_nombre);
  return v_org;
end;
$$;

revoke all on function crear_organizacion(text, text) from public;
revoke all on function unirse_a_organizacion(text, text) from public;
grant execute on function crear_organizacion(text, text) to authenticated;
grant execute on function unirse_a_organizacion(text, text) to authenticated;

-- El dueño administra los roles de su equipo.
create policy perfiles_admin_upd on perfiles for update
  using (organizacion_id = org_actual() and es_dueno());
create policy perfiles_admin_del on perfiles for delete
  using (organizacion_id = org_actual() and es_dueno() and user_id <> auth.uid());
