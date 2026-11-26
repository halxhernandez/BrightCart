/* ============================================================================
   Script: Lo que vuelve — Análisis de Devoluciones, Motivos, Tallaje e Impacto Neto
   Base de datos: BrightCartDB
   Tablas: lineas_pedido (lp), pedidos (p), productos (pr), devoluciones (d)
   Descripción: Evalúa la tasa de devolución global y por categoría, diagnostica
                el caso del producto estrella ('Vestido Alma') frente al resto
                del catálogo (motivos, tallas y ventana de retorno) y cuantifica
                el impacto financiero real sobre los ingresos de la campaña 1.
   ============================================================================ */

USE BrightCartDB;

/* ----------------------------------------------------------------------------
1. La tasa de devolución global y por categoría
   Cruza las líneas de pedido con devoluciones para calcular la tasa de retorno
   global y desglosada por categoría. Se parte de las líneas vendidas mediante
   LEFT JOIN para evitar que devoluciones huérfanas distorsionen el denominador.
   ---------------------------------------------------------------------------- */
WITH lineas_cat AS (
    -- Asocia cada línea de pedido con la categoría correspondiente del producto
    SELECT
        lp.linea_id,
        pr.categoria
    FROM lineas_pedido AS lp
    INNER JOIN productos AS pr
        ON lp.producto_id = pr.producto_id
)
SELECT
    COALESCE(lc.categoria, 'GLOBAL')                        AS categoria,       -- Sustituye el NULL del subtotal general por etiqueta legible
    COUNT(*)                                                AS lineas_vendidas,
    COUNT(d.linea_id)                                       AS devoluciones,
    ROUND(COUNT(d.linea_id) * 100.0 / NULLIF(COUNT(*), 0), 1) AS tasa_pct       -- Porcentaje protegido contra división por cero
FROM lineas_cat AS lc
LEFT JOIN devoluciones AS d
    ON lc.linea_id = d.linea_id
GROUP BY GROUPING SETS ((lc.categoria), ())                                     -- Calcula el desglose por categoría y el total global en una sola pasada
ORDER BY
    (lc.categoria IS NULL) DESC,                                                -- Fija la fila 'GLOBAL' al inicio del reporte
    tasa_pct DESC;


/* ----------------------------------------------------------------------------
2. El número uno en ventas, ¿y en devoluciones?
   Calcula unidades, líneas vendidas, devoluciones y tasa de retorno por
   producto, filtrando el artículo líder en volumen para comprobar si su éxito
   comercial viene acompañado de una alta tasa de devolución.
   ---------------------------------------------------------------------------- */
WITH por_producto AS (
    -- Pre-agregación de métricas de venta y retorno a nivel producto
    SELECT
        pr.producto_id,                                                         -- Clave primaria para evitar colisiones entre productos homónimos
        pr.nombre,
        SUM(lp.cantidad)    AS unidades,
        COUNT(*)            AS lineas_vendidas,
        COUNT(d.linea_id)   AS devoluciones
    FROM lineas_pedido AS lp
    INNER JOIN productos AS pr
        ON lp.producto_id = pr.producto_id
    LEFT JOIN devoluciones AS d
        ON lp.linea_id = d.linea_id
    GROUP BY
        pr.producto_id,
        pr.nombre
)
SELECT
    nombre,
    unidades,
    lineas_vendidas,
    devoluciones,
    ROUND(devoluciones * 100.0 / NULLIF(lineas_vendidas, 0), 1) AS tasa_pct     -- Porcentaje de líneas devueltas respecto a líneas vendidas
FROM por_producto
ORDER BY unidades DESC
LIMIT 1;


/* ----------------------------------------------------------------------------
3. Por qué vuelve, y cuánto cuesta (Margen neto del Vestido Alma)
   Calcula el impacto económico real del 'Vestido Alma' en la campaña 1:
   al ingreso bruto se le descuentan los reembolsos (líneas devueltas) y el
   costo directo (COGS) únicamente de las unidades que el cliente conservó.
   ---------------------------------------------------------------------------- */
