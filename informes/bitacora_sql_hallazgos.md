# Bitácora SQL y Hallazgos — Caso BrightCart

## Índice de scripts SQL
* `sql/01_ingesta_brightcart.sql` — Creación/conexión de `BrightCartDB` en DuckDB e ingesta de los 7 CSV limpios (`datos/processed/*_clean.csv`).
* `sql/02_kpis_generales_campana.sql` — KPIs generales de campaña (ingresos, unidades, pedidos, ticket medio y mediana), comparativa vs. semana previa, descuentos ponderado vs. simple, clientes únicos, ticket por canal y métodos de pago.
* `sql/03_analisis_integral_campana.sql` — Desglose por categoría y producto, margen bruto (`COGS`), comparativa volumen vs. ingresos, peso del *Vestido Alma*, tráfico vs. conversión por canal (`1–21 jul`) y concentración del catálogo (Top 10 / Top 50).
* `sql/05_analisis_devoluciones_campana.sql` — Tasas de devolución (global con `GROUPING SETS`, categoría y producto líder), margen neto del *Vestido Alma*, motivos de devolución, distribución por talla, cautela por ventana abierta de 30 días e impacto financiero en ingresos de la campaña 1.

---

## Fase 1: Ingesta a base de datos limpia (`01_ingesta_brightcart.sql`)
* **Qué hace el script:** Adjunta `datos/processed/BrightCartDB.duckdb` en DuckDB y carga mediante `read_csv_auto` las tablas saneadas (`campanas`, `clientes`, `devoluciones`, `lineas_pedido`, `pedidos`, `productos` y `visitas_web`).
* **Enlace con la limpieza previa:** Consolida en tablas consultables los datos ya saneados en Pandas (precios numéricos, descuentos normalizados en fracción `0–1`, fechas parseadas, categorías normalizadas y exclusiones/controles documentados).
* **Criterio clave:** Pasar de la exploración/limpieza en Pandas a consultas reproducibles en SQL sobre tablas limpias evita repetir transformaciones manuales y sienta la base para análisis compartidos y cuadros de mando.

---

## Fase 2: Primeros KPIs, línea base y definiciones (`02_kpis_generales_campana.sql`)
* **Consultas incluidas:**
  1. Comparativa de ingresos netos, unidades, pedidos únicos (`COUNT(DISTINCT lp.pedido_id)`) y ticket medio entre la **semana previa** (`2024-06-24` a `2024-06-30`) y la **semana de rebajas** (`2024-07-01` a `2024-07-07`).
  2. Contraste de ingresos a precio de catálogo (`ingreso_catalogo`) frente a ingresos tras descuento (`ingreso_pagado`) en `campana_id = 1`.
  3. Descuento promedio **ponderado** por volumen monetario frente a **simple** (`AVG` por línea).
  4. Alcance de compradores distintos (`COUNT(DISTINCT cliente_id)`) por periodo.
  5. Variación porcentual (`%`) de ingresos, unidades y ticket medio entre ambas semanas de igual duración (7 días).
  6. Ticket medio por `canal` y estadísticos del ticket por pedido (`AVG`, `MEDIAN` y `MAX` vía CTE `ticket_por_pedido`).
  7. Reparto de unidades y porcentaje por `metodo_pago` usando función de ventana (`SUM(SUM(lp.cantidad)) OVER ()`).
* **Hallazgos y criterios registrados:**
  * **Efecto rebajas y lectura conjunta:** Ingresos y unidades crecen con fuerza frente a la semana previa mientras el ticket medio baja (de `105,87 €` a `83,83 €` en el ejemplo del caso), lo que refleja mayor volumen/compradores a precios rebajados, no un deterioro.
  * **Media vs. mediana:** El ticket medio (`AVG`) puede verse empujado por pedidos altos (ej. `491,27 €`); revisar la mediana (`MEDIAN`, ej. `69,52 €`) muestra cómo es el pedido típico.
  * **Definición obligatoria:** Todo número debe llevar su apellido (**bruto vs. neto**, **nivel/granularidad** y **ventana temporal comparable**) para evitar discrepancias entre áreas como Marketing y Finanzas.

---

