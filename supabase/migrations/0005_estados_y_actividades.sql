-- ============================================================
-- Estados según las categorías reales del establo, y calendario
-- de actividades diarias por caballo.
-- ============================================================

-- ---------- Estados nuevos ----------
-- preparacion se divide en hechura y doma; vientre se divide en
-- cría donante (embriones) y cría natural.

alter table caballos drop constraint if exists caballos_estado_check;
update caballos set estado = 'hechura' where estado = 'preparacion';
update caballos set estado = 'cria_donante' where estado = 'vientre';
alter table caballos add constraint caballos_estado_check
  check (estado in ('competicion','juego','hechura','doma','recuperacion',
                    'cria_donante','cria_natural','prestada','retirada','baja'));

-- ---------- Calendario de actividades ----------
-- Un registro por caballo y día. Sin registro = reposo.

create table actividades (
  id               uuid primary key default gen_random_uuid(),
  organizacion_id  uuid not null references organizaciones (id),
  caballo_id       uuid not null references caballos (id) on delete cascade,
  fecha            date not null,
  tipo             text not null check (tipo in ('practica','vareo','partido')),
  unique (caballo_id, fecha)
);
create index actividades_caballo_idx on actividades (caballo_id, fecha);
create index actividades_org_fecha_idx on actividades (organizacion_id, fecha);

alter table actividades enable row level security;

-- A diferencia del resto, acá el delete es para todos los roles:
-- sacar una actividad es la corrección diaria normal (volver a reposo),
-- no un borrado de historia.
create policy sel on actividades for select using (organizacion_id = org_actual());
create policy ins on actividades for insert with check (organizacion_id = org_actual());
create policy upd on actividades for update using (organizacion_id = org_actual());
create policy del on actividades for delete using (organizacion_id = org_actual());
