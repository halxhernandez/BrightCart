"""
Limpieza de datos de BrightCart.

Este script aplica las decisiones D1-D7 del cliente y los 13 pasos del
plan de limpieza.
"""

from pathlib import Path

import numpy as np
import pandas as pd

# ============================================================
# RUTAS DEL PROYECTO
# ============================================================
BASE_DIR = Path(__file__).resolve().parents[2]
RAW_DIR = BASE_DIR / "datos" / "raw"
PROCESSED_DIR = BASE_DIR / "datos" / "processed"

# Crea la carpeta de salida si todavía no existe
PROCESSED_DIR.mkdir(parents=True, exist_ok=True)


# ============================================================
# REGISTRO DE CAMBIOS
# ============================================================
# Aquí iremos guardando un registro de cada regla aplicada.
changes = []


def log_change(table, rule, description, rows_before, rows_after, rows_affected):
    """Guarda una fila en el log de cambios de la limpieza."""
    changes.append({
        "table": table,
        "rule": rule,
        "description": description,
        "rows_before": rows_before,
        "rows_after": rows_after,
        "rows_affected": rows_affected,
    })


def get_changes_df():
    """Devuelve el historial de cambios listo como DataFrame."""
    return pd.DataFrame(changes)


# ============================================================
# FUNCIONES AUXILIARES DE LIMPIEZA
# ============================================================

def parse_date(series):
    """Convierte texto a fecha aceptando dos formatos: 2024-07-01 y 01/07/2024."""
    # Primero intentamos con el formato ISO (yyyy-mm-dd).
    parsed = pd.to_datetime(series, format="%Y-%m-%d", errors="coerce")

    # Las que no se parsearon, las intentamos con dd/mm/yyyy.
    missing = parsed.isna() & series.notna()
    if missing.any():
        parsed[missing] = pd.to_datetime(series[missing], format="%d/%m/%Y", errors="coerce")

    return parsed


def parse_amount(value):
    """Convierte '63,83 €', '61.000 €' o 48000.0 a número (float)."""
    # Valores vacíos -> NaN
    if pd.isna(value):
        return np.nan

    # Si ya es número, lo devolvemos tal cual
    if isinstance(value, (int, float)):
        return float(value)

    # Quitamos el símbolo del euro y los espacios
    text = str(value).replace("€", "").replace(" ", "").strip()
    if text == "":
        return np.nan

    if "," in text and "." in text:
        # Si tiene coma y punto, el punto es separador de miles.
        text = text.replace(".", "").replace(",", ".")
    elif "," in text:
        # Solo coma: es el separador decimal.
        text = text.replace(",", ".")
    elif "." in text:
        # Caso tipo "61.000" (miles) frente a "48000.0" (decimal).
        parts = text.split(".")
        if len(parts) == 2 and len(parts[1]) == 3 and parts[0] != "0":
            text = text.replace(".", "")

    try:
        return float(text)
    except ValueError:
        return np.nan


def normalize_discount(value):
    """Lleva cualquier descuento a escala 0-1 (decisión D5)."""
    if pd.isna(value):
        return np.nan

    # Si ya viene como número, solo ajustamos si está en % (mayor que 1).
    if isinstance(value, (int, float)):
        return value / 100 if value > 1 else value

    text = str(value).replace(" ", "").strip()
    if text == "":
        return np.nan

    # Texto con símbolo %, por ejemplo "20%"
    if text.endswith("%"):
        try:
            return float(text[:-1]) / 100
        except ValueError:
            return np.nan

    # Texto numérico sin %, por ejemplo "30"
    try:
        number = float(text)
        return number / 100 if number > 1 else number
    except ValueError:
        return np.nan


def normalize_city(series):
    """Deja la ciudad en formato Título (Bilbao, Madrid...)."""
    return series.astype("string").str.strip().str.title()


def normalize_size(series):
    """Limpia 'Talla', deja en MAYÚSCULAS y convierte tallas numéricas a letra."""
    # Equivalencia entre tallas numéricas y tallas en letra
    size_map = {
        "32": "XXS",
        "34": "XS",
        "36": "S",
        "38": "M",
        "40": "L",
        "42": "XL",
        "44": "XXL",
        "46": "XXXL",
    }

    # Mayúsculas, sin la palabra "TALLA" y sin espacios sobrantes
    cleaned = (
        series.astype("string")
        .str.upper()
        .str.replace(r"^TALLA\s*", "", regex=True)
        .str.strip()
    )

    return cleaned.replace(size_map)


def normalize_gender(series):
    """Mapea todas las variantes de género a F, M o X."""
    values = series.astype("string").str.strip().str.upper()

    # Unificamos las variantes más comunes
    values = values.replace({
        "FEMENINO": "F",
        "MUJER": "F",
        "FEMALE": "F",
        "MASCULINO": "M",
        "HOMBRE": "M",
        "MALE": "M",
    })

    # Cualquier otro valor (u vacío) pasa a "X"
    return values.where(values.isin(["F", "M"]), "X")