WITH alma AS (
    -- Clasifica cada línea vendida del producto estrella como retenida o devuelta
    SELECT
        lp.cantidad * lp.precio_unitario * (1 - COALESCE(lp.descuento_pct, 0))  AS ingreso,
        lp.cantidad * COALESCE(pr.coste_unitario, 0)                            AS coste,
        (lp.linea_id IN (SELECT linea_id FROM devoluciones))                    AS devuelta -- Bandera booleana de existencia en devoluciones
    FROM lineas_pedido AS lp
    INNER JOIN pedidos AS p
        ON lp.pedido_id = p.pedido_id
    INNER JOIN productos AS pr
        ON lp.producto_id = pr.producto_id
    WHERE pr.nombre = 'Vestido Alma'
      AND p.campana_id = 1
)
SELECT
    ROUND(SUM(ingreso), 2)                                                      AS ingreso_bruto,
    -- Ingreso neto = facturación de las líneas que NO se devolvieron (retenidas)
    ROUND(SUM(ingreso) FILTER (WHERE NOT devuelta), 2)                          AS ingreso_neto,
    -- Margen neto = ingreso retenido - costo directo de las unidades retenidas
    ROUND(
        SUM(ingreso) FILTER (WHERE NOT devuelta)
        - SUM(coste) FILTER (WHERE NOT devuelta), 2
    )                                                                           AS margen_neto
FROM alma;


/* ----------------------------------------------------------------------------
4. Por qué se devuelve, en toda la tienda
   Diagnostica si los retornos por talla son exclusivos del 'Vestido Alma' o un
   problema estructural del negocio, contabilizando los motivos de devolución
   normalizados en toda la tienda y su peso porcentual.
   ---------------------------------------------------------------------------- */
SELECT
    LOWER(TRIM(d.motivo))                                       AS motivo,      -- Normaliza mayúsculas y espacios para evitar categorías duplicadas
    COUNT(*)                                                    AS devoluciones,
    ROUND(COUNT(*) * 100.0 / NULLIF(SUM(COUNT(*)) OVER (), 0), 1) AS porcentaje -- Cuota sobre el total de devoluciones mediante función ventana
FROM devoluciones AS d
WHERE d.linea_id IN (SELECT linea_id FROM lineas_pedido)                        -- Filtra únicamente devoluciones vinculadas a líneas válidas
GROUP BY LOWER(TRIM(d.motivo))
ORDER BY devoluciones DESC;


/* ----------------------------------------------------------------------------
5. Dónde se vende el Alma antes de dónde se devuelve
   Desglosa las ventas del 'Vestido Alma' por talla en la campaña 1. Si la
   prenda "tira pequeño", la demanda (y posteriores cambios) se concentrará
   en las tallas centrales.
   ---------------------------------------------------------------------------- */
SELECT
    TRIM(REPLACE(UPPER(lp.talla), 'TALLA', ''))                             AS talla,      -- Limpia prefijos inconsistentes (ej. 'Talla M' -> 'M')
    SUM(lp.cantidad)                                                        AS unidades,
    ROUND(SUM(lp.cantidad) * 100.0 / NULLIF(SUM(SUM(lp.cantidad)) OVER (), 0), 1) AS porcentaje
FROM lineas_pedido AS lp
INNER JOIN pedidos AS p
    ON lp.pedido_id = p.pedido_id
INNER JOIN productos AS pr
    ON lp.producto_id = pr.producto_id
WHERE pr.nombre = 'Vestido Alma'
  AND p.campana_id = 1
GROUP BY TRIM(REPLACE(UPPER(lp.talla), 'TALLA', ''))
ORDER BY unidades DESC;


/* ----------------------------------------------------------------------------
6. El 42.7% es un suelo, no un techo (Ventana de devolución abierta)
   Dado que la política de devolución es de 30 días y la campaña lleva apenas
   tres semanas, la tasa actual puede seguir subiendo. Verifica la fecha del
   último retorno registrado y qué proporción entró a partir del 15 de julio.
   ---------------------------------------------------------------------------- */
