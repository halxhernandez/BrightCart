# Diccionario de Datos — Proyecto BrightCart

**Última actualización:** 2026-12-12
**Responsable:** Alejandro Hernández Rodríguez
**Base de datos origen:** PostgreSQL (brightcart_db)

## 1. Convenciones Globales
Para garantizar la consistencia en los análisis (Python, Power BI, etc.), todo el modelo de datos sigue estas reglas:
- **Fechas:** Todas las fechas del sistema deben tratarse en formato ISO `YYYY-MM-DD` y zona horaria **UTC**.
- **Moneda:** Todos los importes económicos están expresados en **Euros (EUR)**.
- **Decimales:** Los campos monetarios deben ser de tipo `float`/`decimal` puro (sin símbolos como `€` ni separadores de miles, ej. `61000.0`).
- **Nulos (`NaN`):** Un valor nulo indica ausencia de información en el origen, no un error del sistema.

## 2. Relaciones Principales (Foreign Keys)
- `pedidos.cliente_id`  ➔  `clientes.cliente_id`
- `pedidos.campana_id`  ➔  `campanas.campana_id`
- `lineas_pedido.pedido_id`  ➔  `pedidos.pedido_id`
- `lineas_pedido.producto_id`  ➔  `productos.producto_id`
- `devoluciones.linea_id`  ➔  `lineas_pedido.linea_id`

---

## 3. Tablas del Modelo

### Tabla: `campanas`
**Origen:** Google Sheets (Marketing) → PostgreSQL

| Campo | Tipo | Descripción | Valores / Reglas | Nulo | Origen |
|-------|------|-------------|------------------|------|--------|
| `campana_id` | integer | Identificador único de la campaña. | Clave primaria. | No | Google Sheets |
| `nombre` | string | Nombre comercial de la campaña. | Texto libre. | No | Google Sheets |
| `tipo` | string | Categoría o motivo de la campaña. | `rebajas`, `black_friday`, `promo` | No | Google Sheets |
| `fecha_inicio` | date | Fecha de inicio de la campaña. | Formato `YYYY-MM-DD`. | No | Google Sheets |
| `fecha_fin` | date | Fecha de finalización de la campaña. | Formato `YYYY-MM-DD`. Debe ser >= `fecha_inicio`. | No | Google Sheets |
| `canal` | string | Medio principal de difusión. | `instagram`, `email`, `google` | No | Google Sheets |
| `presupuesto` | float | Importe asignado a la campaña. | >= 0. Moneda: EUR (solo números). | Sí | Google Sheets |
| `ventas_ano_anterior` | float | Ventas históricas de la campaña el año anterior (*baseline*). | >= 0. Moneda: EUR. | Sí | Google Sheets |

**Notas de Calidad (`campanas`):**
- **Inconsistencia en origen:** Al introducirse manualmente desde Google Sheets, se detectan valores de texto en `presupuesto` (ej. `"61.000 €"`).

---

### Tabla: `clientes`
**Origen:** Shopify Plus → PostgreSQL

| Campo | Tipo | Descripción | Valores / Reglas | Nulo | Origen |
|-------|------|-------------|------------------|------|--------|
| `cliente_id` | integer | Identificador único del cliente. | Clave primaria. | No | Shopify Plus |
| `fecha_registro` | date | Fecha de creación de la cuenta. | Formato `YYYY-MM-DD`. | No | Shopify Plus |
| `ciudad` | string | Ciudad de residencia o envío. | Texto en formato Título (ej. Bilbao, Madrid). | Sí | Shopify Plus |
| `genero` | string | Género declarado por el usuario. | Solo `F` o `M` (en mayúscula). | Sí | Shopify Plus |
| `edad` | integer | Edad del cliente en el momento de la extracción. | >= 0. | Sí | Shopify Plus |

