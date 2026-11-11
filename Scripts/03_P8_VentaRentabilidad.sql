
USE superstore_db;

-- ==========================================
-- A. PARETO DE VENTAS
-- ==========================================

-- 1. Consolidar ventas por producto
WITH productos AS (
    SELECT
        product_id,
        product_name,
        category,
        SUM(sales) AS ventas
    FROM fact_superstore
    GROUP BY product_id, product_name, category
),

-- 2. Calcular participación y acumulado
pareto_ventas AS (
    SELECT
        product_id,
        product_name,
        category,
        ventas,

        SUM(ventas) OVER () AS ventas_globales,

        ROW_NUMBER() OVER (
            ORDER BY ventas DESC, product_id
        ) AS posicion,

        SUM(ventas) OVER (
            ORDER BY ventas DESC, product_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS ventas_acumuladas

    FROM productos
)

-- 3. Resultado Pareto de ventas
SELECT
    product_id,
    product_name,
    category,
    ROUND(ventas, 2) AS ventas,

    ROUND(
        ventas / NULLIF(ventas_globales, 0) * 100,
        2
    ) AS participacion_pct,

    ROUND(ventas_acumuladas, 2) AS ventas_acumuladas,

    ROUND(
        ventas_acumuladas / NULLIF(ventas_globales, 0) * 100,
        2
    ) AS participacion_acumulada_pct,

    posicion

FROM pareto_ventas
ORDER BY posicion;

-- 4. Cantidad de productos necesarios para alcanzar el 80 % de ventas
WITH productos AS (
    SELECT
        product_id,
        product_name,
        SUM(sales) AS ventas
    FROM fact_superstore
    GROUP BY product_id, product_name
),
pareto AS (
    SELECT
        product_id,
        ventas,

        ROW_NUMBER() OVER (
            ORDER BY ventas DESC, product_id
        ) AS posicion,

        SUM(ventas) OVER (
            ORDER BY ventas DESC, product_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS ventas_acumuladas,

        SUM(ventas) OVER () AS ventas_globales

    FROM productos
)
SELECT
    MIN(
        CASE
            WHEN ventas_acumuladas / NULLIF(ventas_globales, 0) >= 0.80
            THEN posicion
        END
    ) AS productos_para_80_por_ciento_ventas,

    COUNT(*) AS productos_totales

FROM pareto;

-- ==========================================
-- B. PARETO DE GANANCIAS
-- ==========================================

-- 1. Consolidar ganancias por producto
WITH productos AS (
    SELECT
        product_id,
        product_name,
        category,
        SUM(profit) AS ganancias
    FROM fact_superstore
    GROUP BY product_id, product_name, category
),

-- 2. Calcular participación y acumulado
pareto_ganancias AS (
    SELECT
        product_id,
        product_name,
        category,
        ganancias,

        SUM(ganancias) OVER () AS ganancias_globales,

        ROW_NUMBER() OVER (
            ORDER BY ganancias DESC, product_id
        ) AS posicion,

        SUM(ganancias) OVER (
            ORDER BY ganancias DESC, product_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS ganancias_acumuladas

    FROM productos
)

-- 3. Resultado Pareto de ganancias
SELECT
    product_id,
    product_name,
    category,
    ROUND(ganancias, 2) AS ganancias,

    ROUND(
        ganancias / NULLIF(ganancias_globales, 0) * 100,
        2
    ) AS participacion_pct,

    ROUND(ganancias_acumuladas, 2) AS ganancias_acumuladas,

    ROUND(
        ganancias_acumuladas / NULLIF(ganancias_globales, 0) * 100,
        2
    ) AS participacion_acumulada_pct,

    posicion

FROM pareto_ganancias
ORDER BY posicion;

-- 4. Cantidad de productos necesarios para alcanzar el 80 % de ganancias
WITH productos AS (
    SELECT
        product_id,
        product_name,
        SUM(profit) AS ganancias
    FROM fact_superstore
    GROUP BY product_id, product_name
),
pareto AS (
    SELECT
        product_id,
        ganancias,

        ROW_NUMBER() OVER (
            ORDER BY ganancias DESC, product_id
        ) AS posicion,

        SUM(ganancias) OVER (
            ORDER BY ganancias DESC, product_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS ganancias_acumuladas,

        SUM(ganancias) OVER () AS ganancias_globales

    FROM productos
)
SELECT
    MIN(
        CASE
            WHEN ganancias_acumuladas / NULLIF(ganancias_globales, 0) >= 0.80
            THEN posicion
        END
    ) AS productos_para_80_por_ciento_ganancias,

    COUNT(*) AS productos_totales

FROM pareto;
