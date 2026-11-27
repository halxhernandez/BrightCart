# Informe de Calidad de Datos: BrightCart
Fecha de entrega de los datos: 17/11/2026  |  Fecha del informe: 18/11/2016

## 1. Resumen Ejecutivo

Se han perfilado **7 tablas**, **39.224 filas** y **42 columnas**: campañas (4), clientes (5.010), devoluciones (5.558), lineas_pedido (20.140), pedidos (8.000), productos (400) y visitas_web (112).

Los problemas más importantes, en lenguaje llano:

1. **Hay clientes y líneas de pedido repetidos, y no siempre son copias exactas.** En clientes, 40 IDs aparecen más de una vez (80 filas con ID repetido); de ellos, 2 filas son duplicados exactos y los otros 38 IDs corresponden a clientes con datos distintos entre sí (76 filas). En lineas_pedido, 140 filas de más: 139 son duplicados exactos y 1 es un ID repetido con datos distintos. Si se suma sin limpiar, se duplican ventas y clientes.
2. **Hay 42 devoluciones que apuntan a líneas de pedido inexistentes (0,76%).** Son devoluciones con `linea_id` en el rango 2.011.474–2.047.096, fuera del rango 900.001–920.000 de lineas_pedido. No se pueden cruzar con ningún pedido.
3. **La información de campañas está prácticamente inservible para medir ROI.** En pedidos, `campana_id` solo toma el valor 1,0 o nulo (14,74% nulos): las otras 3 campañas no aparecen nunca. No se puede atribuir ventas a campañas.
4. **Fechas e importes están guardados como texto y con formatos mezclados** (`24/06/2024` y `2024-07-02` en pedidos y devoluciones; `48000.0` y `61.000 €` en campañas; `63,83 €` en lineas_pedido; `0.3`, `30%` y `0%` en descuento_pct). Cualquier cálculo directo falla o da resultados erróneos.
5. **Hay valores imposibles:** 13 edades fuera de [0, 100] en clientes (0,26%, incluidos −5 y 250 años) y 15 cantidades negativas en lineas_pedido (0,07%, mínimo −1).

**Prioridad global:** Alta. Los puntos 1, 2 y 3 bloquean análisis clave (ventas por cliente, devoluciones por pedido y ROI por campaña); los puntos 4 y 5 se resuelven con normalización y reglas de validación.

---

## 2. Metodología

**Dimensiones revisadas:** completitud (nulos), unicidad (claves y duplicados), validez (rangos y valores imposibles), consistencia (formatos y dominios de valores), integridad referencial (claves que no encuentran correspondencia) y lógica temporal (orden de fechas).

**Definición de severidad (usada de forma uniforme en todo el informe):**

- **Alta:** impide analizar correctamente. Duplicados o colisiones de clave, valores imposibles o fuera de rango, claves foráneas sin correspondencia, nulos en campos que rompen la atribución.
- **Media:** el dato es utilizable pero requiere normalización o parseo previo (fechas e importes como texto, categorías con mayúsculas/minúsculas mezcladas, tipos inconsistentes).
- **Baja:** cosmético o documental; no altera los resultados (formato de una columna, nulos puntuales en un campo no crítico).

**Convención de numeración:** prefijo por tabla (`CAM`, `CLI`, `DEV`, `LIN`, `PED`, `PRO`, `VIS`) + número. Estos códigos se reutilizan en el plan de limpieza (sección 5).

**Nota sobre cuantificación:** los conteos marcados con `≥` son mínimos confirmados por el perfilado; el resto son cifras exactas. Los porcentajes se calculan sobre las filas de la tabla salvo indicación contraria.

---

## 3. Resultados por tabla

### campañas
Filas: 4 | Columnas: 8 | Valoración global: **Media prioridad**

| # | Columna | Problema | Afectadas (nº y %) | Severidad | Limpieza propuesta |
|---|---|---|---|---|---|
| CAM1 | presupuesto | Importe como texto con formatos mezclados (`48000.0` vs `61.000 €`) | 1 fila (25%) | Media | Eliminar `€` y separador de miles, convertir coma decimal y castear a numérico. Validar que quede en rango razonable (p. ej. 10.000–100.000). |
| CAM2 | fecha_inicio, fecha_fin | Fechas almacenadas como texto (todas ISO de 10 caracteres) | 4 filas (100%) | Baja | Castear a fecha ISO. Validación ya ejecutada: `fecha_fin < fecha_inicio` = 0 filas. |
| CAM3 | campana_id | Solo 4 campañas, pero 3 de ellas nunca aparecen en pedidos (ver PED2) | 3 de 4 campañas (75%) | Alta | No es un defecto de esta tabla, pero bloquea el análisis. Ver PED2 y decisión D3 en la sección 5. |

