CREATE DATABASE BrojIndeksa
GO
USE BrojIndeksa

CREATE TABLE Prodavaci
(
	ProdavacID INT CONSTRAINT PK_Prodavaci PRIMARY KEY IDENTITY(1,1),
	Ime NVARCHAR(50) NOT NULL,
	Prezime NVARCHAR(50) NOT NULL,
	OpisPosla NVARCHAR(50) NOT NULL,
	EmailAdresa NVARCHAR(50)
)

CREATE TABLE Proizvodi
(
	ProizvodID INT CONSTRAINT PK_Proizvodi PRIMARY KEY IDENTITY(1,1),
	Naziv NVARCHAR(50) NOT NULL,
	SifraProizvoda NVARCHAR(25) NOT NULL,
	Boja NVARCHAR(15),
	NazivPodkategorije NVARCHAR(50) NOT NULL,
)

CREATE TABLE ZaglavljeNarudzbe
(
	NarudzbaID INT CONSTRAINT PK_ZaglavljeNarudzbe PRIMARY KEY IDENTITY(1,1),
	DatumNarudzbe DATETIME NOT NULL,
	DatumIsporuke DATETIME,
	KreditnaKarticaID INT,
	ImeKupca NVARCHAR(50) NOT NULL,
	PrezimeKupca NVARCHAR(50) NOT NULL,
	NazivGradaIsporuke NVARCHAR(30) NOT NULL,
	ProdavacID INT CONSTRAINT FK_ZaglavljeNarudzbe_Prodavac FOREIGN KEY REFERENCES Prodavaci(ProdavacID),
	NacinIsporuke NVARCHAR(50) NOT NULL
)

CREATE TABLE DetaljiNarudzbe
(
	NarudzbaID INT CONSTRAINT FK_DetaljiNarudzbe_ZaglavljeNarudzbe FOREIGN KEY REFERENCES ZaglavljeNarudzbe(NarudzbaID) NOT NULL,
	ProizvodID INT CONSTRAINT FK_DetaljiNarudzbe_Proizvodi FOREIGN KEY REFERENCES Proizvodi(ProizvodID) NOT NULL,
	Cijena MONEY NOT NULL,
	Kolicina SMALLINT NOT NULL,
	Popust MONEY NOT NULL,
	OpisSpecijalnePonude NVARCHAR(255) NOT NULL,
	DetaljiNarudzbeID INT CONSTRAINT PK_DetaljiNarudzbe PRIMARY KEY IDENTITY(1,1)
)

SET IDENTITY_INSERT Prodavaci ON
INSERT INTO Prodavaci(ProdavacID, Ime, Prezime, OpisPosla, EmailAdresa)
SELECT SP.BusinessEntityID, PP.FirstName, PP.LastName, E.JobTitle, EA.EmailAddress
FROM AdventureWorks2019.Sales.SalesPerson AS SP
INNER JOIN AdventureWorks2019.Person.Person AS PP
ON PP.BusinessEntityID = SP.BusinessEntityID
INNER JOIN AdventureWorks2019.HumanResources.Employee AS E
ON E.BusinessEntityID = PP.BusinessEntityID
INNER JOIN AdventureWorks2019.Person.EmailAddress AS EA
ON EA.BusinessEntityID = PP.BusinessEntityID
SET IDENTITY_INSERT Prodavaci OFF

SET IDENTITY_INSERT Proizvodi ON
INSERT INTO Proizvodi(ProizvodID, Naziv, SifraProizvoda, Boja, NazivPodkategorije)
SELECT P.ProductID, P.Name, P.ProductNumber, P.Color, PS.Name
FROM AdventureWorks2019.Production.Product AS P
INNER JOIN AdventureWorks2019.Production.ProductSubcategory AS PS
ON PS.ProductSubcategoryID = P.ProductSubcategoryID
SET IDENTITY_INSERT Proizvodi OFF

SET IDENTITY_INSERT ZaglavljeNarudzbe ON
INSERT INTO ZaglavljeNarudzbe (NarudzbaID, DatumNarudzbe, DatumIsporuke, KreditnaKarticaID, ImeKupca, PrezimeKupca, NazivGradaIsporuke, ProdavacID, NacinIsporuke)
SELECT SOH.SalesOrderID, SOH.OrderDate, SOH.ShipDate, SOH.CreditCardID, PP.FirstName, PP.LastName, PA.City, SOH.SalesPersonID, SM.Name
FROM AdventureWorks2019.Sales.SalesOrderHeader AS SOH
INNER JOIN AdventureWorks2019.Sales.Customer AS SC
ON SC.CustomerID = SOH.CustomerID
INNER JOIN AdventureWorks2019.Person.Person AS PP
ON PP.BusinessEntityID = SC.PersonID
INNER JOIN AdventureWorks2019.Person.Address AS PA
ON PA.AddressID = SOH.ShipToAddressID
INNER JOIN AdventureWorks2019.Purchasing.ShipMethod AS SM
ON SM.ShipMethodID = SOH.ShipMethodID
SET IDENTITY_INSERT ZaglavljeNarudzbe OFF

SET IDENTITY_INSERT DetaljiNarudzbe ON
INSERT INTO DetaljiNarudzbe (NarudzbaID, ProizvodID, Cijena, Kolicina, Popust, OpisSpecijalnePonude)
SELECT SOD.SalesOrderID, SOD.ProductID, SOD.UnitPrice, SOD.OrderQty, SOD.UnitPriceDiscount, SO.Description
FROM AdventureWorks2019.Sales.SalesOrderDetail AS SOD
INNER JOIN AdventureWorks2019.Sales.SpecialOfferProduct AS SOP
ON SOD.SpecialOfferID = SOP.SpecialOfferID AND SOD.ProductID = SOP.ProductID
INNER JOIN AdventureWorks2019.Sales.SpecialOffer AS SO
ON SO.SpecialOfferID = SOP.SpecialOfferID
SET IDENTITY_INSERT DetaljiNarudzbe OFF

