/*
 * Analítica de ventas en PostgreSQL — Matías Nicolás Echeveste Cardozo
 * Carga los datos de demostración en una base en memoria y muestra cada consulta.
 * Uso: npm run informe [-- 01_ventas_mensuales.sql]
 */
import { readdir } from 'node:fs/promises'
import { consultar, crearBase } from '../pruebas/bd.mjs'

const pedida = process.argv[2]
const archivos = (await readdir(new URL('../consultas/', import.meta.url))).filter((a) => a.endsWith('.sql') && (!pedida || a === pedida))

console.log('Cargando datos de demostración…')
const db = await crearBase({ datos: 'sql/03_datos_demo.sql' })
for (const archivo of archivos) {
  const filas = await consultar(db, archivo)
  console.log(`\n== ${archivo} (${filas.length} filas, se muestran hasta 12) ==`)
  console.table(filas.slice(0, 12))
}
await db.close()
