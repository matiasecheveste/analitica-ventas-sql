/*
 * Analítica de ventas en PostgreSQL — Matías Nicolás Echeveste Cardozo
 * Cada consulta se verifica contra resultados calculados a mano sobre pruebas/fixture.sql.
 */
import assert from 'node:assert/strict'
import { after, before, describe, test } from 'node:test'
import { consultar, crearBase } from './bd.mjs'

let db
before(async () => {
  db = await crearBase()
})
after(() => db.close())

describe('consultas analíticas', () => {
  test('ventas mensuales con variación y acumulado', async () => {
    // Enero 410+180, febrero 560+120, marzo 330+300.
    assert.deepEqual(await consultar(db, '01_ventas_mensuales.sql'), [
      { mes: '2026-01', importe: 590, variacion_pct: null, acumulado_anual: 590 },
      { mes: '2026-02', importe: 680, variacion_pct: 15.25, acumulado_anual: 1270 },
      { mes: '2026-03', importe: 630, variacion_pct: -7.35, acumulado_anual: 1900 },
    ])
  })

  test('top de productos por categoría con participación', async () => {
    assert.deepEqual(await consultar(db, '02_top_productos.sql'), [
      { categoria: 'Almacén', puesto: 1, producto: 'Yerba', importe: 1000, participacion_pct: 80.65 },
      { categoria: 'Almacén', puesto: 2, producto: 'Arroz', importe: 240, participacion_pct: 19.35 },
      { categoria: 'Bebidas', puesto: 1, producto: 'Refresco', importe: 360, participacion_pct: 54.55 },
      { categoria: 'Bebidas', puesto: 2, producto: 'Agua', importe: 300, participacion_pct: 45.45 },
    ])
  })

  test('retención por cohorte', async () => {
    // Cohorte de enero: Ana y Bruno. En febrero vuelve Ana; en marzo vuelven los dos.
    assert.deepEqual(await consultar(db, '03_cohortes.sql'), [
      { cohorte: '2026-01', meses_despues: 0, clientes: 2, retencion_pct: 100 },
      { cohorte: '2026-01', meses_despues: 1, clientes: 1, retencion_pct: 50 },
      { cohorte: '2026-01', meses_despues: 2, clientes: 2, retencion_pct: 100 },
      { cohorte: '2026-02', meses_despues: 0, clientes: 1, retencion_pct: 100 },
    ])
  })

  test('segmentación RFM', async () => {
    const filas = await consultar(db, '04_rfm.sql')
    assert.deepEqual(
      filas.map(({ cliente_id, dias_desde_ultima, compras, monto, r, f, m, segmento }) => [cliente_id, dias_desde_ultima, compras, monto, r, f, m, segmento]),
      [
        [1, 9, 3, 1300, 2, 3, 3, 'En riesgo'],
        [2, 0, 2, 480, 3, 2, 2, 'Recientes'],
        [3, 24, 1, 120, 1, 1, 1, 'Dormidos'],
      ],
    )
  })

  test('mediana y percentil 90 del ticket por departamento', async () => {
    // Montevideo: 120, 330, 410, 560. Canelones: 180, 300.
    assert.deepEqual(await consultar(db, '05_ticket_por_departamento.sql'), [
      { departamento: 'Montevideo', tickets: 4, promedio: 355, mediana: 370, p90: 515 },
      { departamento: 'Canelones', tickets: 2, promedio: 240, mediana: 240, p90: 288 },
    ])
  })

  test('análisis de canasta con soporte y lift', async () => {
    // Arroz+Yerba aparece en 2 de 6 ventas; Arroz en 2/6 y Yerba en 3/6 → lift = (2/6) / (2/6 · 3/6) = 2.
    assert.deepEqual(await consultar(db, '06_canasta.sql'), [
      { producto_a: 'Arroz', producto_b: 'Yerba', ventas_juntas: 2, soporte: 0.3333, lift: 2 },
    ])
  })
})

describe('esquema', () => {
  test('el importe de cada línea es una columna generada', async () => {
    const { rows } = await db.query('SELECT importe FROM lineas_venta WHERE venta_id = 1 AND producto_id = 1')
    assert.equal(Number(rows[0].importe), 160)
  })

  test('rechaza cantidades y precios no positivos', async () => {
    await assert.rejects(db.query('INSERT INTO lineas_venta VALUES (4, 1, 0, 80)'), /check/i)
    await assert.rejects(db.query('INSERT INTO lineas_venta VALUES (4, 1, 1, -5)'), /check/i)
  })

  test('la vista materializada se refresca sin bloquear lecturas', async () => {
    await db.exec(`INSERT INTO ventas (id, cliente_id, sucursal_id, fecha) VALUES (7, 3, 2, '2026-03-10');
                   INSERT INTO lineas_venta (venta_id, producto_id, cantidad, precio_unitario) VALUES (7, 2, 1, 250);`)
    const antes = await db.query("SELECT count(*)::int AS n FROM resumen_diario WHERE fecha = '2026-03-10'")
    assert.equal(antes.rows[0].n, 1)
    await db.exec('REFRESH MATERIALIZED VIEW CONCURRENTLY resumen_diario')
    const { rows } = await db.query("SELECT sucursal_id, tickets, importe FROM resumen_diario WHERE fecha = '2026-03-10' ORDER BY sucursal_id")
    assert.deepEqual(rows.map((r) => [r.sucursal_id, r.tickets, Number(r.importe)]), [[2, 1, 250], [3, 1, 300]])
    await db.exec('DELETE FROM ventas WHERE id = 7; REFRESH MATERIALIZED VIEW resumen_diario')
  })
})
