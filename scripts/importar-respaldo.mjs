#!/usr/bin/env node
/**
 * Importa un respaldo de El Corral (el JSON que baja "Exportar respaldo")
 * a un proyecto de Supabase ya migrado.
 *
 * Uso:
 *   SUPABASE_URL=https://<ref>.supabase.co \
 *   SUPABASE_SERVICE_KEY=<service_role> \
 *   node scripts/importar-respaldo.mjs <respaldo.json> <organizacion_id>
 *
 * - Usa la service key (salta RLS): correrlo solo desde una máquina propia.
 * - Es idempotente por nombre: si un caballo ya existe en la organización,
 *   lo saltea entero (no duplica ni pisa).
 * - Las fotos base64 del respaldo se suben al bucket "fotos".
 * - Los videos del prototipo viven en IndexedDB y NO están en el respaldo:
 *   se recargan a mano desde la app.
 */

import { readFileSync } from "node:fs";

const [archivo, organizacionId] = process.argv.slice(2);
const URL_BASE = process.env.SUPABASE_URL;
const SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY;

if (!archivo || !organizacionId || !URL_BASE || !SERVICE_KEY) {
  console.error("Faltan datos. Uso:\n  SUPABASE_URL=... SUPABASE_SERVICE_KEY=... node scripts/importar-respaldo.mjs <respaldo.json> <organizacion_id>");
  process.exit(1);
}

const cab = (p) => `${URL_BASE}/rest/v1/${p}`;
const CABECERAS = {
  apikey: SERVICE_KEY,
  Authorization: `Bearer ${SERVICE_KEY}`,
  "Content-Type": "application/json",
};

async function insertar(tabla, filas, devolver = false) {
  if (!filas.length) return [];
  const r = await fetch(cab(tabla), {
    method: "POST",
    headers: { ...CABECERAS, Prefer: devolver ? "return=representation" : "return=minimal" },
    body: JSON.stringify(filas),
  });
  if (!r.ok) throw new Error(`${tabla}: ${r.status} ${await r.text()}`);
  return devolver ? r.json() : [];
}

async function existentes() {
  const r = await fetch(cab(`caballos?organizacion_id=eq.${organizacionId}&select=id,nombre`), { headers: CABECERAS });
  if (!r.ok) throw new Error(`leyendo caballos: ${r.status}`);
  return r.json();
}

async function subirFoto(caballoId, indice, dataUrl) {
  const [meta, b64] = dataUrl.split(",");
  const tipo = (meta.match(/data:(.*?);/) || [])[1] || "image/jpeg";
  const ext = tipo.includes("png") ? "png" : "jpg";
  const ruta = `${organizacionId}/${caballoId}/foto-${indice}.${ext}`;
  const r = await fetch(`${URL_BASE}/storage/v1/object/fotos/${ruta}`, {
    method: "POST",
    headers: { apikey: SERVICE_KEY, Authorization: `Bearer ${SERVICE_KEY}`, "Content-Type": tipo, "x-upsert": "true" },
    body: Buffer.from(b64, "base64"),
  });
  if (!r.ok) throw new Error(`subiendo foto: ${r.status} ${await r.text()}`);
  return ruta;
}

const norm = (s) => String(s || "").toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "").trim();

const respaldo = JSON.parse(readFileSync(archivo, "utf8"));
const caballos = respaldo.horses || [];
const temporadas = respaldo.temporadas || [];
console.log(`Respaldo: ${caballos.length} caballos, ${temporadas.length} temporadas.`);

const yaCargados = await existentes();
const porNombre = new Map(yaCargados.map((c) => [norm(c.nombre), c.id]));
const nuevos = caballos.filter((h) => !porNombre.has(norm(h.nombre)));
const salteados = caballos.length - nuevos.length;
if (salteados) console.log(`Salteo ${salteados} que ya existen con el mismo nombre.`);

