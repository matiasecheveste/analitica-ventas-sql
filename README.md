# Analítica de ventas en PostgreSQL

Modelo de datos y consultas analíticas para una cadena de comercios con sucursales en distintos departamentos de Uruguay. El SQL es el producto principal. Node.js se usa sólo para correr las pruebas, y lo hace sobre **PGlite** (PostgreSQL real compilado a WebAssembly), así que no hace falta instalar un servidor.

## Contenido

| Archivo | Técnica |
|---|---|
| `sql/01_esquema.sql` | claves foráneas, `CHECK`, columnas `IDENTITY`, columna generada (`importe`), índices compuestos |
| `sql/02_vistas.sql` | vista de detalle y **vista materializada** con índice único para `REFRESH … CONCURRENTLY` |
| `sql/03_datos_demo.sql` | datos sintéticos reproducibles con `setseed`, `generate_series` y `LATERAL` (~20.000 ventas) |
| `consultas/01_ventas_mensuales.sql` | `LAG` para variación mensual y `SUM() OVER (PARTITION BY año)` para el acumulado |
| `consultas/02_top_productos.sql` | `DENSE_RANK` por categoría y participación porcentual |
| `consultas/03_cohortes.sql` | retención por cohorte de primera compra con `age()` y `FIRST_VALUE` |
| `consultas/04_rfm.sql` | segmentación RFM en quintiles con `NTILE` |
| `consultas/05_ticket_por_departamento.sql` | mediana y percentil 90 con `percentile_cont … WITHIN GROUP` |
| `consultas/06_canasta.sql` | productos que se compran juntos: soporte y *lift* |

## Pruebas

`pruebas/fixture.sql` carga seis ventas cuyos resultados se pueden calcular a mano. Cada consulta se compara contra el resultado exacto esperado, y los comentarios de `pruebas/consultas.test.mjs` muestran el cálculo. Por ejemplo, el par Arroz + Yerba aparece en 2 de 6 ventas, y su *lift* es (2/6) / (2/6 · 3/6) = 2.

Las pruebas también cubren:

- las restricciones del esquema;
- el refresco concurrente de la vista materializada;
- el volumen generado por los datos de demostración;
- que el planificador use el índice compuesto para el historial de un cliente (`EXPLAIN`).

```bash
npm install
npm test           # 12 pruebas en PGlite
npm run informe    # carga los datos de demostración y muestra todas las consultas
npm run informe -- 04_rfm.sql
```

## Con un PostgreSQL propio

```bash
createdb ventas
psql -d ventas -v ON_ERROR_STOP=1 -f sql/01_esquema.sql -f sql/02_vistas.sql -f sql/03_datos_demo.sql
psql -d ventas -f consultas/03_cohortes.sql
```

## Integración continua

GitHub Actions corre las pruebas en PGlite y, en otro trabajo, carga el esquema y los datos en un **PostgreSQL 17** real. Ahí ejecuta cada consulta con `ON_ERROR_STOP` y guarda el `EXPLAIN ANALYZE` de cada una como artefacto.

## Autor

Matías Nicolás Echeveste Cardozo — licencia MIT.
