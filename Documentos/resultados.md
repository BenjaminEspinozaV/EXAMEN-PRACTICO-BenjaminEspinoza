Durante el desarrollo del proyecto se trabajó con el dataset Sample Superstore, compuesto por 9.994 registros y 21 campos relacionados con pedidos, clientes, productos, ventas, descuentos y ganancias.

En la etapa inicial se realizó una auditoría para verificar la estructura y calidad de los datos. Se comprobó que los registros presentaban una estructura consistente, sin columnas incompletas, valores nulos, identificadores duplicados ni fechas inválidas. También se verificó que no existieran ventas menores o iguales a cero, descuentos fuera del intervalo permitido ni fechas de envío anteriores a las fechas de pedido.

Posteriormente, se implementó el almacenamiento en Apache Hive mediante dos tablas. La tabla stg_superstore permitió importar los datos originales en formato STRING, mientras que fact_superstore almacenó la información transformada con tipos de datos adecuados, utilizando DATE, INT, DECIMAL y STRING. La tabla analítica se almacenó en formato ORC para facilitar el procesamiento de consultas.

A partir de la información cargada se desarrollaron consultas analíticas para estudiar el comportamiento comercial por región y año, segmentar clientes mediante el modelo RFM, identificar productos de mayor y menor rentabilidad, analizar el impacto de los descuentos, estudiar las tendencias mensuales y determinar la concentración de ventas y ganancias mediante el análisis Pareto.

Los resultados de estas consultas permiten organizar la información comercial desde diferentes perspectivas y obtener indicadores que facilitan la interpretación del comportamiento del negocio.