// --- Pasada 1: caballos, sin padres todavía (se resuelven por nombre después) ---
for (const h of nuevos) {
  const fila = {
    organizacion_id: organizacionId,
    nombre: h.nombre,
    apodo: h.apodo || null,
    sexo: h.sexo || null,
    nacimiento: h.nacimiento || null,
    pelaje: h.pelaje || null,
    estado: h.estado || "juego",
    reproductivo: h.reproductivo || "",
    ubicacion: h.ubicacion || null,
    petisero: h.petisero || null,
    jinete: h.jinete || null,
    criador: h.criador || null,
    microchip: h.microchip || null,
    origen: h.origen || "",
    aptitudes: h.aptitudes || {},
    observaciones: h.observacionesFisicas || null,
    historial_clinico: h.historialClinico || null,
    notas: h.notas || null,
    video_link: h.video || null,
    costo_monto: h.costoMonto === "" ? null : h.costoMonto,
    costo_moneda: h.costoMoneda || "USD",
    valuacion: h.valuacion === "" ? null : h.valuacion,
    valuacion_moneda: h.valuacionMoneda || "USD",
    precio_venta: h.precioVenta === "" ? null : h.precioVenta,
    precio_moneda: h.precioMoneda || "USD",
    seguro_suma: h.seguroSuma === "" ? null : h.seguroSuma,
    seguro_moneda: h.seguroMoneda || "USD",
    vacuna_fecha: h.vacunaFecha || null,
    coggins_fecha: h.cogginsFecha || null,
    herraje_fecha: h.herrajeFecha || null,
    desparasitacion_fecha: h.desparasitacionFecha || null,
    odontologia_fecha: h.odontologiaFecha || null,
    alta_estimada: h.altaEstimada || null,
    servicio: h.servicio || null,
    receptora: h.receptora || null,
    fecha_parto: h.fechaParto || null,
    fecha_baja: h.fechaBaja || null,
    causa_baja: h.motivoBaja || null,
    padre_texto: h.padre || null,
    madre_texto: h.madre || null,
  };
  const [creado] = await insertar("caballos", [fila], true);
  porNombre.set(norm(h.nombre), creado.id);
  h._id = creado.id;
  process.stdout.write(".");
}
console.log(`\nCaballos insertados: ${nuevos.length}.`);

// --- Pasada 2: resolver padre/madre por nombre a ids ---
let enlazados = 0;
for (const h of nuevos) {
  const padreId = porNombre.get(norm(h.padre));
  const madreId = porNombre.get(norm(h.madre));
  if (!padreId && !madreId) continue;
  const patch = {};
  if (padreId) { patch.padre_id = padreId; patch.padre_texto = null; }
  if (madreId) { patch.madre_id = madreId; patch.madre_texto = null; }
  const r = await fetch(cab(`caballos?id=eq.${h._id}`), { method: "PATCH", headers: CABECERAS, body: JSON.stringify(patch) });
  if (!r.ok) throw new Error(`pedigrí de ${h.nombre}: ${r.status}`);
  enlazados++;
}
console.log(`Pedigrí enlazado en ${enlazados} caballos.`);

// --- Pasada 3: satélites ---
let nG = 0, nI = 0, nT = 0, nM = 0, nF = 0;
for (const h of nuevos) {
  const id = h._id;
  const base = { organizacion_id: organizacionId, caballo_id: id };
  await insertar("gastos", (h.gastos || []).filter((g) => g.monto).map((g) => ({
    ...base, fecha: g.fecha, rubro: g.rubro === "Pensión / campo" ? "Pensión/campo" : (g.rubro || "Otros"),
    detalle: g.detalle || null, monto: g.monto, moneda: g.moneda || "USD",
  })));
  nG += (h.gastos || []).length;
  await insertar("ingresos", (h.ingresos || []).filter((g) => g.monto).map((g) => ({
    ...base, fecha: g.fecha, rubro: g.rubro || "Otros", detalle: g.detalle || null, monto: g.monto, moneda: g.moneda || "USD",
  })));
  nI += (h.ingresos || []).length;
  await insertar("torneos_caballo", (h.torneos || []).map((t) => ({
    ...base, anio: t.anio || null, torneo: t.torneo || null, jugador: t.jugador || null,
    chukkers: t.chukkers || null, premio: t.premio || null,
  })));
  nT += (h.torneos || []).length;
  await insertar("movimientos", (h.movimientos || []).map((m) => ({
    ...base, fecha: m.fecha, desde: m.desde || null, hacia: m.hasta || null,
    motivo: m.motivo || null, transporte: m.transporte || null,
  })));
  nM += (h.movimientos || []).length;
  for (let i = 0; i < (h.fotos || []).length; i++) {
    const ruta = await subirFoto(id, i, h.fotos[i]);
    await insertar("fotos", [{ ...base, storage_path: ruta, orden: i }]);
    nF++;
  }
}
console.log(`Gastos ${nG} · Ingresos ${nI} · Torneos ${nT} · Movimientos ${nM} · Fotos ${nF}.`);

// --- Pasada 4: temporadas ---
for (const t of temporadas) {
  const [creada] = await insertar("temporadas", [{
    organizacion_id: organizacionId, nombre: t.nombre, sede: t.sede || null,
    desde: t.desde || null, hasta: t.hasta || null, notas: t.notas || null,
  }], true);
  const idsViejos = new Map(caballos.map((h) => [h.id, porNombre.get(norm(h.nombre))]));
  const filas = (t.caballos || []).map((cid) => idsViejos.get(cid)).filter(Boolean)
    .map((cid) => ({ temporada_id: creada.id, caballo_id: cid }));
  await insertar("temporada_caballos", filas);
  console.log(`Temporada "${t.nombre}": ${filas.length} caballos.`);
}

console.log("Listo. Los videos del prototipo no viajan en el respaldo: recargalos desde la app.");
