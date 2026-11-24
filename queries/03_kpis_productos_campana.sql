/* ============================================================================
   Script: Análisis de Rendimiento y Rentabilidad de Productos por Campaña
   Base de datos: BrightCartDB
   Tablas: lineas_pedido (lp), pedidos (p), productos (pr)
   Descripción: Evalúa el volumen de ventas, ingresos netos y margen bruto
                de los productos participantes en la campaña 1.
   ============================================================================ */

USE BrightCartDB;

/* ----------------------------------------------------------------------------
1. Top 10 productos por volumen de ventas en la campaña 1
   ---------------------------------------------------------------------------- */
SELECT
    pr.producto_id,                                                                         -- Clave primaria para evitar colisiones si hay productos homónimos
    pr.nombre                                                                               AS nombre_producto,
    SUM(lp.cantidad)                                                                        AS unidades_vendidas,   -- Total de artículos vendidos en la campaña
    ROUND(SUM(lp.cantidad * lp.precio_unitario * (1 - COALESCE(lp.descuento_pct, 0))), 2)   AS ingresos             -- Ingreso neto tratando descuentos NULL como 0
FROM lineas_pedido AS lp
INNER JOIN pedidos AS p
    ON lp.pedido_id = p.pedido_id
INNER JOIN productos AS pr
    ON lp.producto_id = pr.producto_id
WHERE p.campana_id = 1
GROUP BY
    pr.producto_id,
    pr.nombre
ORDER BY
    unidades_vendidas DESC,
    ingresos DESC                                                                           -- Desempate determinista por mayor ingreso neto
LIMIT 10;


/* ----------------------------------------------------------------------------
2. Rentabilidad y margen bruto por producto en la campaña 1
   ---------------------------------------------------------------------------- */
WITH resumen_productos AS (
    -- Pre-agregación a nivel producto para aislar el cálculo de ingresos y costos directos
    SELECT
        pr.producto_id,
        pr.nombre                                                                   AS nombre_producto,
        SUM(lp.cantidad)                                                            AS unidades_vendidas,
        SUM(lp.cantidad * lp.precio_unitario * (1 - COALESCE(lp.descuento_pct, 0))) AS ingresos,         -- Ingreso neto con descuento aplicado
        SUM(lp.cantidad * COALESCE(pr.coste_unitario, 0))                           AS cogs              -- Costo de bienes vendidos (trata costos NULL como 0)
    FROM lineas_pedido AS lp
    INNER JOIN pedidos AS p
        ON lp.pedido_id = p.pedido_id
    INNER JOIN productos AS pr
        ON lp.producto_id = pr.producto_id
    WHERE p.campana_id = 1
    GROUP BY
        pr.producto_id,
        pr.nombre
)
SELECT
    producto_id,
    nombre_producto,
    unidades_vendidas,
    ROUND(ingresos, 2)                                          AS ingresos,
    ROUND(cogs, 2)                                              AS cogs,
    ROUND(ingresos - cogs, 2)                                   AS margen_bruto,      -- Utilidad bruta absoluta (Ingresos - COGS)
    ROUND(((ingresos - cogs) / NULLIF(ingresos, 0)) * 100, 2)   AS margen_bruto_pct   -- Rentabilidad porcentual protegida contra división por cero
FROM resumen_productos
ORDER BY
    margen_bruto DESC;                                                                -- Ordenado de mayor a menor rentabilidad (explícito)
