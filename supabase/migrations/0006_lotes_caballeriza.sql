-- Lotes dentro de la caballeriza principal (ex "competición").
-- El estado interno sigue llamándose 'competicion'; cambia la etiqueta
-- en la app y se agrega el lote: A, B o NUEVAS (null = sin lote).
alter table caballos add column lote text check (lote in ('A', 'B', 'NUEVAS'));
