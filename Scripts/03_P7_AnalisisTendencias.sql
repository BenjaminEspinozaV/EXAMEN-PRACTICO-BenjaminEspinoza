
USE superstore_db;

-- 1. Consolidar ventas y ganancias por mes
WITH ventas_mensuales AS (
    SELECT
        CAST(
            CONCAT(DATE_FORMAT(order_date, 'yyyy-MM'), '-01')
            AS DATE
        ) AS mes,
        SUM(sales) AS ventas,
        SUM(profit) AS ganancias
    FROM fact_superstore
    GROUP BY DATE_FORMAT(order_date, 'yyyy-MM')
),

-- 2. Variación respecto al mes anterior y promedio móvil
indicadores AS (
    SELECT
        mes,
        ventas,
        ganancias,

        LAG(ventas, 1) OVER (
            ORDER BY mes
        ) AS ventas_mes_anterior,

        LAG(ganancias, 1) OVER (
            ORDER BY mes
        ) AS ganancias_mes_anterior,

        AVG(ventas) OVER (
            ORDER BY mes
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS promedio_movil_3_meses,

        AVG(ganancias) OVER (
            ORDER BY mes
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS promedio_ganancias_3_meses

    FROM ventas_mensuales
)

-- 3. Comparar con el mismo mes del año anterior
SELECT
    DATE_FORMAT(actual.mes, 'yyyy-MM') AS mes,
    ROUND(actual.ventas, 2) AS ventas,
    ROUND(actual.ganancias, 2) AS ganancias,

    ROUND(
        (actual.ventas - actual.ventas_mes_anterior)
        / NULLIF(actual.ventas_mes_anterior, 0) * 100,
        2
    ) AS variacion_ventas_mes_pct,

    ROUND(
        (actual.ganancias - actual.ganancias_mes_anterior)
        / NULLIF(ABS(actual.ganancias_mes_anterior), 0) * 100,
        2
    ) AS variacion_ganancias_mes_pct,

    ROUND(anterior.ventas, 2) AS ventas_mismo_mes_anio_anterior,

    ROUND(
        (actual.ventas - anterior.ventas)
        / NULLIF(anterior.ventas, 0) * 100,
        2
    ) AS variacion_interanual_ventas_pct,

    ROUND(anterior.ganancias, 2)
        AS ganancias_mismo_mes_anio_anterior,

    ROUND(
        (actual.ganancias - anterior.ganancias)
        / NULLIF(ABS(anterior.ganancias), 0) * 100,
        2
    ) AS variacion_interanual_ganancias_pct,

    ROUND(actual.promedio_movil_3_meses, 2)
        AS promedio_movil_ventas_3_meses,

    ROUND(actual.promedio_ganancias_3_meses, 2)
        AS promedio_movil_ganancias_3_meses

FROM indicadores actual

LEFT JOIN ventas_mensuales anterior
    ON anterior.mes = ADD_MONTHS(actual.mes, -12)

ORDER BY actual.mes;

-- 4. Verificar que no falten meses en el periodo
WITH meses AS (
    SELECT
        CAST(
            CONCAT(DATE_FORMAT(order_date, 'yyyy-MM'), '-01')
            AS DATE
        ) AS mes
    FROM fact_superstore
    GROUP BY DATE_FORMAT(order_date, 'yyyy-MM')
)
SELECT
    COUNT(*) AS meses_con_datos,
    MIN(mes) AS primer_mes,
    MAX(mes) AS ultimo_mes,
    CAST(
        MONTHS_BETWEEN(MAX(mes), MIN(mes)) AS INT
    ) + 1 AS meses_esperados
FROM meses;

-- 5. Tres meses con mayores ventas
WITH ventas_mensuales AS (
    SELECT
        DATE_FORMAT(order_date, 'yyyy-MM') AS mes,
        SUM(sales) AS ventas,
        SUM(profit) AS ganancias
    FROM fact_superstore
    GROUP BY DATE_FORMAT(order_date, 'yyyy-MM')
),
ranking AS (
    SELECT
        *,
        RANK() OVER (ORDER BY ventas DESC) AS posicion
    FROM ventas_mensuales
)
SELECT
    mes,
    ROUND(ventas, 2) AS ventas,
    ROUND(ganancias, 2) AS ganancias,
    posicion
FROM ranking
WHERE posicion <= 3
ORDER BY posicion;

-- 6. Tres meses con menores ventas
WITH ventas_mensuales AS (
    SELECT
        DATE_FORMAT(order_date, 'yyyy-MM') AS mes,
        SUM(sales) AS ventas,
        SUM(profit) AS ganancias
    FROM fact_superstore
    GROUP BY DATE_FORMAT(order_date, 'yyyy-MM')
),
ranking AS (
    SELECT
        *,
        RANK() OVER (ORDER BY ventas ASC) AS posicion
    FROM ventas_mensuales
)
SELECT
    mes,
    ROUND(ventas, 2) AS ventas,
    ROUND(ganancias, 2) AS ganancias,
    posicion
FROM ranking
WHERE posicion <= 3
ORDER BY posicion;
