-- Analítica de ventas en PostgreSQL — Matías Nicolás Echeveste Cardozo
-- Datos mínimos con resultados calculables a mano (ver comentarios en las pruebas).
INSERT INTO sucursales (id, nombre, departamento_id) VALUES
  (1, 'Centro', 10), (2, 'Pocitos', 10), (3, 'Las Piedras', 2);
INSERT INTO categorias (id, nombre) VALUES (1, 'Almacén'), (2, 'Bebidas');
INSERT INTO productos (id, nombre, categoria_id, precio_lista) VALUES
  (1, 'Arroz', 1, 80), (2, 'Yerba', 1, 250), (3, 'Agua', 2, 60), (4, 'Refresco', 2, 120);
INSERT INTO clientes (id, nombre, alta) VALUES
  (1, 'Ana', '2025-12-01'), (2, 'Bruno', '2025-12-01'), (3, 'Carla', '2025-12-01');
INSERT INTO ventas (id, cliente_id, sucursal_id, fecha) VALUES
  (1, 1, 1, '2026-01-05'), (2, 2, 3, '2026-01-20'), (3, 1, 2, '2026-02-03'),
  (4, 3, 1, '2026-02-14'), (5, 1, 1, '2026-03-01'), (6, 2, 3, '2026-03-10');
INSERT INTO lineas_venta (venta_id, producto_id, cantidad, precio_unitario) VALUES
  (1, 1, 2, 80), (1, 2, 1, 250),          -- 410
  (2, 3, 3, 60),                          -- 180
  (3, 2, 2, 250), (3, 3, 1, 60),          -- 560
  (4, 4, 1, 120),                         -- 120
  (5, 1, 1, 80), (5, 2, 1, 250),          -- 330
  (6, 4, 2, 120), (6, 3, 1, 60);          -- 300
REFRESH MATERIALIZED VIEW resumen_diario;