*Observación:* tabla pequeña y sin nulos ni duplicados. Los problemas de esta tabla son menores; el problema real está en cómo se relaciona con pedidos.

---

### clientes
Filas: 5.010 | Columnas: 5 | Valoración global: **Alta prioridad**

| # | Columna | Problema | Afectadas (nº y %) | Severidad | Limpieza propuesta |
|---|---|---|---|---|---|
| CLI1 | cliente_id | 2 filas totalmente duplicadas | 2 filas (0,04%) | Alta | Eliminar duplicados exactos conservando la primera aparición. |
| CLI2 | cliente_id | 38 IDs repetidos con datos distintos entre sí (colisión de clave). En total hay 80 filas con ID repetido | 38 IDs / 76 filas (1,52%) | Alta | Comparar los pares por columna, definir regla de supervivencia (registro más reciente / más completo) y consolidar en un único registro por ID. Requiere decisión D1. |
| CLI3 | fecha_registro | Nulos en fecha de alta | 150 filas (2,99%) | Media | Decidir si se imputan (p. ej. fecha mínima del sistema) o se marcan como "desconocida". Castear a fecha. |
| CLI4 | ciudad | Inconsistencias de mayúsculas/minúsculas (`bilbao`/`Bilbao`, `madrid`/`Madrid`) | 31 valores únicos; filas exactas por cuantificar al normalizar | Media | Normalizar a un catálogo único de ciudades (Title Case + sin duplicados) y reutilizarlo en pedidos.ciudad (PED4). |
| CLI5 | genero | 6 valores distintos para 2–3 categorías reales (`F`, `M`, `m`, ...). El valor `M` domina con 1.403 filas | 6 valores únicos; filas por cuantificar | Media | Mapear a catálogo cerrado (F/M/X/No informado) y documentar el mapeo. |
| CLI6 | edad | 13 valores fuera del rango válido [0, 100], incluidos mínimo −5 y máximo 250 | 13 filas (0,26%) | Alta | Marcar como nulo o corregir los valores imposibles; decidir tratamiento de outliers (D6). Validar rango 0–100 en la carga. |

*Observación de negocio:* solo 2.287 de los 4.970 clientes únicos tienen pedidos (el 54% de los clientes no ha comprado). No es un defecto, pero condiciona los análisis de conversión.

---

### devoluciones
Filas: 5.558 | Columnas: 5 | Valoración global: **Alta prioridad**

| # | Columna | Problema | Afectadas (nº y %) | Severidad | Limpieza propuesta |
|---|---|---|---|---|---|
| DEV1 | linea_id | 42 devoluciones apuntan a `linea_id` fuera del rango de lineas_pedido (900.001–920.000); máximo observado 2.047.096 | 42 filas (0,76%) | Alta | Excluir del análisis o reasignar si BrightCart aporta el mapeo (D4). Ejemplos: 2034641, 2011474, 2027240, 2046423, 2014402. |
| DEV2 | fecha_devolucion | Formato mixto `dd/mm/yyyy` y `yyyy-mm-dd` | 79 valores únicos; formatos mezclados confirmados | Media | Parsear ambos formatos de forma explícita y castear a fecha ISO. |
| DEV3 | talla | 29 valores distintos con mezcla numérico/texto y mayúsculas/minúsculas (`36`, `XL`, `m`, `M`, `s`, `S`). El valor `M` domina con 1.059 filas | 29 valores únicos; filas por cuantificar | Media | Normalizar a catálogo único de tallas y reutilizarlo en lineas_pedido.talla (LIN4). |
| DEV4 | motivo | 8 motivos; alta concentración en "talla incorrecta" (1.509 filas) | 1.509 filas (27,1%) en el motivo dominante | Baja | Revisar si los 8 motivos son un catálogo cerrado y si hay variantes de texto; no requiere limpieza urgente. |

*Observación:* 5.558 devoluciones sobre 20.140 líneas equivale a una tasa de devolución del 27,6%. Es un dato de negocio relevante, no un defecto de calidad, pero conviene confirmarlo con BrightCart.

