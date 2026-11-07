-- Analítica de ventas en PostgreSQL — Matías Nicolás Echeveste Cardozo
-- Retención por cohorte: clientes agrupados por el mes de su primera compra y
-- porcentaje que vuelve a comprar N meses después.
WITH compras AS (
  SELECT DISTINCT cliente_id, date_trunc('month', fecha)::date AS mes
  FROM ventas
),
cohorte AS (
  SELECT cliente_id, min(mes) AS mes_cohorte
  FROM compras
  GROUP BY cliente_id
),
actividad AS (
  SELECT c.mes_cohorte,
         (extract(year FROM age(p.mes, c.mes_cohorte)) * 12
          + extract(month FROM age(p.mes, c.mes_cohorte)))::int AS meses_despues,
         count(*) AS clientes
  FROM compras p
  JOIN cohorte c USING (cliente_id)
  GROUP BY 1, 2
)
SELECT to_char(mes_cohorte, 'YYYY-MM') AS cohorte,
       meses_despues,
       clientes,
       round(100.0 * clientes / first_value(clientes) OVER (PARTITION BY mes_cohorte ORDER BY meses_despues), 1) AS retencion_pct
FROM actividad
ORDER BY mes_cohorte, meses_despues;
