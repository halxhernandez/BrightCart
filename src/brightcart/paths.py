# src/brightcart/paths.py
import os
from pathlib import Path

# Raíz del proyecto: BrightCart/src/brightcart/paths.py -> parents[2]
# Se puede sobrescribir con la variable de entorno BRIGHTCART_ROOT.
PROJECT_ROOT = Path(
    os.environ.get("BRIGHTCART_ROOT", Path(__file__).resolve().parents[2])
)

DATA_DIR = PROJECT_ROOT / "datos"
DATA_RAW = DATA_DIR / "raw"
DATA_PROCESSED = DATA_DIR / "processed"

NOTEBOOKS_DIR = PROJECT_ROOT / "notebooks"
REPORTS_DIR = PROJECT_ROOT / "informes"
DOCS_DIR = PROJECT_ROOT / "docs"
QUERIES_DIR = PROJECT_ROOT / "queries"


def crear_directorios_salida() -> None:
    """Crea las carpetas de salida si no existen."""
    for ruta in (DATA_PROCESSED, REPORTS_DIR):
        ruta.mkdir(parents=True, exist_ok=True)


def verificar_datos_raw() -> None:
    """Falla con un mensaje claro si no hay datos de entrada válidos (.csv o .parquet)."""
    if not DATA_RAW.exists():
        raise FileNotFoundError(f"La carpeta {DATA_RAW} no existe.")

    # Verifica si hay al menos un archivo .csv o .parquet
    hay_datos = any(DATA_RAW.glob("*.csv")) or any(DATA_RAW.glob("*.parquet"))

    if not hay_datos:
        raise FileNotFoundError(
            f"No hay datos válidos (.csv o .parquet) en {DATA_RAW}. "
            "Descarga el dataset y colócalo ahí."
        )