---

### lineas_pedido
Filas: 20.140 | Columnas: 7 | Valoración global: **Alta prioridad**

| # | Columna | Problema | Afectadas (nº y %) | Severidad | Limpieza propuesta |
|---|---|---|---|---|---|
| LIN1 | linea_id | 139 filas totalmente duplicadas | 139 filas (0,69%) | Alta | Eliminar duplicados exactos. Confirmar con BrightCart que son reintentos de carga y no líneas legítimas repetidas (D2). |
| LIN2 | linea_id | 1 ID repetido con datos distintos (20.140 filas frente a 20.000 IDs únicos; 280 filas con ID repetido, de las que 139 son duplicados exactos) | 1 fila (0,005%) | Alta | Revisar el par, decidir qué versión es correcta y consolidar. |
| LIN3 | cantidad | 15 valores imposibles: mínimo −1 | 15 filas (0,07%) | Alta | Corregir a valor positivo si es error de signo o anular la línea; validar `cantidad ≥ 1` en la carga. |
| LIN4 | talla | 29 valores distintos con formatos mezclados. El valor `M` domina con 3.818 filas | 29 valores únicos; filas por cuantificar | Media | Normalizar con el mismo catálogo que DEV3. |
| LIN5 | precio_unitario | Precio como texto con `€` y coma decimal (`63,83 €`) | 389 valores únicos (100% de la columna a convertir) | Media | Limpiar símbolo y separador de miles, convertir coma decimal y castear a numérico. |
| LIN6 | descuento_pct | Formato mixto: decimal (`0.3`), porcentaje (`30%`) y cero (`0`, `0.0`, `0%`) | 18 valores distintos (100% de la columna a normalizar) | Media | Unificar a una sola escala (recomendado 0–1) y documentar la decisión (D5). |
| LIN7 | pedido_id, producto_id | Rangos compatibles con pedidos y productos; 0 huérfanos confirmados por LEFT JOIN | 0 filas (0%) | Baja | Ninguna acción adicional: la comprobación ya se ejecutó y no hay huérfanos. |

---

### pedidos
Filas: 8.000 | Columnas: 7 | Valoración global: **Alta prioridad**

| # | Columna | Problema | Afectadas (nº y %) | Severidad | Limpieza propuesta |
|---|---|---|---|---|---|
| PED1 | fecha_pedido | Formato mixto `dd/mm/yyyy` y `yyyy-mm-dd` | 81 valores únicos; formatos mezclados confirmados | Media | Parsear ambos formatos y castear a fecha ISO. |
| PED2 | campana_id | Solo contiene el valor 1,0 (1 valor único para 4 campañas posibles) y además es float64 frente a int en campañas | 6.821 filas no nulas (85,3%) con un único valor | Alta | Determinar con BrightCart si es un error de carga o si la atribución de campañas se perdió (D3). Si es error, recargar; si no, documentar que solo la campaña 1 es atribuible y no calcular ROI por campaña. |
| PED3 | campana_id | Nulos en la clave foránea de campaña | 1.179 filas (14,74%) | Media | Mantener como nulo (venta no atribuida a campaña) y documentarlo; no imputar. Castear a entero nullable. |
| PED4 | ciudad | 31 valores con mayúsculas/minúsculas mezcladas (`Oporto`/`lisboa`/`Madrid`). `Madrid` domina con 1.124 filas | 31 valores únicos; filas por cuantificar | Media | Aplicar el mismo catálogo de ciudades que CLI4. |
| PED5 | canal | 4 canales; `instagram` concentra 2.792 pedidos | 2.792 filas (34,9%) en el canal dominante | Baja | Validar que el catálogo de 4 canales es cerrado y coincide con el de visitas_web. |
| PED6 | metodo_pago | 3 métodos; `tarjeta` concentra 4.372 pedidos | 4.372 filas (54,7%) en el método dominante | Baja | Validar catálogo cerrado; sin acción de limpieza. |

---

### productos
Filas: 400 | Columnas: 7 | Valoración global: **Media prioridad**