## Fase 3: Rankings, margen bruto, conversión y cola larga (`03_analisis_integral_campana.sql`)
* **Consultas incluidas:**
  1. Ingresos netos y unidades por `categoria` en la campaña 1 (`GROUP BY pr.categoria`).
  2. Top 10 productos por `unidades_vendidas` e `ingresos` (agrupando por `pr.producto_id` y `pr.nombre`).
  3. Cálculo de `cogs`, `margen_bruto` (`ingresos - cogs`) y `margen_bruto_pct` por producto en CTE `resumen_productos`.
  4. Comparativa paralela (`UNION ALL`) del Top 3 por unidades frente al Top 3 por ingresos.
  5. Peso porcentual del **Vestido Alma** sobre el total de unidades de la campaña y sobre la categoría `Vestidos`.
  6. Tasa de conversión por canal (`numero_pedidos * 100.0 / numero_sesiones`) en la ventana `2024-07-01` a `2024-07-21`, conservando canales sin compras con `LEFT JOIN` desde `visitas_web`, junto con el ranking puro de sesiones.
  7. Concentración del catálogo (`top10_pct` y `top50_pct` sobre el total de productos distintos mediante `ROW_NUMBER()`).
* **Hallazgos y criterios registrados:**
  * **Liderazgo en volumen y sesgo de confirmación:** El **Vestido Alma** lidera en unidades (`1.016` uds. frente a `602` del segundo, un `69%` más). Confirmar esta expectativa no cierra el análisis: se frena un *reorder* de `2.000` unidades hasta revisar devoluciones y rentabilidad real.
  * **Tráfico vs. conversión:** Más sesiones no garantizan más pedidos; los canales se evalúan cruzando numerador (pedidos) y denominador (sesiones).
  * **Cola larga y límites de datos:** Pocos productos concentran gran parte del volumen mientras una larga cola vende poco (en la campaña, el `20%` superior ronda el `50%` y se requieren `215` de `400` referencias para el `80%`). Además, si falta detalle histórico (como desglose por producto de rebajas del año anterior), se acota lo disponible y se proponen comparativas viables.
  * **Las 5 preguntas del detective:** Antes de publicar un ranking, verificar *por qué se ordena*, *sobre cuántos casos*, *qué periodo cubre*, *qué falta por ver* y *si cambia una decisión*, usando alias claros y consistentes (`unidades_vendidas`, `ingresos`, `margen_bruto`).

---

## Fase 4: Devoluciones, tallaje y margen neto (`05_analisis_devoluciones_campana.sql`)
* **Consultas incluidas:**
  1. Tasa de devolución global (`'GLOBAL'`) y por categoría en una sola pasada con `GROUPING SETS` (`LEFT JOIN` desde líneas de pedido con producto).
  2. Volumen, líneas vendidas, devoluciones y `tasa_pct` del producto líder en unidades.
  3. Impacto económico del **Vestido Alma** en campaña 1 (`ingreso_bruto`, `ingreso_neto` retenido y `margen_neto` descontando `coste` de unidades retenidas mediante `FILTER (WHERE NOT devuelta)`).
  4. Motivos de devolución normalizados (`LOWER(TRIM(d.motivo))`) en toda la tienda sobre `linea_id` existentes en `lineas_pedido`.
  5. Distribución de unidades vendidas del **Vestido Alma** por talla normalizada (`TRIM(REPLACE(UPPER(lp.talla), 'TALLA', ''))`).
  6. Control temporal de devoluciones del **Vestido Alma** (`MAX(fecha_devolucion)` y proporción `>= 2024-07-15`) ante una política de devolución de 30 días.
  7. Tasa de devolución por talla estándar (`XS` a `XL`) en toda la tienda, ordenada lógicamente.
  8. Impacto financiero global en campaña 1: `ingreso_bruto`, `ingreso_devuelto`, `ingreso_neto` y `pct_devuelto`.
* **Hallazgos y decisiones registrados:**
  * **Desagregación crítica:** Frente a una tasa global del `27,6%`, **Vestidos** alcanza el `35,5%` y el **Vestido Alma** llega al `42,7%` (sobre `858` ventas), concentrado en tallas **M** y **L** por motivo de **talla incorrecta** (prenda que tira pequeña).
  * **Margen neto negativo y efecto contraintuitivo:** Al `40%` de descuento (`29,99 €` de ingreso unitario vs. `30,10 €` de coste), cada unidad retenida pierde dinero (`-60 €` de margen neto). Reducir devoluciones a cero sin corregir precio/descuento elevaría la pérdida (`-108 €` en el ejemplo), sin contar costes logísticos/operativos de retorno no incluidos en la fórmula.
  * **Cautela temporal (no un segundo hallazgo):** Con ~3 semanas transcurridas y ventana de devolución de 30 días, la tasa del `42,7%` actúa como **suelo**, no como techo; se reporta como refuerzo/cautela del titular principal.
  * **Recomendación y comunicación:** Separar dos acciones —no reordenar sin corregir la guía de tallas y revisar el descuento del `40%` que vende bajo coste— y comunicar el hallazgo con rigor, foco en el dato y tacto con el equipo antes de la demo con dirección.
