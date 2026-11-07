-- Analítica de ventas en PostgreSQL — Matías Nicolás Echeveste Cardozo
-- Vista de detalle y vista materializada para tableros.

CREATE VIEW ventas_detalle AS
SELECT v.id            AS venta_id,
       v.fecha,
       v.cliente_id,
       s.id            AS sucursal_id,
       s.nombre        AS sucursal,
       d.nombre        AS departamento,
       p.id            AS producto_id,
       p.nombre        AS producto,
       c.nombre        AS categoria,
       l.cantidad,
       l.importe
FROM ventas v
JOIN sucursales s    ON s.id = v.sucursal_id
JOIN departamentos d ON d.id = s.departamento_id
JOIN lineas_venta l  ON l.venta_id = v.id
JOIN productos p     ON p.id = l.producto_id
JOIN categorias c    ON c.id = p.categoria_id;

-- Resumen diario por sucursal. El índice único permite REFRESH ... CONCURRENTLY
-- (sin bloquear las lecturas del tablero mientras se recalcula).
CREATE MATERIALIZED VIEW resumen_diario AS
SELECT v.fecha,
       v.sucursal_id,
       count(DISTINCT v.id)       AS tickets,
       sum(l.importe)::numeric(14, 2) AS importe
FROM ventas v
JOIN lineas_venta l ON l.venta_id = v.id
GROUP BY v.fecha, v.sucursal_id
WITH DATA;

CREATE UNIQUE INDEX resumen_diario_pk ON resumen_diario (fecha, sucursal_id);
