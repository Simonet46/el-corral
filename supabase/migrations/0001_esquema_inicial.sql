-- ============================================================
-- El Corral — Esquema inicial
-- Multi-tenant por organización (criadero), con RLS en todo.
-- ============================================================

-- ---------- Organizaciones y perfiles ----------

create table organizaciones (
  id          uuid primary key default gen_random_uuid(),
  nombre      text not null,
  created_at  timestamptz not null default now()
);

create table perfiles (
  user_id          uuid primary key references auth.users (id) on delete cascade,
  organizacion_id  uuid not null references organizaciones (id),
  rol              text not null check (rol in ('dueno', 'petisero', 'veterinario')),
  nombre           text,
  created_at       timestamptz not null default now()
);

-- Helpers para las políticas: organización y rol del usuario logueado.
create or replace function org_actual() returns uuid
language sql stable security definer set search_path = public as
$$ select organizacion_id from perfiles where user_id = auth.uid() $$;

create or replace function es_dueno() returns boolean
language sql stable security definer set search_path = public as
$$ select coalesce((select rol = 'dueno' from perfiles where user_id = auth.uid()), false) $$;

-- ---------- Caballos ----------

create table caballos (
  id               uuid primary key default gen_random_uuid(),
  organizacion_id  uuid not null references organizaciones (id),
  nombre           text not null,
  apodo            text,
  sexo             text check (sexo in ('Yegua', 'Padrillo', 'Castrado', 'Potranca', 'Potrillo')),
  nacimiento       date,
  pelaje           text,
  estado           text not null default 'juego'
                   check (estado in ('competicion','juego','preparacion','recuperacion',
                                     'vientre','prestada','retirada','baja')),
  reproductivo     text check (reproductivo in ('', 'vacia', 'prenada')),
  ubicacion        text,
  petisero         text,
  jinete           text,
  criador          text,
  microchip        text,                -- microchip / n° de marca
  padre_id         uuid references caballos (id),
  madre_id         uuid references caballos (id),
  padre_texto      text,                -- pedigrí externo, cuando el padre no está en el sistema
  madre_texto      text,
  origen           text check (origen in ('', 'Embrión (cría propia)', 'Manada (cría propia)',
                                          'Compra de embrión', 'Comprado')),
  aptitudes        jsonb not null default '{}'::jsonb,  -- {velocidad, boca, freno, temperamento, resistencia, recuperacion} 1–10
  observaciones    text,                -- observaciones físicas / de juego
  historial_clinico text,               -- extra del prototipo, para no perder datos
  notas            text,                -- extra del prototipo
  video_link       text,               -- extra del prototipo (link a YouTube u otro)
  costo_monto      numeric,
  costo_moneda     text default 'USD' check (costo_moneda in ('USD', 'ARS')),
  valuacion        numeric,
  valuacion_moneda text default 'USD' check (valuacion_moneda in ('USD', 'ARS')),
  precio_venta     numeric,
  precio_moneda    text default 'USD' check (precio_moneda in ('USD', 'ARS')),
  seguro_suma      numeric,
  seguro_moneda    text default 'USD' check (seguro_moneda in ('USD', 'ARS')),
  vacuna_fecha     date,
  coggins_fecha    date,
  herraje_fecha    date,
  desparasitacion_fecha date,           -- extra del prototipo
  odontologia_fecha     date,           -- extra del prototipo
  alta_estimada    date,                -- extra del prototipo (recuperación)
  servicio         text,                -- extra del prototipo (reproducción)
  receptora        text,                -- extra del prototipo
  fecha_parto      date,                -- extra del prototipo
  fecha_baja       date,
  causa_baja       text,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

create index caballos_org_idx    on caballos (organizacion_id);
create index caballos_estado_idx on caballos (organizacion_id, estado);
create unique index caballos_nombre_unico on caballos (organizacion_id, lower(nombre));

-- ---------- Media ----------

-- Feature central: la evolución de cada caballo en video.
create table videos (
  id                     uuid primary key default gen_random_uuid(),
  organizacion_id        uuid not null references organizaciones (id),
  caballo_id             uuid not null references caballos (id) on delete cascade,
  storage_path           text not null,           -- ruta en el bucket "videos": org/caballo/archivo
  fecha                  date,
  edad_meses_al_momento  int,                     -- se calcula al subir, con el nacimiento del caballo
  hito                   text,                    -- "potranca en el campo", "primera doma", "taqueo", "primer chukker", ...
  nota                   text,
  created_by             uuid references auth.users (id),
  created_at             timestamptz not null default now()
);
create index videos_caballo_idx on videos (caballo_id, fecha);

create table fotos (
  id               uuid primary key default gen_random_uuid(),
  organizacion_id  uuid not null references organizaciones (id),
  caballo_id       uuid not null references caballos (id) on delete cascade,
  storage_path     text not null,
  orden            int not null default 0
);
create index fotos_caballo_idx on fotos (caballo_id, orden);

-- ---------- Economía ----------

create table gastos (
  id               uuid primary key default gen_random_uuid(),
  organizacion_id  uuid not null references organizaciones (id),
  caballo_id       uuid not null references caballos (id) on delete cascade,
  fecha            date not null,
  rubro            text not null check (rubro in ('Alimentación','Veterinaria','Herrería','Pensión/campo',
                                                  'Transporte','Personal','Seguro','Torneos','Reproducción','Otros')),
  detalle          text,
  monto            numeric not null,
  moneda           text not null default 'USD' check (moneda in ('USD', 'ARS'))
);
create index gastos_caballo_idx on gastos (caballo_id, fecha);

create table ingresos (
  id               uuid primary key default gen_random_uuid(),
  organizacion_id  uuid not null references organizaciones (id),
  caballo_id       uuid not null references caballos (id) on delete cascade,
  fecha            date not null,
  rubro            text not null check (rubro in ('Venta','Alquiler de temporada','Premio',
                                                  'Venta de embrión','Servicio','Otros')),
  detalle          text,
  monto            numeric not null,
  moneda           text not null default 'USD' check (moneda in ('USD', 'ARS'))
);
create index ingresos_caballo_idx on ingresos (caballo_id, fecha);

-- ---------- Deportivo y logística ----------

create table torneos_caballo (
  id               uuid primary key default gen_random_uuid(),
  organizacion_id  uuid not null references organizaciones (id),
  caballo_id       uuid not null references caballos (id) on delete cascade,
  anio             int,
  torneo           text,
  jugador          text,
  chukkers         int,
  premio           text
);
create index torneos_caballo_idx on torneos_caballo (caballo_id, anio);

create table temporadas (
  id               uuid primary key default gen_random_uuid(),
  organizacion_id  uuid not null references organizaciones (id),
  nombre           text not null,
  sede             text,
  desde            date,
  hasta            date,
  notas            text
);

create table temporada_caballos (
  temporada_id  uuid not null references temporadas (id) on delete cascade,
  caballo_id    uuid not null references caballos (id) on delete cascade,
  primary key (temporada_id, caballo_id)
);

create table movimientos (
  id               uuid primary key default gen_random_uuid(),
  organizacion_id  uuid not null references organizaciones (id),
  caballo_id       uuid not null references caballos (id) on delete cascade,
  fecha            date not null,
  desde            text,
  hacia            text,
  motivo           text,               -- extra del prototipo
  transporte       text,               -- extra del prototipo
  nota             text
);
create index movimientos_caballo_idx on movimientos (caballo_id, fecha);

-- ---------- Ficha comercial compartible ----------

create table fichas_publicas (
  id               uuid primary key default gen_random_uuid(),
  organizacion_id  uuid not null references organizaciones (id),
  caballo_id       uuid not null references caballos (id) on delete cascade,
  slug             text not null unique,
  activa           boolean not null default true,
  vistas           int not null default 0,
  created_at       timestamptz not null default now()
);

-- ============================================================
-- RLS: cada organización ve solo lo suyo.
-- Borrar es solo del dueño; el resto puede cargar y editar.
-- ============================================================

alter table organizaciones    enable row level security;
alter table perfiles          enable row level security;
alter table caballos          enable row level security;
alter table videos            enable row level security;
alter table fotos             enable row level security;
alter table gastos            enable row level security;
alter table ingresos          enable row level security;
alter table torneos_caballo   enable row level security;
alter table temporadas        enable row level security;
alter table temporada_caballos enable row level security;
alter table movimientos       enable row level security;
alter table fichas_publicas   enable row level security;

create policy org_propia_select on organizaciones for select using (id = org_actual());
create policy perfil_propio     on perfiles       for select using (organizacion_id = org_actual());

-- Macro repetida por tabla: mismo criterio en todas.
create policy sel on caballos for select using (organizacion_id = org_actual());
create policy ins on caballos for insert with check (organizacion_id = org_actual());
create policy upd on caballos for update using (organizacion_id = org_actual());
create policy del on caballos for delete using (organizacion_id = org_actual() and es_dueno());

create policy sel on videos for select using (organizacion_id = org_actual());
create policy ins on videos for insert with check (organizacion_id = org_actual());
create policy upd on videos for update using (organizacion_id = org_actual());
create policy del on videos for delete using (organizacion_id = org_actual() and es_dueno());

create policy sel on fotos for select using (organizacion_id = org_actual());
create policy ins on fotos for insert with check (organizacion_id = org_actual());
create policy upd on fotos for update using (organizacion_id = org_actual());
create policy del on fotos for delete using (organizacion_id = org_actual() and es_dueno());

create policy sel on gastos for select using (organizacion_id = org_actual());
create policy ins on gastos for insert with check (organizacion_id = org_actual());
create policy upd on gastos for update using (organizacion_id = org_actual());
create policy del on gastos for delete using (organizacion_id = org_actual() and es_dueno());

create policy sel on ingresos for select using (organizacion_id = org_actual());
create policy ins on ingresos for insert with check (organizacion_id = org_actual());
create policy upd on ingresos for update using (organizacion_id = org_actual());
create policy del on ingresos for delete using (organizacion_id = org_actual() and es_dueno());

create policy sel on torneos_caballo for select using (organizacion_id = org_actual());
create policy ins on torneos_caballo for insert with check (organizacion_id = org_actual());
create policy upd on torneos_caballo for update using (organizacion_id = org_actual());
create policy del on torneos_caballo for delete using (organizacion_id = org_actual() and es_dueno());

create policy sel on temporadas for select using (organizacion_id = org_actual());
create policy ins on temporadas for insert with check (organizacion_id = org_actual());
create policy upd on temporadas for update using (organizacion_id = org_actual());
create policy del on temporadas for delete using (organizacion_id = org_actual() and es_dueno());

create policy sel on temporada_caballos for select
  using (exists (select 1 from temporadas t where t.id = temporada_id and t.organizacion_id = org_actual()));
create policy ins on temporada_caballos for insert
  with check (exists (select 1 from temporadas t where t.id = temporada_id and t.organizacion_id = org_actual()));
create policy del on temporada_caballos for delete
  using (exists (select 1 from temporadas t where t.id = temporada_id and t.organizacion_id = org_actual()));

create policy sel on movimientos for select using (organizacion_id = org_actual());
create policy ins on movimientos for insert with check (organizacion_id = org_actual());
create policy upd on movimientos for update using (organizacion_id = org_actual());
create policy del on movimientos for delete using (organizacion_id = org_actual() and es_dueno());

-- Fichas públicas: solo el dueño las prende y apaga.
create policy sel on fichas_publicas for select using (organizacion_id = org_actual());
create policy ins on fichas_publicas for insert with check (organizacion_id = org_actual() and es_dueno());
create policy upd on fichas_publicas for update using (organizacion_id = org_actual() and es_dueno());
create policy del on fichas_publicas for delete using (organizacion_id = org_actual() and es_dueno());
