# Queries SQL - BrightCart

Consultas SQL para el análisis de negocio sobre la base de datos `BrightCart.duck` (DuckDB). Las tablas de la base son las versiones limpias: `pedidos_clean`, `lineas_pedido_clean`, `productos_clean`,`clientes_clean`, `devoluciones_clean`, `campanas_clean`, `visitas_web_clean`.

## Definiciones de KPI

| KPI | Fórmulas |
| --- | --- |
| Ventas netas | `Σ (cantidad × precio_unitario × (1 − descuento_pct))` |
| Unidades vendidas | `Σ cantidad` |
| Pedidos | `COUNT(DISTINCT pedido_id)` |
| Ticket medio | Ventas netas / Pedidos |

## Criterios

- Ventas brutas: las devoluciones se analizan por separado.
- Solo se cuentan pedidos con al menos una línea válida.

## Consultas disponibles

| Archivo | Qué responde |
|---|---|
| `01_ingesta_brightcart.sql` | Script que crea la base de datos y carga los datos |
| `02_kpi_ventas_campana.sql` | KPIs de ventas sobre la campaña con campana_id = 1 |
