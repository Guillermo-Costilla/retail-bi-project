# Retail BI Project

Proyecto personal de Business Intelligence orientado a la toma de decisiones comerciales.

## Descripción

Pipeline de datos completo que transforma un dataset de ventas retail de 200.000 transacciones 
en un modelo dimensional optimizado para análisis en Power BI.

## Tecnologías utilizadas

- SQL Server 2022
- SQL Server Management Studio 22
- Power BI Desktop
- Git / GitHub

## Arquitectura del modelo

El proyecto implementa un esquema estrella compuesto por:

- `staging_Ventas` — tabla de aterrizaje con los datos crudos del CSV
- `DimCliente` — 197.000 clientes únicos con ciudad, estado y región
- `DimProducto` — 51 productos únicos con categoría y subcategoría
- `DimFecha` — calendario continuo 2023-2024 con atributos de tiempo
- `FactVentas` — 200.000 transacciones normalizadas con claves foráneas

## Pipeline

CSV (200.000 filas) 
→ staging_Ventas (SQL Server)
→ Normalización y limpieza
→ Esquema estrella (DimCliente, DimProducto, DimFecha, FactVentas)
→ Power BI (dashboard de toma de decisiones)


## Estado del proyecto

- [x] Carga de datos al staging
- [x] Limpieza y validación
- [x] Creación de dimensiones
- [x] Creación de tabla de hechos
- [ ] Conexión Power BI
- [ ] Medidas DAX
- [ ] Dashboard final

Link dataset (CSV): https://www.kaggle.com/datasets/yashyennewar/product-sales-dataset-2023-2024?resource=download
