# Reporte de Calidad y Limpieza de Datos — BrightCart

Este documento centraliza el análisis de calidad, los problemas detectados y las reglas de limpieza para cada una de las tablas del proyecto.

## Índice de Tablas
1. [Tabla: campañas](#1-tabla-campañas)
2. [Tabla: clientes](#2-tabla-clientes)
3. [Tabla: devoluciones](#3-tabla-devoluciones)
4. [Tabla: lineas_pedido](#4-tabla-lineas_pedido)
5. [Tabla: pedidos](#5-tabla-pedidos)
6. [Tabla: productos](#6-tabla-productos)
7. [Tabla: visitas_web](#7-tabla-visitas_web)

---

## 1. Tabla: `campañas`

**Última actualización:** 2026-11-13
**Responsable:** Alejandro Hernández Rodríguez
**Origen de datos:** Archivo `campana.csv`

### 1.1 Descripción General y Alcance

Este documento aplica a la tabla **“campaña”**, compuesta por:

- **4 filas**
- **8 columnas**
- **0 valores nulos**
- **0 filas duplicadas**
- **0 columnas constantes**

El dataset es muy pequeño, por lo que las conclusiones estadísticas y la detección de valores atípicos deben tomarse con cautela. El objetivo es documentar la calidad inicial y las acciones necesarias para dejar el dataset apto para análisis.

### 1.2 Inventario y Calidad Inicial

#### 1.2.1 Inventario de columnas

| Columna | Tipo detectado | Observación inicial |
|---|---|---|
| `campana_id` | Numérico entero | Posible clave primaria. 4 valores únicos para 4 filas. |
| `nombre` | Texto | 4 valores únicos. No debe considerarse ID por el tamaño de la tabla. |
| `tipo` | Texto | 3 categorías: `rebajas`, `black_friday`, `promo`. |
| `fecha_inicio` | Texto | Debe convertirse a fecha para análisis temporal. |
| `fecha_fin` | Texto | Debe convertirse a fecha y validarse contra `fecha_inicio`. |
| `canal` | Texto | 3 categorías: `instagram`, `email`, `google`. |
| `presupuesto` | Texto | **Problema principal:** mezcla formatos numéricos y símbolo de moneda. |
| `ventas_ano_anterior` | Numérico decimal | Sin nulos, ceros ni negativos. |

#### 1.2.2 Resumen de calidad

| Característica | Valor |
|---|---|
| Filas | 4 |
| Columnas | 8 |
| Valores nulos | 0 |
| Filas duplicadas | 0 |
| Columnas constantes | 0 |

### 1.3 Hallazgos de Calidad

#### 1.3.1 Puntos fuertes

- No hay valores nulos.
- No hay filas duplicadas.
- No hay columnas constantes.
- `campana_id` parece una clave primaria válida: único y sin nulos.
- `ventas_ano_anterior` es numérica y no presenta ceros ni negativos.
- Las columnas `tipo` y `canal` tienen pocas categorías y no muestran errores evidentes de escritura.

#### 1.3.2 Problemas detectados

1. **`presupuesto` está almacenado como texto y con formatos mezclados.**
   Ejemplos observados:
   - `48000.0`
   - `52000.0`
   - `61.000 €`
   - `22000.0`

   Esto impide calcular estadísticas, sumas o comparaciones numéricas fiables.

2. **Las fechas están como texto.**
   `fecha_inicio` y `fecha_fin` no están tipadas como fecha, lo que dificulta ordenar, calcular duración de campañas o validar rangos.

3. **La columna `presupuesto` no entra en el análisis numérico inicial.**
   Al estar como texto, queda fuera de las estadísticas descriptivas numéricas.

4. **“Columnas 100% únicas” no significa que sean identificadores.**
   Con solo 4 filas, que una columna sea única no implica que sea un ID. El único identificador claro es `campana_id`.

5. **Tamaño muestral muy reducido.**
   No se deben eliminar valores atípicos ni sacar conclusiones fuertes de distribuciones con solo 4 registros.

### 1.4 Consideraciones para la Limpieza

#### 1.4.1 Presupuesto

**Acción prevista:** normalizar `presupuesto` a un valor numérico.

Consideraciones:

- Eliminar el símbolo de moneda `€`.
- Eliminar espacios en blanco.
- Unificar el separador decimal.
- Eliminar separadores de miles cuando correspondan.
- Convertir la columna a tipo numérico.
- Validar que todos los valores sean mayores que cero.
- Documentar expresamente la interpretación de `61.000 €`.

**Decisión pendiente de confirmar con negocio:**
`61.000 €` debe interpretarse probablemente como **61.000 euros**. Sin embargo, debe confirmarse antes de normalizarlo, porque el formato puede ser ambiguo según el locale.

**Resultado esperado:** columna `presupuesto` numérica, sin símbolos ni texto, con valores positivos.

#### 1.4.2 Fechas

**Acción prevista:** convertir `fecha_inicio` y `fecha_fin` a tipo fecha.

Consideraciones:

- Validar que todas las fechas tengan formato interpretable.
- Comprobar que `fecha_fin` sea mayor o igual que `fecha_inicio`.
- Calcular, si se requiere, la duración de la campaña.
- Definir si la duración se calcula como diferencia de días o como rango inclusivo.
- No modificar las fechas originales sin dejar trazabilidad.

**Resultado esperado:** ambas columnas como fechas válidas y rangos coherentes.

#### 1.4.3 Identificador de campaña

**Acción prevista:** validar `campana_id` como clave primaria.

Consideraciones:

- Debe ser único.
- No debe tener nulos.
- Debe mantenerse como entero.
- No se debe reemplazar por `nombre`, aunque `nombre` sea único en esta muestra.

**Resultado esperado:** `campana_id` único y no nulo.

#### 1.4.4 Columnas categóricas

**Acción prevista:** revisar y estandarizar `tipo` y `canal` solo si es necesario.

Consideraciones:

- Revisar espacios al inicio o al final.
- Revisar mayúsculas y minúsculas.
- Confirmar el conjunto de valores permitidos para `tipo`: `rebajas`, `black_friday`, `promo`.
- Confirmar el conjunto de valores permitidos para `canal`: `instagram`, `email`, `google`.
- Mantener los nombres originales salvo que exista una razón documentada para cambiarlos.
- No agrupar categorías sin validación de negocio.

**Resultado esperado:** categorías coherentes y sin variantes accidentales.

#### 1.4.5 Ventas del año anterior

**Acción prevista:** mantener como variable numérica y validar.

Consideraciones:

- Confirmar que no haya nulos.
- Confirmar que no haya valores negativos.
- Revisar si un valor cero tendría sentido en el negocio.
- No eliminar valores extremos con solo 4 registros.

**Resultado esperado:** columna numérica, no negativa y consistente.

#### 1.4.6 Duplicados

**Acción prevista:** volver a comprobar duplicados después de normalizar formatos.

Consideraciones:

- Aunque inicialmente no hay duplicados, la normalización de `presupuesto` y fechas podría revelar registros equivalentes.
- Los duplicados deben evaluarse por `campana_id`, no solo por igualdad exacta de texto.

**Resultado esperado:** sin duplicados por clave de campaña.

### 1.5 Reglas de Validación Propuestas

Antes de dar por limpio el dataset, comprobar:

| Validación | Criterio esperado |
|---|---|
| `campana_id` único | 4 valores únicos para 4 filas |
| `campana_id` no nulo | 0 nulos |
| `presupuesto` numérico | 0 errores de conversión |
| `presupuesto` positivo | Todos los valores > 0 |
| `fecha_inicio` válida | Todas las fechas interpretables |
| `fecha_fin` válida | Todas las fechas interpretables |
| Rango de fechas coherente | `fecha_fin >= fecha_inicio` |
| `tipo` válido | Solo categorías permitidas |
| `canal` válido | Solo categorías permitidas |
| `ventas_ano_anterior` no negativo | Todos los valores >= 0 |
| Duplicados por `campana_id` | 0 duplicados |
| Nulos en columnas clave | 0 nulos |

### 1.6 Decisiones Pendientes de Confirmación

1. Interpretación definitiva de `61.000 €`.
2. Moneda de `presupuesto`: se asume EUR, pero debe confirmarse.
3. Criterio de duración de campaña: diferencia simple o rango inclusivo.
4. Lista oficial de valores permitidos para `tipo`.
5. Lista oficial de valores permitidos para `canal`.
6. Si se conservan los valores originales en columnas auxiliares para trazabilidad.
7. Si se renombran columnas o se mantienen los nombres originales.
8. Si se elimina alguna columna; en principio, no se recomienda eliminar ninguna en esta fase.

### 1.7 Restricciones y Buenas Prácticas

- No imputar valores nulos, porque no hay nulos.
- No eliminar valores atípicos con solo 4 registros.
- No usar `nombre` como clave primaria.
- No convertir `presupuesto` sin antes resolver la ambigüedad de `61.000 €`.
- No modificar los datos originales sin conservar una copia o registro de cambios.
- No agrupar categorías de `tipo` o `canal` sin validación de negocio.

### 1.8 Entregables Esperados

1. Dataset limpio con `presupuesto` numérico y fechas tipadas.
2. Registro de cambios aplicados.
3. Informe de validación con las comprobaciones realizadas.
4. Documentación de decisiones tomadas, especialmente sobre `61.000 €`.
5. Copia del dataset original sin modificaciones.

### 1.9 Conclusión

La calidad inicial del dataset es **buena en completitud y duplicados**, pero requiere **normalización de tipos y formatos**, especialmente en `presupuesto` y en las fechas. El principal riesgo es que `presupuesto` está como texto con formatos mezclados, lo que bloquea análisis numéricos fiables. Con las validaciones y decisiones documentadas en este reporte, el dataset puede quedar apto para análisis posterior.

[⬆ Volver al índice de tablas](#índice-de-tablas)

---

## 2. Tabla: `clientes`

**Última actualización:** 2026-11-13
**Responsable:** Alejandro Hernández Rodríguez
**Origen de datos:** Archivo `clientes.csv`

### 2.1 Descripción General y Alcance

Este documento aplica a la tabla **“clientes”**, compuesta por:

- **5.010 filas**
- **5 columnas**
- **150 valores nulos** en `fecha_registro` (2,99 %)
- **2 filas duplicadas** exactas (0,04 %)
- **0 columnas constantes**
- **0 columnas 100 % únicas** (⚠️ ni siquiera `cliente_id`)

El dataset tiene volumen suficiente para sacar conclusiones estadísticas razonables, a diferencia de `campañas`. Sin embargo, presenta problemas de **integridad y dominio de valores** que deben resolverse antes de un análisis fiable.

### 2.2 Inventario y Calidad Inicial

#### 2.2.1 Inventario de columnas

| Columna | Tipo detectado | Observación inicial |
|---|---|---|
| `cliente_id` | Numérico entero | **No es único.** 5.010 filas frente a un `max` de 4.970. No puede usarse como clave primaria sin investigar. |
| `fecha_registro` | Texto | 150 nulos (2,99 %). Debe convertirse a fecha. 2.023 valores únicos. |
| `ciudad` | Texto | 31 valores únicos. Revisar acentos, mayúsculas y posibles valores residuales. |
| `genero` | Texto | **Codificación inconsistente:** `M`, `F`, `Femenino`, `Masculino`, `f` y al menos una categoría adicional no listada. |
| `edad` | Numérico entero | **Contiene valores imposibles:** mínimo -5, máximo 250, 5 ceros y 4 negativos. |

#### 2.2.2 Resumen de calidad

| Característica | Valor |
|---|---|
| Filas | 5.010 |
| Columnas | 5 |
| Valores nulos | 150 en `fecha_registro` (2,99 %) |
| Filas duplicadas exactas | 2 (0,04 %) |
| Columnas constantes | 0 |
| Columnas 100 % únicas | 0 |
| Memoria | ~0,99 MB |

### 2.3 Hallazgos de Calidad

#### 2.3.1 Puntos fuertes

- Completitud alta: solo una columna tiene nulos, y representa un 2,99 %, un porcentaje manejable.
- `ciudad` y `genero` no tienen nulos.
- `edad` y `cliente_id` son numéricas y sin nulos.
- No hay columnas constantes.
- Los duplicados exactos son muy pocos (2 filas), fáciles de tratar.
- Volumen suficiente (5.010 filas) para sacar conclusiones estadísticas razonables.

#### 2.3.2 Problemas detectados

1. **`cliente_id` no es una clave primaria válida.** ⚠️
   - 5.010 filas frente a un `max` de 4.970 → hay al menos 40 IDs repetidos.
   - Los 2 duplicados exactos detectados (IDs `1435` y `3187`) confirman que hay IDs repetidos, pero no explican todas las repeticiones: existen IDs repetidos con datos distintos.
   - **Implicación:** no se puede usar `cliente_id` como identificador único sin investigar si se trata de un error de carga, de clientes legítimamente repetidos o si falta un identificador compuesto.

2. **`edad` contiene valores imposibles.** ⚠️
   - `min = -5` → 4 valores negativos.
   - `max = 250` → edad imposible para un humano.
   - 5 ceros → ¿bebés reales o error de captura?
   - **Implicación:** la media (37,36) y la desviación (14,0) están contaminadas por estos outliers extremos.

3. **`genero` tiene codificación inconsistente.** ⚠️
   Valores observados:
   - `M` (1.403)
   - `F` (1.318)
   - `Femenino` (686)
   - `Masculino` (603)
   - `f` (511)
   - Al menos **una sexta categoría no listada** en el top 5 (aprox. 489 registros).

   **Implicación:** hay al menos 3 formas de codificar lo mismo y un valor desconocido. Cualquier análisis por género es inválido sin normalizar.

4. **`fecha_registro` está como texto y con nulos.** ⚠️
   - Tipo detectado: `str`, no fecha.
   - 150 nulos (2,99 %).
   - 2.023 valores únicos → plausible para un registro de clientes.
   - **Implicación:** no se puede ordenar, calcular antigüedad, segmentar por cohortes ni validar rangos temporales.

5. **`ciudad` con 31 valores únicos — revisar posibles inconsistencias.**
   - Sin nulos ni valores raros en el top 5.
   - Conviene revisar acentos, mayúsculas, espacios y valores residuales tipo “N/A”, “-”, “Desconocido”.

6. **2 duplicados exactos (0,04 %).**
   - IDs `1435` y `3187` aparecen cada uno dos veces con datos idénticos.
   - Hay que decidir si se eliminan, se conservan marcados o son legítimos.

7. **Desbalance en `ciudad` y `genero`.**
   - `ciudad`: Madrid (938) vs Bilbao (214) — normal en datos reales.
   - `genero`: categorías mezcladas, no comparable hasta normalizar.

### 2.4 Consideraciones para la Limpieza

#### 2.4.1 `cliente_id`

**Acción prevista:** investigar la unicidad antes de tratarlo como clave.

Consideraciones:

- Contar IDs repetidos y revisar si los repetidos tienen datos distintos o idénticos.
- Decidir si se trata de un error de carga, de clientes duplicados legítimos o de la ausencia de un identificador compuesto.
- Documentar la decisión antes de eliminar o marcar filas.

**Resultado esperado:** criterio claro sobre la unicidad de `cliente_id` y tratamiento documentado.

#### 2.4.2 `edad`

**Acción prevista:** definir rango válido y tratar valores imposibles.

Consideraciones:

- Definir rango válido (p. ej. 0–110).
- Decidir tratamiento de negativos (probablemente nulos o exclusión).
- Decidir tratamiento del 250 (probablemente error de captura).
- Decidir si los 5 ceros son válidos (bebés) o error.
- No eliminar outliers sin criterio documentado.

**Resultado esperado:** columna `edad` con valores dentro de un rango válido y criterio de tratamiento registrado.

#### 2.4.3 `genero`

**Acción prevista:** normalizar a un conjunto cerrado de categorías.

Consideraciones:

- Unificar `M`/`Masculino` y `F`/`Femenino`/`f`.
- Confirmar con negocio la categoría adicional no listada (aprox. 489 registros).
- Definir el conjunto oficial de valores permitidos.
- Revisar espacios y mayúsculas/minúsculas.

**Resultado esperado:** categorías coherentes y análisis por género válido.

#### 2.4.4 `fecha_registro`

**Acción prevista:** convertir a fecha y decidir política de nulos.

Consideraciones:

- Convertir a tipo fecha.
- Validar que no haya fechas futuras ni imposibles.
- Decidir política de nulos: imputar, marcar como “desconocido” o excluir.
- No modificar las fechas originales sin dejar trazabilidad.

**Resultado esperado:** columna fecha válida y política de nulos documentada.

#### 2.4.5 `ciudad`

**Acción prevista:** revisar codificación solo si es necesario.

Consideraciones:

- Revisar acentos, mayúsculas y espacios.
- Revisar valores residuales tipo “N/A”, “-”, “Desconocido”.
- Confirmar que no haya provincias mezcladas con ciudades.
- Mantener los nombres originales salvo razón documentada.

**Resultado esperado:** categorías coherentes y sin variantes accidentales.

#### 2.4.6 Duplicados

**Acción prevista:** decidir tratamiento de los 2 duplicados exactos.

Consideraciones:

- Confirmar que son duplicados exactos y no registros legítimos.
- Decidir si se eliminan, se conservan marcados o se mantienen.
- Revisar duplicados por `cliente_id` una vez resuelta la unicidad.

**Resultado esperado:** sin duplicados no justificados y criterio documentado.

### 2.5 Reglas de Validación Propuestas

Antes de dar por limpio el dataset, comprobar:

| Validación | Criterio esperado |
|---|---|
| `cliente_id` único | 0 duplicados tras definir criterio |
| `cliente_id` no nulo | 0 nulos |
| `edad` en rango válido | Todos los valores entre 0 y 110 |
| `edad` sin negativos | 0 valores negativos |
| `genero` normalizado | Solo categorías del conjunto oficial |
| `fecha_registro` válida | Todas las fechas interpretables |
| `fecha_registro` sin futuras | 0 fechas futuras |
| Política de nulos en `fecha_registro` | Decisión documentada y aplicada |
| `ciudad` sin variantes | 0 variantes accidentales |
| Duplicados exactos | 0 duplicados no justificados |
| Nulos en columnas clave | 0 nulos en `cliente_id` |

### 2.6 Decisiones Pendientes de Confirmación

1. Criterio de unicidad de `cliente_id` y tratamiento de IDs repetidos.
2. Rango válido de `edad` y tratamiento de valores imposibles.
3. Interpretación de los 5 ceros en `edad`.
4. Categoría adicional no listada en `genero` (aprox. 489 registros).
5. Conjunto oficial de valores permitidos para `genero`.
6. Política de nulos en `fecha_registro` (imputar, marcar o excluir).
7. Tratamiento de los 2 duplicados exactos.
8. Si se conservan los valores originales en columnas auxiliares para trazabilidad.

### 2.7 Restricciones y Buenas Prácticas

- No usar `cliente_id` como clave primaria sin resolver su unicidad.
- No eliminar outliers de `edad` sin criterio documentado.
- No agrupar categorías de `genero` sin validación de negocio.
- No imputar nulos en `fecha_registro` sin decisión documentada.
- No modificar los datos originales sin conservar una copia o registro de cambios.
- No eliminar duplicados sin antes confirmar que no son registros legítimos.

### 2.8 Entregables Esperados

1. Dataset limpio con `cliente_id` con unicidad documentada, `edad` en rango válido, `genero` normalizado y `fecha_registro` tipada.
2. Registro de cambios aplicados.
3. Informe de validación con las comprobaciones realizadas.
4. Documentación de decisiones tomadas, especialmente sobre `cliente_id`, `edad` y `genero`.
5. Copia del dataset original sin modificaciones.

### 2.9 Conclusión

La calidad inicial del dataset es **aceptable en completitud, pero con problemas serios de integridad**. A diferencia de `campañas`, aquí no basta con normalizar formatos: hay **valores imposibles en `edad`**, **codificación inconsistente en `genero`**, **`cliente_id` que no es único** y **nulos en `fecha_registro`**. Antes de usar esta tabla para análisis o para unirla con otras, hay que resolver al menos esos cuatro puntos y documentar las decisiones.

[⬆ Volver al índice de tablas](#índice-de-tablas)

---

## 3. Tabla: `devoluciones`

**Última actualización:** 2026-11-13
**Responsable:** Alejandro Hernández Rodríguez
**Origen de datos:** Archivo `devoluciones.csv`

### 3.1 Descripción General y Alcance

Este documento aplica a la tabla **“devoluciones”**, compuesta por:

- **5.558 filas**
- **5 columnas**
- **0 valores nulos**
- **0 filas duplicadas**
- **0 columnas constantes**
- **2 columnas 100 % únicas:** `devolucion_id` y `linea_id`

La tabla es la más limpia a nivel estructural de las tres documentadas hasta ahora (sin nulos ni duplicados, con clave primaria válida). Sin embargo, presenta **riesgos de codificación** en `talla` y `motivo`, y un **riesgo de integridad** en `linea_id` por la mezcla de rangos de identificadores.

### 3.2 Inventario y Calidad Inicial

#### 3.2.1 Inventario de columnas

| Columna | Tipo detectado | Observación inicial |
|---|---|---|
| `devolucion_id` | Numérico entero | **Clave primaria válida.** 5.558 valores únicos, rango continuo 700.001–705.558. |
| `linea_id` | Numérico entero | 100 % único, pero **mezcla dos rangos de IDs** (≈900.000–920.000 y ≈2.000.000). |
| `fecha_devolucion` | Texto | 79 valores únicos. Debe convertirse a fecha. Concentración alta en julio de 2024. |
| `talla` | Texto | **29 valores únicos.** Excesivo para tallas estándar. Probables variantes de codificación. |
| `motivo` | Texto | 8 valores únicos. Revisar 3 categorías no listadas y unificar codificación. |

#### 3.2.2 Resumen de calidad

| Característica | Valor |
|---|---|
| Filas | 5.558 |
| Columnas | 5 |
| Valores nulos | 0 |
| Filas duplicadas exactas | 0 |
| Columnas constantes | 0 |
| Columnas 100 % únicas | 2 (`devolucion_id`, `linea_id`) |
| Memoria | ~1,14 MB |

### 3.3 Hallazgos de Calidad

#### 3.3.1 Puntos fuertes

- Sin valores nulos en ninguna columna.
- Sin filas duplicadas.
- Sin columnas constantes.
- `devolucion_id` es una clave primaria válida: 5.558 valores únicos para 5.558 filas, rango continuo, sin ceros ni negativos.
- `linea_id` es 100 % único (con matices de rango, ver abajo).
- `fecha_devolucion` tiene solo 79 valores únicos → rango temporal acotado y manejable.
- `motivo` tiene pocas categorías (8), manejable para análisis.

#### 3.3.2 Problemas detectados

1. **`linea_id` mezcla rangos de IDs.** ⚠️
   - Es 100 % único, pero el rango es sospechoso:
     - `min = 900.002`
     - `75 % = 915.206`
     - `max = 2.047.096`
   - La media (918.500) está muy cerca del `75 %`, lo que indica que la gran mayoría de `linea_id` están en el rango 900.000–920.000, pero hay un grupo pequeño con IDs en torno a 2.000.000.
   - **Implicación:** parecen convivir dos esquemas de identificación distintos en la misma columna (posiblemente líneas de pedido de sistemas o periodos diferentes, o un error de carga). Aunque es único, no se debe asumir que todos los IDs pertenecen al mismo esquema.

2. **`talla` tiene 29 valores únicos.** ⚠️
   - 29 categorías es excesivo para una columna de tallas; el conjunto estándar suele ser de ~10–15 valores.
   - El top 5 (`M`, `L`, `S`, `XL`, `XS`) suma 3.380 registros de 5.558 → quedan 2.178 registros en 24 categorías no listadas.
   - **Implicación:** probablemente haya variantes de codificación (`M` vs `m` vs `Mediana` vs `Medium`, `XL` vs `Xl`, etc.). Sin normalizar, cualquier análisis por talla es inválido.

3. **`motivo` con 3 categorías no listadas.**
   - El top 5 mostrado suma 5.055 registros. Quedan 503 registros en 3 categorías no listadas.
   - Los motivos actuales mezclan estilos (`talla incorrecta` vs `cambió de opinión`) y conviene revisar espacios, mayúsculas y acentos.
   - **Implicación:** puede haber variantes accidentales de motivos existentes o motivos legítimos adicionales.

4. **`fecha_devolucion` está como texto.** ⚠️
   - Tipo detectado: `str`, no fecha.
   - 79 valores únicos; el top 5 concentra 4 días consecutivos de julio de 2024 (232–274 devoluciones/día).
   - **Implicación:** no se puede ordenar, calcular antigüedad de la devolución ni validar rangos temporales.

5. **Posible concentración temporal en `fecha_devolucion`.**
   - Más de 1.200 devoluciones en 4 días puede ser legítimo (pico post-rebajas) o indicar un problema de registro.
   - No es un error confirmado, pero conviene revisar la distribución temporal completa de los 79 valores únicos.

6. **`devolucion_id` con prefijo fijo.**
   - Rango 700.001–705.558, continuo, sin huecos visibles. Es un ID sintético o de sistema. No es un problema, pero conviene confirmar que no se reutiliza ni se recicla.

### 3.4 Consideraciones para la Limpieza

#### 3.4.1 `devolucion_id`

**Acción prevista:** validar como clave primaria. No requiere transformación.

Consideraciones:

- Confirmar unicidad y ausencia de nulos.
- Mantener como entero.
- Confirmar que no se reutiliza ni se recicla.

**Resultado esperado:** `devolucion_id` único y no nulo, sin cambios.

#### 3.4.2 `linea_id`

**Acción prevista:** investigar la mezcla de rangos antes de usarlo como referencia.

Consideraciones:

- Separar el rango 900.000–920.000 del grupo ~2.000.000 y revisar su origen.
- Decidir si es legítimo (dos orígenes) o error de carga.
- Documentar la decisión antes de eliminar o marcar filas.
- No eliminar outliers sin criterio.

**Resultado esperado:** criterio claro sobre `linea_id` y tratamiento documentado.

#### 3.4.3 `fecha_devolucion`

**Acción prevista:** convertir a fecha y validar rangos.

Consideraciones:

- Convertir a tipo fecha.
- Validar que no haya fechas futuras ni imposibles.
- Revisar la distribución temporal completa de los 79 valores únicos.
- No modificar las fechas originales sin dejar trazabilidad.

**Resultado esperado:** columna fecha válida y rangos coherentes.

#### 3.4.4 `talla`

**Acción prevista:** normalizar a un conjunto cerrado de categorías.

Consideraciones:

- Revisar las 29 categorías y detectar variantes de codificación.
- Unificar mayúsculas/minúsculas, espacios y sinónimos.
- Confirmar con negocio la lista oficial de tallas permitidas.
- No agrupar categorías sin validación de negocio.

**Resultado esperado:** categorías coherentes y análisis por talla válido.

#### 3.4.5 `motivo`

**Acción prevista:** revisar y unificar codificación.

Consideraciones:

- Revisar las 3 categorías no listadas.
- Unificar mayúsculas, espacios y acentos.
- Confirmar la lista oficial de motivos permitidos.
- No agrupar categorías sin validación de negocio.

**Resultado esperado:** categorías coherentes y sin variantes accidentales.

### 3.5 Reglas de Validación Propuestas

Antes de dar por limpio el dataset, comprobar:

| Validación | Criterio esperado |
|---|---|
| `devolucion_id` único | 5.558 valores únicos para 5.558 filas |
| `devolucion_id` no nulo | 0 nulos |
| `linea_id` sin rangos mixtos | Criterio documentado y aplicado |
| `linea_id` no nulo | 0 nulos |
| `fecha_devolucion` válida | Todas las fechas interpretables |
| `fecha_devolucion` sin futuras | 0 fechas futuras |
| `talla` normalizada | Solo categorías del conjunto oficial |
| `motivo` normalizado | Solo categorías del conjunto oficial |
| Duplicados exactos | 0 duplicados |
| Nulos en columnas clave | 0 nulos |

### 3.6 Decisiones Pendientes de Confirmación

1. Origen y tratamiento de los `linea_id` en el rango ~2.000.000.
2. Conjunto oficial de tallas permitidas.
3. Conjunto oficial de motivos permitidos.
4. Categorías no listadas en `talla` (24) y `motivo` (3).
5. Criterio de análisis temporal de `fecha_devolucion` (rango completo, picos, estacionalidad).
6. Si se conservan los valores originales en columnas auxiliares para trazabilidad.
7. Si se renombran columnas o se mantienen los nombres originales.

### 3.7 Restricciones y Buenas Prácticas

- No asumir que `linea_id` pertenece a un solo esquema sin investigar los rangos.
- No agrupar categorías de `talla` o `motivo` sin validación de negocio.
- No eliminar outliers de `linea_id` sin criterio documentado.
- No convertir `fecha_devolucion` sin validar fechas imposibles.
- No modificar los datos originales sin conservar una copia o registro de cambios.

### 3.8 Entregables Esperados

1. Dataset limpio con `devolucion_id` validado, `linea_id` con criterio documentado, `fecha_devolucion` tipada y `talla`/`motivo` normalizados.
2. Registro de cambios aplicados.
3. Informe de validación con las comprobaciones realizadas.
4. Documentación de decisiones tomadas, especialmente sobre `linea_id`, `talla` y `motivo`.
5. Copia del dataset original sin modificaciones.

### 3.9 Conclusión

La calidad inicial del dataset es **buena a nivel estructural, media a nivel de dominio de valores**. `devoluciones` no tiene nulos ni duplicados y tiene una clave primaria clara, lo que la hace más robusta que `clientes`. Sin embargo, **`talla` con 29 categorías** y **`linea_id` con dos rangos de IDs** requieren investigación antes de usarla en análisis o unirla con otras tablas. Con esas correcciones documentadas, la tabla queda apta para análisis.

[⬆ Volver al índice de tablas](#índice-de-tablas)

---

## 4. Tabla: `lineas_pedido`

**Última actualización:** 2026-11-13
**Responsable:** Alejandro Hernández Rodríguez
**Origen de datos:** Archivo `lineas_pedido.csv`

### 4.1 Descripción General y Alcance

Este documento aplica a la tabla **“lineas_pedido”**, compuesta por:

- **20.140 filas**
- **7 columnas**
- **0 valores nulos**
- **139 filas duplicadas** exactas (0,69 %)
- **0 columnas constantes**
- **0 columnas 100 % únicas** (⚠️ ni siquiera `linea_id`)

A diferencia de las tablas anteriores, `lineas_pedido` tiene un volumen importante (20.140 filas) y presenta **problemas de integridad claros** (`linea_id` no único, cantidades inválidas, duplicados) además de **problemas de codificación** en `talla`, `precio_unitario` y `descuento_pct`. Es una tabla crítica porque conecta pedidos con productos, así que sus errores se propagan a los análisis de ventas.

### 4.2 Inventario y Calidad Inicial

#### 4.2.1 Inventario de columnas

| Columna | Tipo detectado | Observación inicial |
|---|---|---|
| `linea_id` | Numérico entero | **No es único.** Rango 900.001–920.000 (20.000 posibles) frente a 20.140 filas → al menos 140 IDs repetidos. |
| `pedido_id` | Numérico entero | Rango 500.001–508.000 (8.000 posibles). ~2,5 líneas por pedido. Sin nulos. |
| `producto_id` | Numérico entero | Rango 1001–1400 (400 posibles). Sin nulos. |
| `talla` | Texto | **29 valores únicos.** Mezcla `S` con `Talla S` y tallas numéricas (`39`). Inconsistente. |
| `cantidad` | Numérico entero | **Valores inválidos:** mínimo -1, máximo 3, 6 negativos y 9 ceros. |
| `precio_unitario` | Texto | **Texto con símbolo `€` y coma decimal** (`49,99 €`). 389 valores únicos. |
| `descuento_pct` | Texto | **Formatos mezclados:** `20%`, `0.2`, `0%`, `0.0`, `10`, `30`, `10%`. 18 valores únicos. |

#### 4.2.2 Resumen de calidad

| Característica | Valor |
|---|---|
| Filas | 20.140 |
| Columnas | 7 |
| Valores nulos | 0 |
| Filas duplicadas exactas | 139 (0,69 %) |
| Columnas constantes | 0 |
| Columnas 100 % únicas | 0 |
| Memoria | ~4,74 MB |

### 4.3 Hallazgos de Calidad

#### 4.3.1 Puntos fuertes

- Sin valores nulos en ninguna columna.
- Sin columnas constantes.
- `pedido_id` y `producto_id` tienen rangos acotados y plausibles.
- `linea_id` tiene un rango acotado (900.001–920.000), lo que facilita la validación.
- `cantidad` tiene distribución concentrada en 1 unidad (media 1,17), típica de líneas de pedido de moda.

#### 4.3.2 Problemas detectados

1. **`linea_id` no es único.** ⚠️
   - El rango 900.001–920.000 ofrece 20.000 valores posibles, pero hay 20.140 filas → **al menos 140 IDs repetidos**.
   - Coincide con los 139 duplicados exactos detectados (probablemente 140 IDs repetidos, de los cuales 139 son duplicados exactos y 1 es un ID repetido con datos distintos).
   - **Implicación:** `linea_id` no puede usarse como clave primaria tal cual. Hay que investigar si los IDs repetidos son duplicados exactos (a eliminar) o registros distintos que necesitan un identificador compuesto.

2. **139 filas duplicadas exactas (0,69 %).** ⚠️
   - Los duplicados muestran un patrón muy claro: las filas originales aparecen en índices bajos (63, 78, 530, 549…) y sus copias en índices ~20.000 (20017, 20081, 20026, 20036…).
   - Esto sugiere que **el final del dataset contiene un bloque duplicado del inicio**, posiblemente por una carga repetida o una concatenación parcial.
   - **Implicación:** es un problema de carga, no de negocio. Probablemente se puedan eliminar los duplicados exactos, pero hay que confirmar el origen.

3. **`cantidad` contiene valores inválidos.** ⚠️
   - 6 valores negativos (mínimo -1).
   - 9 valores en cero.
   - En una línea de pedido, una cantidad negativa o cero no tiene sentido (no es una devolución, porque esa tabla es `devoluciones`).
   - **Implicación:** esos 15 registros deben revisarse: probablemente sean errores de captura y deban marcarse como nulos o excluirse.

4. **`precio_unitario` está como texto con `€` y coma decimal.** ⚠️
   - Formato: `49,99 €`, `12,35 €`, `80,46 €`…
   - 389 valores únicos para 400 productos → plausible.
   - **Implicación:** no se puede calcular importe, ticket medio ni agregaciones sin normalizarlo a numérico.

5. **`descuento_pct` mezcla formatos incompatibles.** ⚠️
   - Valores observados:
     - Con `%`: `20%`, `0%`, `10%`, `30%`
     - Como fracción decimal: `0.2`, `0.0`
     - Como número desnudo: `10`, `30`
   - 18 valores únicos.
   - **Implicación:** `0.2` significa 20 %, pero `10` probablemente significa 10 % (no 0,10). Sin normalizar, cualquier cálculo de descuento medio o importe con descuento es inválido.

6. **`talla` con 29 valores únicos e inconsistentes.** ⚠️
   - El top 5 (`M`, `L`, `S`, `XL`, `XS`) suma 12.730 registros de 20.140 → quedan **7.410 registros en 24 categorías no listadas**.
   - Los duplicados muestran explícitamente la inconsistencia: `S` vs `Talla S`, y tallas numéricas (`39`) mezcladas con letras.
   - Es la **misma columna problemática que en `devoluciones`**, lo que sugiere que el problema es sistémico en el origen.
   - **Implicación:** sin normalizar, no se pueden cruzar tallas entre `lineas_pedido` y `devoluciones`.

7. **`pedido_id` con rango acotado — verificar cardinalidad.**
   - Rango 500.001–508.000 → 8.000 pedidos posibles.
   - 20.140 líneas / 8.000 pedidos ≈ 2,5 líneas por pedido, plausible para moda.
   - No es un problema, pero conviene confirmar que no hay pedidos con cardinalidad anómala (1 línea o 50 líneas) que puedan indicar errores.

8. **`producto_id` con rango acotado — verificar cardinalidad.**
   - Rango 1001–1400 → 400 productos posibles.
   - 20.140 líneas / 400 productos ≈ 50 líneas por producto, plausible.
   - No es un problema, pero conviene confirmar que todos los IDs del rango existen en `productos`.

### 4.4 Consideraciones para la Limpieza

#### 4.4.1 `linea_id`

**Acción prevista:** investigar la unicidad antes de tratarlo como clave.

Consideraciones:

- Confirmar cuántos IDs están repetidos y si las repeticiones son duplicados exactos o registros distintos.
- Si todas las repeticiones son duplicados exactos, eliminarlos resuelve la unicidad.
- Si hay IDs repetidos con datos distintos, definir un identificador compuesto (p. ej. `linea_id` + `pedido_id`) o renumerar.
- No usar `linea_id` como clave primaria hasta resolverlo.

**Resultado esperado:** `linea_id` único, o criterio documentado de clave compuesta.

#### 4.4.2 `pedido_id`

**Acción prevista:** validar cardinalidad y consistencia.

Consideraciones:

- Confirmar que todos los `pedido_id` existen en la tabla `pedidos`.
- Revisar pedidos con cardinalidad anómala (muy pocas o demasiadas líneas).
- No es necesario transformarlo; solo validarlo.

**Resultado esperado:** `pedido_id` consistente con la tabla `pedidos`.

#### 4.4.3 `producto_id`

**Acción prevista:** validar consistencia con la tabla `productos`.

Consideraciones:

- Confirmar que todos los `producto_id` del rango 1001–1400 existen en `productos`.
- Revisar si hay productos con muy pocas o demasiadas líneas.

**Resultado esperado:** `producto_id` consistente con `productos`.

#### 4.4.4 `talla`

**Acción prevista:** normalizar a un conjunto cerrado de categorías.

Consideraciones:

- Revisar las 29 categorías y detectar variantes (`S` vs `Talla S`, tallas numéricas vs letras).
- Unificar mayúsculas/minúsculas y espacios.
- Confirmar con negocio la lista oficial de tallas permitidas.
- Alinear la normalización con la de `devoluciones` para permitir cruces.
- No agrupar categorías sin validación de negocio.

**Resultado esperado:** categorías coherentes y alineadas con `devoluciones`.

#### 4.4.5 `cantidad`

**Acción prevista:** tratar valores inválidos.

Consideraciones:

- Revisar los 6 negativos y los 9 ceros.
- Decidir si se marcan como nulos, se excluyen o se corrigen.
- Confirmar que la cantidad positiva (1–3) es plausible para el negocio.

**Resultado esperado:** `cantidad` con valores > 0 y criterio documentado.

#### 4.4.6 `precio_unitario`

**Acción prevista:** normalizar a valor numérico.

Consideraciones:

- Eliminar el símbolo `€`.
- Eliminar espacios.
- Cambiar coma decimal por punto.
- Convertir a tipo numérico.
- Validar que todos los valores sean > 0.

**Resultado esperado:** columna `precio_unitario` numérica y positiva.

#### 4.4.7 `descuento_pct`

**Acción prevista:** normalizar a un único formato.

Consideraciones:

- Unificar todos los valores a porcentaje entero (0–100) o a fracción decimal (0,0–1,0), pero no mezclar.
- Interpretar `0.2` como 20 %, `10` como 10 %, `10%` como 10 %.
- Documentar la decisión de formato.
- Validar que todos los valores estén en el rango permitido.

**Resultado esperado:** columna `descuento_pct` numérica con formato único.

#### 4.4.8 Duplicados

**Acción prevista:** investigar el origen de los 139 duplicados exactos.

Consideraciones:

- Confirmar el patrón observado (bloque duplicado al final del dataset).
- Decidir si se eliminan los duplicados exactos.
- Revisar si hay IDs repetidos con datos distintos (no exactos) y definir su tratamiento.
- Documentar la decisión.

**Resultado esperado:** sin duplicados no justificados y criterio documentado.

### 4.5 Reglas de Validación Propuestas

Antes de dar por limpio el dataset, comprobar:

| Validación | Criterio esperado |
|---|---|
| `linea_id` único | 0 duplicados tras definir criterio |
| `linea_id` no nulo | 0 nulos |
| `pedido_id` consistente | Todos existen en `pedidos` |
| `producto_id` consistente | Todos existen en `productos` |
| `cantidad` válida | Todos los valores > 0 |
| `precio_unitario` numérico | 0 errores de conversión |
| `precio_unitario` positivo | Todos los valores > 0 |
| `descuento_pct` numérico | 0 errores de conversión |
| `descuento_pct` en rango | Todos los valores entre 0 y 100 (o 0 y 1) |
| `talla` normalizada | Solo categorías del conjunto oficial |
| Duplicados exactos | 0 duplicados no justificados |
| Nulos en columnas clave | 0 nulos |

### 4.6 Decisiones Pendientes de Confirmación

1. Origen de los 139 duplicados exactos (¿bloque duplicado al final?).
2. Criterio de unicidad de `linea_id` y tratamiento de IDs repetidos.
3. Tratamiento de los 15 valores inválidos en `cantidad` (6 negativos + 9 ceros).
4. Formato objetivo de `descuento_pct`: porcentaje (0–100) o fracción (0–1).
5. Conjunto oficial de tallas permitidas y alineación con `devoluciones`.
6. Política de tratamiento de duplicados no exactos (si existen).
7. Si se conservan los valores originales en columnas auxiliares para trazabilidad.
8. Si se renombran columnas o se mantienen los nombres originales.

### 4.7 Restricciones y Buenas Prácticas

- No usar `linea_id` como clave primaria sin resolver su unicidad.
- No eliminar duplicados sin antes confirmar el origen del bloque duplicado.
- No normalizar `descuento_pct` sin decidir el formato objetivo.
- No normalizar `talla` de forma aislada: alinear con `devoluciones`.
- No eliminar valores inválidos de `cantidad` sin criterio documentado.
- No modificar los datos originales sin conservar una copia o registro de cambios.

### 4.8 Entregables Esperados

1. Dataset limpio con `linea_id` con unicidad documentada, `cantidad` válida, `precio_unitario` y `descuento_pct` numéricos, `talla` normalizada y duplicados tratados.
2. Registro de cambios aplicados.
3. Informe de validación con las comprobaciones realizadas.
4. Documentación de decisiones tomadas, especialmente sobre `linea_id`, `descuento_pct` y duplicados.
5. Copia del dataset original sin modificaciones.

### 4.9 Conclusión

La calidad inicial del dataset es **aceptable en completitud, pero con problemas de integridad y de codificación**. No tiene nulos, pero **`linea_id` no es único**, hay **139 duplicados exactos** con un patrón sospechoso (bloque duplicado al final), **`cantidad` tiene 15 valores inválidos**, **`precio_unitario` y `descuento_pct` están como texto con formatos mezclados** y **`talla` repite la inconsistencia de `devoluciones`**. Es una tabla crítica porque conecta pedidos con productos, así que sus errores se propagan a los análisis de ventas. Antes de usarla, hay que resolver la unicidad de `linea_id`, los duplicados, las cantidades inválidas y normalizar las tres columnas de texto.

[⬆ Volver al índice de tablas](#índice-de-tablas)

---

## 5. Tabla: `pedidos`

**Última actualización:** 2026-11-13
**Responsable:** Alejandro Hernández Rodríguez
**Origen de datos:** Archivo `pedidos.csv`

### 5.1 Descripción General y Alcance

Este documento aplica a la tabla **“pedidos”**, compuesta por:

- **8.000 filas**
- **7 columnas**
- **1.179 valores nulos** en `campana_id` (14,74 %)
- **0 filas duplicadas**
- **0 columnas constantes** (a nivel global, pero `campana_id` es constante en sus valores no nulos ⚠️)
- **1 columna 100 % única:** `pedido_id` (clave primaria válida)

La tabla es la **cabecera de pedidos** y conecta con `clientes`, `campañas`, `canal`, `ciudad` y `lineas_pedido`. Aunque está limpia en nulos (salvo `campana_id`) y duplicados, presenta **dos problemas críticos de integridad referencial**: `campana_id` con valor único y nulos, y `cliente_id` que no es único en la tabla `clientes`.

### 5.2 Inventario y Calidad Inicial

#### 5.2.1 Inventario de columnas

| Columna | Tipo detectado | Observación inicial |
|---|---|---|
| `pedido_id` | Numérico entero | **Clave primaria válida.** 8.000 valores únicos, rango continuo 500.001–508.000. |
| `cliente_id` | Numérico entero | Rango 1–4.970. Coincide con `clientes`, pero **`cliente_id` no es único allí** → riesgo de fan-out al unir. |
| `fecha_pedido` | Texto | 81 valores únicos. Concentración alta en julio de 2024. Debe convertirse a fecha. |
| `campana_id` | Numérico decimal | **1.179 nulos (14,74 %).** En los no nulos, **valor constante = 1** (std = 0, min = max = 1). ⚠️ |
| `canal` | Texto | 4 categorías: `instagram`, `google`, `email`, `directo`. |
| `ciudad` | Texto | 31 valores únicos. Debe ser consistente con `clientes`. |
| `metodo_pago` | Texto | 3 categorías limpias: `tarjeta`, `paypal`, `bizum`. |

#### 5.2.2 Resumen de calidad

| Característica | Valor |
|---|---|
| Filas | 8.000 |
| Columnas | 7 |
| Valores nulos | 1.179 en `campana_id` (14,74 %) |
| Filas duplicadas exactas | 0 |
| Columnas constantes | 0 (pero `campana_id` es constante en sus no nulos) |
| Columnas 100 % únicas | 1 (`pedido_id`) |
| Memoria | ~2,18 MB |

### 5.3 Hallazgos de Calidad

#### 5.3.1 Puntos fuertes

- `pedido_id` es una clave primaria válida: 8.000 valores únicos, rango continuo 500.001–508.000, sin nulos.
- Sin filas duplicadas.
- Sin columnas constantes a nivel global.
- `canal` tiene 4 categorías limpias y bien definidas.
- `metodo_pago` tiene solo 3 categorías limpias (`tarjeta`, `paypal`, `bizum`), sin variantes.
- `ciudad` no tiene nulos y su top 5 es coherente.
- El rango de `pedido_id` (500.001–508.000) coincide con el rango de `pedido_id` en `lineas_pedido`, lo que facilita la relación.

#### 5.3.2 Problemas detectados

1. **`campana_id` tiene 1.179 nulos (14,74 %).** ⚠️
   - Es la única columna con nulos en la tabla.
   - 8.000 – 1.179 = 6.821 pedidos con `campana_id` no nulo.
   - **Implicación:** hay que decidir si los nulos significan “pedido sin campaña”, “campaña desconocida” o “error de captura”. No es lo mismo imputar que marcar.

2. **`campana_id` es constante = 1 en todos los valores no nulos.** ⚠️⚠️
   - `std = 0`, `min = 1`, `25 % = 1`, `50 % = 1`, `75 % = 1`, `max = 1`.
   - En la tabla `campañas` existían **4 campañas (IDs 1–4)**, pero en `pedidos` solo aparece la campaña `1`.
   - **Implicación:** esto es un **problema serio de atribución de campañas**. O bien:
     - todos los pedidos se atribuyeron por error a la campaña 1,
     - la columna se rellenó con un placeholder `1` en la carga,
     - o el sistema de atribución solo registra una campaña.
   - Cualquier análisis de rendimiento por campaña es inválido con este dato.
   - Además, `campana_id` está como `float64` (por los nulos), no como entero, lo que complica su uso como clave.

3. **`cliente_id` no es único en `clientes` → riesgo de fan-out al unir.** ⚠️
   - En `pedidos`, `cliente_id` va de 1 a 4.970.
   - En `clientes`, había 5.010 filas pero `cliente_id` **no era único** (ya documentado).
   - **Implicación:** si se hace un `JOIN` por `cliente_id`, un pedido puede multiplicarse por los clientes duplicados. Hay que resolver primero la unicidad en `clientes` o usar un identificador compuesto.

4. **`fecha_pedido` está como texto.** ⚠️
   - Tipo detectado: `str`, no fecha.
   - 81 valores únicos; el top 5 concentra 5 días consecutivos de julio de 2024 (238–268 pedidos/día).
   - **Implicación:** no se puede ordenar, calcular antigüedad del pedido, ni validar rangos temporales.

5. **Posible concentración temporal en `fecha_pedido`.**
   - Más de 1.200 pedidos en 5 días puede ser legítimo (pico de rebajas o campaña) o indicar un problema de registro.
   - No es un error confirmado, pero conviene revisar la distribución temporal completa de los 81 valores únicos.

6. **`canal` incluye `directo`, que no existe en `campañas`.**
   - En `campañas`, `canal` tenía solo `instagram`, `email`, `google`.
   - En `pedidos`, aparece además `directo` (1.576 pedidos).
   - **Implicación:** es plausible (pedidos orgánicos sin campaña), pero hay que confirmar que `directo` no es una variante de otro canal ni un error de captura. También hay que alinear la lista oficial de canales entre `campañas` y `pedidos`.

7. **`ciudad` debe ser consistente con `clientes`.**
   - Ambos tienen 31 valores únicos y top 5 similar.
   - No es un problema confirmado, pero conviene validar que las 31 categorías sean exactamente las mismas en ambas tablas (mismos acentos, mayúsculas y variantes).

8. **`pedido_id` con prefijo fijo.**
   - Rango 500.001–508.000, continuo. Es un ID sintético o de sistema. No es un problema, pero conviene confirmar que no se reutiliza ni se recicla.

9. **Riesgo de integridad referencial con `lineas_pedido`.**
   - `lineas_pedido` tiene 20.140 líneas para 8.000 pedidos (≈2,5 líneas/pedido), lo cual es plausible.
   - Pero en `lineas_pedido` ya se detectaron 139 duplicados exactos. Si esos duplicados corresponden a pedidos existentes, el conteo de líneas por pedido queda inflado.
   - **Implicación:** la limpieza de `lineas_pedido` afecta directamente a la validez de `pedidos`.

### 5.4 Consideraciones para la Limpieza

#### 5.4.1 `pedido_id`

**Acción prevista:** validar como clave primaria. No requiere transformación.

Consideraciones:

- Confirmar unicidad y ausencia de nulos.
- Mantener como entero.
- Confirmar que no se reutiliza ni se recicla.

**Resultado esperado:** `pedido_id` único y no nulo, sin cambios.

#### 5.4.2 `cliente_id`

**Acción prevista:** validar la relación con `clientes` antes de unir.

Consideraciones:

- Resolver primero la unicidad de `cliente_id` en `clientes` (pendiente).
- Confirmar que todos los `cliente_id` de `pedidos` existen en `clientes`.
- Definir la estrategia de unión (por `cliente_id` solo si es único, o por clave compuesta).
- Documentar el riesgo de fan-out.

**Resultado esperado:** relación `pedidos`–`clientes` validada y sin fan-out.

#### 5.4.3 `fecha_pedido`

**Acción prevista:** convertir a fecha y validar rangos.

Consideraciones:

- Convertir a tipo fecha.
- Validar que no haya fechas futuras ni imposibles.
- Revisar la distribución temporal completa de los 81 valores únicos.
- No modificar las fechas originales sin dejar trazabilidad.

**Resultado esperado:** columna fecha válida y rangos coherentes.

#### 5.4.4 `campana_id`

**Acción prevista:** investigar el valor constante `1` y los nulos antes de decidir tratamiento.

Consideraciones:

- **Investigar por qué todos los valores no nulos son `1`.** Confirmar con negocio si es un error de carga, un placeholder o una limitación del sistema de atribución.
- Confirmar si las campañas 2, 3 y 4 de `campañas` deberían tener pedidos asociados.
- Decidir la política de nulos: imputar, marcar como “sin campaña” o excluir.
- Decidir si `campana_id` debe convertirse a entero (con un valor centinela para nulos) o mantenerse como `float` con nulos.
- **No usar `campana_id` para análisis de rendimiento por campaña hasta resolver el problema.**

**Resultado esperado:** `campana_id` con valores válidos y política de nulos documentada.

#### 5.4.5 `canal`

**Acción prevista:** validar coherencia con `campañas`.

Consideraciones:

- Confirmar la lista oficial de canales permitidos.
- Decidir si `directo` es una categoría legítima (pedidos orgánicos) o un error.
- Alinear la codificación con la de `campañas`.
- No agrupar categorías sin validación de negocio.

**Resultado esperado:** `canal` con categorías coherentes entre `pedidos` y `campañas`.

#### 5.4.6 `ciudad`

**Acción prevista:** validar consistencia con `clientes`.

Consideraciones:

- Confirmar que las 31 categorías son exactamente las mismas en `pedidos` y `clientes`.
- Revisar acentos, mayúsculas y espacios.
- Revisar valores residuales tipo “N/A”, “-”, “Desconocido”.

**Resultado esperado:** `ciudad` coherente entre `pedidos` y `clientes`.

#### 5.4.7 `metodo_pago`

**Acción prevista:** mantener y validar.

Consideraciones:

- Confirmar que las 3 categorías (`tarjeta`, `paypal`, `bizum`) son las oficiales.
- Revisar espacios y mayúsculas/minúsculas.
- No requiere normalización adicional si están limpias.

**Resultado esperado:** `metodo_pago` con categorías válidas y sin variantes.

#### 5.4.8 Duplicados

**Acción prevista:** mantener la validación de duplicados.

Consideraciones:

- Actualmente no hay duplicados exactos, pero conviene revalidarlos después de normalizar `fecha_pedido` y `canal`.
- Revisar duplicados por `pedido_id` (debería ser 0).

**Resultado esperado:** sin duplicados por `pedido_id`.

### 5.5 Reglas de Validación Propuestas

Antes de dar por limpio el dataset, comprobar:

| Validación | Criterio esperado |
|---|---|
| `pedido_id` único | 8.000 valores únicos para 8.000 filas |
| `pedido_id` no nulo | 0 nulos |
| `cliente_id` consistente | Todos existen en `clientes` (tras resolver su unicidad) |
| `fecha_pedido` válida | Todas las fechas interpretables |
| `fecha_pedido` sin futuras | 0 fechas futuras |
| `campana_id` sin constante | Más de un valor distinto en los no nulos |
| Política de nulos en `campana_id` | Decisión documentada y aplicada |
| `canal` válido | Solo categorías del conjunto oficial |
| `ciudad` coherente | Mismas 31 categorías que en `clientes` |
| `metodo_pago` válido | Solo `tarjeta`, `paypal`, `bizum` |
| Duplicados exactos | 0 duplicados |
| Duplicados por `pedido_id` | 0 duplicados |
| Nulos en columnas clave | 0 nulos en `pedido_id` |

### 5.6 Decisiones Pendientes de Confirmación

1. Origen del valor constante `1` en `campana_id`.
2. Política de nulos en `campana_id` (imputar, marcar o excluir).
3. Si `campana_id` debe ser entero con centinela o `float` con nulos.
4. Si `directo` es una categoría legítima de `canal` o un error.
5. Lista oficial de canales permitidos, alineada con `campañas`.
6. Resolución de la unicidad de `cliente_id` en `clientes` antes de unir.
7. Tratamiento de los 139 duplicados de `lineas_pedido` que afectan al conteo por pedido.
8. Si se conservan los valores originales en columnas auxiliares para trazabilidad.

### 5.7 Restricciones y Buenas Prácticas

- No usar `campana_id` para análisis de rendimiento por campaña hasta resolver el valor constante.
- No unir `pedidos` con `clientes` por `cliente_id` sin resolver antes la unicidad en `clientes`.
- No eliminar outliers de `fecha_pedido` sin criterio documentado.
- No asumir que `directo` es una categoría oficial sin validación de negocio.
- No modificar los datos originales sin conservar una copia o registro de cambios.

### 5.8 Entregables Esperados

1. Dataset limpio con `pedido_id` validado, `fecha_pedido` tipada, `campana_id` con política de nulos aplicada y valores no constantes, `canal` y `ciudad` alineados con sus tablas de referencia.
2. Registro de cambios aplicados.
3. Informe de validación con las comprobaciones realizadas.
4. Documentación de decisiones tomadas, especialmente sobre `campana_id`, `canal` y la unión con `clientes`.
5. Copia del dataset original sin modificaciones.

### 5.9 Conclusión

La calidad inicial del dataset es **buena en estructura, pero con dos problemas críticos de integridad**. `pedidos` tiene una clave primaria válida, sin duplicados y con columnas categóricas limpias. Sin embargo, **`campana_id` tiene 1.179 nulos (14,74 %) y es constante = 1 en todos los valores no nulos**, lo que invalida cualquier análisis por campaña; y **`cliente_id` no es único en `clientes`**, lo que genera riesgo de fan-out al unir. Además, `fecha_pedido` está como texto y hay que alinear `canal` y `ciudad` con sus tablas de referencia. Antes de usar esta tabla, hay que resolver `campana_id` y la unicidad de `cliente_id`, y normalizar `fecha_pedido`.

[⬆ Volver al índice de tablas](#índice-de-tablas)

---

## 6. Tabla: `productos`

**Última actualización:** 2026-11-13
**Responsable:** Alejandro Hernández Rodríguez
**Origen de datos:** Archivo `productos.csv`

### 6.1 Descripción General y Alcance

Este documento aplica a la tabla **“productos”**, compuesta por:

- **400 filas**
- **7 columnas**
- **12 valores nulos** en `coste_unitario` (3,0 %)
- **0 filas duplicadas**
- **0 columnas constantes**
- **2 columnas 100 % únicas:** `producto_id` y `nombre`

La tabla es el **catálogo de productos** y conecta con `lineas_pedido` (por `producto_id`). Es una tabla pequeña y con clave primaria válida, pero presenta **problemas serios de codificación** en `categoria` y `temporada`, y un **3 % de nulos** en `coste_unitario` que afecta al cálculo de márgenes.

### 6.2 Inventario y Calidad Inicial

#### 6.2.1 Inventario de columnas

| Columna | Tipo detectado | Observación inicial |
|---|---|---|
| `producto_id` | Numérico entero | **Clave primaria válida.** 400 valores únicos, rango continuo 1001–1400. |
| `nombre` | Texto | 400 valores únicos (100 %). Plausible pero conviene confirmar que no es coincidencia. |
| `categoria` | Texto | **35 valores únicos.** Codificación inconsistente: `Vestidos`, `vestido`, `VESTIDOS`, `vestidos`, `camiseta`… |
| `temporada` | Texto | **5 valores únicos, todos son variantes de “Verano 2024”**: `Verano 2024`, `verano`, `SS24`, `Verano24`, `verano 2024`. ⚠️ |
| `coleccion` | Texto | 8 valores únicos. Top 5 coherente (`Mediterráneo`, `Básicos`, `Atelier`, `Denim`, `Noche`). |
| `coste_unitario` | Numérico decimal | **12 nulos (3,0 %).** Sin ceros ni negativos. |
| `precio_base` | Numérico decimal | Sin nulos, ceros ni negativos. Rango 10,36–89,35. |

#### 6.2.2 Resumen de calidad

| Característica | Valor |
|---|---|
| Filas | 400 |
| Columnas | 7 |
| Valores nulos | 12 en `coste_unitario` (3,0 %) |
| Filas duplicadas exactas | 0 |
| Columnas constantes | 0 |
| Columnas 100 % únicas | 2 (`producto_id`, `nombre`) |
| Memoria | ~0,12 MB |

### 6.3 Hallazgos de Calidad

#### 6.3.1 Puntos fuertes

- `producto_id` es una clave primaria válida: 400 valores únicos, rango continuo 1001–1400, sin nulos.
- Sin filas duplicadas.
- Sin columnas constantes.
- `nombre` es 100 % único (400 valores), lo que facilita la identificación de productos.
- `coleccion` tiene solo 8 categorías y su top 5 es coherente.
- `precio_base` está limpio: numérico, sin nulos, sin ceros ni negativos.
- `coste_unitario` es numérico, sin ceros ni negativos (aunque con 12 nulos).
- Relación `coste_unitario` < `precio_base` coherente: el coste máximo (43,47) es menor que el precio máximo (89,35), y el coste mínimo (3,96) es menor que el precio mínimo (10,36).

#### 6.3.2 Problemas detectados

1. **`temporada` es una sola categoría disfrazada de cinco.** ⚠️⚠️
   - Los 5 valores son variantes de “Verano 2024”:
     - `Verano 2024` (171)
     - `verano` (76)
     - `SS24` (72)
     - `Verano24` (44)
     - `verano 2024` (37)
   - La suma es exactamente **400** → **todos los productos son de la misma temporada**, pero codificada de 5 formas distintas.
   - **Implicación:** la columna es, en la práctica, **constante**. Cualquier análisis por temporada es inválido y la columna no aporta información. Hay que normalizarla a un único valor y decidir si se conserva o se elimina.

2. **`categoria` tiene 35 valores únicos con codificación inconsistente.** ⚠️
   - El top 5 muestra el problema: `Vestidos`, `vestido`, `VESTIDOS`, `vestidos`, `camiseta`.
   - Las 4 variantes de “vestidos” suman 77 registros repartidos en 4 categorías distintas.
   - El top 5 suma 97 registros → quedan **303 registros en 30 categorías no listadas**.
   - **Implicación:** sin normalizar, cualquier análisis por categoría es inválido y subestima el peso real de categorías como “vestidos”.

3. **`coste_unitario` tiene 12 nulos (3,0 %).** ⚠️
   - Es la única columna con nulos en la tabla.
   - **Implicación:** el cálculo de márgenes (`precio_base` – `coste_unitario`) fallará en esos 12 productos. Hay que decidir política de nulos: imputar, marcar como “desconocido” o excluir del análisis de márgenes.

4. **`coste_unitario` con mínimo de 3,96.**
   - Un coste de ~4 € es bajo para moda, aunque podría corresponder a accesorios, calcetines o básicos.
   - No es un error confirmado, pero conviene revisar los productos con coste muy bajo para confirmar que es coherente.

5. **`nombre` es 100 % único — confirmar que no es coincidencia.**
   - 400 nombres distintos para 400 productos es plausible en un catálogo de moda (cada producto tiene nombre propio).
   - No es un problema, pero conviene confirmar que no hay duplicados lógicos (p. ej. `Vestido Aura` vs `Vestido Aura ` con espacio).

6. **`categoria` y `temporada` son las mismas columnas problemáticas que en otras tablas.**
   - `talla` en `devoluciones` y `lineas_pedido` también tenía 29 valores inconsistentes.
   - `canal` en `campañas` y `pedidos` también tenía codificación variable.
   - **Implicación:** el problema es **sistémico en el origen**, no aislado de una tabla. Conviene abordarlo de forma transversal con una guía de normalización común.

7. **Relación `producto_id` con `lineas_pedido` — validar integridad referencial.**
   - En `lineas_pedido`, `producto_id` iba de 1001 a 1400 (400 productos posibles).
   - En `productos`, hay exactamente 400 productos con IDs 1001–1400.
   - **Implicación:** la relación parece completa, pero conviene confirmar que **todos los `producto_id` de `lineas_pedido` existen en `productos`** y que **todos los productos del catálogo tienen al menos una línea de pedido** (o documentar los que no).

8. **`coleccion` con 8 valores — revisar las 3 categorías no listadas.**
   - El top 5 suma 265 registros → quedan 135 registros en 3 categorías no listadas.
   - Conviene revisarlas para confirmar que no son variantes de las existentes.

### 6.4 Consideraciones para la Limpieza

#### 6.4.1 `producto_id`

**Acción prevista:** validar como clave primaria. No requiere transformación.

Consideraciones:

- Confirmar unicidad y ausencia de nulos.
- Mantener como entero.
- Confirmar que no se reutiliza ni se recicla.

**Resultado esperado:** `producto_id` único y no nulo, sin cambios.

#### 6.4.2 `nombre`

**Acción prevista:** mantener como identificador descriptivo. No requiere transformación.

Consideraciones:

- Confirmar que no hay duplicados lógicos (espacios, mayúsculas).
- Revisar si algún nombre contiene caracteres problemáticos.
- No usar `nombre` como clave primaria (usar `producto_id`).

**Resultado esperado:** `nombre` único y sin variantes accidentales.

#### 6.4.3 `categoria`

**Acción prevista:** normalizar a un conjunto cerrado de categorías.

Consideraciones:

- Revisar las 35 categorías y detectar variantes (`Vestidos`, `vestido`, `VESTIDOS`, `vestidos`, `camiseta`…).
- Unificar mayúsculas/minúsculas, espacios y sinónimos.
- Confirmar con negocio la lista oficial de categorías permitidas.
- No agrupar categorías sin validación de negocio.

**Resultado esperado:** categorías coherentes y análisis por categoría válido.

#### 6.4.4 `temporada`

**Acción prevista:** normalizar a un único valor y decidir si se conserva la columna.

Consideraciones:

- Unificar las 5 variantes (`Verano 2024`, `verano`, `SS24`, `Verano24`, `verano 2024`) a un único valor canónico.
- Confirmar con negocio el formato oficial (p. ej. `Verano 2024` o `SS24`).
- Decidir si se conserva la columna (aunque sea constante) o se documenta como constante y se excluye de análisis.
- No eliminar la columna sin documentar la decisión.

**Resultado esperado:** `temporada` normalizada a un único valor y decisión documentada sobre su conservación.

#### 6.4.5 `coleccion`

**Acción prevista:** revisar codificación solo si es necesario.

Consideraciones:

- Revisar las 8 categorías y detectar variantes.
- Revisar acentos, mayúsculas y espacios.
- Confirmar la lista oficial de colecciones.
- No agrupar categorías sin validación de negocio.

**Resultado esperado:** `coleccion` con categorías coherentes.

#### 6.4.6 `coste_unitario`

**Acción prevista:** decidir política de nulos y validar valores.

Consideraciones:

- Decidir política de los 12 nulos: imputar (p. ej. con mediana por categoría), marcar como “desconocido” o excluir del análisis de márgenes.
- Validar que los valores bajos (3,96) son coherentes con el tipo de producto.
- No eliminar outliers sin criterio documentado.

**Resultado esperado:** `coste_unitario` con política de nulos documentada y valores coherentes.

#### 6.4.7 `precio_base`

**Acción prevista:** mantener y validar.

Consideraciones:

- Confirmar que no hay nulos, ceros ni negativos.
- Revisar si los valores son coherentes con el tipo de producto.
- No requiere transformación adicional.

**Resultado esperado:** `precio_base` numérico, positivo y consistente.

#### 6.4.8 Duplicados

**Acción prevista:** mantener la validación de duplicados.

Consideraciones:

- Actualmente no hay duplicados exactos, pero conviene revalidarlos después de normalizar `categoria` y `temporada`.
- Revisar duplicados por `producto_id` (debería ser 0).
- Revisar duplicados lógicos por `nombre`.

**Resultado esperado:** sin duplicados por `producto_id` ni por `nombre`.

### 6.5 Reglas de Validación Propuestas

Antes de dar por limpio el dataset, comprobar:

| Validación | Criterio esperado |
|---|---|
| `producto_id` único | 400 valores únicos para 400 filas |
| `producto_id` no nulo | 0 nulos |
| `nombre` único | 400 valores únicos para 400 filas |
| `categoria` normalizada | Solo categorías del conjunto oficial |
| `temporada` normalizada | Un único valor canónico |
| `coleccion` válida | Solo categorías del conjunto oficial |
| `coste_unitario` sin nulos | 0 nulos (o política documentada) |
| `coste_unitario` positivo | Todos los valores > 0 |
| `precio_base` numérico | 0 errores de conversión |
| `precio_base` positivo | Todos los valores > 0 |
| `coste_unitario` < `precio_base` | Todos los productos tienen coste < precio |
| Duplicados exactos | 0 duplicados |
| Nulos en columnas clave | 0 nulos en `producto_id` |

### 6.6 Decisiones Pendientes de Confirmación

1. Formato canónico de `temporada` (`Verano 2024` vs `SS24` vs otro).
2. Si se conserva la columna `temporada` aunque sea constante.
3. Conjunto oficial de categorías permitidas para `categoria`.
4. Conjunto oficial de colecciones permitidas para `coleccion`.
5. Política de nulos en `coste_unitario` (imputar, marcar o excluir).
6. Si se valida la relación con `lineas_pedido` (todos los `producto_id` existen en ambas tablas).
7. Si se revisan los productos con coste muy bajo (3,96) para confirmar coherencia.
8. Si se conservan los valores originales en columnas auxiliares para trazabilidad.

### 6.7 Restricciones y Buenas Prácticas

- No usar `nombre` como clave primaria.
- No agrupar categorías de `categoria` o `coleccion` sin validación de negocio.
- No eliminar `temporada` sin documentar la decisión.
- No imputar nulos en `coste_unitario` sin criterio documentado.
- No modificar los datos originales sin conservar una copia o registro de cambios.

### 6.8 Entregables Esperados

1. Dataset limpio con `producto_id` validado, `categoria` normalizada, `temporada` normalizada, `coleccion` validada y `coste_unitario` con política de nulos aplicada.
2. Registro de cambios aplicados.
3. Informe de validación con las comprobaciones realizadas.
4. Documentación de decisiones tomadas, especialmente sobre `temporada`, `categoria` y `coste_unitario`.
5. Copia del dataset original sin modificaciones.

### 6.9 Conclusión

La calidad inicial del dataset es **buena en estructura, pero con problemas de codificación y completitud**. `productos` tiene una clave primaria válida, sin duplicados, y `precio_base` está limpio. Sin embargo, **`temporada` es una sola categoría disfrazada de cinco** (todos los productos son de “Verano 2024”), **`categoria` tiene 35 valores con codificación inconsistente** y **`coste_unitario` tiene un 3 % de nulos** que afecta al cálculo de márgenes. Además, `categoria` y `temporada` repiten el patrón de codificación inconsistente que ya apareció en `talla` (devoluciones, lineas_pedido) y `canal` (campañas, pedidos), lo que sugiere un **problema sistémico en el origen** que conviene abordar de forma transversal.

[⬆ Volver al índice de tablas](#índice-de-tablas)

---

## 7. Tabla: `visitas_web`

**Última actualización:** 2026-11-13
**Responsable:** Alejandro Hernández Rodríguez
**Origen de datos:** Archivo `visitas_web.csv`

### 7.1 Descripción General y Alcance

Este documento aplica a la tabla **“visitas_web”**, compuesta por:

- **112 filas**
- **3 columnas**
- **4 valores nulos** en `sesiones` (3,57 %)
- **0 filas duplicadas**
- **0 columnas constantes**
- **0 columnas 100 % únicas**

La tabla parece tener una **granularidad diaria por canal**: 28 fechas distintas × 4 canales = 112 filas. Es una tabla pequeña y estructuralmente sencilla, pero presenta **nulos en la métrica principal (`sesiones`)** y la fecha está almacenada como texto. Su calidad es buena en estructura, pero requiere validación de completitud del panel fecha–canal y una decisión documentada sobre los nulos.

### 7.2 Inventario y Calidad Inicial

#### 7.2.1 Inventario de columnas

| Columna | Tipo detectado | Observación inicial |
|---|---|---|
| `fecha` | Texto | 28 valores únicos. Cada fecha aparece 4 veces (una por canal). Debe convertirse a fecha. |
| `canal` | Texto | 4 categorías: `email`, `instagram`, `google`, `directo`. Cada una aparece 28 veces. |
| `sesiones` | Numérico decimal | **4 nulos (3,57 %).** Sin ceros ni negativos. Rango 264–3.754. |

#### 7.2.2 Resumen de calidad

| Característica | Valor |
|---|---|
| Filas | 112 |
| Columnas | 3 |
| Valores nulos | 4 en `sesiones` (3,57 %) |
| Filas duplicadas exactas | 0 |
| Columnas constantes | 0 |
| Columnas 100 % únicas | 0 |
| Memoria | ~0,01 MB |

### 7.3 Hallazgos de Calidad

#### 7.3.1 Puntos fuertes

- Sin filas duplicadas exactas.
- Sin columnas constantes.
- `canal` tiene solo 4 categorías limpias y balanceadas: `email`, `instagram`, `google`, `directo` (28 filas cada una).
- `fecha` tiene 28 valores únicos y cada fecha aparece 4 veces, lo que sugiere un **panel balanceado fecha × canal**.
- `sesiones` no tiene ceros ni negativos; todos los valores no nulos son positivos.
- El rango de `sesiones` (264–3.754) es plausible para sesiones web diarias por canal.
- La tabla es muy pequeña, fácil de auditar manualmente.

#### 7.3.2 Problemas detectados

1. **`sesiones` tiene 4 nulos (3,57 %).** ⚠️
   - Es la única columna con nulos.
   - Al haber 112 filas y una estructura aparente de 28 fechas × 4 canales, los nulos no parecen filas faltantes, sino **valores ausentes dentro de combinaciones fecha–canal existentes**.
   - **Implicación:** hay que identificar exactamente qué combinaciones fecha–canal tienen `sesiones` nula y decidir si se imputan, se marcan como “sin dato” o se excluyen de agregaciones.

2. **`fecha` está como texto.** ⚠️
   - Tipo detectado: `str`, no fecha.
   - 28 valores únicos; el top 5 muestra fechas consecutivas de junio de 2024.
   - **Implicación:** no se puede ordenar, calcular tendencias, validar rangos temporales ni unir por fecha con otras tablas sin convertirla.

3. **Posible panel incompleto o desbalanceado por nulos en la métrica.**
   - La estructura 28 × 4 = 112 sugiere un panel completo a nivel de filas.
   - Pero con 4 nulos en `sesiones`, el panel está **incompleto a nivel de métrica**.
   - **Implicación:** los totales por canal o por fecha pueden estar subestimados si los nulos no se tratan explícitamente.

4. **`canal` incluye `directo`, que no existe en `campañas`.**
   - En `campañas`, `canal` solo tenía `instagram`, `email`, `google`.
   - En `visitas_web`, aparece además `directo`, igual que en `pedidos`.
   - **Implicación:** es plausible que `directo` represente tráfico orgánico sin campaña, pero conviene confirmar que la lista oficial de canales es coherente entre `visitas_web`, `pedidos` y `campañas`.

5. **No hay columnas 100 % únicas — validar unicidad lógica de `(fecha, canal)`.**
   - No hay un ID explícito.
   - La clave lógica debería ser la combinación `fecha` + `canal`.
   - **Implicación:** hay que confirmar que no existan filas duplicadas por `(fecha, canal)`, aunque no haya duplicados exactos.

6. **`sesiones` como `float64` por los nulos.**
   - Las sesiones son un conteo entero; el tipo `float64` se debe a la presencia de nulos.
   - **Implicación:** tras decidir la política de nulos, conviene definir si la columna queda como entero o se mantiene numérica con nulos documentados.

7. **Rango temporal acotado — validar cobertura completa.**
   - 28 fechas únicas sugieren un periodo de 28 días.
   - Conviene confirmar que no falten días intermedios y que el rango sea continuo.
   - **Implicación:** si falta algún día completo, el panel no sería 28 × 4 y habría que documentarlo.

### 7.4 Consideraciones para la Limpieza

#### 7.4.1 `fecha`

**Acción prevista:** convertir a tipo fecha y validar cobertura temporal.

Consideraciones:

- Convertir a tipo fecha.
- Validar que no haya fechas futuras ni imposibles.
- Confirmar que el rango sea continuo y que no falten días intermedios.
- Revisar si las 28 fechas corresponden a un periodo completo esperado.
- No modificar las fechas originales sin dejar trazabilidad.

**Resultado esperado:** columna `fecha` válida y cobertura temporal documentada.

#### 7.4.2 `canal`

**Acción prevista:** validar coherencia con `pedidos` y `campañas`.

Consideraciones:

- Confirmar la lista oficial de canales permitidos.
- Confirmar que `directo` es una categoría legítima.
- Alinear la codificación con `pedidos` y `campañas`.
- Revisar espacios y mayúsculas/minúsculas.
- No agrupar categorías sin validación de negocio.

**Resultado esperado:** `canal` con categorías coherentes entre tablas.

#### 7.4.3 `sesiones`

**Acción prevista:** identificar los 4 nulos y decidir política de tratamiento.

Consideraciones:

- Identificar exactamente qué combinaciones `(fecha, canal)` tienen `sesiones` nula.
- Revisar si los nulos se concentran en un canal, en una fecha o en un periodo concreto.
- Decidir política: imputar (solo con criterio de negocio), marcar como “sin dato” o excluir de agregaciones.
- No imputar cero de forma automática: un nulo no equivale necesariamente a cero sesiones.
- Documentar la decisión y su impacto en totales por canal y por fecha.

**Resultado esperado:** `sesiones` con política de nulos documentada y agregaciones consistentes.

#### 7.4.4 Clave lógica `(fecha, canal)`

**Acción prevista:** validar unicidad lógica.

Consideraciones:

- Confirmar que no hay más de una fila por `(fecha, canal)`.
- Confirmar que existen las 28 × 4 combinaciones esperadas o documentar las ausentes.
- Revisar si los 4 nulos corresponden a combinaciones existentes o a filas faltantes.

**Resultado esperado:** clave lógica `(fecha, canal)` única y panel documentado.

#### 7.4.5 Duplicados

**Acción prevista:** mantener la validación de duplicados.

Consideraciones:

- Actualmente no hay duplicados exactos.
- Revalidar duplicados después de convertir `fecha`.
- Revisar duplicados lógicos por `(fecha, canal)`.

**Resultado esperado:** sin duplicados exactos ni lógicos por `(fecha, canal)`.

### 7.5 Reglas de Validación Propuestas

Antes de dar por limpio el dataset, comprobar:

| Validación | Criterio esperado |
|---|---|
| `fecha` válida | Todas las fechas interpretables |
| `fecha` sin futuras | 0 fechas futuras |
| Cobertura temporal | 28 fechas continuas o justificación documentada |
| `canal` válido | Solo `email`, `instagram`, `google`, `directo` |
| `(fecha, canal)` único | 0 duplicados lógicos |
| Panel completo | 28 × 4 combinaciones o ausencias documentadas |
| `sesiones` sin nulos | 0 nulos (o política documentada) |
| `sesiones` positivo | Todos los valores > 0 |
| Duplicados exactos | 0 duplicados |
| Nulos en columnas clave | 0 nulos en `fecha` y `canal` |

### 7.6 Decisiones Pendientes de Confirmación

1. Identificación exacta de las 4 combinaciones `(fecha, canal)` con `sesiones` nula.
2. Política de nulos en `sesiones`: imputar, marcar o excluir.
3. Si `directo` es una categoría oficial de canal.
4. Lista oficial de canales permitidos, alineada con `pedidos` y `campañas`.
5. Confirmación del rango temporal esperado (28 días) y de su continuidad.
6. Si se conserva `sesiones` como entero tras tratar nulos o se mantiene numérica con nulos documentados.
7. Si se conservan los valores originales en columnas auxiliares para trazabilidad.
8. Si se renombran columnas o se mantienen los nombres originales.

### 7.7 Restricciones y Buenas Prácticas

- No imputar `sesiones` con cero sin validación de negocio.
- No agregar totales por canal o por fecha sin tratar antes los nulos.
- No asumir que `directo` es una categoría oficial sin confirmación.
- No convertir `fecha` sin validar fechas futuras o imposibles.
- No modificar los datos originales sin conservar una copia o registro de cambios.

### 7.8 Entregables Esperados

1. Dataset limpio con `fecha` tipada, `canal` validado y `sesiones` con política de nulos aplicada.
2. Registro de cambios aplicados.
3. Informe de validación con las comprobaciones realizadas.
4. Documentación de decisiones tomadas, especialmente sobre los nulos de `sesiones` y la categoría `directo`.
5. Copia del dataset original sin modificaciones.

### 7.9 Conclusión

La calidad inicial del dataset es **buena en estructura, pero con un problema de completitud en la métrica principal**. `visitas_web` no tiene duplicados ni columnas constantes, y su estructura 28 fechas × 4 canales sugiere un panel balanceado. Sin embargo, **`sesiones` tiene 4 nulos (3,57 %)** que afectan a los totales por canal y por fecha, **`fecha` está como texto** y **`canal` incluye `directo`**, que debe alinearse con `pedidos` y `campañas`. Antes de usar la tabla, hay que identificar los nulos, decidir su tratamiento y convertir la fecha.

[⬆ Volver al índice de tablas](#índice-de-tablas)

---
