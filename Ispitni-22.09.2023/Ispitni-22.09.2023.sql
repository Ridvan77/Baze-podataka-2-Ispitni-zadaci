CREATE DATABASE BrojIndeksa
GO
USE BrojIndeksa

CREATE TABLE Uposlenici
(
	UposlenikID CHAR(9) CONSTRAINT PK_Uposlenici PRIMARY KEY,
	Ime VARCHAR(20) NOT NULL,
	Prezime VARCHAR(20) NOT NULL,
	DatumZaposlenja DATETIME NOT NULL,
	OpisPosla VARCHAR(50) NOT NULL
)

CREATE TABLE Naslovi
(
	NaslovID VARCHAR(6) CONSTRAINT PK_Naslovi PRIMARY KEY,
	Naslov VARCHAR(80) NOT NULL,
	Tip CHAR(12) NOT NULL,
	Cijena MONEY,
	NazivIzdavaca VARCHAR(40),
	GradIzadavaca VARCHAR(20),
	DrzavaIzdavaca VARCHAR(30)
)

CREATE TABLE Prodavnice
(
	ProdavnicaID CHAR(4) CONSTRAINT PK_Prodavnice PRIMARY KEY,
	NazivProdavnice VARCHAR(40),
	Grad VARCHAR(40)
)

CREATE TABLE Prodaja
(
	ProdavnicaID CHAR(4) CONSTRAINT FK_Prodaja_Prodavnice FOREIGN KEY REFERENCES Prodavnice(ProdavnicaID),
	BrojNarudzbe VARCHAR(20) CONSTRAINT PK_Prodaja PRIMARY KEY(BrojNarudzbe, ProdavnicaID, NaslovID),
	NaslovID VARCHAR(6) CONSTRAINT FK_Prodaja_Naslovi FOREIGN KEY REFERENCES Naslovi(NaslovID),
	DatumNarudzbe DATETIME NOT NULL,
	Kolicina SMALLINT NOT NULL
)

INSERT INTO Uposlenici
SELECT E.emp_id, E.fname, E.lname, E.hire_date, J.job_desc
FROM pubs.dbo.employee AS E
INNER JOIN pubs.dbo.jobs AS J
ON J.job_id = E.job_id

INSERT INTO Naslovi
SELECT T.title_id, T.title, T.type, T.price, ISNULL(P.pub_name, 'nepoznat izdavac'), P.city, P.country
FROM pubs.dbo.titles AS T
INNER JOIN pubs.dbo.publishers AS P
ON P.pub_id = T.pub_id

INSERT INTO Prodaja
SELECT S.stor_id, S.ord_num, S.title_id, S.ord_date, S.qty
FROM pubs.dbo.sales AS S

INSERT INTO Prodavnice
SELECT S.stor_id, S.stor_name, S.city
FROM pubs.dbo.stores AS S

GO
CREATE PROCEDURE sp_update_naslov
(
	@NaslovID VARCHAR(6),
	@Naslov VARCHAR(80) = NULL,
	@Tip CHAR(12) = NULL,
	@Cijena MONEY = NULL,
	@NazivIzdavaca VARCHAR(40) = NULL,
	@GradIzdavaca VARCHAR(20) = NULL,
	@DrzavaIzdavaca VARCHAR(30) = NULL
)
AS
BEGIN
	UPDATE Naslovi
	SET Naslov=ISNULL(@Naslov, Naslov),
		Tip=ISNULL(@Tip, Tip),
		Cijena=ISNULL(@Cijena, Cijena),
		NazivIzdavaca=ISNULL(@NazivIzdavaca, NazivIzdavaca),
		GradIzadavaca=ISNULL(@GradIzdavaca, GradIzadavaca),
		DrzavaIzdavaca=ISNULL(@DrzavaIzdavaca, DrzavaIzdavaca)
	WHERE @NaslovID=NaslovID
END

EXEC sp_update_naslov BU2075, NULL, business, 3

GO
USE AdventureWorks2019
GO
SELECT PC.Name ,SUM(SOD.OrderQty), SUM(SOD.OrderQty * SOD.UnitPrice)
FROM Sales.SalesOrderDetail AS SOD
INNER JOIN Production.Product AS PP
ON PP.ProductID = SOD.ProductID
INNER JOIN Production.ProductSubcategory AS PS
ON PS.ProductSubcategoryID = PP.ProductSubcategoryID
INNER JOIN Production.ProductCategory AS PC
ON PC.ProductCategoryID = PS.ProductCategoryID
WHERE PC.NAME NOT IN ('Bikes') AND PP.Color IN ('White', 'Black')
GROUP BY PC.Name
HAVING SUM(SOD.OrderQty) < 20000
ORDER BY 3 DESC