GO
CREATE FUNCTION f_detalji
(
	@NarudzbaID INT
)
RETURNS TABLE
AS
RETURN
SELECT CONCAT(ZN.ImeKupca, ' ', ZN.PrezimeKupca) 'Ime i prezime', ZN.NazivGradaIsporuke, SUM(DN.Cijena * DN.Kolicina * (1 - DN.Popust)) 'Ukupna vrijednost narudzbe sa popustom', IIF(ZN.KreditnaKarticaID IS NULL, 'Nije placeno karticom', 'Placeno karticom') 'Placeno karticom?'
FROM DetaljiNarudzbe AS DN
INNER JOIN ZaglavljeNarudzbe AS ZN
ON ZN.NarudzbaID = DN.NarudzbaID
WHERE ZN.NarudzbaID = @NarudzbaID
GROUP BY CONCAT(ZN.ImeKupca, ' ', ZN.PrezimeKupca), ZN.NazivGradaIsporuke, IIF(ZN.KreditnaKarticaID IS NULL, 'Nije placeno karticom', 'Placeno karticom')
GO

SELECT *
FROM f_detalji(43659)

USE AdventureWorks2019
SELECT PC.Name, COUNT(*)
FROM Production.Product AS PP
INNER JOIN Production.ProductSubcategory AS PS
ON PP.ProductSubcategoryID = PS.ProductSubcategoryID
INNER JOIN Production.ProductCategory AS PC
ON PC.ProductCategoryID = PS.ProductCategoryID
WHERE LEN(REPLACE(PP.Name, ' ', '')) = LEN(PP.Name) - 2 AND PP.Name LIKE '%[0-9]%' AND PP.SellEndDate IS NULL
GROUP BY PC.Name
HAVING COUNT(*) > 50

SELECT CONCAT(PODQ.Name, ' ', PODQ.[Ukupna prodana kolicina], ' kom')
FROM (SELECT PP.Name, SUM(SOD.OrderQty) 'Ukupna prodana kolicina'
FROM Production.Product AS PP
INNER JOIN Sales.SalesOrderDetail AS SOD
ON SOD.ProductID = PP.ProductID
INNER JOIN Production.ProductSubcategory AS PS
ON PS.ProductSubcategoryID = PP.ProductSubcategoryID
INNER JOIN Production.ProductCategory AS PC
ON PC.ProductCategoryID = PS.ProductCategoryID
WHERE PP.SellEndDate IS NOT NULL AND PS.Name NOT LIKE '%Bikes%'
GROUP BY PP.Name
HAVING SUM(SOD.OrderQty) > 200) AS PODQ


SELECT SOH.SalesOrderID, CONCAT(PP.FirstName, ' ', PP.LastName), SOH.TotalDue
FROM Sales.SalesOrderHeader AS SOH
INNER JOIN Sales.Customer AS SC
ON SC.CustomerID = SOH.CustomerID
INNER JOIN Person.Person AS PP
ON PP.BusinessEntityID = SC.PersonID
WHERE DATEDIFF(DAY, SOH.OrderDate, SOH.ShipDate) < (
													SELECT AVG(DATEDIFF(DAY, SOH1.OrderDate, SOH1.ShipDate))
												    FROM Sales.SalesOrderHeader AS SOH1
												   )

USE pubs
SELECT T.title, SUM(S.qty)
FROM titles AS T
INNER JOIN sales AS S
ON S.title_id = T.title_id
WHERE T.title_id IN (
					  SELECT TA.title_id
					  FROM titleauthor AS TA
					  WHERE TA.au_id IN				
				   					   (
				   					    SELECT TA.au_id
									    FROM titleauthor AS TA
				   					    GROUP BY TA.au_id
				   					    HAVING COUNT(TA.title_id) >= 2
				   					   )
					)
GROUP BY T.title
HAVING SUM(S.qty) > 30

SELECT S.title_id, SUM(S.qty)
FROM sales AS S
GROUP BY S.title_id

SELECT T.title, T.title_id, TA.au_id
FROM titles AS T
INNER JOIN titleauthor AS TA
ON TA.title_id = T.title_id


USE AdventureWorks2019
SELECT ST.Name, CAST((CAST(COUNT(SOH.SalesOrderID) AS DECIMAL(18,2)) / (
										   SELECT CAST (COUNT(*) AS DECIMAL(18,2))
										   FROM Sales.SalesOrderHeader
										  )) * 100 AS DECIMAL(18,2))
FROM Sales.SalesOrderHeader AS SOH
INNER JOIN Sales.SalesTerritory AS ST
ON ST.TerritoryID = SOH.TerritoryID
GROUP BY ST.Name

USE prihodi
SELECT CONCAT(O.Ime, ' ', O.PrezIme), G.Grad, O.Adresa, CAST(SUM(RP.Neto) AS DECIMAL(18,2))
FROM Osoba AS O
INNER JOIN RedovniPrihodi AS RP
ON RP.OsobaID = O.OsobaID
INNER JOIN Grad AS G
ON G.GradID = O.GradID
GROUP BY CONCAT(O.Ime, ' ', O.PrezIme), G.Grad, O.Adresa