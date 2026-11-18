# Diccionario de datos

> Tipos indicados según el perfilado observado. Cuando hay formatos mixtos o problemas de calidad, se indican en Observaciones.

---

## Tabla Campañas

**Descripción:** Campañas de marketing/comerciales definidas por la empresa.
**Granularidad:** 1 fila = 1 campaña.
**Clave primaria:** `campana_id`.
**Claves foráneas:** No tiene.

| Columna | Tipo | Descripción | Ejemplo | Nulos permitidos | Observaciones |
|---|---|---|---|---|---|
| campana_id | int64 | Identificador único de campaña | 1 | No (0%) | PK. 4 valores únicos para 4 filas. |
| nombre | str | Nombre comercial de la campaña | Rebajas Verano 2024 | No (0%) | 4 valores únicos. |
| tipo | str | Tipo de campaña | rebajas | No (0%) | 3 valores únicos. |
| fecha_inicio | str | Fecha de inicio de campaña | 2024-07-01 | No (0%) | Almacenada como texto; convertir a fecha. |
| fecha_fin | str | Fecha de fin de campaña | 2024-07-21 | No (0%) | Almacenada como texto; convertir a fecha. |
| canal | str | Canal principal de campaña | instagram | No (0%) | 3 valores únicos. |
| presupuesto | str | Presupuesto de campaña | 48000.0; 61.000 € | No (0%) | Formato mixto: numérico y texto con €/miles. Convertir a numérico. |
| ventas_ano_anterior | float64 | Ventas del año anterior para la campaña | 512340.0 | No (0%) | Numérico. |

---

## Tabla Clientes

**Descripción:** Clientes registrados en la empresa.
**Granularidad:** 1 fila = 1 cliente.
**Clave primaria:** `cliente_id` teórica.
**Claves foráneas:** No tiene.

**Calidad:** 5.010 filas, 2 filas totalmente duplicadas y solo 4.970 `cliente_id` únicos; revisar duplicados/unicidad de PK.

| Columna | Tipo | Descripción | Ejemplo | Nulos permitidos | Observaciones |
|---|---|---|---|---|---|
| cliente_id | int64 | Identificador único de cliente | 2371 | No (0%) | PK teórica. 4.970 únicos para 5.010 filas. |
| fecha_registro | str | Fecha de alta del cliente | 2019-10-18 | Sí (2.99%) | 150 nulos; almacenada como texto. |
| ciudad | str | Ciudad del cliente | bilbao / Bilbao / madrid | No (0%) | 31 valores únicos; inconsistencias de mayúsculas/minúsculas. |
| genero | str | Género del cliente | F / M / m | No (0%) | 6 valores únicos; probablemente variantes de codificación. |
| edad | int64 | Edad del cliente | 29 | No (0%) | Valores inválidos: mínimo -5 y máximo 250. Revisar outliers. |

---

## Tabla Devoluciones

**Descripción:** Devoluciones de líneas de pedido.
**Granularidad:** 1 fila = 1 devolución de una línea de pedido.
**Clave primaria:** `devolucion_id`.
**Claves foráneas:** `linea_id` → `lineas_pedido.linea_id`.

| Columna | Tipo | Descripción | Ejemplo | Nulos permitidos | Observaciones |
|---|---|---|---|---|---|
| devolucion_id | int64 | Identificador único de devolución | 702838 | No (0%) | PK. 5.558 únicos para 5.558 filas. |
| linea_id | int64 | Línea de pedido devuelta | 910363 | No (0%) | FK lógica a `lineas_pedido.linea_id`. 5.558 únicos. |
| fecha_devolucion | str | Fecha de la devolución | 15/07/2024; 2024-07-16 | No (0%) | Formato mixto `dd/mm/yyyy` y `yyyy-mm-dd`. Convertir a fecha. |
| talla | str | Talla devuelta | 36 / XL / m | No (0%) | 29 valores únicos; mezcla numérica, texto y mayúsculas/minúsculas. |
| motivo | str | Motivo de devolución | talla incorrecta | No (0%) | 8 valores únicos. |

---

## Tabla Lineas Pedido

**Descripción:** Líneas/detalle de productos incluidos en cada pedido.
**Granularidad:** 1 fila = 1 línea de pedido.
**Clave primaria:** `linea_id` teórica, no garantizada por el perfil.
**Claves foráneas:** `pedido_id` → `pedidos.pedido_id`; `producto_id` → `productos.producto_id`.

**Calidad:** 20.140 filas, 139 filas totalmente duplicadas y solo 20.000 `linea_id` únicos; revisar PK y duplicados antes de usar.

