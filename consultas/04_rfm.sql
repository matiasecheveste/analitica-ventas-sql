-- Analítica de ventas en PostgreSQL — Matías Nicolás Echeveste Cardozo
-- Segmentación RFM (recencia, frecuencia, monto) en quintiles con NTILE.
-- La fecha de referencia es la última venta registrada, no la fecha del servidor,
-- para que el resultado sea reproducible.
WITH referencia AS (
  SELECT max(fecha) AS hoy FROM ventas
),
por_cliente AS (
  SELECT v.cliente_id,
         (SELECT hoy FROM referencia) - max(v.fecha) AS dias_desde_ultima,
         count(DISTINCT v.id)                         AS compras,
         sum(l.importe)                               AS monto
  FROM ventas v
  JOIN lineas_venta l ON l.venta_id = v.id
  GROUP BY v.cliente_id
),
puntuado AS (
  SELECT *,
         ntile(5) OVER (ORDER BY dias_desde_ultima DESC, cliente_id) AS r,
         ntile(5) OVER (ORDER BY compras, cliente_id)                AS f,
         ntile(5) OVER (ORDER BY monto, cliente_id)                  AS m
  FROM por_cliente
)
SELECT cliente_id, dias_desde_ultima, compras, monto, r, f, m,
       CASE
         WHEN r >= 4 AND f >= 4 THEN 'Campeones'
         WHEN r >= 3 AND f >= 3 THEN 'Leales'
         WHEN r >= 3            THEN 'Recientes'
         WHEN f >= 3            THEN 'En riesgo'
         ELSE 'Dormidos'
       END AS segmento
FROM puntuado
ORDER BY monto DESC, cliente_id;
