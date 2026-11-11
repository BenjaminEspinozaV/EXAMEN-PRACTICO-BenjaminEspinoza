Para mejorar la organización y el procesamiento de los datos se aplicaron diferentes prácticas dentro de Apache Hive:

Separación de tablas: se utilizaron tablas de staging y analítica para diferenciar los datos originales de los datos transformados.

Formato ORC: se utilizó para almacenar la tabla analítica, aprovechando su estructura columnar y sus mecanismos de compresión.

Conversión de tipos de datos: se transformaron los campos originales a tipos adecuados para realizar operaciones y cálculos correctamente.

Expresiones CTE: se utilizaron para dividir las consultas complejas en etapas más comprensibles y organizadas.

Funciones de ventana: se aplicaron para realizar comparaciones temporales, rankings, segmentaciones y cálculos acumulativos.

Consultas específicas: se seleccionaron únicamente las columnas necesarias para cada análisis, evitando recuperar información innecesaria.

Estadísticas de Hive: se contempla su recopilación mediante ANALYZE TABLE para proporcionar información al optimizador de consultas.

Estas prácticas permiten mantener un proceso de análisis estructurado y facilitan la ampliación del proyecto para trabajar con conjuntos de datos de mayor tamaño.