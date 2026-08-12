# Plan de migración a Supabase — branch `supabase-mvp`

Estado: **propuesto, esperando aprobación**. Nada de esto está aplicado.

## Qué cambia para el usuario

Hoy los datos viven en el navegador de cada dispositivo: lo que carga Matías en su celular no se ve en ninguna otra pantalla. Con esta fase:

- Cada persona entra con **email y contraseña**.
- Todos los del criadero ven **los mismos datos, desde cualquier dispositivo**.
- Roles: **dueño** (todo), **petisero** y **veterinario** (cargan, no borran).
- Los **videos y fotos** viven en el servidor: se suben desde el celular en el campo y se ven desde cualquier lado. Es la base de la línea de tiempo en video.
- **Ficha comercial por link**: una página pública de solo lectura por caballo, que se prende y se apaga, y cuenta las visitas.

## Esquema

Está completo en [`supabase/migrations/`](../supabase/migrations/):

- **`0001_esquema_inicial.sql`** — `organizaciones`, `perfiles` (rol dueño/petisero/veterinario), `caballos` (todo el modelo del prototipo, con `padre_id`/`madre_id` auto-referenciados + texto libre para pedigrí externo y `aptitudes` en jsonb), `videos` (con `hito` y `edad_meses_al_momento`: la evolución en video), `fotos`, `gastos`, `ingresos`, `torneos_caballo`, `temporadas` + `temporada_caballos`, `movimientos`, `fichas_publicas`. RLS en todas las tablas por organización; borrar es solo del dueño.
- **`0002_ficha_publica_y_storage.sql`** — la función `ficha_publica(slug)` que expone al público únicamente los datos comerciales (nunca costos ni nada interno) y suma visitas; buckets privados `fotos` y `videos` con política por convención de ruta `organizacion/caballo/archivo`, y lectura anónima solo para los medios de caballos con ficha activa.

### Decisiones tomadas (avisar si alguna no va)

1. **Campos extra sobre el pedido original**, para no perder datos del prototipo: `desparasitacion_fecha`, `odontologia_fecha`, `alta_estimada`, `servicio`, `receptora`, `fecha_parto`, `historial_clinico`, `notas`, `video_link`, y `motivo`/`transporte` en movimientos.
2. **Nombre único por organización** (`unique (organizacion_id, lower(nombre))`) — el prototipo arma el pedigrí por nombre y ya avisa si se repite.
3. **"La plata" y los roles:** en esta v1 la restricción de que petisero/veterinario no vean costos se aplica en la interfaz, no en la base (RLS es por fila, no por columna). Si querés que sea una garantía de verdad, en v1.1 se agrega una vista `caballos_sin_plata` y se les revoca el select directo a la tabla.
4. **Origen** con las opciones nuevas: Embrión (cría propia), Manada (cría propia), Compra de embrión, Comprado.

## Migración de datos

`scripts/importar-respaldo.mjs` (a escribir en el paso 3): toma el JSON de **Exportar respaldo** de la app actual y lo sube — crea la organización, inserta los caballos resolviendo madre/padre por nombre a `madre_id`/`padre_id`, y sube las fotos base64 al bucket. **Limitación:** los videos guardados en el prototipo (IndexedDB) no viajan en el respaldo; se recargan a mano.

## Frontend

La UI y el CSS quedan **exactamente iguales** (corral, colores, fichas, todo). Solo se reemplaza la capa de datos: donde hoy hay `localStorage` pasa a haber un objeto `repo` con funciones async contra `supabase-js` (por CDN, sin build tooling). Se agrega una pantalla mínima de login y una ruta pública `#/f/:slug` para la ficha comercial. Sigue siendo un archivo estático deployable en Pages.

## Orden de ejecución (cuando lo apruebes)

1. Crear el proyecto en Supabase y aplicar las dos migraciones.
2. Buckets y un usuario dueño para probar.
3. Script de importación + probar con un respaldo real.
4. Frontend: capa `repo` + login + ficha pública.
5. Deploy y prueba de punta a punta con dos dispositivos.

## Cómo aplicar las migraciones

Con el conector de Supabase conectado, las aplico yo. Si no:

```bash
supabase login
supabase link --project-ref <ref-del-proyecto>
supabase db push
```

O pegando cada archivo en el SQL Editor del dashboard, en orden.
