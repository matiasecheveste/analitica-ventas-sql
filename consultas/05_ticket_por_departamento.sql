-- Analítica de ventas en PostgreSQL — Matías Nicolás Echeveste Cardozo
-- Distribución del ticket por departamento: promedio, mediana y percentil 90
-- (agregados ordenados percentile_cont ... WITHIN GROUP).
WITH tickets AS (
  SELECT v.id, d.nombre AS departamento, sum(l.importe) AS total
  FROM ventas v
  JOIN sucursales s    ON s.id = v.sucursal_id
  JOIN departamentos d ON d.id = s.departamento_id
  JOIN lineas_venta l  ON l.venta_id = v.id
  GROUP BY v.id, d.nombre
)
SELECT departamento,
       count(*)                                                        AS tickets,
       round(avg(total), 2)                                            AS promedio,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY total)::numeric, 2) AS mediana,
       round(percentile_cont(0.9) WITHIN GROUP (ORDER BY total)::numeric, 2) AS p90
FROM tickets
GROUP BY departamento
ORDER BY tickets DESC, departamento;
