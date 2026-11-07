/*
 * Analítica de ventas en PostgreSQL — Matías Nicolás Echeveste Cardozo
 * Verifica que el generador de datos de demostración produce un volumen coherente,
 * que todas las consultas corren sobre él y que el planificador usa los índices.
 */
import assert from 'node:assert/strict'
import { after, before, test } from 'node:test'
import { consultar, crearBase } from './bd.mjs'

let db
before(async () => {
  db = await crearBase({ datos: 'sql/03_datos_demo.sql' })
})
after(() => db.close())

test('genera el volumen esperado de datos', async () => {
  const { rows } = await db.query(`SELECT (SELECT count(*) FROM ventas)::int AS ventas,
                                          (SELECT count(*) FROM lineas_venta)::int AS lineas,
                                          (SELECT min(fecha) FROM ventas)::text AS desde,
                                          (SELECT max(fecha) FROM ventas)::text AS hasta`)
  const [r] = rows
  assert.ok(r.ventas > 19_000 && r.ventas < 21_000, `ventas: ${r.ventas}`)
  assert.ok(r.lineas > 2 * r.ventas && r.lineas < 3 * r.ventas, `líneas: ${r.lineas}`)
  assert.equal(r.desde, '2025-01-01')
  assert.equal(r.hasta, '2026-06-30')
})

test('todas las consultas producen resultados sobre los datos de demostración', async () => {
  const meses = await consultar(db, '01_ventas_mensuales.sql')
  assert.equal(meses.length, 18)
  const suma2026 = meses.slice(12).reduce((s, m) => s + m.importe, 0)
  assert.ok(Math.abs(meses.at(-1).acumulado_anual - suma2026) < 0.005)

  const top = await consultar(db, '02_top_productos.sql')
  assert.equal(new Set(top.map((t) => t.categoria)).size, 5)

  const rfm = await consultar(db, '04_rfm.sql')
  assert.ok(rfm.some((c) => c.segmento === 'Campeones'))

  const departamentos = await consultar(db, '05_ticket_por_departamento.sql')
  assert.equal(departamentos[0].departamento, 'Montevideo')
  for (const d of departamentos) assert.ok(d.mediana <= d.p90)

  assert.ok((await consultar(db, '03_cohortes.sql')).length > 0)
  assert.ok((await consultar(db, '06_canasta.sql')).length > 0)
})

test('el historial de un cliente se resuelve con el índice compuesto', async () => {
  const { rows } = await db.query("EXPLAIN SELECT * FROM ventas WHERE cliente_id = 42 AND fecha >= '2026-01-01'")
  const plan = rows.map((r) => r['QUERY PLAN']).join('\n')
  assert.match(plan, /ventas_cliente_fecha_idx/)
})
