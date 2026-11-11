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