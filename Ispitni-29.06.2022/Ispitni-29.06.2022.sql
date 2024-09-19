CREATE DATABASE IB210224_1
GO
USE IB210224_1

CREATE TABLE Proizvodi
(
	ProizvodID INT CONSTRAINT PK_Proizvodi PRIMARY KEY IDENTITY(1,1),
	Naziv NVARCHAR(50) NOT NULL,
	SifraProizvoda NVARCHAR(50) NOT NULL,
	Boja NVARCHAR(15),
	NazivKategorije NVARCHAR(50) NOT NULL,
	Tezina DECIMAL(18,2)
)
CREATE TABLE ZaglavljeNarudzbe
(
	NarudzbaID INT CONSTRAINT PK_ZaglavljeNarudzbe PRIMARY KEY IDENTITY(1,1),
	DatumNarudzbe DATETIME NOT NULL,
	DatumIsporuke DATETIME,
	ImeKupca NVARCHAR(50) NOT NULL,
	PrezimeKupca NVARCHAR(50) NOT NULL,
	NazivTeritorije NVARCHAR(50) NOT NULL,
	NazivRegije NVARCHAR(50) NOT NULL,
	NacinIsporuke NVARCHAR(50) NOT NULL
)
CREATE TABLE DetaljiNarudzbe
(
	DetaljiNarudzbe INT CONSTRAINT PK_DetaljiNarudzbe PRIMARY KEY IDENTITY(1,1),
	NarudzbaID INT NOT NULL CONSTRAINT FK_DetaljiNarudzbe_ZaglavljeNarudzbe FOREIGN KEY REFERENCES ZaglavljeNarudzbe(NarudzbaID),
	ProizvodID INT NOT NULL CONSTRAINT FK_DetaljiNarudzbe_Proizvodi FOREIGN KEY REFERENCES Proizvodi(ProizvodID),
	Cijena MONEY NOT NULL,
	Kolicina SMALLINT NOT NULL,
	Popust MONEY NOT NULL
)

SET IDENTITY_INSERT Proizvodi ON
INSERT INTO Proizvodi(ProizvodID, Naziv, SifraProizvoda, Boja, NazivKategorije, Tezina)
SELECT P.ProductID, P.Name, P.ProductNumber, P.Color, PC.Name, ISNULL(P.Weight, 0)
FROM AdventureWorks2019.Production.Product AS P
INNER JOIN AdventureWorks2019.Production.ProductSubcategory AS PS 
ON P.ProductSubcategoryID=PS.ProductSubcategoryID
INNER JOIN AdventureWorks2019.Production.ProductCategory AS PC
ON PS.ProductCategoryID = PC.ProductCategoryID
SET IDENTITY_INSERT Proizvodi OFF

SET IDENTITY_INSERT ZaglavljeNarudzbe ON
INSERT INTO ZaglavljeNarudzbe(NarudzbaID, DatumNarudzbe, DatumIsporuke, ImeKupca, PrezimeKupca, NazivTeritorije, NazivRegije, NacinIsporuke)
SELECT SOH.SalesOrderID, SOH.OrderDate, SOH.ShipDate, P.FirstName, P.LastName, ST.Name, ST.[Group], SM.Name
FROM
AdventureWorks2019.Sales.SalesOrderHeader AS SOH
INNER JOIN AdventureWorks2019.Sales.Customer AS C
ON SOH.CustomerID = C.CustomerID
INNER JOIN AdventureWorks2019.Person.Person AS P
ON C.PersonID = P.BusinessEntityID
INNER JOIN AdventureWorks2019.Sales.SalesTerritory AS ST
ON SOH.TerritoryID = ST.TerritoryID
INNER JOIN AdventureWorks2019.Purchasing.ShipMethod AS SM
ON SOH.ShipMethodID = SM.ShipMethodID
SET IDENTITY_INSERT ZaglavljeNarudzbe OFF

INSERT INTO DetaljiNarudzbe
SELECT SOD.SalesOrderID, SOD.ProductID, SOD.UnitPrice, SOD.OrderQty, SOD.UnitPriceDiscount
FROM AdventureWorks2019.Sales.SalesOrderDetail AS SOD


USE AdventureWorks2019

