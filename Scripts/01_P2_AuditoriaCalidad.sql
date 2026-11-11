
USE superstore_db;

-- 1. Resumen general de calidad
SELECT
    COUNT(*) AS total_registros,

    COUNT(DISTINCT row_id) AS row_id_unicos,

    COUNT(*) - COUNT(DISTINCT row_id) AS posibles_duplicados,

    COUNT(DISTINCT order_id) AS ordenes_unicas,

    COUNT(DISTINCT customer_id) AS clientes_unicos,

    SUM(CASE
        WHEN sales <= 0 THEN 1
        ELSE 0
    END) AS ventas_no_validas,

    SUM(CASE
        WHEN discount < 0 OR discount > 1 THEN 1
        ELSE 0
    END) AS descuentos_invalidos,

    SUM(CASE
        WHEN ship_date < order_date THEN 1
        ELSE 0
    END) AS envios_inconsistentes

FROM fact_superstore;


-- 2. Comprobar valores NULL
SELECT
    SUM(CASE WHEN row_id IS NULL THEN 1 ELSE 0 END) AS row_id_nulos,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS order_id_nulos,
    SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END) AS order_date_nulos,
    SUM(CASE WHEN ship_date IS NULL THEN 1 ELSE 0 END) AS ship_date_nulos,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS customer_id_nulos,
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS product_id_nulos,
    SUM(CASE WHEN sales IS NULL THEN 1 ELSE 0 END) AS sales_nulos,
    SUM(CASE WHEN quantity IS NULL THEN 1 ELSE 0 END) AS quantity_nulos,
    SUM(CASE WHEN discount IS NULL THEN 1 ELSE 0 END) AS discount_nulos,
    SUM(CASE WHEN profit IS NULL THEN 1 ELSE 0 END) AS profit_nulos
FROM fact_superstore;


-- 3. Identificar Row ID duplicados
SELECT
    row_id,
    COUNT(*) AS cantidad
FROM fact_superstore
GROUP BY row_id
HAVING COUNT(*) > 1
ORDER BY cantidad DESC;


-- 4. Mostrar ventas no válidas
SELECT *
FROM fact_superstore
WHERE sales <= 0
LIMIT 20;


-- 5. Mostrar descuentos incorrectos
SELECT *
FROM fact_superstore
WHERE discount < 0 OR discount > 1
LIMIT 20;


-- 6. Mostrar fechas de envío inconsistentes
SELECT *
FROM fact_superstore
WHERE ship_date < order_date
LIMIT 20;
