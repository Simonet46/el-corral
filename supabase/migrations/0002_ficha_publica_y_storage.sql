-- ============================================================
-- El Corral — Ficha comercial pública y buckets de storage
-- ============================================================

-- ---------- Acceso público a la ficha, sin login ----------
-- Nunca se abren las tablas al rol anon: una única función security definer
-- devuelve solo lo que un comprador tiene que ver, y solo si la ficha está activa.
-- Los costos, gastos y todo lo interno del establo nunca salen por acá.

create or replace function ficha_publica(p_slug text) returns jsonb
language plpgsql stable security definer set search_path = public as
$$
declare
  v_ficha  fichas_publicas%rowtype;
  v_out    jsonb;
begin
  select * into v_ficha from fichas_publicas where slug = p_slug and activa;
  if not found then
    return null;
  end if;

  select jsonb_build_object(
    'nombre', c.nombre,
    'apodo', c.apodo,
    'sexo', c.sexo,
    'nacimiento', c.nacimiento,
    'pelaje', c.pelaje,
    'criador', c.criador,
    'origen', c.origen,
    'aptitudes', c.aptitudes,
    'observaciones', c.observaciones,
    'precio_venta', c.precio_venta,
    'precio_moneda', c.precio_moneda,
    'video_link', c.video_link,
    'padre', coalesce((select p.nombre from caballos p where p.id = c.padre_id), c.padre_texto),
    'madre', coalesce((select m.nombre from caballos m where m.id = c.madre_id), c.madre_texto),
    'torneos', (select coalesce(jsonb_agg(jsonb_build_object(
                  'anio', t.anio, 'torneo', t.torneo, 'jugador', t.jugador,
                  'chukkers', t.chukkers, 'premio', t.premio) order by t.anio desc), '[]'::jsonb)
                from torneos_caballo t where t.caballo_id = c.id),
    'fotos',   (select coalesce(jsonb_agg(f.storage_path order by f.orden), '[]'::jsonb)
                from fotos f where f.caballo_id = c.id),
    'videos',  (select coalesce(jsonb_agg(jsonb_build_object(
                  'path', v.storage_path, 'hito', v.hito, 'fecha', v.fecha,
                  'edad_meses', v.edad_meses_al_momento) order by v.fecha), '[]'::jsonb)
                from videos v where v.caballo_id = c.id)
  ) into v_out
  from caballos c where c.id = v_ficha.caballo_id;

  return v_out;
end;
$$;

-- anon puede ejecutar solo esta función
revoke all on function ficha_publica(text) from public;
grant execute on function ficha_publica(text) to anon, authenticated;

-- Contador de visitas separado: la función de lectura es stable y no puede escribir.
create or replace function ficha_publica_visita(p_slug text) returns void
language sql volatile security definer set search_path = public as
$$ update fichas_publicas set vistas = vistas + 1 where slug = p_slug and activa $$;

revoke all on function ficha_publica_visita(text) from public;
grant execute on function ficha_publica_visita(text) to anon, authenticated;

-- ---------- Storage ----------
-- Buckets privados. Convención de ruta: organizacion_id/caballo_id/archivo
-- Los usuarios logueados leen y suben solo dentro de su organización.
-- El público (anon) puede leer un archivo únicamente si el caballo de esa
-- ruta tiene una ficha pública activa.

insert into storage.buckets (id, name, public) values ('fotos', 'fotos', false)
  on conflict (id) do nothing;
insert into storage.buckets (id, name, public) values ('videos', 'videos', false)
  on conflict (id) do nothing;

create policy medios_org_select on storage.objects for select to authenticated
  using (bucket_id in ('fotos', 'videos')
         and split_part(name, '/', 1) = org_actual()::text);

create policy medios_org_insert on storage.objects for insert to authenticated
  with check (bucket_id in ('fotos', 'videos')
              and split_part(name, '/', 1) = org_actual()::text);

create policy medios_org_delete on storage.objects for delete to authenticated
  using (bucket_id in ('fotos', 'videos')
         and split_part(name, '/', 1) = org_actual()::text
         and es_dueno());

create policy medios_ficha_publica on storage.objects for select to anon
  using (bucket_id in ('fotos', 'videos')
         and exists (select 1 from fichas_publicas fp
                     where fp.activa
                       and fp.caballo_id::text = split_part(name, '/', 2)));
