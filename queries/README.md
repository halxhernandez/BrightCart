# Queries SQL - BrightCart

Consultas SQL en DuckDB sobre la base de datos `datos/processed/BrightCartDB.duckdb`, cargada desde los CSV ya saneados (`campanas`, `clientes`, `devoluciones`, `lineas_pedido`, `pedidos`, `productos` y `visitas_web`).

## Definiciones de KPI y métricas clave

| Métrica | Definición / Fórmula | Nota |
| :--- | :--- | :--- |
| **Ingreso bruto (catálogo)** | `Σ (cantidad × precio_unitario)` | Valor sin aplicar descuentos (`descuento_pct` normalizado en escala `0–1`). |
| **Ingreso neto (tras descuento)** | `Σ (cantidad × precio_unitario × (1 − descuento_pct))` | Dinero facturado tras descuento; revisar devoluciones por separado según el análisis. |
| **Unidades vendidas** | `Σ cantidad` | Volumen físico de artículos. |
| **Pedidos** | `COUNT(DISTINCT pedido_id)` | Conteo de pedidos únicos, no de filas de línea. |
| **Ticket medio** | `Ingreso neto / Pedidos` | Sensible a pedidos de importe alto; contrastar con la mediana (`MEDIAN`) por pedido. |

## Criterios generales

* Los cálculos se realizan sobre las tablas cargadas tras el pipeline de limpieza (`*_clean.csv`).
* Se distingue siempre entre granularidad de **línea** (`linea_id`), **pedido** (`pedido_id`) y **producto/categoría/canal**.
* Las devoluciones se analizan cruzando con `lineas_pedido` y revisando integridad de `linea_id` y ventana temporal.

## Consultas disponibles

| Archivo | Qué responde |
| :--- | :--- |
| `01_ingesta_brightcart.sql` | Crea/adjunta `BrightCartDB.duckdb` y carga las 7 tablas desde `datos/processed/*_clean.csv`. |
| `02_kpis_generales_campana.sql` | Comparativa semanal (24–30 jun vs. 1–7 jul), ingresos catálogo vs. pagado, descuentos ponderado/simple, clientes únicos, ticket medio/mediana/máximo, ticket por canal y métodos de pago. |
| `03_analisis_integral_campana.sql` | Ingresos y unidades por categoría, top productos en unidades/ingresos, margen bruto (`COGS`), peso del *Vestido Alma*, conversión y sesiones por canal (1–21 jul) y concentración del catálogo. |
| `05_analisis_devoluciones_campana.sql` | Tasa de devolución global (`GROUPING SETS`), por categoría y por producto líder; margen neto del *Vestido Alma*, motivos, tallas, ventana de retorno e impacto financiero en la campaña 1. |
