# src/brightcart/quality.py
import pandas as pd


def _mostrar(obj) -> None:
    """Usa display() en Jupyter/Databricks y print() en terminal."""
    try:
        display(obj)  # noqa: F821
    except NameError:
        print(obj)


def _titulo(texto: str) -> None:
    print(f"\n{'=' * 50}\n{texto}\n{'=' * 50}")


def analizar_dataframe(
    df: pd.DataFrame,
    max_duplicados: int = 20,
    max_categorias: int = 5,
) -> None:
    """
    Resumen exploratorio rápido de un DataFrame.

    Parámetros
    ----------
    df : pd.DataFrame
        DataFrame a analizar.
    max_duplicados : int
        Máximo de filas duplicadas a mostrar (evita saturar el notebook).
    max_categorias : int
        Máximo de valores más frecuentes a mostrar por columna categórica.
    """
    if df.empty:
        print("El DataFrame está vacío.")
        return

    memoria_mb = df.memory_usage(deep=True).sum() / 1024**2
    print(f"Dimensiones: {df.shape[0]:,} filas x {df.shape[1]:,} columnas")
    print(f"Memoria: {memoria_mb:,.2f} MB")

    # 1. Información general
    _titulo("1. INFORMACIÓN GENERAL")
    df.info()

    # 2. Valores nulos
    _titulo("2. VALORES NULOS")
    nulos = df.isnull().sum()
    resumen_nulos = (
        pd.DataFrame({"nulos": nulos, "porcentaje": (nulos / len(df) * 100).round(2)})
        .query("nulos > 0")
        .sort_values("nulos", ascending=False)
    )
    if resumen_nulos.empty:
        print("Sin valores nulos.")
    else:
        _mostrar(resumen_nulos)

    # 3. Estadísticas numéricas
    _titulo("3. ESTADÍSTICAS NUMÉRICAS")
    num = df.select_dtypes(include="number")
    if num.empty:
        print("No hay columnas numéricas.")
    else:
        stats = num.describe().T
        stats["ceros"] = (num == 0).sum()
        stats["negativos"] = (num < 0).sum()
        _mostrar(stats)

    # 4. Estadísticas categóricas
    _titulo("4. COLUMNAS CATEGÓRICAS / TEXTO")
    cat = df.select_dtypes(include=["object", "category", "string"])
    if cat.empty:
        print("No hay columnas categóricas.")
    else:
        for col in cat.columns:
            n_unicos = cat[col].nunique(dropna=True)
            print(f"\n▸ {col}  ({n_unicos:,} valores únicos)")
            _mostrar(cat[col].value_counts(dropna=False).head(max_categorias))

    # 5. Fechas
    fechas = df.select_dtypes(include=["datetime", "datetimetz"])
    if not fechas.empty:
        _titulo("5. COLUMNAS DE FECHA")
        _mostrar(fechas.agg(["min", "max"]).T)

    # 6. Columnas constantes / alta cardinalidad
    _titulo("6. CALIDAD DE COLUMNAS")
    n_unicos = df.nunique(dropna=False)
    constantes = n_unicos[n_unicos <= 1].index.tolist()
    posibles_id = [
        c for c in df.columns
        if n_unicos[c] == len(df) and len(df) > 1
    ]
    print(f"Columnas constantes: {constantes or 'ninguna'}")
    print(f"Columnas 100% únicas (posibles IDs): {posibles_id or 'ninguna'}")

    # 7. Duplicados
    _titulo("7. DUPLICADOS")
    mask_dup = df.duplicated(keep=False)
    n_dup = int(df.duplicated().sum())
    if n_dup == 0:
        print("Filas duplicadas: 0")
    else:
        print(f"Filas duplicadas: {n_dup:,} ({n_dup / len(df):.2%})")
        print(f"Mostrando hasta {max_duplicados} filas involucradas:")
        _mostrar(df[mask_dup].sort_values(by=df.columns.tolist()).head(max_duplicados))
