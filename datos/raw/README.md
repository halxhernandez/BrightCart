# Datos Crudos (`datos/raw/`)

Este directorio está destinado a almacenar los conjuntos de datos originales e inmutables del proyecto *BrightCart*.

> **⚠️ Nota de Privacidad y Seguridad:** Por políticas de confidencialidad del cliente y buenas prácticas de control de versiones, **los archivos de datos reales no se suben a este repositorio** (están excluidos mediante `.gitignore`).

## Origen y Linaje

Los datos provienen de la base de datos central **PostgreSQL** (alimentada por **Shopify Plus** y **Google Analytics 4**) y de una hoja de cálculo operativa de Marketing (**Google Sheets**).

* Para ver el diagrama completo del flujo y linaje, consulta: [`docs/arquitectura.md`](../../docs/arquitectura_datos.md).

## Archivos Locales Esperado

Para ejecutar el entorno localmente, exporta o solicita los siguientes cortes y colócalos directamente en esta ruta (`datos/raw/`):

Archivo esperado | Tabla / Fuente origen | Descripción |
| :--- | :--- | :--- |
| `pedidos.csv` | PostgreSQL (`orders`) | Cabecera de órdenes, fechas, clientes y totales. |
| `lineas_pedido.csv` | PostgreSQL (`order_items`) | Detalle de productos, cantidades y precios por pedido. |
| `devoluciones.csv` | PostgreSQL (`returns`) | Registro de reembolsos, cancelaciones y motivos. |
| `clientes.csv` | PostgreSQL (`customers`) | Catálogo de clientes y datos demográficos. |
| `productos.csv` | PostgreSQL (`products`) | Maestro de productos, precios y categorías. |
| `trafico_web.csv` | Google Analytics 4 | Sesiones y métricas de visitas a la web. |
| `campana.csv` | Google Sheets (Marketing) | Catálogo de campañas, canales, fechas, presupuestos y ventas base. |

## Reglas de Manejo
1. **Solo lectura:** No modifiques manualmente los archivos dentro de `datos/raw/`.
2. **Salida:** Todo procesamiento o limpieza debe escribirse en `datos/processed/`.
