-- Analítica de ventas en PostgreSQL — Matías Nicolás Echeveste Cardozo
-- Datos de demostración reproducibles (semilla fija): 12 sucursales, 40 productos,
-- 1.500 clientes y unas 20.000 ventas entre enero de 2025 y junio de 2026.
-- Precios de lista en pesos uruguayos, con una variación de ±10 % sobre un valor de referencia.

SELECT setseed(0.2026);

INSERT INTO sucursales (nombre, departamento_id) VALUES
  ('Centro', 10), ('Pocitos', 10), ('Cordón', 10), ('Malvín', 10), ('Las Piedras', 2),
  ('Ciudad de la Costa', 2), ('Punta del Este', 9), ('Colonia del Sacramento', 4),
  ('Salto Centro', 15), ('Paysandú Centro', 11), ('Rivera Centro', 13), ('La Paloma', 14);

INSERT INTO categorias (nombre) VALUES
  ('Almacén'), ('Bebidas'), ('Limpieza'), ('Frescos'), ('Perfumería');

INSERT INTO productos (nombre, categoria_id, precio_lista)
SELECT p.nombre, c.id, round((p.precio * (0.9 + random() * 0.2))::numeric, 2)
FROM (VALUES
  ('Almacén', 'Yerba 1 kg', 260), ('Almacén', 'Arroz 1 kg', 75), ('Almacén', 'Fideos 500 g', 65), ('Almacén', 'Aceite 900 ml', 140),
  ('Almacén', 'Azúcar 1 kg', 70), ('Almacén', 'Harina 1 kg', 55), ('Almacén', 'Dulce de leche 500 g', 150), ('Almacén', 'Galletitas 300 g', 90),
  ('Bebidas', 'Agua 2 l', 70), ('Bebidas', 'Refresco 1,5 l', 120), ('Bebidas', 'Jugo 1 l', 95), ('Bebidas', 'Cerveza 1 l', 150),
  ('Bebidas', 'Vino tannat 750 ml', 390), ('Bebidas', 'Café 250 g', 290), ('Bebidas', 'Té 25 saquitos', 80), ('Bebidas', 'Agua tónica 1,5 l', 110),
  ('Limpieza', 'Detergente 750 ml', 95), ('Limpieza', 'Jabón en polvo 800 g', 230), ('Limpieza', 'Hipoclorito 1 l', 60),
  ('Limpieza', 'Limpiador de pisos 1 l', 110), ('Limpieza', 'Esponjas x3', 85), ('Limpieza', 'Bolsas de residuos x10', 75),
  ('Limpieza', 'Papel de cocina x2', 130), ('Limpieza', 'Suavizante 900 ml', 170),
  ('Frescos', 'Leche 1 l', 48), ('Frescos', 'Queso colonia 500 g', 330), ('Frescos', 'Manteca 200 g', 150), ('Frescos', 'Yogur 1 l', 120),
  ('Frescos', 'Huevos x12', 190), ('Frescos', 'Pan flauta', 45), ('Frescos', 'Muzzarella 500 g', 290), ('Frescos', 'Jamón 200 g', 200),
  ('Perfumería', 'Shampoo 400 ml', 240), ('Perfumería', 'Acondicionador 400 ml', 250), ('Perfumería', 'Jabón de tocador x3', 130),
  ('Perfumería', 'Pasta dental 90 g', 110), ('Perfumería', 'Desodorante 150 ml', 190), ('Perfumería', 'Papel higiénico x4', 150),
  ('Perfumería', 'Protector solar 200 ml', 620), ('Perfumería', 'Cepillo de dientes', 120)
) AS p (categoria, nombre, precio)
JOIN categorias c ON c.nombre = p.categoria;

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