def normalize_category(series):
    """Categoría del producto en formato Título."""
    return series.astype("string").str.strip().str.title()


def normalize_season(series):
    """Unifica temporadas: 'Verano24' / 'verano' -> 'Verano 2024'."""
    values = series.astype("string").str.strip().str.title()

    # Mete un espacio entre letra y número: Verano24 -> Verano 24
    values = values.str.replace(r"([A-Za-z])(\d)", r"\1 \2", regex=True)

    # Convierte '24' en '2024'
    values = values.str.replace(r"\b(\d{2})\b", r"20\1", regex=True)

    # Si no hay año, añade 2024
    values = values.str.replace(r"^([A-Za-z]+)$", r"\1 2024", regex=True)

    return values


# ============================================================
# PRUEBAS RÁPIDAS DEL MÓDULO
# ============================================================
if __name__ == "__main__":

    # 1. log_change y get_changes_df
    changes.clear()
    log_change("ventas", "REGLA1", "Prueba de registro", 100, 95, 5)
    df_log = get_changes_df()
    assert len(df_log) == 1
    assert df_log["table"].iloc[0] == "ventas"
    assert df_log["rows_affected"].iloc[0] == 5
    changes.clear()

    # 2. parse_date
    fechas = pd.Series(["2024-07-01", "01/07/2024", "fecha_mala", None])
    res_fechas = parse_date(fechas)
    assert res_fechas.iloc[0] == pd.Timestamp("2024-07-01")
    assert res_fechas.iloc[1] == pd.Timestamp("2024-07-01")
    assert pd.isna(res_fechas.iloc[2])
    assert pd.isna(res_fechas.iloc[3])

    # 3. parse_amount
    assert parse_amount("63,83 €") == 63.83
    assert parse_amount("61.000 €") == 61000.0
    assert parse_amount("1.250,50 €") == 1250.50
    assert parse_amount("48000.0") == 48000.0
    assert parse_amount("-45,20 €") == -45.20
    assert np.isnan(parse_amount(""))
    assert np.isnan(parse_amount(None))
    assert np.isnan(parse_amount("texto"))

    # 4. normalize_discount
    assert normalize_discount(0.15) == 0.15
    assert normalize_discount(15) == 0.15
    assert normalize_discount("20%") == 0.20
    assert normalize_discount(" 12.5 % ") == 0.125
    assert normalize_discount("30") == 0.30
    assert np.isnan(normalize_discount(""))
    assert np.isnan(normalize_discount(None))
    assert np.isnan(normalize_discount("abc%"))

    # 5. normalize_city
    ciudades = pd.Series(["  madrid ", "BILBAO", "san sebastián", None])
    res_ciudades = normalize_city(ciudades)
    assert res_ciudades.iloc[0] == "Madrid"
    assert res_ciudades.iloc[1] == "Bilbao"
    assert res_ciudades.iloc[2] == "San Sebastián"
    assert pd.isna(res_ciudades.iloc[3])

    # 6. normalize_size (la talla "41" no está en el mapa, se queda igual)
    tallas = pd.Series(["Talla L", "talla S", "xs", "41", "Talla 38", "40"])
    res_tallas = normalize_size(tallas)
    assert res_tallas.iloc[0] == "L"
    assert res_tallas.iloc[1] == "S"
    assert res_tallas.iloc[2] == "XS"
    assert res_tallas.iloc[3] == "41"
    assert res_tallas.iloc[4] == "M"
    assert res_tallas.iloc[5] == "L"

    # 7. normalize_gender
    generos = pd.Series(["Femenino", "mujer", "HOMBRE", "male", "Otro", None])
    res_generos = normalize_gender(generos)
    assert res_generos.iloc[0] == "F"
    assert res_generos.iloc[1] == "F"
    assert res_generos.iloc[2] == "M"
    assert res_generos.iloc[3] == "M"
    assert res_generos.iloc[4] == "X"
    assert res_generos.iloc[5] == "X"

    # 8. normalize_season
    temporadas = pd.Series(["Verano24", "verano", "INVIERNO 2023", "  primavera 24 "])
    res_temporadas = normalize_season(temporadas)
    assert res_temporadas.iloc[0] == "Verano 2024"
    assert res_temporadas.iloc[1] == "Verano 2024"
    assert res_temporadas.iloc[2] == "Invierno 2023"
    assert res_temporadas.iloc[3] == "Primavera 2024"

    # 9. normalize_category
    categorias = pd.Series(["  camisetas ", "PANTALONES", "calzado deportivo", "ropa interior"])
    res_categorias = normalize_category(categorias)
    assert res_categorias.iloc[0] == "Camisetas"
    assert res_categorias.iloc[1] == "Pantalones"
    assert res_categorias.iloc[2] == "Calzado Deportivo"
    assert res_categorias.iloc[3] == "Ropa Interior"

    print("Todas las pruebas del módulo cleaning.py pasaron correctamente.")
