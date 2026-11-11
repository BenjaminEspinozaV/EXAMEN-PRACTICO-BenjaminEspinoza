
USE superstore_db;

-- 1. Fecha máxima disponible en el dataset
WITH fecha_referencia AS (
    SELECT MAX(order_date) AS fecha_maxima
    FROM fact_superstore
),

-- 2. Métricas RFM por cliente
metricas_rfm AS (
    SELECT
        f.customer_id,
        f.customer_name,
        DATEDIFF(
            r.fecha_maxima,
            MAX(f.order_date)
        ) AS recency,
        COUNT(DISTINCT f.order_id) AS frequency,
        SUM(f.sales) AS monetary
    FROM fact_superstore f
    CROSS JOIN fecha_referencia r
    GROUP BY
        f.customer_id,
        f.customer_name,
        r.fecha_maxima
),

-- 3. Puntuaciones de 1 a 5
puntuaciones AS (
    SELECT
        customer_id,
        customer_name,
        recency,
        frequency,
        monetary,

        NTILE(5) OVER (
            ORDER BY recency DESC
        ) AS score_recency,

        NTILE(5) OVER (
            ORDER BY frequency ASC
        ) AS score_frequency,

        NTILE(5) OVER (
            ORDER BY monetary ASC
        ) AS score_monetary

    FROM metricas_rfm
),

-- 4. Clasificación de clientes
clasificacion AS (
    SELECT
        *,
        score_recency
        + score_frequency
        + score_monetary AS score_total,

        CASE
            WHEN score_recency >= 4
             AND score_frequency >= 4
             AND score_monetary >= 4
                THEN 'Cliente de alto valor'

            WHEN score_recency >= 3
             AND score_frequency >= 4
                THEN 'Cliente recurrente'

            WHEN score_recency <= 2
             AND score_frequency >= 3
                THEN 'Cliente en riesgo'

            WHEN score_recency <= 2
                THEN 'Cliente inactivo'

            ELSE 'Cliente ocasional'
        END AS segmento

    FROM puntuaciones
)

SELECT
    customer_id,
    customer_name,
    recency,
    frequency,
    ROUND(monetary, 2) AS monetary,
    score_recency,
    score_frequency,
    score_monetary,
    score_total,
    segmento
FROM clasificacion
ORDER BY score_total DESC, monetary DESC;

-- 5. Cantidad de clientes por segmento
WITH fecha_referencia AS (
    SELECT MAX(order_date) AS fecha_maxima
    FROM fact_superstore
),
metricas_rfm AS (
    SELECT
        f.customer_id,
        DATEDIFF(r.fecha_maxima, MAX(f.order_date)) AS recency,
        COUNT(DISTINCT f.order_id) AS frequency,
        SUM(f.sales) AS monetary
    FROM fact_superstore f
    CROSS JOIN fecha_referencia r
    GROUP BY f.customer_id, r.fecha_maxima
),
puntuaciones AS (
    SELECT
        *,
        NTILE(5) OVER (ORDER BY recency DESC) AS score_recency,
        NTILE(5) OVER (ORDER BY frequency ASC) AS score_frequency,
        NTILE(5) OVER (ORDER BY monetary ASC) AS score_monetary
    FROM metricas_rfm
),
clasificacion AS (
    SELECT
        CASE
            WHEN score_recency >= 4
             AND score_frequency >= 4
             AND score_monetary >= 4
                THEN 'Cliente de alto valor'
            WHEN score_recency >= 3
             AND score_frequency >= 4
                THEN 'Cliente recurrente'
            WHEN score_recency <= 2
             AND score_frequency >= 3
                THEN 'Cliente en riesgo'
            WHEN score_recency <= 2
                THEN 'Cliente inactivo'
            ELSE 'Cliente ocasional'
        END AS segmento
    FROM puntuaciones
)

SELECT
    segmento,
    COUNT(*) AS cantidad_clientes
FROM clasificacion
GROUP BY segmento
ORDER BY cantidad_clientes DESC;
