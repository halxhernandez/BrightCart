/* ============================================================================
   Script: Los Primeros KPIs — Ventas, Descuentos, Crecimiento y Ticket (Campaña 1)
   Base de datos: BrightCartDB
   Tablas: lineas_pedido (lp), pedidos (p)
   Descripción: Evalúa cuánto se vendió, cuántas unidades, cuántos pedidos y a
                qué ticket medio en la semana de rebajas frente a la semana
                previa; analiza el impacto real de los descuentos, el ticket
                por canal/distribución y la preferencia de métodos de pago.
   ============================================================================ */

USE BrightCartDB;

/* ----------------------------------------------------------------------------
1. La campaña frente a la semana anterior
   Compara los cuatro KPIs básicos (ingresos netos, unidades, pedidos y ticket
   medio) entre la semana previa (24–30 jun) y la semana de rebajas (1–7 jul).
   ---------------------------------------------------------------------------- */
SELECT
    CASE
        WHEN p.fecha_pedido BETWEEN DATE '2024-06-24' AND DATE '2024-06-30' THEN 'Semana previa'
        WHEN p.fecha_pedido BETWEEN DATE '2024-07-01' AND DATE '2024-07-07' THEN 'Semana rebajas'
    END                                                                                     AS periodo,
    ROUND(SUM(lp.cantidad * lp.precio_unitario * (1 - COALESCE(lp.descuento_pct, 0))), 2)   AS ingresos,      -- Ingreso neto tratando descuentos NULL como 0
    SUM(lp.cantidad)                                                                        AS unidades,      -- Total de artículos despachados en el periodo
    COUNT(DISTINCT lp.pedido_id)                                                            AS pedidos,       -- Conteo de pedidos únicos (evita duplicados por línea)
    ROUND(
        SUM(lp.cantidad * lp.precio_unitario * (1 - COALESCE(lp.descuento_pct, 0)))
        / NULLIF(COUNT(DISTINCT lp.pedido_id), 0), 2
    )                                                                                       AS ticket_medio   -- Facturación neta dividida entre pedidos únicos
FROM lineas_pedido AS lp
INNER JOIN pedidos AS p
    ON lp.pedido_id = p.pedido_id
WHERE p.fecha_pedido BETWEEN DATE '2024-06-24' AND DATE '2024-07-07'
GROUP BY periodo
ORDER BY periodo;


/* ----------------------------------------------------------------------------
2. Los dos ingresos que no cuadran (Catálogo vs. Pagado)
   Contrasta la facturación bruta a precio de catálogo frente al ingreso real
   cobrado tras aplicar los descuentos promocionales en toda la campaña 1.
   ---------------------------------------------------------------------------- */
SELECT
    ROUND(SUM(lp.cantidad * lp.precio_unitario), 2)                                         AS ingreso_catalogo, -- Valor teórico sin ningún descuento aplicado
    ROUND(SUM(lp.cantidad * lp.precio_unitario * (1 - COALESCE(lp.descuento_pct, 0))), 2)   AS ingreso_pagado    -- Dinero real facturado tras descuentos
FROM lineas_pedido AS lp
INNER JOIN pedidos AS p
    ON lp.pedido_id = p.pedido_id
WHERE p.campana_id = 1;


/* ----------------------------------------------------------------------------
3. ¿Cuánto descuento regalamos de media? (Ponderado vs. Simple)
   Evalúa el esfuerzo promocional real: el descuento ponderado pesa cada rebaja
   por el dinero que representa sobre el catálogo, mientras que el simple trata
   cada línea de pedido por igual sin importar precio ni cantidad.
   ---------------------------------------------------------------------------- */
SELECT
    -- Ponderado = dinero descontado / valor total a precio de catálogo (pesa por volumen monetario)
    ROUND(
        SUM(lp.cantidad * lp.precio_unitario * COALESCE(lp.descuento_pct, 0))
        / NULLIF(SUM(lp.cantidad * lp.precio_unitario), 0) * 100.0, 1
    )                                                                   AS descuento_ponderado,
    -- Simple = promedio aritmético de descuento_pct (cada línea pesa lo mismo)
    ROUND(AVG(COALESCE(lp.descuento_pct, 0)) * 100.0, 1)                AS descuento_simple
FROM lineas_pedido AS lp
INNER JOIN pedidos AS p
    ON lp.pedido_id = p.pedido_id
WHERE p.campana_id = 1;


/* ----------------------------------------------------------------------------
4. ¿Cuánta gente distinta trajo la campaña?
   Mide el alcance de compradores únicos (clientela activa) comparando la
   semana previa frente a la semana de rebajas sin cruzar con líneas de pedido.
   ---------------------------------------------------------------------------- */
SELECT
    CASE
        WHEN fecha_pedido BETWEEN DATE '2024-06-24' AND DATE '2024-06-30' THEN 'Semana previa'
        WHEN fecha_pedido BETWEEN DATE '2024-07-01' AND DATE '2024-07-07' THEN 'Semana rebajas'
    END                         AS periodo,
    COUNT(DISTINCT cliente_id)  AS clientes     -- Clientes únicos con al menos una compra en el rango
FROM pedidos
WHERE fecha_pedido BETWEEN DATE '2024-06-24' AND DATE '2024-07-07'
GROUP BY periodo
ORDER BY periodo;


/* ----------------------------------------------------------------------------
5. Expresa la subida como porcentaje (Variación semanal)
   Cuantifica el crecimiento porcentual de ingresos, unidades y ticket medio
   entre la semana previa y la semana de rebajas.
   ---------------------------------------------------------------------------- */