SELECT D.Name, COUNT(E.BusinessEntityID)
FROM HumanResources.EmployeeDepartmentHistory AS EDH
INNER JOIN HumanResources.Department AS D
ON EDH.DepartmentID = D.DepartmentID
INNER JOIN HumanResources.Employee AS E
ON E.BusinessEntityID = EDH.BusinessEntityID
WHERE EDH.EndDate IS NULL AND DATEDIFF(YEAR, E.HireDate, GETDATE()) > 10
GROUP BY D.Name
ORDER BY 2 DESC

SELECT MONTH(POH.OrderDate), SUM(POD.LineTotal), SUM(POD.ReceivedQty), (SELECT COUNT(*)
	FROM Purchasing.PurchaseOrderDetail AS POD1
	INNER JOIN Purchasing.PurchaseOrderHeader AS POH1
	ON POH1.PurchaseOrderID = POD1.PurchaseOrderID
	INNER JOIN Purchasing.ShipMethod AS SM1
	ON POH1.ShipMethodID = SM1.ShipMethodID
	WHERE MONTH(POH.OrderDate) = MONTH(POH1.OrderDate) AND POD1.RejectedQty > 100
	 AND YEAR(POH1.OrderDate) = 2012 AND POH1.Freight BETWEEN 500 AND 2500  AND SM1.Name LIKE '%CARGO%')
FROM Purchasing.PurchaseOrderDetail AS POD
INNER JOIN Purchasing.PurchaseOrderHeader AS POH
ON POD.PurchaseOrderID = POH.PurchaseOrderID
INNER JOIN Purchasing.ShipMethod AS SM
ON SM.ShipMethodID = POH.ShipMethodID
WHERE YEAR(POH.OrderDate) = 2012 AND POH.Freight BETWEEN 500 AND 2500  AND SM.Name LIKE '%CARGO%'
GROUP BY MONTH(POH.OrderDate)

SELECT COUNT(SOH.SalesOrderID), E.BusinessEntityID
FROM HumanResources.Employee AS E
INNER JOIN Sales.SalesPerson AS SP
ON E.BusinessEntityID = SP.BusinessEntityID
INNER JOIN Sales.SalesOrderHeader AS SOH
ON SP.BusinessEntityID = SOH.SalesPersonID
INNER JOIN Sales.SalesTerritory AS ST
ON ST.TerritoryID = SOH.TerritoryID
WHERE (YEAR(SOH.OrderDate) = 2011 OR YEAR(SOH.OrderDate) = 2012) AND 
(SELECT COUNT(*)
FROM Sales.SalesOrderDetail AS SOD1
WHERE SOD1.SalesOrderID = SOH.SalesOrderID
AND SOD1.UnitPriceDiscount > 0) >= 2
AND ST.Name IN ('United Kingdom', 'France', 'Canada')
GROUP BY E.BusinessEntityID

USE Northwind
SELECT P.ProductName, S.CompanyName, P.UnitsInStock, LEFT(P.ProductName, 2) + '/' + SUBSTRING(S.CompanyName, CHARINDEX(' ' ,S.CompanyName) + 1, 2) + IIF(LEN(P.ProductID) = 1, CAST(P.ProductID AS NVARCHAR) + 'a', REVERSE(CAST(P.ProductID AS NVARCHAR)))
FROM Products AS P
INNER JOIN Suppliers AS S
ON S.SupplierID = P.SupplierID
WHERE LEN(S.CompanyName) - LEN(REPLACE(S.CompanyName, ' ', '')) IN (1, 2)

USE IB210224_1
CREATE INDEX IX_Proizvodi_Sifra_NazivProizvoda
ON Proizvodi(SifraProizvoda, Naziv)
SELECT * 
FROM Proizvodi
WHERE SifraProizvoda LIKE 'A%' OR Naziv LIKE 'B%'

GO
CREATE OR ALTER PROCEDURE sp_search_products
(
	@NazivKategorije NVARCHAR(50) = NULL,
	@Tezina DECIMAL(18,2) = NULL
)
AS
BEGIN
SELECT * 
FROM Proizvodi AS P
WHERE (P.NazivKategorije LIKE @NazivKategorije + '%') OR (P.Tezina > @Tezina)
END
GO
EXEC sp_search_products C