-- Analítica de ventas en PostgreSQL — Matías Nicolás Echeveste Cardozo
-- Datos de demostración reproducibles (semilla fija): 12 sucursales, 40 productos,
-- 1.500 clientes y unas 20.000 ventas entre enero de 2025 y junio de 2026.

SELECT setseed(0.2026);

INSERT INTO sucursales (nombre, departamento_id) VALUES
  ('Centro', 10), ('Pocitos', 10), ('Cordón', 10), ('Malvín', 10), ('Las Piedras', 2),
  ('Ciudad de la Costa', 2), ('Punta del Este', 9), ('Colonia del Sacramento', 4),
  ('Salto Centro', 15), ('Paysandú Centro', 11), ('Rivera Centro', 13), ('La Paloma', 14);

INSERT INTO categorias (nombre) VALUES
  ('Almacén'), ('Bebidas'), ('Limpieza'), ('Frescos'), ('Perfumería');

INSERT INTO productos (nombre, categoria_id, precio_lista)
SELECT format('%s %s', c.nombre, n), c.id, round((40 + random() * 460)::numeric, 2)
FROM categorias c, generate_series(1, 8) AS n;

INSERT INTO clientes (nombre, alta)
SELECT format('Cliente %s', n), date '2024-06-01' + (random() * 500)::int
FROM generate_series(1, 1500) AS n;

-- Ventas: las sucursales de Montevideo y los fines de semana venden más.
INSERT INTO ventas (cliente_id, sucursal_id, fecha)
SELECT 1 + floor(random() * 1500)::int,
       CASE WHEN random() < 0.55 THEN 1 + floor(random() * 4)::int ELSE 5 + floor(random() * 8)::int END,
       f.dia
FROM generate_series(date '2025-01-01', date '2026-06-30', interval '1 day') AS f(dia),
     generate_series(1, CASE WHEN extract(isodow FROM f.dia) >= 6 THEN 50 ELSE 32 END);

-- Entre 1 y 4 productos distintos por venta, con el precio de lista de ese momento.
INSERT INTO lineas_venta (venta_id, producto_id, cantidad, precio_unitario)
SELECT v.id, p.id, 1 + floor(random() * 3)::int, p.precio_lista
FROM ventas v
CROSS JOIN LATERAL (
  SELECT id, precio_lista FROM productos
  WHERE v.id > 0  -- referencia a la fila externa: se sortea por venta
  ORDER BY random()
  LIMIT 1 + floor(random() * 4)::int
) p;

REFRESH MATERIALIZED VIEW resumen_diario;
ANALYZE;
