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

**Cómo se relacionan:** un cliente realiza pedidos, cada pedido se compone de
líneas (cada una de un producto), y una línea puede acabar en devolución. Un
pedido puede estar vinculado a una campaña de marketing. La tabla de visitas web
es independiente y se cruza con las demás por fecha y canal.

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
| clientes | ✅ | ✅ | ⬜ | ⬜ |
| productos | ✅ | ✅ | ⬜ | ⬜ |
| campaña | ✅ | ✅ | ⬜ | ⬜ |
| pedidos | ✅ | ✅ | ⬜ | ⬜ |
| líneas_pedido | ✅ | ⬜ | ⬜ | ⬜ |
| devoluciones | ✅ | ⬜ | ⬜ | ⬜ |
| visitas_web | ✅ | ⬜ | ⬜ | ⬜ |