WITH previa AS (
    -- Métricas base de la semana previa (24–30 jun)
    SELECT
        SUM(lp.cantidad * lp.precio_unitario * (1 - COALESCE(lp.descuento_pct, 0))) AS ingresos,
        CAST(SUM(lp.cantidad) AS DOUBLE)                                            AS unidades, -- Cast explícito a punto flotante para evitar división entera
        SUM(lp.cantidad * lp.precio_unitario * (1 - COALESCE(lp.descuento_pct, 0)))
            / NULLIF(COUNT(DISTINCT lp.pedido_id), 0)                               AS ticket
    FROM lineas_pedido AS lp
    INNER JOIN pedidos AS p
        ON lp.pedido_id = p.pedido_id
    WHERE p.fecha_pedido BETWEEN DATE '2024-06-24' AND DATE '2024-06-30'
),
rebajas AS (
    -- Métricas de la semana de rebajas (1–7 jul)
    SELECT
        SUM(lp.cantidad * lp.precio_unitario * (1 - COALESCE(lp.descuento_pct, 0))) AS ingresos,
        CAST(SUM(lp.cantidad) AS DOUBLE)                                            AS unidades,
        SUM(lp.cantidad * lp.precio_unitario * (1 - COALESCE(lp.descuento_pct, 0)))
            / NULLIF(COUNT(DISTINCT lp.pedido_id), 0)                               AS ticket
    FROM lineas_pedido AS lp
    INNER JOIN pedidos AS p
        ON lp.pedido_id = p.pedido_id
    WHERE p.fecha_pedido BETWEEN DATE '2024-07-01' AND DATE '2024-07-07'
)
SELECT
    -- Crecimiento % = ((nuevo - anterior) / anterior) * 100
    ROUND((r.ingresos - p.ingresos) / NULLIF(p.ingresos, 0) * 100.0, 1) AS crecimiento_ingresos,
    ROUND((r.unidades - p.unidades) / NULLIF(p.unidades, 0) * 100.0, 1) AS crecimiento_unidades,
    ROUND((r.ticket - p.ticket) / NULLIF(p.ticket, 0) * 100.0, 1)       AS crecimiento_ticket
FROM previa AS p
CROSS JOIN rebajas AS r;                                                -- Producto cartesiano controlado de 1x1 fila


/* ----------------------------------------------------------------------------
6. ¿Por qué canal se gasta más por pedido?
   Calcula el ticket medio neto (ingresos entre pedidos únicos) desglosado
   por canal de venta durante toda la campaña 1.
   ---------------------------------------------------------------------------- */
SELECT
    p.canal,
    -- Ticket = ingresos netos del canal / pedidos distintos del canal
    ROUND(
        SUM(lp.cantidad * lp.precio_unitario * (1 - COALESCE(lp.descuento_pct, 0)))
        / NULLIF(COUNT(DISTINCT lp.pedido_id), 0), 2
    ) AS ticket_medio
FROM lineas_pedido AS lp
INNER JOIN pedidos AS p
    ON lp.pedido_id = p.pedido_id
WHERE p.campana_id = 1
GROUP BY p.canal
ORDER BY ticket_medio DESC;


/* ----------------------------------------------------------------------------
7. La media y la mediana del ticket (Distribución de gasto por pedido)
   Contrasta el ticket medio (promedio aritmético) frente al ticket típico
   (mediana, robusta ante compras atípicas) y muestra el pedido máximo.
   ---------------------------------------------------------------------------- */
WITH ticket_por_pedido AS (
    -- Pre-agregación a nivel pedido para calcular estadísticos sin sesgo por número de líneas
    SELECT
        lp.pedido_id,
        SUM(lp.cantidad * lp.precio_unitario * (1 - COALESCE(lp.descuento_pct, 0))) AS ticket
    FROM lineas_pedido AS lp
    INNER JOIN pedidos AS p
        ON lp.pedido_id = p.pedido_id
    WHERE p.campana_id = 1
    GROUP BY lp.pedido_id
)
SELECT
    ROUND(AVG(ticket), 2)       AS ticket_medio,    -- Promedio aritmético (sensible a pedidos grandes)
    ROUND(MEDIAN(ticket), 2)    AS ticket_tipico,   -- Mediana: valor central de la distribución (requiere motor con MEDIAN)
    ROUND(MAX(ticket), 2)       AS pedido_mas_alto  -- Valor máximo registrado en un solo pedido
FROM ticket_por_pedido;


/* ----------------------------------------------------------------------------
8. Cómo paga la gente en rebajas (Distribución por método de pago)
   Analiza cómo se reparten las unidades vendidas entre los medios de pago
   (tarjeta, PayPal, Bizum) y su cuota porcentual mediante función de ventana.
   ---------------------------------------------------------------------------- */
SELECT
    p.metodo_pago,
    SUM(lp.cantidad)                                                        AS unidades,
    ROUND(SUM(lp.cantidad) * 100.0 / NULLIF(SUM(SUM(lp.cantidad)) OVER (), 0), 1) AS porcentaje -- Cuota sobre el total de unidades usando función ventana
FROM lineas_pedido AS lp
INNER JOIN pedidos AS p
    ON lp.pedido_id = p.pedido_id
WHERE p.campana_id = 1
GROUP BY p.metodo_pago
ORDER BY unidades DESC;
