-- Creo la base de datos RetailDB para los datos de ventas

CREATE DATABASE RetailDB;

GO
-- Selecciono la base de datos RetailDB para trabajar con ella

USE RetailDB;

GO
-- Creo la tabla staging_Ventas para almacenar los datos de ventas en bruto
CREATE TABLE staging_Ventas (
	Order_ID VARCHAR(50),
	Order_Date VARCHAR(50),
	Customer_Name VARCHAR(100),
	City VARCHAR(100),
	State VARCHAR(100),
	Region VARCHAR(50),
	Country VARCHAR(50),
	Category VARCHAR(100),
	Sub_Category VARCHAR(100),
	Product_Name VARCHAR(100),
	Quantity INT,
	Unit_Price DECIMAL(10,2),
	Revenue DECIMAL(10,2),
	Profit DECIMAL(10,2)
	);
GO

-- Poblar la tabla staging_Ventas con datos del csv con bulk insert

TRUNCATE TABLE staging_Ventas;
GO

BULK INSERT dbo.staging_Ventas
FROM 'D:\Proyecto final Reporting\product_sales_dataset_final.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n',
	TABLOCK
	);


-- Verifico que los datos se hayan cargado correctamente en la tabla staging_Ventas
SELECT TOP 100 * FROM dbo.staging_Ventas;

-- Datos cargados correctamente en la tabla staging_Ventas. Ahora puedo proceder con la normalización y limpieza de los datos antes de insertarlos en las tablas finales del modelo dimensional.
-- Verifico el número total de registros cargados en la tabla staging_Ventas
SELECT COUNT(*) AS total_Registros FROM dbo.staging_Ventas;

-- Verificamos si hay nulos en las columnas:

SELECT 
    SUM(CASE WHEN Order_ID IS NULL THEN 1 ELSE 0 END)       AS nulos_orderid,
    SUM(CASE WHEN Order_Date IS NULL THEN 1 ELSE 0 END)     AS nulos_fecha,
    SUM(CASE WHEN Customer_Name IS NULL THEN 1 ELSE 0 END)  AS nulos_cliente,
    SUM(CASE WHEN Product_Name IS NULL THEN 1 ELSE 0 END)   AS nulos_producto,
    SUM(CASE WHEN Revenue IS NULL THEN 1 ELSE 0 END)        AS nulos_revenue,
    SUM(CASE WHEN Profit IS NULL THEN 1 ELSE 0 END)         AS nulos_profit
FROM staging_Ventas; 

-- Verofico si hay registros duplicados en la columna Order_ID

SELECT Order_ID, COUNT(*) AS cantidad
FROM staging_Ventas
GROUP BY Order_ID
HAVING COUNT(*) > 1
ORDER BY cantidad DESC;

-- Verifico el formato de las fechas en la columna Order_date
SELECT DISTINCT TOP 10 Order_Date 
FROM staging_Ventas;

-- Verifico la conversión de las fechas a YYYY-MM-DD

SELECT TOP 10
    Order_Date,
    CONVERT(DATE, Order_Date, 10) AS fecha_convertida
FROM staging_Ventas;

-- Creo las tablas de Dimenciones DimCliente

CREATE TABLE DimCliente (
ID_Cliente INT IDENTITY(1,1) PRIMARY KEY,
Customer_Name VARCHAR(100) NOT NULL,
City VARCHAR(100),
State VARCHAR(100),
Region VARCHAR(50),
Country VARCHAR(50)
);

GO

-- Ahora poblo la DimCliente con valores unicos y verifico que no existan para evitar duplicados

INSERT INTO DimCliente (Customer_Name, City, State, Region, Country)
SELECT DISTINCT 
    s.Customer_Name,
	s.City,
	s.State,
	s.Region,
	s.Country
FROM dbo.staging_Ventas s
WHERE NOT EXISTS (
    SELECT 1 FROM DimCliente d
	WHERE d.Customer_Name = s.Customer_Name
	AND d.City = s.City
	AND d.State = s.State
	AND d.Region = s.Region
	AND d.Country = s.Country
);
GO


-- Verifico que los datos se hayan insertado correctamente en la DimCliente
SELECT COUNT(*) AS total_clientes FROM DimCliente;
SELECT TOP 5 * FROM DimCliente;

-- Creo la tabla DimProducto

CREATE TABLE DimProducto (
ID_Producto INT IDENTITY(1,1) PRIMARY KEY,
Product_Name VARCHAR(100) NOT NULL,
Category VARCHAR(100),
Sub_Category VARCHAR(100)
);

GO

-- Poblo la DimProducto con valores unicos y verifico que no existan para evitar duplicados

INSERT INTO DimProducto (Product_Name, Category, Sub_Category)
SELECT DISTINCT
    s.Product_Name,
	s.Category,
	s.Sub_Category