SELECT CONCAT(PP.FirstName, ' ', PP.LastName), EA.EmailAddress, SOD.OrderQty, FORMAT(SOH.OrderDate, 'dd.MM.yyyy')
FROM Sales.Customer AS SC
INNER JOIN Person.Person AS PP
ON PP.BusinessEntityID = SC.PersonID
INNER JOIN Sales.SalesOrderHeader AS SOH
ON SOH.CustomerID = SC.CustomerID
INNER JOIN Person.EmailAddress AS EA
ON EA.BusinessEntityID = PP.BusinessEntityID
INNER JOIN Sales.SalesOrderDetail AS SOD
ON SOH.SalesOrderID = SOD.SalesOrderID
INNER JOIN Production.Product AS P
ON P.ProductID = SOD.ProductID
WHERE MONTH(SOH.OrderDate) = 5 AND YEAR(SOH.OrderDate) IN ('2013', '2014') AND P.Name LIKE 'Front Brakes' AND SOD.OrderQty > 5
ORDER BY 3

USE Northwind
SELECT TOP 1 S.CompanyName, SUM(OD.Quantity)
FROM Suppliers AS S
INNER JOIN Products AS P
ON P.SupplierID = S.SupplierID
INNER JOIN [Order Details] AS OD
ON OD.ProductID = P.ProductID
INNER JOIN Categories AS C
ON C.CategoryID = P.CategoryID
INNER JOIN Orders AS O
ON O.OrderID = OD.OrderID
WHERE C.CategoryName LIKE 'Seafood' AND O.ShippedDate IS NOT NULL AND OD.Discount > 0
GROUP BY S.CompanyName
ORDER BY 2 DESC

USE AdventureWorks2019
SELECT SOH.SalesOrderID, CONCAT(PP.FirstName, ' ', PP.LastName), SOH.SubTotal
FROM Sales.SalesOrderDetail AS SOD
INNER JOIN Sales.SalesOrderHeader AS SOH
ON SOH.SalesOrderID = SOD.SalesOrderID
INNER JOIN Sales.Customer AS SC
ON SC.CustomerID = SOH.CustomerID
INNER JOIN Person.Person AS PP
ON PP.BusinessEntityID = SC.PersonID
GROUP BY SOH.SalesOrderID, CONCAT(PP.FirstName, ' ', PP.LastName), SOH.SubTotal
HAVING SOH.SubTotal + 2000 < SUM(SOD.OrderQty*SOD.UnitPrice)
ORDER BY SOH.SubTotal DESC

USE AdventureWorks2019
SELECT PODQ1.Name, PODQ1.[Ukupan broj narudzbi], PODQ2.Name, PODQ2.[Ukupna kolicina proizvoda], IIF(PODQ1.ShipMethodID = PODQ2.ShipMethodID, 'Jedna kompanija', 'Vise kompanija') 'Jedna ili vise kompanija'
FROM 
	(SELECT TOP 1 SM.Name, COUNT(SOH.SalesOrderID) 'Ukupan broj narudzbi', SM.ShipMethodID
	FROM Purchasing.ShipMethod AS SM
	INNER JOIN Sales.SalesOrderHeader AS SOH
	ON SOH.ShipMethodID = SM.ShipMethodID
	GROUP BY SM.Name, SM.ShipMethodID
	ORDER BY 2 DESC)
	AS PODQ1,
	(SELECT TOP 1 SM.Name, SUM(SOD.OrderQty) 'Ukupna kolicina proizvoda', SM.ShipMethodID
	FROM Purchasing.ShipMethod AS SM
	INNER JOIN Sales.SalesOrderHeader AS SOH
	ON SOH.ShipMethodID = SM.ShipMethodID
	INNER JOIN Sales.SalesOrderDetail AS SOD
	ON SOD.SalesOrderID = SOH.SalesOrderID
	GROUP BY SM.Name, SM.ShipMethodID
	ORDER BY 2 DESC) 
	AS PODQ2

USE Ispitni_22_09_2023_1
CREATE INDEX IX_Naslovi_Naslov
ON Naslovi(Naslov)

SELECT Naslov
FROM Naslovi
WHERE Naslov LIKE '%a%'