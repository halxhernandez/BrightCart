# BrightCart: Análisis de datos

Proyecto de análisis de datos para **BrightCart**, un e-commerce. Su objetivo es conocer la calidad de sus datos, limpiarlos y dejarlos listos para el análisis.

## Objetivo

Este proyecto ayuda a **BrightCart** a confiar en sus datos antes de analizarlos. BrightCart nos entrega la información de su negocio en archivos CSV, y nuestro trabajo se organiza en tres etapas:

1. **Conocer la calidad de los datos:** detectar errores, duplicados, formatos inconsistente y valores imposibles, y documentarlos en un informe.
2. **Limpiar los datos:** corregir lo detectado con reglas clras y trazables, dejando registrado qué se modifica o se descarta y por qué.
3. **Dejar los datos listos para el análisis:** con tablas limpias y documentadas sobre las que realizar los análisis de negocio en los próximos días.

## Datos de origen

BrightCart nos entrega sus datos en archivos CSV. Hasta ahora son **7 tablas**:

| Tabla | Qué contiene | Cada fila representa |
|---|---|---|
| clientes | Personas registradas en la tienda (fecha de alta, ciudad, género y edad) | Un cliente |
| productos | Catálogo de productos (categoría, temporada, colección, coste y precio) | Un producto |
| campañas | Campañas de marketing (tipo, canal, fechas, presupuesto y ventas del año anterior) | Una campaña |
| pedidos | Compras realizadas (cliente, fecha, canal, ciudad, método de pago y campaña asociada) | Un pedido |
| lineas_pedido | Detalle de lo comprado en cada pedido (producto, talla, cantidad, precio y descuento) | Un producto dentro de un pedido |
| devoluciones | Productos devueltos por los clientes (fecha, talla y motivo) | Una devolución |
| visitas_web | Visitas a la web, agrupadas por día y canal de tráfico | Un día y un canal |

**Cómo se relacionan:** un cliente realiza pedidos, cada pedido se compone de líneas (cada una de un producto), y una línea puede acabar en devolución. Un pedido puede estar vinculado a una campaña de marketing. La tabla de visitas web es independiente y se cruza con las demás por fecha y canal.

- Descripción detallada de cada columna: [docs/diccionario_datos.md](docs/diccionario_datos.md)
- Arquitectura y origen de los datos: [docs/arquitectura_datos.md](docs/arquitectura_datos.md)

> Los CSV originales no se incluyen en el repositorio por ser datos del cliente.

## Estructura del repositorio

```
brightcart/
├── datos/        # CSV originales (raw) y limpios (processed); no se suben a Git
├── docs/         # Diccionario de datos, arquitectura y reglas de limpieza
├── informes/     # Informes de calidad para el cliente
├── notebooks/    # Exploración de los datos
├── queries/      # Consultas SQL
├── src/          # Código reutilizable (limpieza, rutas)
└── README.md
```

## Estado del proyecto

| Tabla | Diccionario | Perfilado de calidad | Informe | Limpieza |
|---|---|---|---|---|
| campañas | ✅ | ✅ | ✅ | ⬜ |
| clientes | ✅ | ✅ | ✅ | ⬜ |
| devoluciones | ✅ | ✅ | ✅ | ⬜ |
| lineas_pedido | ✅ | ✅ | ✅ | ⬜ |
| pedidos | ✅ | ✅ | ✅ | ⬜ |
| productos | ✅ | ✅ | ✅ | ⬜ |
| visitas_web | ✅ | ✅ | ✅ | ⬜ |

**Leyenda:** ✅ completado · ⬜ pendiente

**Última actualización:** perfilado de calidad e informe de calidad completados para las 7 tablas. Siguiente hito: fase de limpieza (sección 5 del informe de calidad).

## Entregables

| Entregable | Ubicación | Estado |
|---|---|---|
| Diccionario de datos | [docs/diccionario_datos.md](docs/diccionario_datos.md) | ✅ |
| Informe de calidad de datos | [informes/calidad_datos.md](informes/calidad_datos.md) | ✅ |
| Reglas de limpieza | [docs/reglas_limpieza.md](docs/reglas_limpieza.md) | ⬜ (se define en la fase de limpieza) |
| Datos limpios (processed) | `datos/processed/` | ⬜ |
| Notebooks de exploración | `notebooks/` | ⬜ |
| Consultas SQL | `queries/` | ⬜ |

## Hallazgos principales del informe de calidad

Resumen de los problemas que bloquean el análisis y que se abordarán en la fase de limpieza (detalle completo en [informes/calidad_datos.md](informes/calidad_datos.md)):

1. **Duplicados y colisiones de clave** en `clientes` (40 IDs repetidos) y en `lineas_pedido` (139 duplicados exactos + 1 ID con datos distintos). Riesgo de duplicar ventas y clientes al agregar.
2. **42 devoluciones huérfanas** (0,76%) que apuntan a líneas de pedido inexistentes.
3. **Atribución de campañas inservible**: `pedidos.campana_id` solo toma el valor `1,0` o nulo (14,74% de nulos), por lo que no se puede calcular ROI por campaña.
4. **Fechas e importes como texto y con formatos mezclados** en `campañas`, `pedidos`, `devoluciones` y `lineas_pedido`.
5. **Valores imposibles**: 13 edades fuera de [0, 100] y 15 cantidades negativas en `lineas_pedido`.

**Prioridad global:** Alta. Los puntos 1, 2 y 3 bloquean análisis clave; los puntos 4 y 5 se resuelven con normalización y reglas de validación.

## Decisiones pendientes del cliente (BrightCart)

Antes de ejecutar la limpieza necesitamos confirmación sobre:

- **D1:** criterio para consolidar los 38 IDs de cliente con datos divergentes.
- **D2:** si los 139 duplicados de `lineas_pedido` son reintentos de carga o líneas legítimas.
- **D3:** origen de `pedidos.campana_id` (¿error de carga o atribución perdida?).
- **D4:** qué hacer con las 42 devoluciones huérfanas.
- **D5:** escala de `descuento_pct` (0–1 o 0–100).
- **D6:** tratamiento de las 13 edades fuera de rango.
- **D7:** tratamiento de los 12 `coste_unitario` nulos.

Detalle de cada decisión en la sección 5 del [informe de calidad](informes/calidad_datos.md).
