
USE superstore_db;

-- 1. Consolidar información por producto
WITH productos AS (
    SELECT
        product_id,
        product_name,
        category,
        sub_category,
        SUM(sales) AS ventas_totales,
        SUM(profit) AS ganancias_totales,
        SUM(quantity) AS unidades_vendidas,

        CASE
            WHEN SUM(sales) = 0 THEN 0
            ELSE SUM(profit) / SUM(sales) * 100
        END AS margen_pct

    FROM fact_superstore
    GROUP BY
        product_id,
        product_name,
        category,
        sub_category
),

-- 2. Rankings y acumulados
rankings AS (
    SELECT
        *,
        RANK() OVER (
            PARTITION BY category
            ORDER BY ganancias_totales DESC
        ) AS ranking_ganancias_categoria,

        DENSE_RANK() OVER (
            PARTITION BY category
            ORDER BY unidades_vendidas DESC
        ) AS ranking_unidades_categoria,

        RANK() OVER (
            ORDER BY unidades_vendidas DESC
        ) AS ranking_volumen_general,

        RANK() OVER (
            ORDER BY margen_pct ASC
        ) AS ranking_menor_margen,

        SUM(ganancias_totales) OVER (
            PARTITION BY category
            ORDER BY ganancias_totales DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS ganancias_acumuladas_categoria

    FROM productos
)

-- 3. Mostrar todos los rankings
SELECT
    product_id,
    product_name,
    category,
    sub_category,
    ROUND(ventas_totales, 2) AS ventas,
    ROUND(ganancias_totales, 2) AS ganancias,
    unidades_vendidas,
    ROUND(margen_pct, 2) AS margen_pct,
    ranking_ganancias_categoria,
    ranking_unidades_categoria,
    ranking_volumen_general,
    ranking_menor_margen,
    ROUND(ganancias_acumuladas_categoria, 2)
        AS ganancias_acumuladas_categoria
FROM rankings
ORDER BY category, ranking_ganancias_categoria;

-- 4. Cinco productos con mayores ganancias por categoría
WITH productos AS (
    SELECT
        product_id,
        product_name,
        category,
        SUM(sales) AS ventas,
        SUM(profit) AS ganancias,
        SUM(quantity) AS unidades,
        SUM(profit) / NULLIF(SUM(sales), 0) * 100 AS margen_pct
    FROM fact_superstore
    GROUP BY product_id, product_name, category
),
ranking AS (
    SELECT
        *,
        RANK() OVER (
            PARTITION BY category
            ORDER BY ganancias DESC
        ) AS posicion
    FROM productos
)
SELECT
    category,
    product_name,
    ROUND(ventas, 2) AS ventas,
    ROUND(ganancias, 2) AS ganancias,
    ROUND(margen_pct, 2) AS margen_pct,
    posicion
FROM ranking
WHERE posicion <= 5
ORDER BY category, posicion;

-- 5. Cinco productos con mayor volumen de unidades
WITH productos AS (
    SELECT
        product_id,
        product_name,
        category,
        SUM(quantity) AS unidades,
        SUM(sales) AS ventas,
        SUM(profit) AS ganancias
    FROM fact_superstore
    GROUP BY product_id, product_name, category
),
ranking AS (
    SELECT
        *,
        RANK() OVER (
            ORDER BY unidades DESC
        ) AS posicion
    FROM productos
)
SELECT
    product_name,
    category,
    unidades,
    ROUND(ventas, 2) AS ventas,
    ROUND(ganancias, 2) AS ganancias,
    posicion
FROM ranking
WHERE posicion <= 5
ORDER BY posicion;

-- 6. Cinco productos con menor margen de rentabilidad
WITH productos AS (
    SELECT
        product_id,
        product_name,
        category,
        SUM(sales) AS ventas,
        SUM(profit) AS ganancias,
        SUM(quantity) AS unidades,
        SUM(profit) / NULLIF(SUM(sales), 0) * 100 AS margen_pct
    FROM fact_superstore
    GROUP BY product_id, product_name, category
),
ranking AS (
    SELECT
        *,
        RANK() OVER (
            ORDER BY margen_pct ASC
        ) AS posicion
    FROM productos
    WHERE ventas > 0
)
SELECT
    product_name,
    category,
    ROUND(ventas, 2) AS ventas,
    ROUND(ganancias, 2) AS ganancias,
    unidades,
    ROUND(margen_pct, 2) AS margen_pct,
    posicion
FROM ranking
WHERE posicion <= 5
ORDER BY posicion;
