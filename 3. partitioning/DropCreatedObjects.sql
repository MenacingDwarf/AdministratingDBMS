USE Northwind;

DROP TABLE OrdersPartioned;

ALTER DATABASE Northwind  
REMOVE FILE f1;

ALTER DATABASE Northwind  
REMOVE FILE f2;

ALTER DATABASE Northwind  
REMOVE FILE f3;

DROP PARTITION SCHEME my_ps;

DROP PARTITION FUNCTION my_pf;

ALTER DATABASE Northwind  
REMOVE FILEGROUP g1;

ALTER DATABASE Northwind  
REMOVE FILEGROUP g2;

ALTER DATABASE Northwind  
REMOVE FILEGROUP g3;