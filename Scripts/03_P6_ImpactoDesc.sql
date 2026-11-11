
USE superstore_db;

-- 1. Clasificar cada registro según su descuento
WITH registros_descuento AS (
    SELECT
        category,
        sub_category,
        sales,
        profit,
        discount,

        CASE
            WHEN discount = 0 THEN 'Sin descuento'
            WHEN discount > 0 AND discount <= 0.20
                THEN 'Descuento bajo'
            WHEN discount > 0.20 AND discount <= 0.50
                THEN 'Descuento medio'
            WHEN discount > 0.50
                THEN 'Descuento alto'
        END AS rango_descuento

    FROM fact_superstore
)

-- 2. Resultados generales por rango de descuento
SELECT
    rango_descuento,
    COUNT(*) AS cantidad_registros,
    ROUND(SUM(sales), 2) AS ventas_totales,
    ROUND(SUM(profit), 2) AS ganancias_totales,

    ROUND(
        CASE
            WHEN SUM(sales) = 0 THEN 0
            ELSE SUM(profit) / SUM(sales) * 100
        END,
        2
    ) AS margen_pct,

    SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END)
        AS registros_con_perdidas,

    SUM(CASE WHEN profit <= 0 THEN 1 ELSE 0 END)
        AS registros_no_rentables,

    ROUND(
        SUM(CASE WHEN profit <= 0 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS porcentaje_no_rentable,

    ROUND(AVG(discount) * 100, 2)
        AS descuento_promedio_pct

FROM registros_descuento
GROUP BY rango_descuento
ORDER BY
    CASE rango_descuento
        WHEN 'Sin descuento' THEN 1
        WHEN 'Descuento bajo' THEN 2
        WHEN 'Descuento medio' THEN 3
        WHEN 'Descuento alto' THEN 4
    END;

-- 3. Impacto de los descuentos por categoría y subcategoría
WITH registros_descuento AS (
    SELECT
        category,
        sub_category,
        sales,
        profit,
        discount,

        CASE
            WHEN discount = 0 THEN 'Sin descuento'
            WHEN discount > 0 AND discount <= 0.20
                THEN 'Descuento bajo'
            WHEN discount > 0.20 AND discount <= 0.50
                THEN 'Descuento medio'
            WHEN discount > 0.50
                THEN 'Descuento alto'
        END AS rango_descuento

    FROM fact_superstore
)

SELECT
    category,
    sub_category,
    rango_descuento,
    COUNT(*) AS cantidad_registros,
    ROUND(SUM(sales), 2) AS ventas,
    ROUND(SUM(profit), 2) AS ganancias,

    ROUND(
        CASE
            WHEN SUM(sales) = 0 THEN 0
            ELSE SUM(profit) / SUM(sales) * 100
        END,
        2
    ) AS margen_pct,

    SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END)
        AS registros_con_perdidas,

    ROUND(
        SUM(CASE WHEN profit <= 0 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS porcentaje_no_rentable,

    ROUND(AVG(discount) * 100, 2)
        AS descuento_promedio_pct

FROM registros_descuento
GROUP BY category, sub_category, rango_descuento
ORDER BY category, sub_category, rango_descuento;

-- 4. Subcategorías con mayores pérdidas acumuladas
SELECT
    category,
    sub_category,
    COUNT(*) AS cantidad_registros,
    SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END)
        AS registros_con_perdidas,
    ROUND(SUM(profit), 2) AS ganancias_totales,
    ROUND(AVG(discount) * 100, 2) AS descuento_promedio_pct
FROM fact_superstore
GROUP BY category, sub_category
ORDER BY ganancias_totales ASC
LIMIT 10;