FROM dbo.staging_Ventas s
WHERE NOT EXISTS (
 SELECT 1 FROM DimProducto d
 WHERE d.Product_Name = s.Product_Name
 AND d.Category = s.Category
 AND d.Sub_Category = s.Sub_Category
 );

GO

-- Verifico que los datos se hayan insertado correctamente en la DimProducto
SELECT COUNT(*) AS total_productos FROM DimProducto;
SELECT TOP 5 * FROM DimProducto;

-- Ahora verifico las fechas:

SELECT 
    MIN(CONVERT(DATE, Order_Date, 10)) AS fecha_minima,
    MAX(CONVERT(DATE, Order_Date, 10)) AS fecha_maxima
FROM staging_Ventas;

-- Creo la tabla DimFecha con una cte recursiva para generar las fechas entre la fecha mínima y máxima

CREATE TABLE DimFecha (
ID_Fecha INT IDENTITY(1,1) PRIMARY KEY,
Fecha DATE,
Anio INT,
Mes INT,
NombreMes VARCHAR(20),
Trimestre VARCHAR(5),
DiaSemana VARCHAR(20),
EsFinDeSemana BIT
);

-- Creo una CTE recursiva para generar las fechas entre la fecha mínima y máxima

WITH Calendario AS (
    SELECT CAST('2023-01-01' AS DATE) AS Fecha
    UNION ALL
    SELECT DATEADD(DAY, 1, Fecha)
    FROM Calendario
    WHERE Fecha < '2024-12-31'
)
INSERT INTO DimFecha (Fecha, Anio, Mes, NombreMes, Trimestre, DiaSemana, EsFinDeSemana)
SELECT
    Fecha,
    YEAR(Fecha)                                             AS Anio,
    MONTH(Fecha)                                            AS Mes,
    DATENAME(MONTH, Fecha)                                  AS NombreMes,
    'Q' + CAST(DATEPART(QUARTER, Fecha) AS VARCHAR)        AS Trimestre,
    DATENAME(WEEKDAY, Fecha)                                AS DiaSemana,
    CASE WHEN DATEPART(WEEKDAY, Fecha) IN (1,7) THEN 1 
         ELSE 0 END                                         AS EsFinDeSemana
FROM Calendario
-- Modifico la maxima recursión para permitir más de 1000 días si es necesario, ya que por defecto el limite es de 100
OPTION (MAXRECURSION 1000);
GO

-- Verifico que los datos se hayan insertado correctamente en la DimFecha
SELECT TOP 10 * FROM DimFecha;
SELECT COUNT(*) AS total_fechas FROM DimFecha;

-- Creo la tabla de hechos FactVentas

CREATE TABLE FactVentas (
    ID_Venta        INT IDENTITY(1,1) PRIMARY KEY,
    Order_ID        VARCHAR(50),
    ID_Cliente      INT,
    ID_Producto     INT,
    ID_Fecha        INT,
    Quantity        INT,
    Unit_Price      DECIMAL(10,2),
    Revenue         DECIMAL(10,2),
    Profit          DECIMAL(10,2),

    CONSTRAINT FK_Cliente  FOREIGN KEY (ID_Cliente)  REFERENCES DimCliente(ID_Cliente),
    CONSTRAINT FK_Producto FOREIGN KEY (ID_Producto) REFERENCES DimProducto(ID_Producto),
    CONSTRAINT FK_Fecha    FOREIGN KEY (ID_Fecha)    REFERENCES DimFecha(ID_Fecha)
);
GO

-- Ahora poblo la tabla de hechos FactVentas con los datos de la tabla staging_Ventas, relacionando las dimensiones correspondientes

INSERT INTO FactVentas (
    Order_ID, ID_Cliente, ID_Producto, ID_Fecha,
    Quantity, Unit_Price, Revenue, Profit
)
SELECT
    s.Order_ID,
    c.ID_Cliente,
    p.ID_Producto,
    f.ID_Fecha,
    s.Quantity,
    s.Unit_Price,
    s.Revenue,
    s.Profit
FROM staging_Ventas s
INNER JOIN DimCliente c
    ON s.Customer_Name = c.Customer_Name
    AND s.City         = c.City
    AND s.State        = c.State
    AND s.Region       = c.Region
    AND s.Country      = c.Country
INNER JOIN DimProducto p
    ON s.Category      = p.Category
    AND s.Sub_Category = p.Sub_Category
    AND s.Product_Name = p.Product_Name
INNER JOIN DimFecha f
    ON CONVERT(DATE, s.Order_Date, 10) = f.Fecha
WHERE NOT EXISTS (
    SELECT 1 FROM FactVentas fv
    WHERE fv.Order_ID = s.Order_ID
);
GO

-- Verifico que los datos se hayan insertado correctamente en la FactVentas

SELECT COUNT(*) AS total_ventas FROM FactVentas;
SELECT TOP 5 * FROM FactVentas;

-- Fin.