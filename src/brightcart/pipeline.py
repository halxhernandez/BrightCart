"""
Pipeline principal de limpieza de datos de BrightCart.
Importa las funciones auxiliares desde src/brightcart/cleaning.py.
"""

import json
from datetime import datetime

import numpy as np
import pandas as pd

from brightcart.cleaning import (
    PROCESSED_DIR,
    RAW_DIR,
    get_changes_df,
    log_change,
    normalize_category,
    normalize_city,
    normalize_discount,
    normalize_gender,
    normalize_season,
    normalize_size,
    parse_amount,
    parse_date,
)


def main():
    # Hora de inicio, solo para mostrarla en pantalla
    inicio = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print("\n==========================================")
    print(f"INICIANDO PIPELINE BRIGHTCART: {inicio}")
    print("==========================================")

    # ============================================================
    # PASO 1 Y 2 — LEER LOS CSV ORIGINALES
    # ============================================================
    print("Leyendo CSV originales…")
    campanas      = pd.read_csv(RAW_DIR / "campana.csv")
    clientes      = pd.read_csv(RAW_DIR / "clientes.csv")
    devoluciones  = pd.read_csv(RAW_DIR / "devoluciones.csv")
    lineas_pedido = pd.read_csv(RAW_DIR / "lineas_pedido.csv")
    pedidos       = pd.read_csv(RAW_DIR / "pedidos.csv")
    productos     = pd.read_csv(RAW_DIR / "productos.csv")
    visitas_web   = pd.read_csv(RAW_DIR / "visitas_web.csv")

    # ============================================================
    # TABLA: lineas_pedido
    # ============================================================
    print("Limpiando lineas_pedido…")

    # Quitamos líneas duplicadas y nos quedamos con la última
    rows_before = len(lineas_pedido)
    lineas_pedido = lineas_pedido.drop_duplicates(subset="linea_id", keep="last").reset_index(drop=True)
    log_change("lineas_pedido", "LIN1+LIN2+D2", "Deduplicar linea_id, conservar la última versión",
               rows_before, len(lineas_pedido), rows_before - len(lineas_pedido))

    # Guardamos los ids válidos para filtrar las devoluciones más abajo
    valid_line_ids = set(lineas_pedido["linea_id"].astype(int))

    # Cantidades no válidas (0 o negativas) pasan a NaN
    invalid_qty = lineas_pedido["cantidad"] <= 0
    lineas_pedido.loc[invalid_qty, "cantidad"] = np.nan
    lineas_pedido["cantidad"] = lineas_pedido["cantidad"].astype("Int64")
    log_change("lineas_pedido", "LIN3", "cantidad <= 0 → NaN (decisión D8 pendiente)",
               len(lineas_pedido), len(lineas_pedido), int(invalid_qty.sum()))

    lineas_pedido["talla"] = normalize_size(lineas_pedido["talla"])
    log_change("lineas_pedido", "LIN4", "talla normalizada",
               len(lineas_pedido), len(lineas_pedido), len(lineas_pedido))

    lineas_pedido["precio_unitario"] = lineas_pedido["precio_unitario"].apply(parse_amount)
    log_change("lineas_pedido", "LIN5", "precio_unitario a número",
               len(lineas_pedido), len(lineas_pedido), len(lineas_pedido))

    lineas_pedido["descuento_pct"] = lineas_pedido["descuento_pct"].apply(normalize_discount)
    log_change("lineas_pedido", "LIN6+D5", "descuento_pct a escala 0–1",
               len(lineas_pedido), len(lineas_pedido), len(lineas_pedido))

    # ============================================================
    # TABLA: campañas
    # ============================================================
    print("Limpiando campañas…")

    campanas["presupuesto"] = campanas["presupuesto"].apply(parse_amount)
    log_change("campañas", "CAM1", "presupuesto a número",
               len(campanas), len(campanas), len(campanas))

    campanas["fecha_inicio"] = parse_date(campanas["fecha_inicio"])
    campanas["fecha_fin"]    = parse_date(campanas["fecha_fin"])
    log_change("campañas", "CAM2", "fechas a tipo fecha",
               len(campanas), len(campanas), len(campanas))

    # ============================================================
    # TABLA: clientes
    # ============================================================
    print("Limpiando clientes…")

    # Quitamos clientes duplicados y nos quedamos con el último
    rows_before = len(clientes)
    clientes = clientes.drop_duplicates(subset="cliente_id", keep="last").reset_index(drop=True)
    log_change("clientes", "CLI1+CLI2+D1", "Deduplicar cliente_id, conservar la última versión",
               rows_before, len(clientes), rows_before - len(clientes))

    clientes["fecha_registro"] = parse_date(clientes["fecha_registro"])
    log_change("clientes", "CLI3", "fecha_registro a tipo fecha",
               len(clientes), len(clientes), len(clientes))

    clientes["ciudad"] = normalize_city(clientes["ciudad"])
    clientes["genero"] = normalize_gender(clientes["genero"])
    log_change("clientes", "CLI4+CLI5", "ciudad y género normalizados",
               len(clientes), len(clientes), len(clientes))

    # Edades imposibles (menores de 0 o mayores de 100) pasan a NaN
    out_of_range = (clientes["edad"] < 0) | (clientes["edad"] > 100)
    clientes.loc[out_of_range, "edad"] = np.nan
    clientes["edad"] = clientes["edad"].astype("Int64")
    log_change("clientes", "CLI6+D6", "edad fuera de [0,100] → NaN",
               len(clientes), len(clientes), int(out_of_range.sum()))

    # ============================================================
    # TABLA: pedidos
    # ============================================================
    print("Limpiando pedidos…")

    pedidos["fecha_pedido"] = parse_date(pedidos["fecha_pedido"])
    log_change("pedidos", "PED1", "fecha_pedido a tipo fecha",
               len(pedidos), len(pedidos), len(pedidos))

    # Int64 permite tener vacíos (pedidos sin campaña)
    pedidos["campana_id"] = pedidos["campana_id"].astype("Int64")
    log_change("pedidos", "PED3+D3", "campana_id a entero nullable",
               len(pedidos), len(pedidos), int(pedidos["campana_id"].isna().sum()))

    pedidos["ciudad"] = normalize_city(pedidos["ciudad"])
    log_change("pedidos", "PED4", "ciudad en formato Título",
               len(pedidos), len(pedidos), len(pedidos))

    # ============================================================
    # TABLA: productos
    # ============================================================
    print("Limpiando productos…")

    productos["categoria"] = normalize_category(productos["categoria"])
    productos["temporada"] = normalize_season(productos["temporada"])
    log_change("productos", "PRO1+PRO2", "categoría y temporada normalizadas",
               len(productos), len(productos), len(productos))

    # Aquí no se cambia nada, solo se registra cuántos NaN hay
    log_change("productos", "PRO3+D7", "coste_unitario NaN conservados",
               len(productos), len(productos), int(productos["coste_unitario"].isna().sum()))

    # ============================================================
    # TABLA: devoluciones
    # ============================================================
    print("Limpiando devoluciones…")

    # Descartamos devoluciones cuya línea de pedido ya no existe
    rows_before = len(devoluciones)
    devoluciones = devoluciones[devoluciones["linea_id"].isin(valid_line_ids)].reset_index(drop=True)
    log_change("devoluciones", "DEV1+D4", "Descartar devoluciones huérfanas",
               rows_before, len(devoluciones), rows_before - len(devoluciones))

    devoluciones["fecha_devolucion"] = parse_date(devoluciones["fecha_devolucion"])
    log_change("devoluciones", "DEV2", "fecha_devolucion a tipo fecha",
               len(devoluciones), len(devoluciones), len(devoluciones))

    devoluciones["talla"] = normalize_size(devoluciones["talla"])
    log_change("devoluciones", "DEV3", "talla normalizada",
               len(devoluciones), len(devoluciones), len(devoluciones))

    # ============================================================
    # TABLA: visitas_web
    # ============================================================
    print("Limpiando visitas_web…")

    visitas_web["sesiones"] = visitas_web["sesiones"].astype("Int64")
    log_change("visitas_web", "VIS1+VIS2", "sesiones a entero nullable",
               len(visitas_web), len(visitas_web), int(visitas_web["sesiones"].isna().sum()))

    visitas_web["fecha"] = parse_date(visitas_web["fecha"])
    log_change("visitas_web", "VIS3", "fecha a tipo fecha",
               len(visitas_web), len(visitas_web), len(visitas_web))

    # ============================================================
    # PASO 8 — CATÁLOGOS CONSOLIDADOS (catalogs.json)
    # ============================================================
    print("Generando catálogos...")

    # Listas de valores únicos y ordenados de cada columna clave
    catalogs = {
        "ciudades": sorted(
            set(clientes["ciudad"].dropna().unique())
            | set(pedidos["ciudad"].dropna().unique())
        ),
        "categorias": sorted(productos["categoria"].dropna().unique().tolist()),
        "temporadas": sorted(productos["temporada"].dropna().unique().tolist()),
        "tallas": sorted(
            set(lineas_pedido["talla"].dropna().unique())
            | set(devoluciones["talla"].dropna().unique())
        ),
        "generos": sorted(clientes["genero"].dropna().unique().tolist()),
    }

    with open(PROCESSED_DIR / "catalogs.json", "w", encoding="utf-8") as f:
        json.dump(catalogs, f, ensure_ascii=False, indent=2)

    # ============================================================
    # PASO 9 — VALIDACIÓN POST-LIMPIEZA (validacion_post_limpieza.csv)
    # ============================================================
    print("Ejecutando validación post-limpieza...")

    tablas = {
        "campanas": campanas,
        "clientes": clientes,
        "devoluciones": devoluciones,
        "lineas_pedido": lineas_pedido,
        "pedidos": pedidos,
        "productos": productos,
        "visitas_web": visitas_web,
    }

    # Un resumen por tabla: filas, columnas, nulos y duplicados
    resumen_validacion = []
    for nombre, df in tablas.items():
        resumen_validacion.append({
            "tabla": nombre,
            "filas": len(df),
            "columnas": len(df.columns),
            "nulos_totales": int(df.isna().sum().sum()),
            "duplicados_exactos": int(df.duplicated().sum()),
        })

    df_validacion = pd.DataFrame(resumen_validacion)
    df_validacion.to_csv(PROCESSED_DIR / "validacion_post_limpieza.csv", index=False)

    # ============================================================
    # PASO 10 — GUARDAR TABLAS LIMPIAS (*_clean.csv) Y LOG
    # ============================================================
    print("Guardando archivos limpios en datos/processed/...")

    for nombre, df in tablas.items():
        df.to_csv(PROCESSED_DIR / f"{nombre}_clean.csv", index=False)

    get_changes_df().to_csv(PROCESSED_DIR / "limpieza_log.csv", index=False)

    fin = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"¡Proceso finalizado correctamente a las {fin}!")


if __name__ == "__main__":
    main()