| Columna | Tipo | Descripción | Ejemplo | Nulos permitidos | Observaciones |
|---|---|---|---|---|---|
| linea_id | int64 | Identificador de línea de pedido | 900001 | No (0%) | PK teórica. 20.000 únicos para 20.140 filas; no es única. |
| pedido_id | int64 | Pedido al que pertenece la línea | 500001 | No (0%) | FK a `pedidos.pedido_id`. |
| producto_id | int64 | Producto de la línea | 1137 | No (0%) | FK a `productos.producto_id`. |
| talla | str | Talla del producto en la línea | 39 / XL / S | No (0%) | 29 valores únicos; formatos mixtos. |
| cantidad | int64 | Cantidad de unidades | 1 | No (0%) | Mínimo -1: valor inválido. |
| precio_unitario | str | Precio unitario | 63,83 € | No (0%) | Texto con € y coma decimal; convertir a numérico. |
| descuento_pct | str | Descuento aplicado | 0.3 / 30% / 0% | No (0%) | Formato mixto: decimal, porcentaje y cero. Normalizar. |

---

## Tabla Pedidos

**Descripción:** Cabecera de pedidos realizados por clientes.
**Granularidad:** 1 fila = 1 pedido.
**Clave primaria:** `pedido_id`.
**Claves foráneas:** `cliente_id` → `clientes.cliente_id`; `campana_id` → `campañas.campana_id` (nullable).

| Columna | Tipo | Descripción | Ejemplo | Nulos permitidos | Observaciones |
|---|---|---|---|---|---|
| pedido_id | int64 | Identificador único de pedido | 500001 | No (0%) | PK. 8.000 únicos para 8.000 filas. |
| cliente_id | int64 | Cliente que realiza el pedido | 2290 | No (0%) | FK a `clientes.cliente_id`. 2.287 únicos. |
| fecha_pedido | str | Fecha del pedido | 24/06/2024; 2024-07-02 | No (0%) | Formato mixto de fecha; convertir. |
| campana_id | float64 | Campaña asociada al pedido | 1.0 | Sí (14.74%) | 1.179 nulos; solo aparece el valor 1.0 aunque `campañas` tiene 4 IDs. Revisar. |
| canal | str | Canal del pedido | directo / instagram | No (0%) | 4 valores únicos. |
| ciudad | str | Ciudad del pedido | Oporto / lisboa / Madrid | No (0%) | 31 valores únicos; inconsistencias de mayúsculas/minúsculas. |
| metodo_pago | str | Método de pago | tarjeta | No (0%) | 3 valores únicos. |

---

## Table Productos

**Descripción:** Catálogo de productos.
**Granularidad:** 1 fila = 1 producto.
**Clave primaria:** `producto_id`.
**Claves foráneas:** No tiene.

| Columna | Tipo | Descripción | Ejemplo | Nulos permitidos | Observaciones |
|---|---|---|---|---|---|
| producto_id | int64 | Identificador único de producto | 1001 | No (0%) | PK. 400 únicos para 400 filas. |
| nombre | str | Nombre del producto | Vestido Aura | No (0%) | 400 valores únicos. |
| categoria | str | Categoría del producto | Vestidos / VESTIDOS / vestido | No (0%) | 35 valores únicos; normalizar mayúsculas/minúsculas. |
| temporada | str | Temporada del producto | Verano24 / verano / verano 2024 | No (0%) | 5 valores únicos; formatos inconsistentes. |
| coleccion | str | Colección del producto | Cápsula Sol | No (0%) | 8 valores únicos. |
| coste_unitario | float64 | Coste unitario del producto | 12.47 | Sí (3.0%) | 12 nulos. |
| precio_base | float64 | Precio base de venta | 32.57 | No (0%) | 389 valores únicos. |

---

## Tabla Visitas Web

**Descripción:** Sesiones web agregadas por fecha y canal.
**Granularidad:** 1 fila = 1 fecha + 1 canal.
**Clave primaria:** Compuesta `(fecha, canal)`.
**Claves foráneas:** No tiene.

| Columna | Tipo | Descripción | Ejemplo | Nulos permitidos | Observaciones |
|---|---|---|---|---|---|
| fecha | str | Fecha de las visitas | 2024-06-24 | No (0%) | Parte de PK compuesta. 28 fechas únicas. |
| canal | str | Canal de tráfico web | email / instagram / google / directo | No (0%) | Parte de PK compuesta. 4 canales. |
| sesiones | float64 | Número de sesiones web | 1421.0 | Sí (3.57%) | 4 nulos; tipo float aunque debería ser entero. |

---

## Notas transversales de calidad

- Varias fechas están como `str` y con formatos mixtos: `pedidos`, `devoluciones`, `clientes`, `campañas` y `visitas_web`.
- Importes y descuentos vienen como texto en `campañas.presupuesto`, `lineas_pedido.precio_unitario` y `lineas_pedido.descuento_pct`.
- Hay inconsistencias de mayúsculas/minúsculas en ciudades, categorías, temporadas, tallas y género.
- Revisar PKs en `clientes` y `lineas_pedido` por duplicados/valores repetidos.
- Revisar valores inválidos: `clientes.edad` (-5, 250) y `lineas_pedido.cantidad` (-1).
- `pedidos.campana_id` solo contiene el valor `1.0` y tiene 14.74% de nulos; contrastar con la tabla `campañas`.
