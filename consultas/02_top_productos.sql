-- Analítica de ventas en PostgreSQL — Matías Nicolás Echeveste Cardozo
-- Los 3 productos más facturados de cada categoría y su participación en ella.
WITH por_producto AS (
  SELECT categoria, producto, sum(importe) AS importe
  FROM ventas_detalle
  GROUP BY categoria, producto
),
ranqueado AS (
  SELECT categoria, producto, importe,
         dense_rank() OVER (PARTITION BY categoria ORDER BY importe DESC) AS puesto,
         round(100 * importe / sum(importe) OVER (PARTITION BY categoria), 2) AS participacion_pct
  FROM por_producto
)
SELECT categoria, puesto, producto, importe, participacion_pct
FROM ranqueado
WHERE puesto <= 3
ORDER BY categoria, puesto, producto;
