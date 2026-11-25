/* ============================================================================
   Script: Análisis Integral de Campaña 1 — Categorías, Productos, Margen y Canales
   Base de datos: BrightCartDB
   Tablas: lineas_pedido (lp), pedidos (p), productos (pr), visitas_web (vw)
   Descripción: Evalúa qué categorías y productos impulsaron la campaña en
                volumen, ingresos y margen bruto; analiza tráfico y conversión
                por canal; y mide la concentración del catálogo frente al
                producto estrella.
   ============================================================================ */

USE BrightCartDB;

/* ----------------------------------------------------------------------------
1. ¿Qué categorías tiran de la campaña?
   Identifica qué líneas de producto lideran la facturación neta y el volumen
   físico de artículos despachados en la campaña 1.
   ---------------------------------------------------------------------------- */
SELECT
    pr.categoria,
    ROUND(SUM(lp.cantidad * lp.precio_unitario * (1 - COALESCE(lp.descuento_pct, 0))), 2)   AS ingresos, -- Ingreso neto tratando descuentos NULL como 0
    SUM(lp.cantidad)                                                                        AS unidades  -- Total de unidades vendidas en la categoría
FROM lineas_pedido AS lp
INNER JOIN pedidos AS p
    ON lp.pedido_id = p.pedido_id
INNER JOIN productos AS pr
    ON lp.producto_id = pr.producto_id
WHERE p.campana_id = 1
GROUP BY pr.categoria
ORDER BY ingresos DESC, unidades DESC;


/* ----------------------------------------------------------------------------
2. Ranking de los 10 productos más vendidos por unidades durante la campaña
   Muestra los artículos con mayor rotación física y su aporte correspondiente
   en facturación neta para identificar los líderes de demanda.
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
3. Rentabilidad y margen bruto por producto en la campaña 1
   Vender más unidades no garantiza mayor ganancia: este bloque evalúa qué
   productos realmente dejan mayor utilidad después de descontar su costo
   directo (COGS) y los descuentos aplicados en la campaña.
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


/* ----------------------------------------------------------------------------
4. Comparativa Top 3 productos: volumen (unidades) vs. facturación (ingresos)
   Contrasta si los artículos más baratos y de alta rotación coinciden con los
   que mayor dinero ingresan a caja durante la campaña 1.
   ---------------------------------------------------------------------------- */