WITH dev_alma AS (
    -- Historial de fechas de devolución asociadas al 'Vestido Alma'
    SELECT
        d.fecha_devolucion
    FROM devoluciones AS d
    INNER JOIN lineas_pedido AS lp
        ON d.linea_id = lp.linea_id
    INNER JOIN productos AS pr
        ON lp.producto_id = pr.producto_id
    WHERE pr.nombre = 'Vestido Alma'
)
SELECT
    COUNT(*)                                                                AS devoluciones,
    MAX(fecha_devolucion)                                                   AS ultima_devolucion,
    -- Devoluciones recibidas del 15 de julio en adelante (ventana reciente)
    COUNT(*) FILTER (WHERE fecha_devolucion >= DATE '2024-07-15')           AS desde_15_jul,
    ROUND(
        COUNT(*) FILTER (WHERE fecha_devolucion >= DATE '2024-07-15') * 100.0
        / NULLIF(COUNT(*), 0), 1
    )                                                                       AS pct_ultima_semana
FROM dev_alma;


/* ----------------------------------------------------------------------------
7. ¿Devuelve más la talla M en toda la tienda?
   Aísla el efecto del tallaje general: el 'Vestido Alma' vuelve sobre todo en
   M y L, pero antes de culpar al patronaje del modelo se verifica si esas
   tallas tienen mayor tasa de retorno en toda la tienda (rango XS a XL).
   ---------------------------------------------------------------------------- */
WITH lineas_norm AS (
    -- Estandariza el formato de talla en todo el histórico de líneas
    SELECT
        lp.linea_id,
        TRIM(REPLACE(UPPER(lp.talla), 'TALLA', '')) AS talla
    FROM lineas_pedido AS lp
)
SELECT
    ln.talla,
    COUNT(*)                                                AS ventas,
    COUNT(d.linea_id)                                       AS devoluciones,
    ROUND(COUNT(d.linea_id) * 100.0 / NULLIF(COUNT(*), 0), 1) AS tasa_pct
FROM lineas_norm AS ln
LEFT JOIN devoluciones AS d
    ON ln.linea_id = d.linea_id
WHERE ln.talla IN ('XS', 'S', 'M', 'L', 'XL')                                   -- Acota el análisis a tallaje estándar de ropa
GROUP BY ln.talla
ORDER BY CASE ln.talla
    WHEN 'XS' THEN 1
    WHEN 'S'  THEN 2
    WHEN 'M'  THEN 3
    WHEN 'L'  THEN 4
    WHEN 'XL' THEN 5
END;                                                                            -- Orden lógico de tallaje en lugar de orden alfabético


/* ----------------------------------------------------------------------------
8. Cuánto dinero volvió a salir por la puerta (Impacto financiero en Campaña 1)
   Traduce el volumen de devoluciones a impacto monetario real sobre toda la
   campaña 1: contrasta la facturación bruta frente al monto reembolsado y el
   ingreso neto retenido, demostrando por qué mirar solo el bruto engaña.
   ---------------------------------------------------------------------------- */
WITH camp AS (
    -- Evalúa línea por línea el ingreso facturado y si terminó en devolución
    SELECT
        lp.cantidad * lp.precio_unitario * (1 - COALESCE(lp.descuento_pct, 0))  AS ingreso,
        (lp.linea_id IN (SELECT linea_id FROM devoluciones))                    AS devuelta
    FROM lineas_pedido AS lp
    INNER JOIN pedidos AS p
        ON lp.pedido_id = p.pedido_id
    WHERE p.campana_id = 1
)
SELECT
    ROUND(SUM(ingreso), 2)                                                      AS ingreso_bruto,
    -- Ingreso devuelto = facturación de las líneas que SÍ se devolvieron
    ROUND(SUM(ingreso) FILTER (WHERE devuelta), 2)                              AS ingreso_devuelto,
    ROUND(SUM(ingreso) FILTER (WHERE NOT devuelta), 2)                          AS ingreso_neto,
    ROUND(
        SUM(ingreso) FILTER (WHERE devuelta) * 100.0 / NULLIF(SUM(ingreso), 0), 1
    )                                                                           AS pct_devuelto
FROM camp;
