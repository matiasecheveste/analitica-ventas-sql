/*
 * Analítica de ventas en PostgreSQL — Matías Nicolás Echeveste Cardozo
 * Utilidades de prueba: crea una base PostgreSQL en memoria (PGlite) con el esquema.
 */
import { PGlite } from '@electric-sql/pglite'
import { readFile } from 'node:fs/promises'

const raiz = new URL('../', import.meta.url)
export const leer = (ruta) => readFile(new URL(ruta, raiz), 'utf8')

export async function crearBase({ datos = 'pruebas/fixture.sql' } = {}) {
  const db = new PGlite()
  await db.exec(await leer('sql/01_esquema.sql'))
  await db.exec(await leer('sql/02_vistas.sql'))
  if (datos) await db.exec(await leer(datos))
  return db
}

/** Ejecuta una consulta de consultas/ y convierte los numeric (texto) en número. */
export async function consultar(db, archivo) {
  const { rows } = await db.query(await leer(`consultas/${archivo}`))
  return rows.map((fila) =>
    Object.fromEntries(Object.entries(fila).map(([k, v]) => [k, typeof v === 'string' && /^-?\d+(\.\d+)?$/.test(v) ? Number(v) : v])),
  )
}
