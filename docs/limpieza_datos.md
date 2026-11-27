# Documentación de Limpieza de Datos — BrightCart

## 1. Arquitectura y flujo del pipeline
El proceso de saneamiento se divide en dos módulos Python que transforman los 7 ficheros crudos (`datos/raw/*.csv`) en tablas limpias (`datos/processed/*_clean.csv`) listas para ser ingestadas en DuckDB (`01_ingesta_brightcart.sql`):

* **`src/brightcart/cleaning.py`:** Contiene las funciones auxiliares reutilizables de parseo, normalización y auditoría (`log_change`, `get_changes_df`), además de pruebas unitarias rápidas en el bloque `__main__`.
* **`pipeline.py`:** Orquesta la lectura de los CSV crudos, aplica las reglas de negocio por tabla, genera los catálogos consolidados (`catalogs.json`), ejecuta la validación post-limpieza (`validacion_post_limpieza.csv`) y exporta los ficheros limpios junto con el registro de auditoría (`limpieza_log.csv`).

---

## 2. Funciones auxiliares y reglas de normalización (`cleaning.py`)

| Función | Objetivo | Lógica aplicada |
| :--- | :--- | :--- |
| `parse_date` | Unificar fechas mixtas a `datetime` | Intenta primero formato ISO (`%Y-%m-%d`) y, sobre los valores no parseados, aplica formato europeo (`%d/%m/%Y`) con `errors="coerce"`. |
| `parse_amount` | Convertir importes sucios a `float` | Elimina `€` y espacios; resuelve separadores de miles (`.`) y decimales (`,`), distinguiendo formatos como `"63,83 €"`, `"61.000 €"`, `"1.250,50 €"` o `"48000.0"`. |
| `normalize_discount` | Estandarizar descuentos a escala `0–1` | Convierte textos con `%` (`"20%"` → `0.20`) y valores mayores que `1` (`15` o `"30"` → `0.15` / `0.30`) a proporción decimal entre `0` y `1`. |
| `normalize_city` | Estandarizar nombres de ciudad | Elimina espacios laterales (`.str.strip()`) y aplica formato Título (`.str.title()`). |
| `normalize_size` | Unificar tallas de prenda | Pasa a mayúsculas, elimina el prefijo `"TALLA"` y mapea tallas numéricas a letra (`32`→`XXS`, `34`→`XS`, `36`→`S`, `38`→`M`, `40`→`L`, `42`→`XL`, `44`→`XXL`, `46`→`XXXL`). |
| `normalize_gender` | Estandarizar género | Unifica variantes (`FEMENINO`, `MUJER`, `FEMALE` → `F`; `MASCULINO`, `HOMBRE`, `MALE` → `M`) y asigna `X` a cualquier otro valor o nulo. |
| `normalize_category` | Limpiar categorías de producto | Elimina espacios laterales y aplica formato Título antes del mapeo canónico. |
| `normalize_season` | Estandarizar temporadas | Formatea a Título, separa letra y número (`Verano24` → `Verano 24`), expande años de 2 dígitos a 4 (`24` → `2024`) y añade `2024` si falta el año (`Verano` → `Verano 2024`). |

---

## 3. Reglas aplicadas por tabla (`pipeline.py`)

### `lineas_pedido` (Tabla de hechos)
* **`LIN1+LIN2+D2` — Deduplicación:** Se eliminan duplicados por `linea_id` conservando la última aparición (`keep="last"`). Se extrae el conjunto `valid_line_ids` para garantizar integridad referencial con `devoluciones`.
* **`LIN3` — Cantidades inválidas:** Valores en `cantidad <= 0` se reemplazan por `np.nan` y la columna se tipa como entero *nullable* (`Int64`), dejando constancia del conteo afectado sin eliminar la fila.
* **`LIN4` — Tallas:** Normalizadas mediante `normalize_size`.
* **`LIN5` — Precio unitario:** Convertido a `float` mediante `parse_amount`.
* **`LIN6+D5` — Descuento:** Normalizado a escala `0–1` mediante `normalize_discount`.

### `campanas` (origen: `campana.csv`)
* **`CAM1` — Presupuesto:** Convertido a `float` mediante `parse_amount`.
* **`CAM2` — Fechas:** `fecha_inicio` y `fecha_fin` convertidas a fecha con `parse_date`.

### `clientes`
* **`CLI1+CLI2+D1` — Deduplicación:** Se eliminan registros repetidos por `cliente_id` conservando la última versión (`keep="last"`).
* **`CLI3` — Fecha de registro:** Parseada con `parse_date`.
* **`CLI4+CLI5` — Ciudad y género:** Normalizados con `normalize_city` y `normalize_gender`.
* **`CLI6+D6` — Rango de edad:** Edades fuera del intervalo `[0, 100]` se convierten a `np.nan` y la columna se tipa como `Int64`.

### `pedidos`
* **`PED1` — Fecha de pedido:** Parseada con `parse_date`.
* **`PED3+D3` — Campaña asociada:** `campana_id` se convierte a `Int64` para preservar los valores nulos legítimos (pedidos realizados fuera de campaña).
* **`PED4` — Ciudad:** Normalizada con `normalize_city`.

### `productos`
* **`PRO1+PRO2` — Categoría y temporada:** `categoria` se limpia con `normalize_category` y se mapea a nombres canónicos en plural (`Vestido`→`Vestidos`, `Camiseta`→`Camisetas`, `Pantalon`→`Pantalones`, `Falda`→`Faldas`, `Accesorio`→`Accesorios`, `Jersey`/`Jerséis`→`Jerseis`, `Abrigo`→`Abrigos`, `Zapatos`→`Calzado`). `temporada` se unifica con `normalize_season`.
* **`PRO3+D7` — Coste unitario:** Se conservan los `NaN` existentes en `coste_unitario` y se registra su volumen en el log de auditoría sin imputar valores artificiales.

### `devoluciones`
* **`DEV1+D4` — Integridad referencial:** Se descartan las devoluciones huérfanas cuyo `linea_id` no existe en `valid_line_ids`.
* **`DEV2` — Fecha de devolución:** Parseada con `parse_date`.
* **`DEV3` — Talla:** Normalizada con `normalize_size`.

### `visitas_web`
* **`VIS1+VIS2` — Sesiones:** Tipadas como entero *nullable* (`Int64`), registrando la cantidad de nulos.
* **`VIS3` — Fecha:** Parseada con `parse_date`.

---

## 4. Artefactos de salida y auditoría (`datos/processed/`)
Al finalizar la ejecución, el pipeline genera automáticamente:
1. **Tablas saneadas (`*_clean.csv`):** `campanas_clean.csv`, `clientes_clean.csv`, `devoluciones_clean.csv`, `lineas_pedido_clean.csv`, `pedidos_clean.csv`, `productos_clean.csv` y `visitas_web_clean.csv`.
2. **Catálogos consolidados (`catalogs.json`):** Listas ordenadas de valores únicos para `ciudades`, `categorias`, `temporadas`, `tallas` y `generos`.
3. **Validación post-limpieza (`validacion_post_limpieza.csv`):** Resumen por tabla con total de filas, columnas, nulos totales y duplicados exactos tras el proceso.
4. **Registro de auditoría (`limpieza_log.csv`):** Historial tabular generado por `log_change` con tabla, código de regla, descripción, filas antes, filas después y filas afectadas en cada paso.[cite: 5, 6]