WITH resumen_productos AS (
    -- Base agregada por producto para comparar ambos criterios en paralelo
    SELECT
        pr.producto_id,
        pr.nombre,
        SUM(lp.cantidad)                                                            AS unidades,
        SUM(lp.cantidad * lp.precio_unitario * (1 - COALESCE(lp.descuento_pct, 0))) AS ingreso
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
(
    SELECT
        'unidades' AS ranking,
        nombre,
        unidades   AS valor
    FROM resumen_productos
    ORDER BY unidades DESC
    LIMIT 3
)
UNION ALL -- Mantiene ambos rankings separados incluso si hay productos repetidos
(
    SELECT
        'ingresos'        AS ranking,
        nombre,
        ROUND(ingreso, 2) AS valor
    FROM resumen_productos
    ORDER BY ingreso DESC
    LIMIT 3
);


/* ----------------------------------------------------------------------------
5. ¿Cuánto pesa el Vestido Alma de verdad?
   Evalúa la dependencia real respecto al producto estrella midiendo qué
   porcentaje representa sobre el total de unidades de la campaña y dentro
   de su propia categoría ('Vestidos').
   ---------------------------------------------------------------------------- */
SELECT
    SUM(lp.cantidad)                                                        AS unidades_campana,
    SUM(CASE WHEN pr.nombre = 'Vestido Alma' THEN lp.cantidad ELSE 0 END)   AS unidades_alma,
    -- Alma sobre el TOTAL de la campaña, en %:
    ROUND(
        SUM(CASE WHEN pr.nombre = 'Vestido Alma' THEN lp.cantidad ELSE 0 END) * 100.0
        / NULLIF(SUM(lp.cantidad), 0), 1
    )                                                                       AS alma_sobre_total,
    -- Alma sobre la categoría Vestidos, en %:
    ROUND(
        SUM(CASE WHEN pr.nombre = 'Vestido Alma' THEN lp.cantidad ELSE 0 END) * 100.0
        / NULLIF(SUM(CASE WHEN pr.categoria = 'Vestidos' THEN lp.cantidad ELSE 0 END), 0), 1
    )                                                                       AS alma_sobre_vestidos
FROM lineas_pedido AS lp
INNER JOIN pedidos AS p
    ON lp.pedido_id = p.pedido_id
INNER JOIN productos AS pr
    ON lp.producto_id = pr.producto_id
WHERE p.campana_id = 1;


/* ----------------------------------------------------------------------------
6. ¿Qué canal convierte mejor? (Ventana de campaña: 1–21 jul)
   Mide la eficiencia real de cada canal de adquisición calculando qué
   porcentaje de las sesiones recibidas se transformaron en pedidos únicos.
   ---------------------------------------------------------------------------- */
WITH ses AS (
    -- Pre-agregación de sesiones web por canal durante la ventana activa de la campaña
    SELECT
        canal,
        SUM(sesiones) AS numero_sesiones
    FROM visitas_web
    WHERE fecha BETWEEN DATE '2024-07-01' AND DATE '2024-07-21'
    GROUP BY canal
),
ped AS (
    -- Pre-agregación de pedidos únicos atribuibles a la campaña 1 por canal
    SELECT
        canal,
        COUNT(DISTINCT pedido_id) AS numero_pedidos
    FROM pedidos
    WHERE campana_id = 1
    GROUP BY canal
)
SELECT
    ses.canal,
    COALESCE(ped.numero_pedidos, 0)                                                      AS numero_pedidos,
    ses.numero_sesiones,
    ROUND((COALESCE(ped.numero_pedidos, 0) * 100.0) / NULLIF(ses.numero_sesiones, 0), 2) AS conversion_pct     -- Porcentaje protegido contra división por cero; 100.0 evita truncamiento entero
FROM ses
LEFT JOIN ped
    ON ses.canal = ped.canal                                                            -- LEFT JOIN desde sesiones para conservar canales con tráfico pero 0 compras
ORDER BY
    conversion_pct DESC;


/* ----------------------------------------------------------------------------
7. Tráfico no es lo mismo que conversión
   Identifica qué canal trae mayor volumen bruto de sesiones durante la ventana
   de campaña (1–21 jul) para contrastar alcance frente a eficiencia de compra.
   ---------------------------------------------------------------------------- */
SELECT
    canal,
    SUM(sesiones) AS sesiones -- Volumen total de sesiones sin cruzar con conversiones
FROM visitas_web
WHERE fecha BETWEEN DATE '2024-07-01' AND DATE '2024-07-21'
GROUP BY canal
ORDER BY sesiones DESC;


/* ----------------------------------------------------------------------------
8. Cuánto pesa el top frente al resto (Concentración de catálogo / Pareto)
   Un ranking top da la impresión de que unos pocos productos son "la campaña".
   Este bloque comprueba cuántos productos distintos se vendieron y qué cuota
   de unidades concentran los 10 y los 50 líderes, clave para evitar
   sobresaturar la comunicación comercial con un solo producto estrella.
   ---------------------------------------------------------------------------- */
WITH por_producto AS (
    -- Unidades vendidas por producto en la campaña 1
    SELECT
        lp.producto_id,
        SUM(lp.cantidad) AS unidades
    FROM lineas_pedido AS lp
    INNER JOIN pedidos AS p
        ON lp.pedido_id = p.pedido_id
    WHERE p.campana_id = 1
    GROUP BY lp.producto_id
),
rankeado AS (
    -- Posición ordinal según volumen descendente
    SELECT
        producto_id,
        unidades,
        ROW_NUMBER() OVER (ORDER BY unidades DESC) AS rn
    FROM por_producto
)
SELECT
    COUNT(*)                                                                            AS productos_distintos,
    ROUND(
        SUM(CASE WHEN rn <= 10 THEN unidades ELSE 0 END) * 100.0 / NULLIF(SUM(unidades), 0),
        1
    )                                                                                   AS top10_pct,
    ROUND(
        SUM(CASE WHEN rn <= 50 THEN unidades ELSE 0 END) * 100.0 / NULLIF(SUM(unidades), 0),
        1
    )                                                                                   AS top50_pct
FROM rankeado;
