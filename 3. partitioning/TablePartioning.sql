USE Northwind;
GO

-- creating groups of files
ALTER DATABASE Northwind
ADD FILEGROUP g1;

ALTER DATABASE Northwind
ADD FILEGROUP g2;

ALTER DATABASE Northwind
ADD FILEGROUP g3;

-- adding files to each group
ALTER DATABASE Northwind
ADD FILE
(
NAME = f1,
FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\f1.ndf'
) TO FILEGROUP g1;

ALTER DATABASE Northwind
ADD FILE
(
NAME = f2,
FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\f2.ndf'
) TO FILEGROUP g2;

ALTER DATABASE Northwind
ADD FILE
(
NAME = f3,
FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\f3.ndf'
) TO FILEGROUP g3;

-- creating a partition function
CREATE PARTITION FUNCTION my_pf(int)
AS
RANGE LEFT
FOR VALUES (300, 600)

-- creating a partition scheme
CREATE PARTITION SCHEME my_ps
AS PARTITION my_pf
TO (g1, g2, g3)


-- creating a new partitioned table
CREATE TABLE OrdersPartioned (
	"OrderID" "int" IDENTITY (1, 1) NOT NULL ,
	"CustomerID" nchar (5) NULL ,
	"EmployeeID" "int" NULL ,
	"OrderDate" "datetime" NULL ,
	"RequiredDate" "datetime" NULL ,
	"ShippedDate" "datetime" NULL ,
	"ShipVia" "int" NULL ,
	"Freight" "money" NULL CONSTRAINT "DF_OrdersPartioned_Freight" DEFAULT (0),
	"ShipName" nvarchar (40) NULL ,
	"ShipAddress" nvarchar (60) NULL ,
	"ShipCity" nvarchar (15) NULL ,
	"ShipRegion" nvarchar (15) NULL ,
	"ShipPostalCode" nvarchar (10) NULL ,
	"ShipCountry" nvarchar (15) NULL ,
) ON my_ps("OrderID");
SET IDENTITY_INSERT OrdersPartioned ON; 

DECLARE @OrderID int,
	@CustomerID nchar (5),
	@EmployeeID int,
	@OrderDate datetime,
	@RequiredDate datetime,
	@ShippedDate datetime,
	@ShipVia int,
	@Freight money,
	@ShipName nvarchar (40),
	@ShipAddress nvarchar (60),
	@ShipCity nvarchar (15),
	@ShipRegion nvarchar (15),
	@ShipPostalCode nvarchar (10),
	@ShipCountry nvarchar (15);

-- now fill the table with data (the data is taken from the original, unpartitioned table)
DECLARE OrdersCursor CURSOR FOR 
    SELECT "OrderID", "CustomerID", "EmployeeID", "OrderDate", "RequiredDate", "ShippedDate", "ShipVia", "Freight", "ShipName", "ShipAddress", "ShipCity", "ShipRegion", "ShipPostalCode", "ShipCountry"
FROM Orders 
 
OPEN OrdersCursor 
FETCH NEXT FROM OrdersCursor INTO @OrderID, @CustomerID, @EmployeeID, @OrderDate, @RequiredDate, @ShippedDate, @ShipVia, @Freight, @ShipName, @ShipAddress, @ShipCity, @ShipRegion, @ShipPostalCode, @ShipCountry 
 
WHILE @@FETCH_STATUS = 0 
BEGIN 
	INSERT INTO OrdersPartioned ("OrderID", "CustomerID", "EmployeeID", "OrderDate", "RequiredDate", "ShippedDate", "ShipVia", "Freight", "ShipName", "ShipAddress", "ShipCity", "ShipRegion", "ShipPostalCode", "ShipCountry")
	VALUES (@OrderID, @CustomerID, @EmployeeID, @OrderDate, @RequiredDate, @ShippedDate, @ShipVia, @Freight, @ShipName, @ShipAddress, @ShipCity, @ShipRegion, @ShipPostalCode, @ShipCountry)
	FETCH NEXT FROM OrdersCursor INTO @OrderID, @CustomerID, @EmployeeID, @OrderDate, @RequiredDate, @ShippedDate, @ShipVia, @Freight, @ShipName, @ShipAddress, @ShipCity, @ShipRegion, @ShipPostalCode, @ShipCountry
END

CLOSE OrdersCursor 
DEALLOCATE OrdersCursor