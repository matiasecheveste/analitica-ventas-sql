-- Analítica de ventas en PostgreSQL — Matías Nicolás Echeveste Cardozo
-- Análisis de canasta: pares de productos que se compran juntos, con soporte
-- (fracción de ventas que contienen el par) y lift (cuánto más de lo esperado
-- si las compras fueran independientes). Lift > 1 indica afinidad.
WITH total AS (
  SELECT count(*)::numeric AS ventas FROM ventas
),
soporte_producto AS (
  SELECT producto_id, count(*) / (SELECT ventas FROM total) AS soporte
  FROM lineas_venta
  GROUP BY producto_id
),
pares AS (
  SELECT a.producto_id AS producto_a, b.producto_id AS producto_b, count(*) AS ventas_juntas
  FROM lineas_venta a
  JOIN lineas_venta b ON b.venta_id = a.venta_id AND a.producto_id < b.producto_id
  GROUP BY 1, 2
)
SELECT pa.nombre AS producto_a,
       pb.nombre AS producto_b,
       p.ventas_juntas,
       round(p.ventas_juntas / t.ventas, 4)                         AS soporte,
       round((p.ventas_juntas / t.ventas) / (sa.soporte * sb.soporte), 2) AS lift
FROM pares p
CROSS JOIN total t
JOIN soporte_producto sa ON sa.producto_id = p.producto_a
JOIN soporte_producto sb ON sb.producto_id = p.producto_b
JOIN productos pa ON pa.id = p.producto_a
JOIN productos pb ON pb.id = p.producto_b
WHERE p.ventas_juntas >= 2
ORDER BY lift DESC, ventas_juntas DESC, producto_a, producto_b
LIMIT 20;
