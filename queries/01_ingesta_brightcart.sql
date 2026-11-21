-- ============================================================================
-- Script: Creación e ingesta de datos limpios en BrightCartDB
-- Motor: DuckDB
-- Descripción: Crea/conecta el archivo de base de datos en 'datos/processed/'
--              y carga las tablas principales desde los CSV limpios.
-- ============================================================================

-- Crea el archivo de base de datos si no existe y lo adjunta al entorno
ATTACH IF NOT EXISTS 'datos/processed/BrightCartDB.duckdb' AS BrightCartDB;

-- Selecciona la base de datos de destino
USE BrightCartDB;

-- Tabla de campañas de marketing
CREATE OR REPLACE TABLE campanas AS
SELECT * FROM read_csv_auto('datos/processed/campanas_clean.csv');

-- Tabla maestra de clientes
CREATE OR REPLACE TABLE clientes AS
SELECT * FROM read_csv_auto('datos/processed/clientes_clean.csv');

-- Tabla de registro de devoluciones
CREATE OR REPLACE TABLE devoluciones AS
SELECT * FROM read_csv_auto('datos/processed/devoluciones_clean.csv');

-- Tabla de detalle de productos por pedido
CREATE OR REPLACE TABLE lineas_pedido AS
SELECT * FROM read_csv_auto('datos/processed/lineas_pedido_clean.csv');

-- Tabla de cabecera de pedidos
CREATE OR REPLACE TABLE pedidos AS
SELECT * FROM read_csv_auto('datos/processed/pedidos_clean.csv');

-- Tabla de catálogo de productos
CREATE OR REPLACE TABLE productos AS
SELECT * FROM read_csv_auto('datos/processed/productos_clean.csv');

-- Tabla de registro de tráfico y sesiones web
CREATE OR REPLACE TABLE visitas_web AS
SELECT * FROM read_csv_auto('datos/processed/visitas_web_clean.csv');
