/* ============================================================================
   Script: Análisis de KPIs de Ventas y Desempeño de Campaña
   Base de datos: BrightCartDB
   Tablas: pedidos (p), lineas_pedido (lp)
   Descripción: Extrae métricas generales en una ventana de fechas y analiza
                ingresos y distribución de ticket para la campaña 1.
   ============================================================================ */

USE BrightCartDB;

/* ----------------------------------------------------------------------------
   1. KPIs generales por rango de fechas (2024-07-01 al 2024-07-07)
   ---------------------------------------------------------------------------- */
SELECT
    COUNT(DISTINCT lp.pedido_id)                    AS pedidos,            -- Total de pedidos únicos
    COUNT(DISTINCT p.cliente_id)                    AS clientes_distintos, -- Clientes únicos con compra
    SUM(lp.cantidad)                                AS unidades,           -- Total de artículos vendidos
    ROUND(SUM(lp.cantidad * lp.precio_unitario
            * (1 - lp.descuento_pct)), 2)           AS ingresos
FROM lineas_pedido AS lp
JOIN pedidos AS p ON lp.pedido_id = p.pedido_id
WHERE p.fecha_pedido BETWEEN DATE '2024-07-01' AND DATE '2024-07-07';


/* ----------------------------------------------------------------------------
   2. Resumen agregado de ventas y ticket para la campaña 1
   ---------------------------------------------------------------------------- */
WITH resumen_pedidos AS (
    -- Pre-agregación a nivel pedido para evitar duplicidad de filas al cruzar
    SELECT
        pedido_id,
        SUM(cantidad)                                                       AS unidades_pedido,
        SUM(cantidad * precio_unitario)                                     AS ingreso_sin_descuento,
        SUM(cantidad * precio_unitario * (1 - COALESCE(descuento_pct, 0)))  AS ingreso_con_descuento -- Trata descuentos NULL como 0
    FROM lineas_pedido
    GROUP BY pedido_id
)
SELECT
    COUNT(p.pedido_id)                          AS numero_pedidos,
    SUM(rp.unidades_pedido)                     AS unidades_vendidas,
    ROUND(SUM(rp.ingreso_sin_descuento), 2)     AS ingresos_totales_sin_descuento,
    ROUND(SUM(rp.ingreso_con_descuento), 2)     AS ingresos_totales_con_descuento,
    ROUND(AVG(rp.ingreso_con_descuento), 2)     AS ticket_promedio,
    ROUND(MEDIAN(rp.ingreso_con_descuento), 2)  AS ticket_mediano      -- Requiere motor SQL con soporte nativo para MEDIAN
FROM pedidos AS p
INNER JOIN resumen_pedidos AS rp
    ON p.pedido_id = rp.pedido_id
WHERE p.campana_id = 1;


/* ----------------------------------------------------------------------------
   3. Distribución del ticket por pedido en la campaña 1
   ---------------------------------------------------------------------------- */
WITH ticket_por_pedido AS (
    -- Calcula el monto neto por pedido filtrado directamente por campaña
    SELECT
        lp.pedido_id,
        SUM(lp.cantidad * lp.precio_unitario * (1 - lp.descuento_pct)) AS ticket
    FROM lineas_pedido AS lp
    JOIN pedidos AS p ON lp.pedido_id = p.pedido_id
    WHERE p.campana_id = 1
    GROUP BY lp.pedido_id
)
SELECT ROUND(AVG(ticket), 2)    AS ticket_medio,    -- Promedio aritmético del ticket
       ROUND(MEDIAN(ticket), 2) AS ticket_tipico,   -- Mediana (valor central menos sensible a valores atípicos)
       ROUND(MAX(ticket), 2)    AS pedido_mas_alto  -- Valor máximo registrado en la campaña
FROM ticket_por_pedido;

