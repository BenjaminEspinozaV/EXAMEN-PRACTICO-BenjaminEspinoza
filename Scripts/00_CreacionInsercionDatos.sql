--Creacion de la bdd y la tabla stg_superstore
CREATE DATABASE IF NOT EXISTS superstore_db;

USE superstore_db;

SHOW DATABASES;

CREATE TABLE IF NOT EXISTS stg_superstore (
    row_id STRING,
    order_id STRING,
    order_date STRING,
    ship_date STRING,
    ship_mode STRING,
    customer_id STRING,
    customer_name STRING,
    segment STRING,
    country STRING,
    city STRING,
    state STRING,
    postal_code STRING,
    region STRING,
    product_id STRING,
    category STRING,
    sub_category STRING,
    product_name STRING,
    sales STRING,
    quantity STRING,
    discount STRING,
    profit STRING
)
ROW FORMAT SERDE
'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
    "separatorChar" = ",",
    "quoteChar" = "\"",
    "escapeChar" = "\\"
)
STORED AS TEXTFILE
TBLPROPERTIES ("skip.header.line.count"="1");


DESCRIBE stg_superstore;

--carga de datos en la tabla stg_superstore
USE superstore_db;

LOAD DATA LOCAL INPATH '/tmp/Sample-Superstore.csv'
OVERWRITE INTO TABLE stg_superstore;

SELECT COUNT(*) FROM stg_superstore;

SELECT *
FROM stg_superstore
LIMIT 10;

-- creacion de la tabla fact_superstore tabla analitica
CREATE TABLE IF NOT EXISTS fact_superstore (
    row_id INT,
    order_id STRING,
    order_date DATE,
    ship_date DATE,
    ship_mode STRING,
    customer_id STRING,
    customer_name STRING,
    segment STRING,
    country STRING,
    city STRING,
    state STRING,
    postal_code STRING,
    region STRING,
    product_id STRING,
    category STRING,
    sub_category STRING,
    product_name STRING,
    sales DECIMAL(14,2),
    quantity INT,
    discount DECIMAL(6,4),
    profit DECIMAL(14,2)
)
STORED AS ORC;      
DESCRIBE fact_superstore;

-- datos ya con tipos correspondientes

INSERT OVERWRITE TABLE fact_superstore
SELECT
    CAST(TRIM(row_id) AS INT),
    TRIM(order_id),

    CAST(
        FROM_UNIXTIME(
            UNIX_TIMESTAMP(TRIM(order_date), 'M/d/yyyy'),
            'yyyy-MM-dd'
        ) AS DATE
    ),

    CAST(
        FROM_UNIXTIME(
            UNIX_TIMESTAMP(TRIM(ship_date), 'M/d/yyyy'),
            'yyyy-MM-dd'
        ) AS DATE
    ),

    TRIM(ship_mode),
    TRIM(customer_id),
    TRIM(customer_name),
    TRIM(segment),
    TRIM(country),
    TRIM(city),
    TRIM(state),
    TRIM(postal_code),
    TRIM(region),
    TRIM(product_id),
    TRIM(category),
    TRIM(sub_category),
    TRIM(product_name),

    CAST(TRIM(sales) AS DECIMAL(14,2)),
    CAST(TRIM(quantity) AS INT),
    CAST(TRIM(discount) AS DECIMAL(6,4)),
    CAST(TRIM(profit) AS DECIMAL(14,2))

FROM stg_superstore;