
USE superstore_db;

-- 1. Ventas y ganancias por región y año
WITH ventas_anuales AS (
    SELECT
        region,
        YEAR(order_date) AS anio,
        SUM(sales) AS ventas_totales,
        SUM(profit) AS ganancias_totales,
        CASE
            WHEN SUM(sales) = 0 THEN 0
            ELSE SUM(profit) / SUM(sales) * 100
        END AS margen_porcentual
    FROM fact_superstore
    GROUP BY region, YEAR(order_date)
),

-- 2. Comparación con el año anterior
comparacion AS (
    SELECT
        region,
        anio,
        ventas_totales,
        ganancias_totales,
        margen_porcentual,

        LAG(ventas_totales) OVER (
            PARTITION BY region
            ORDER BY anio
        ) AS ventas_anio_anterior,

        LAG(ganancias_totales) OVER (
            PARTITION BY region
            ORDER BY anio
        ) AS ganancias_anio_anterior

    FROM ventas_anuales
)

-- 3. Resultado final
SELECT
    region,
    anio,
    ROUND(ventas_totales, 2) AS ventas,
    ROUND(ganancias_totales, 2) AS ganancias,
    ROUND(margen_porcentual, 2) AS margen_pct,

    ROUND(
        (ventas_totales - ventas_anio_anterior)
        / NULLIF(ventas_anio_anterior, 0) * 100,
        2
    ) AS variacion_ventas_pct,

    ROUND(
        (ganancias_totales - ganancias_anio_anterior)
        / NULLIF(ABS(ganancias_anio_anterior), 0) * 100,
        2
    ) AS variacion_ganancias_pct

FROM comparacion
ORDER BY region, anio;

-- 4. Desempeño general por región
WITH resumen_region AS (
    SELECT
        region,
        SUM(sales) AS ventas_totales,
        SUM(profit) AS ganancias_totales,
        SUM(profit) / NULLIF(SUM(sales), 0) * 100 AS margen_pct
    FROM fact_superstore
    GROUP BY region
)

SELECT
    region,
    ROUND(ventas_totales, 2) AS ventas,
    ROUND(ganancias_totales, 2) AS ganancias,
    ROUND(margen_pct, 2) AS margen_pct,
    RANK() OVER (ORDER BY ganancias_totales DESC) AS ranking_ganancias,
    RANK() OVER (ORDER BY ganancias_totales ASC) AS ranking_menores_ganancias
FROM resumen_region
ORDER BY ganancias_totales DESC;