**Notas de Calidad (`clientes`):**
- **Inconsistencia en `genero`:** Mezcla de formatos (`F`, `M`, `f`, `Femenino`, `Masculino`).
- **Inconsistencia en `ciudad`:** Mezcla de mayúsculas y minúsculas (`bilbao`, `Bilbao`).

---

### Tabla: `devoluciones`
**Origen:** Shopify Plus → PostgreSQL

| Campo | Tipo | Descripción | Valores / Reglas | Nulo | Origen |
|-------|------|-------------|------------------|------|--------|
| `devolucion_id` | integer | Identificador único de la devolución. | Clave primaria. | No | Shopify Plus |
| `linea_id` | integer | FK a la línea de pedido original devuelta. | Clave foránea. | No | Shopify Plus |
| `fecha_devolucion` | date | Fecha en la que se procesó la devolución. | Formato `YYYY-MM-DD`. | No | Shopify Plus |
| `talla` | string | Talla del producto devuelto. | Letras en mayúscula (S, M, L, XL) o números sin prefijos (ej. 36, 37). | Sí | Shopify Plus |
| `motivo` | string | Razón de la devolución. | `talla incorrecta`, `no me gusta`, `defecto` | No | Shopify Plus |

**Notas de Calidad (`devoluciones`):**
- **Inconsistencia en `fecha_devolucion`:** Mezcla formatos `DD/MM/YYYY` y `YYYY-MM-DD`.
- **Inconsistencia en `talla`:** Mezcla mayúsculas/minúsculas (`XL`, `m`, `S`) y prefijos de texto (`Talla 37`).

---

### Tabla: `lineas_pedido`
**Origen:** Shopify Plus → PostgreSQL

| Campo | Tipo | Descripción | Valores / Reglas | Nulo | Origen |
|-------|------|-------------|------------------|------|--------|
| `linea_id` | integer | Identificador único de la línea. | Clave primaria. | No | Shopify Plus |
| `pedido_id` | integer | FK a la cabecera del pedido. | Clave foránea. | No | Shopify Plus |
| `producto_id` | integer | FK al producto comprado. | Clave foránea. | No | Shopify Plus |
| `talla` | string | Talla del producto comprado. | Letras en mayúscula (S, M, L, XL) o números sin prefijos (ej. 36, 37). | Sí | Shopify Plus |
| `cantidad` | integer | Unidades compradas. | > 0 | No | Shopify Plus |
| `precio_unitario` | float | Precio de venta unitario en el momento de compra. | >= 0. Moneda: EUR (solo números). | No | Shopify Plus |
| `descuento_pct` | float | Porcentaje de descuento aplicado. | Rango numérico de 0.0 a 1.0 (ej. 0.30 para 30%). | No | Shopify Plus |

**Notas de Calidad (`lineas_pedido`):**
- **Inconsistencia en `precio_unitario`:** Mezcla valores numéricos con strings (`"63,83 €"`).
- **Inconsistencia en `descuento_pct`:** Mezcla porcentajes como texto (`"30%"`, `"0%"`) con decimales (`0.3`, `0.0`).

---

### Tabla: `pedidos`
**Origen:** Shopify Plus → PostgreSQL

| Campo | Tipo | Descripción | Valores / Reglas | Nulo | Origen |
|-------|------|-------------|------------------|------|--------|
| `pedido_id` | integer | Identificador único de la cabecera del pedido. | Clave primaria. | No | Shopify Plus |
| `cliente_id` | integer | FK al cliente que realizó el pedido. | Clave foránea. | No | Shopify Plus |
| `fecha_pedido` | date | Fecha de realización del pedido. | Formato `YYYY-MM-DD`. | No | Shopify Plus |
| `campana_id` | float | FK a la campaña de marketing (si aplica). | Clave foránea. | Sí | Shopify Plus |
| `canal` | string | Canal de adquisición del pedido. | `directo`, `instagram`, `email`, `google` | No | Shopify Plus |
| `ciudad` | string | Ciudad de envío del pedido. | Texto en formato Título (ej. Oporto, Lisboa). | Sí | Shopify Plus |
| `metodo_pago` | string | Forma de pago utilizada. | `tarjeta`, `bizum`, `paypal` | No | Shopify Plus |