| # | Columna | Problema | Afectadas (nº y %) | Severidad | Limpieza propuesta |
|---|---|---|---|---|---|
| PRO1 | categoria | 35 valores distintos con variantes de mayúsculas (`Vestidos`, `VESTIDOS`, `vestido`). `Vestidos` domina con 22 filas | 35 valores únicos; filas por cuantificar | Media | Normalizar a un catálogo de categorías (Title Case, singular/plural unificado) y validar el número final de categorías reales. |
| PRO2 | temporada | 5 valores con formatos inconsistentes (`Verano24`, `verano`, `verano 2024`); el valor canónico "Verano 2024" agrupa 171 productos | 5 valores únicos; 171 filas (42,75%) en el valor dominante | Media | Mapear a un catálogo de temporadas (`Verano 2024`, etc.) y documentar el mapeo. |
| PRO3 | coste_unitario | Nulos en el coste | 12 filas (3,0%) | Media | Recuperar el coste de la fuente original si existe; si no, imputar por mediana de la categoría y marcar la fila como "coste estimado". |
| PRO4 | coleccion | 8 colecciones; "Mediterráneo" agrupa 57 productos | 57 filas (14,25%) en la colección dominante | Baja | Validar catálogo cerrado; sin acción urgente. |
| PRO5 | precio_base | 389 valores únicos en 400 productos; rango 10,36–89,35, sin nulos | 400 filas revisadas, 0 problemas | Baja | Ninguna. Usar como referencia para validar precio_unitario de lineas_pedido (debe ser ≤ precio_base salvo promoción). |

---

### visitas_web
Filas: 112 | Columnas: 3 | Valoración global: **Baja prioridad**

| # | Columna | Problema | Afectadas (nº y %) | Severidad | Limpieza propuesta |
|---|---|---|---|---|---|
| VIS1 | sesiones | Nulos en sesiones | 4 filas (3,57%) | Media | Decidir si se imputa 0 (canal sin sesiones ese día) o se mantiene nulo; documentar la decisión. |
| VIS2 | sesiones | Tipo float64 aunque el dato es un conteo entero | 108 filas no nulas (96,4%) | Baja | Castear a entero tras tratar los nulos. |
| VIS3 | fecha, canal | Estructura correcta: 28 fechas × 4 canales = 112 filas, sin duplicados ni huecos | 0 problemas | Baja | Ninguna. Usar como tabla de referencia del catálogo de canales. |

---

## 4. Integridad entre tablas

Comprobaciones de integridad ejecutadas con LEFT JOIN sobre los datos reales:

| Relación | Clave | Estado | Evidencia | Acción |
|---|---|---|---|---|
| pedidos → clientes | `cliente_id` | **0 huérfanos confirmados, pero join con riesgo de duplicar** | 8.000 pedidos cruzan con 2.287 IDs de cliente en rango 1–4.970. Sin huérfanos, pero clientes tiene 40 IDs repetidos (CLI2), así que el join expandirá filas para esos clientes. | Resolver CLI1/CLI2 **antes** de cualquier join. No requiere más verificación de huérfanos. |
| lineas_pedido → pedidos | `pedido_id` | **0 huérfanos confirmados** | LEFT JOIN ejecutado: 0 filas sin correspondencia. Rangos compatibles 500.001–508.000. | Ninguna. |
| lineas_pedido → productos | `producto_id` | **0 huérfanos confirmados** | LEFT JOIN ejecutado: 0 filas sin correspondencia. lineas_pedido usa 1.001–1.400, idéntico a productos. | Ninguna. |
| devoluciones → lineas_pedido | `linea_id` | **42 huérfanos confirmados (0,76%)** | 42 `linea_id` fuera del rango 900.001–920.000 de lineas_pedido. Ejemplos: 2034641, 2011474, 2027240, 2046423, 2014402. | Excluir o reasignar (D4). Atención: lineas_pedido tiene 140 IDs repetidos (LIN1/LIN2), así que el join también expandirá filas. |
| pedidos → campañas | `campana_id` | **0 huérfanos, pero integridad rota por el lado del dato** | El único valor no nulo es 1,0, que existe en campañas. No hay huérfanos, pero faltan 3 campañas y hay 14,74% de nulos (PED2, PED3). | Resolver PED2 con BrightCart antes de calcular ROI. |
| pedidos.ciudad ↔ clientes.ciudad | Dominio compartido | **Consistencia pendiente** | Ambas tienen 31 valores únicos con el mismo patrón de mayúsculas mezcladas. | Normalizar con un único catálogo (CLI4 + PED4). |
| lineas_pedido.talla ↔ devoluciones.talla | Dominio compartido | **Consistencia pendiente** | Ambas tienen 29 valores únicos con formatos mezclados. | Normalizar con un único catálogo (LIN4 + DEV3). |
| pedidos.canal ↔ visitas_web.canal | Dominio compartido | **Coherente** | 4 canales en ambas tablas (instagram, email, google, directo). | Validar que los valores son idénticos carácter a carácter. |
| Lógica temporal: devolución ≥ pedido | `fecha_devolucion` vs `fecha_pedido` | **Pendiente** | Requiere join devoluciones → lineas_pedido → pedidos; no verificable con el perfilado puro. | Ejecutar tras normalizar fechas (DEV2, PED1) y listar devoluciones anteriores a su pedido. |
| Lógica temporal: campañas | `fecha_fin ≥ fecha_inicio` | **Validada: 0 filas** | Regla ejecutada sobre campañas: 0 infracciones. | Ninguna. |

