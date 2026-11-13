# Diagramas de Arquitectura y Linaje

## 1. Flujo de Datos General
![Linaje de Datos](./linaje_datos.png)

**Descripción del flujo:**

- **Dónde ocurre (Origen):** La interacción del usuario se captura en Shopify Plus (tienda/pagos) y Google Analytics 4 (visitas web).

- **Dónde se guarda (Almacenamiento):** Los datos se centralizan y consolidan en una base de datos PostgreSQL (pedidos, producto, clientes).

- **Dónde se mira (Consumo):**
    - *Power BI:* Para paneles de dirección (KPIs de negocio).
    - *Python + Seaborn:* Para análisis exploratorio y validación.
    - *Google Sheets:* Uso manual residual por parte de Marketing.

**Herramienta de creación:** Boceto conceptual creado en *draw.io* (estilo hand-drawn) exportado a PNG.

## 2. Modelo Relacional

El siguiente diagrama muestra la estructura de la base de datos (Modelo Entidad-Relación), detallando las claves primarias (PK), claves foráneas (FK) y los tipos de datos de cada campo.

![Modelo Relacional E-Commerce](./diagramas/modelo_relacional.png)

### Descripción General del Modelo
El modelo está diseñado bajo un esquema relacional clásico para e-commerce, dividiendo la información en:
1. **Tablas Maestras (Dimensiones):** `clientes`, `productos` y `campanas`. Contienen la información descriptiva y única de cada entidad.
2. **Tablas Transaccionales (Hechos):** `pedidos`, `lineas_pedido` y `devoluciones`. Registran los eventos de compra y post-venta.
3. **Tabla de Analítica Web:** `visitas_web`. Es una tabla independiente (sin FKs) que almacena agregaciones diarias por canal provenientes de Google Analytics 4.

### Relaciones Principales (Foreign Keys)
- `pedidos.cliente_id`  ➔  `clientes.cliente_id`
- `pedidos.campana_id`  ➔  `campanas.campana_id`
- `lineas_pedido.pedido_id`  ➔  `pedidos.pedido_id`
- `lineas_pedido.producto_id`  ➔  `productos.producto_id`
- `devoluciones.linea_id`  ➔  `lineas_pedido.linea_id`

### Notas del Modelo
- **Tabla `visitas_web`:** Al no tener claves foráneas, se cruza con el resto del modelo mediante la columna `fecha` y `canal` (cruce lógico, no físico), permitiendo comparar el tráfico web con las ventas reales.
- **Tabla `devoluciones`:** Depende directamente de `lineas_pedido` y no de `pedidos`. Esto es una excelente práctica de diseño porque permite rastrear devoluciones parciales (ej. en un pedido de 3 camisetas, el cliente solo devuelve 1).

---