**Notas de Calidad (`pedidos`):**
- **Inconsistencia en `fecha_pedido`:** Mezcla formatos `DD/MM/YYYY` y `YYYY-MM-DD`.
- **Nulos en `campana_id`:** El valor nulo es correcto e indica ventas orgánicas o directas no asociadas a campañas.

---

### Tabla: `productos`
**Origen:** Shopify Plus → PostgreSQL

| Campo | Tipo | Descripción | Valores / Reglas | Nulo | Origen |
|-------|------|-------------|------------------|------|--------|
| `producto_id` | integer | Identificador único del producto (SKU). | Clave primaria. | No | Shopify Plus |
| `nombre` | string | Nombre comercial del producto. | Texto libre. | No | Shopify Plus |
| `categoria` | string | Categoría principal del producto. | Singular y Primera letra mayúscula (Vestido, Accesorio). | No | Shopify Plus |
| `temporada` | string | Temporada de lanzamiento. | Código unificado (ej. V24 para Verano 2024, SS24). | No | Shopify Plus |
| `coleccion` | string | Colección o línea de diseño. | Texto libre (ej. Cápsula Sol). | Sí | Shopify Plus |
| `coste_unitario` | float | Coste de producción/adquisición. | >= 0. Moneda: EUR. | No | Shopify Plus |
| `precio_base` | float | Precio de venta al público (PVP). | >= 0. Moneda: EUR. | No | Shopify Plus |

**Notas de Calidad (`productos`):**
- **Inconsistencia en `categoria`:** Mezcla mayúsculas/minúsculas y singular/plural (`Vestidos`, `VESTIDOS`, `vestido`).
- **Inconsistencia en `temporada`:** Múltiples formatos (`Verano24`, `verano`, `verano 2024`, `SS24`).

---

### Tabla: `visitas_web`
**Origen:** Google Analytics 4 (GA4) → PostgreSQL

| Campo | Tipo | Descripción | Valores / Reglas | Nulo | Origen |
|-------|------|-------------|------------------|------|--------|
| `fecha` | date | Día del registro de visitas. | Formato `YYYY-MM-DD`. | No | Google Analytics 4 |
| `canal` | string | Canal de adquisición del tráfico. | `email`, `instagram`, `google`, `directo` | No | Google Analytics 4 |
| `sesiones` | integer | Número de sesiones únicas en el día. | Entero >= 0 | Sí | Google Analytics 4 |

**Notas de Calidad (`visitas_web`):**
- **Nulos en `sesiones`:** Se detectan valores `NaN` (ej. canal email). Puede deberse a fallos de seguimiento. No deben imputarse a 0 automáticamente sin consultar con Marketing.

---

## 4. Glosario Global de Negocio

**Tipos de Campaña (`campanas.tipo`)**
- `rebajas`: Campañas estacionales de descuentos.
- `black_friday`: Evento comercial específico de noviembre.
- `promo`: Promociones puntuales.

**Canales de Adquisición (`campanas.canal`, `pedidos.canal`, `visitas_web.canal`)**
- `directo`: Tráfico que llega escribiendo la URL o desde marcadores (orgánico puro).
- `email`: Tráfico proveniente de campañas de correo electrónico (Newsletter).
- `instagram`: Tráfico proveniente de la red social (Social Media).
- `google`: Tráfico proveniente de búsquedas en Google o Google Ads (Search/Display).

**Motivos de Devolución (`devoluciones.motivo`)**
- `talla incorrecta`: El cliente pide una talla diferente.
- `no me gusta`: El producto no cumple las expectativas visuales.
- `defecto`: El producto llegó dañado o con un fallo de fabricación.
