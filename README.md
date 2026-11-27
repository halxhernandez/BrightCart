# BrightCart: Análisis de datos

Proyecto de análisis de datos para **BrightCart**, un e-commerce. Su objetivo es evaluar la calidad de sus datos, limpiarlos con trazabilidad y generar análisis y recomendaciones accionables sobre su negocio.

## Objetivo

Este proyecto ayuda a **BrightCart** a confiar en sus datos antes de tomar decisiones. Partiendo de los archivos CSV de origen, el trabajo se organiza en cuatro etapas:

1. **Conocer la calidad de los datos:** detectar duplicados, colisiones de clave, formatos inconsistentes, valores imposibles y problemas de integridad referencial, y documentarlos.
2. **Limpiar los datos:** corregir lo detectado con reglas claras y reproducibles en Python, dejando registro de cada transformación y exclusión.
3. **Analizar el negocio en SQL:** calcular KPIs, comparativas, rankings, conversión, devoluciones y márgenes sobre las tablas limpias en DuckDB.
4. **Comunicar hallazgos y decisiones:** trasladar los resultados a un formato ejecutivo claro que respalde decisiones de negocio.

## Datos de origen

BrightCart entrega su información en archivos CSV (**7 tablas**, **39.224 filas** y **42 columnas** en el perfilado inicial):

| Tabla | Qué contiene | Cada fila representa |
|---|---|---|
| clientes | Personas registradas en la tienda (fecha de alta, ciudad, género y edad) | Un cliente |
| productos | Catálogo de productos (categoría, temporada, colección, coste y precio) | Un producto |
| campañas | Campañas de marketing (tipo, canal, fechas, presupuesto y ventas del año anterior) | Una campaña |
| pedidos | Compras realizadas (cliente, fecha, canal, ciudad, método de pago y campaña asociada) | Un pedido |
| lineas_pedido | Detalle de lo comprado en cada pedido (producto, talla, cantidad, precio y descuento) | Un producto dentro de un pedido |
| devoluciones | Productos devueltos por los clientes (fecha, talla y motivo) | Una devolución |
| visitas_web | Visitas a la web, agrupadas por día y canal de tráfico | Un día y un canal |

**Cómo se relacionan y granularidad:** `lineas_pedido` actúa como tabla de hechos central (cada fila es un artículo dentro de un pedido), conectada por claves compartidas con `pedidos` (`pedido_id`), `productos` (`producto_id`) y `devoluciones` (`linea_id`). `pedidos` vincula al cliente (`cliente_id`) y, cuando aplica, a una campaña (`campana_id`), mientras que `visitas_web` registra sesiones por fecha y canal. Distinguir el nivel de detalle (**línea**, **pedido**, **cliente** o **producto/categoría**) antes de contar o promediar es clave para no inflar métricas ni mezclar escalas.

- Documentación de limpieza y pipeline: [docs/limpieza_datos.md](docs/limpieza_datos.md)
- Bitácora SQL y hallazgos por día: [docs/bitacora_sql_hallazgos.md](docs/bitacora_sql_hallazgos.md)
- Informe de calidad de datos: [informes/calidad_datos.md](docs/informe_calidad_datos.md)
- Documentación de consultas SQL: [queries/README.md](queries/README.md)

> Los CSV originales no se incluyen en el repositorio por ser datos del cliente.

## Estructura del repositorio

```text
brightcart/
├── datos/
│   ├── raw/              # CSV originales (no se suben a Git)
│   └── processed/        # CSV limpios (*_clean.csv), DuckDB y artefactos de validación/log
├── docs/                 # Documentación técnica, limpieza y bitácora SQL
├── informes/             # Informes de calidad y entregables ejecutivos (one-pager)
├── notebooks/            # Exploración y validación de datos
├── queries/              # Consultas SQL en DuckDB y su README
├── src/
│   └── brightcart/
│       ├── __init__.py
│       ├── cleaning.py   # Funciones auxiliares de limpieza y registro de cambios
│       └── pipeline.py   # Pipeline principal de limpieza
└── README.md
```

## Estado del proyecto

| Tabla | Perfilado / Calidad | Limpieza (`cleaning` + `pipeline`) | Ingesta y análisis SQL | Hallazgos / Cierre |
|---|---|---|---|---|
| campañas | ✅ | ✅ | ✅ | ✅ |
| clientes | ✅ | ✅ | ✅ | ✅ |
| devoluciones | ✅ | ✅ | ✅ | ✅ |
| lineas_pedido | ✅ | ✅ | ✅ | ✅ |
| pedidos | ✅ | ✅ | ✅ | ✅ |
| productos | ✅ | ✅ | ✅ | ✅ |
| visitas_web | ✅ | ✅ | ✅ | ✅ |

**Leyenda:** ✅ completado · 🟡 en curso · ⬜ pendiente

**Última actualización:** limpieza ejecutada (`datos/processed/*_clean.csv`), base DuckDB cargada (`01_ingesta_brightcart.sql`) y análisis de KPIs, campaña y devoluciones completados (`02_kpis_generales_campana.sql`, `03_analisis_integral_campana.sql`, `05_analisis_devoluciones_campana.sql`).

## Hallazgo principal de negocio

* **Volumen vs. rentabilidad en el producto estrella:** El **Vestido Alma** lidera en unidades vendidas (`1.016` uds., un `69 %` por encima del segundo), pero presenta una tasa de devolución del **42,7 %** (frente al `27,6 %` global y `35,5 %` en *Vestidos*), concentrada en tallas **M** y **L** por problemas de **talla incorrecta**.
* **Margen neto y cautela temporal:** Con un `40 %` de descuento, el precio unitario queda por debajo del coste (`29,99 €` vs. `30,10 €`), generando margen neto negativo (`-60 €` en las unidades retenidas, sin contar aún costes logísticos/operativos de devolución ni el posible incremento de retornos mientras siga abierta la ventana de 30 días).
* **Decisión recomendada:** Frenar el *reorder* de `2.000` unidades para agosto hasta corregir la guía de tallas y revisar la política de descuento del `40 %` antes de reponer o promocionar el producto.

## Entregables

| Entregable | Ubicación | Estado |
|---|---|---|
| Informe de calidad de datos | `informes/calidad_datos.md` | ✅ |
| Documentación de limpieza | `docs/limpieza_datos.md` | ✅ |
| Código de limpieza | `src/brightcart/cleaning.py` + `src/brightcart/pipeline.py` | ✅ |
| Datos limpios | `datos/processed/*_clean.csv` | ✅ |
| Catálogos compartidos | `datos/processed/catalogs.json` | ✅ |
| Log de limpieza | `datos/processed/limpieza_log.csv` | ✅ |
| Validación post-limpieza | `datos/processed/validacion_post_limpieza.csv` | ✅ |
| Ingesta y consultas SQL | `queries/01_ingesta_brightcart.sql` … `05_analisis_devoluciones_campana.sql` | ✅ |
| Bitácora SQL y hallazgos | `docs/bitacora_sql_hallazgos.md` | ✅ |
| Resumen ejecutivo (*one-pager*) | `informes/one_pager_campana_brightcart.md` | ✅ |

## Ejecución

### 1. Pipeline de limpieza en Python
Desde la terminal, situado en la raíz del proyecto:

```bash
uv run pipeline.py
```

### 2. Ingesta y consultas SQL en DuckDB
Ejecuta los scripts en orden sobre `BrightCartDB.duckdb` (`01_ingesta_brightcart.sql`, `02_kpis_generales_campana.sql`, `03_analisis_integral_campana.sql` y `05_analisis_devoluciones_campana.sql`).
