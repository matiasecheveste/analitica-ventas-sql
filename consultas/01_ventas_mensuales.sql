-- Analítica de ventas en PostgreSQL — Matías Nicolás Echeveste Cardozo
-- Facturación mensual, variación contra el mes anterior (LAG) y acumulado del año.
WITH mensual AS (
  SELECT date_trunc('month', v.fecha)::date AS mes,
         sum(l.importe)                     AS importe
  FROM ventas v
  JOIN lineas_venta l ON l.venta_id = v.id
  GROUP BY 1
)
SELECT to_char(mes, 'YYYY-MM') AS mes,
       importe,
       round(100 * (importe / lag(importe) OVER (ORDER BY mes) - 1), 2) AS variacion_pct,
       sum(importe) OVER (PARTITION BY date_trunc('year', mes) ORDER BY mes) AS acumulado_anual
FROM mensual
ORDER BY mes;