---

## 5. Plan de limpieza propuesto

**Fase 1 — Bloqueantes (antes de cualquier análisis).** Resolver en este orden, porque cada paso evita que el siguiente propague errores:

1. **CLI1 + CLI2:** eliminar los 2 duplicados exactos y consolidar los 38 IDs de cliente con datos divergentes (76 filas).
2. **LIN1 + LIN2:** eliminar los 139 duplicados exactos y resolver el caso de ID repetido con datos distintos.
3. **DEV1:** identificar y excluir o reasignar las 42 devoluciones huérfanas.
4. **PED2 + PED3:** decidir qué hacer con `campana_id`.
5. **LIN3 + CLI6:** corregir o anular las 15 cantidades negativas y las 13 edades fuera de [0, 100].

**Fase 2 — Normalización (necesaria para calcular).**

6. **Fechas (CAM2, CLI3, DEV2, PED1):** parsear los formatos mixtos y estandarizar a ISO; crear una función de parseo única para todo el dataset.
7. **Importes y porcentajes (CAM1, LIN5, LIN6):** limpiar `€`, separadores de miles y comas decimales; unificar `descuento_pct` a una sola escala.
8. **Catálogos (CLI4, CLI5, DEV3, LIN4, PED4, PRO1, PRO2):** crear un catálogo único de ciudades, géneros, tallas, categorías y temporadas, y aplicarlo en todas las tablas que comparten dominio.
9. **Tipos (PED2, VIS2, PRO3):** castear `campana_id` a entero nullable, `sesiones` a entero y documentar los nulos de `coste_unitario`.

**Fase 3 — Validación y documentación.**

10. **VIS1:** decidir el tratamiento de los 4 nulos de sesiones.
11. **Integridad:** dejar adjunto al informe el resultado de las comprobaciones ya ejecutadas (sección 4) y repetirlas tras la limpieza.
12. **Reglas de validación en la carga:** edad 0–100, cantidad ≥ 1, `fecha_fin ≥ fecha_inicio`, devolución ≥ pedido, `precio_unitario ≤ precio_base` salvo promoción, `campana_id` en el catálogo de campañas.
13. **Documentar** en el diccionario de datos la escala elegida para `descuento_pct`, el catálogo de ciudades y el mapeo de géneros y tallas.

**Decisiones que necesitamos de BrightCart:**

- **D1 (CLI2):** para los 38 IDs de cliente con datos distintos, ¿cuál es el registro correcto? ¿Fusionamos conservando el más reciente o el más completo?
- **D2 (LIN1):** ¿los 139 duplicados de lineas_pedido son reintentos de carga que debemos eliminar, o hay líneas legítimas repetidas?
- **D3 (PED2):** ¿que `campana_id` valga solo 1,0 es un error de carga? ¿Existe una tabla de asignación pedido–campaña que podamos recuperar?
- **D4 (DEV1):** las 42 devoluciones con `linea_id` fuera de rango, ¿corresponden a líneas reales que faltan, o debemos descartarlas?
- **D5 (LIN6):** ¿`descuento_pct` debe expresarse en escala 0–1 o 0–100?
- **D6 (CLI6):** las 13 edades fuera de [0, 100], ¿se corrigen con el dato original del cliente o se anulan?
- **D7 (PRO3):** los 12 costes unitarios nulos, ¿se pueden recuperar de facturas o autorizáis imputarlos por mediana de categoría?
