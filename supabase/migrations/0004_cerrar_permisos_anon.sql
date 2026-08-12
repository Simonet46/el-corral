-- Supabase otorga EXECUTE a anon por defecto en las funciones nuevas.
-- Se lo sacamos a todo lo que requiere estar logueado. Las únicas funciones
-- que el público puede ejecutar son ficha_publica y ficha_publica_visita:
-- son la ficha comercial compartible, y es a propósito.

revoke execute on function crear_organizacion(text, text) from anon;
revoke execute on function unirse_a_organizacion(text, text) from anon;

-- org_actual y es_dueno heredaban además el grant a PUBLIC.
-- Quedan solo para authenticated, que los necesita porque las políticas
-- RLS evalúan estas funciones como el usuario que consulta.
revoke execute on function org_actual() from public, anon;
revoke execute on function es_dueno() from public, anon;
grant execute on function org_actual() to authenticated;
grant execute on function es_dueno() to authenticated;
