/*

Cleaning Data through SQL Queries

*/

SELECT * 
FROM HousingData_Cleaning

---------------------------------------------------------------------------------------------------------------

--Standardize Date format

SELECT SaleDate, CONVERT(date,SaleDate) as Sale_Date
FROM HousingData_Cleaning

ALTER TABLE HousingData_Cleaning
ADD SaleDateConverted DATE;

UPDATE HousingData_Cleaning
SET SaleDateConverted = CONVERT(date,SaleDate)

SELECT SaleDateConverted 
FROM HousingData_Cleaning


---------------------------------------------------------------------------------------------------------------

--Populate Property Address data

SELECT *
FROM HousingData_Cleaning
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID

/*

In the result of the above query, we can see that for the same ParcelID, there are different UniqueID and for some of those, 
the PropertyAddress is missing. So we will populate the same address for all the ParcelID that are same but have null values 

*/

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM HousingData_Cleaning a
JOIN HousingData_Cleaning b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;

/* 

We see in above that self joining by same ParcelID but different UniqueID gives an address that is supposed to be the same for all ParcelID 
that are same.

*/

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM HousingData_Cleaning a
JOIN HousingData_Cleaning b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;

/* 

This will populate the null address values from a with the values from b.

*/

---------------------------------------------------------------------------------------------------------------

-- Breaking Address into Individual Columns (Address, City, State)


SELECT PropertyAddress
FROM HousingData_Cleaning

SELECT 
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress) - 1) AS Street,
	SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) + 1, LEN(PropertyAddress)) AS City
FROM HousingData_Cleaning;

/*

We will seperate the address by ',' 

*/

ALTER TABLE HousingData_Cleaning
ADD 
	PropertyStreet nvarchar(255),
	PropertyCity nvarchar(255);

UPDATE HousingData_Cleaning
SET
	PropertyStreet = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress) - 1),
	PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) + 1, LEN(PropertyAddress)) ;

SELECT PropertyAddress, PropertyStreet, PropertyCity
FROM HousingData_Cleaning


-- For Owner Address


SELECT 
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) ,
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) 
FROM HousingData_Cleaning

/*

We see that it seperates based on ',' using parsename, but since parsename uses default '.' to seperate, we will first 
convert the ',' to '.' and then return the respective values

*/

ALTER TABLE HousingData_Cleaning
ADD 
	OwnerAddressStreet nvarchar(255),
	OwnerAddressCity nvarchar(255),
	OwnerAddressState nvarchar(255);

UPDATE HousingData_Cleaning
SET
	OwnerAddressStreet = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	OwnerAddressCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	OwnerAddressState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

SELECT OwnerAddress, OwnerAddressStreet, OwnerAddressCity, OwnerAddressState
FROM HousingData_Cleaning

---------------------------------------------------------------------------------------------------------------

-- Changing Y/N to Yes/No in 'Sold As Vacant' field

SELECT SoldAsVacant, COUNT(SoldAsVacant)
FROM HousingData_Cleaning
GROUP BY SoldAsVacant
ORDER BY 2;


SELECT SoldAsVacant,
		CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
			 WHEN SoldAsVacant = 'N' THEN 'No'
			 ELSE SoldAsVacant
			 END
FROM HousingData_Cleaning
ORDER BY SoldAsVacant;

/*

The above displays the required result. Now to update

*/


UPDATE HousingData_Cleaning
SET SoldAsVacant = CASE 
						WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
				   END


---------------------------------------------------------------------------------------------------------------

-- Removig Duplicates

/*

We will rank the rows based on custom partitions that ensure 2 rows are duplicates. And then we will remove all ranks > 1

*/

CREATE VIEW DuplicateRowsView AS (
SELECT *, 
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDateConverted,
				 LegalReference
	ORDER BY UniqueID ) AS RowNum
FROM HousingData_Cleaning
)

SELECT * 
FROM DuplicateRowsView

/*

The above result returns all rows that are duplicates (row_num > 1). Row_Number() assigns rank partitioned by the mentioned columns and if 
there are duplicates, it will assign values > 1.

*/


WITH RowNumCTE AS(
SELECT *, 
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDateConverted,
				 LegalReference
	ORDER BY UniqueID ) AS RowNum
FROM HousingData_Cleaning
)

--SELECT * 
--FROM RowNumCTE
--WHERE RowNum > 1;

DELETE 
FROM RowNumCTE
WHERE RowNum > 1;



---------------------------------------------------------------------------------------------------------------


-- Deleting Unused Columns


SELECT * FROM HousingData_Cleaning;

ALTER TABLE HousingData_Cleaning
DROP COLUMN IF EXISTS OwnerAddress, TaxDistrict, PropertyAddress;

ALTER TABLE HousingData_Cleaning
DROP COLUMN IF EXISTS SaleDates;


---------------------------------------------------------------------------------------------------------------


-- Filling other NULL values if possible

/*

Columns with NULL values: 

'Acreage','LandValue', 'BuildingValue', 'TotalValue', 'YearBuilt', 'Bedrooms', 'FullBath', 'HalfBath'

*/

-- Filling null in Name to 'Unknown'

SELECT CASE
		   WHEN OwnerName IS NULL THEN 'UNKNOWN'
		   ELSE OwnerName
	   END
FROM HousingData_Cleaning


UPDATE HousingData_Cleaning
SET OwnerName = CASE
				   WHEN OwnerName IS NULL THEN 'UNKNOWN'
				   ELSE OwnerName
				END

SELECT OwnerName
FROM HousingData_Cleaning
WHERE OwnerName IS NULL;


-- Filling Acreage NULLs with the mode of the field


SELECT Acreage, 
	   CASE 
			WHEN Acreage IS NULL THEN 
				(
				SELECT Acreage FROM (SELECT TOP 1 Acreage, COUNT(Acreage) as AcreMode
				FROM HousingData_Cleaning
				GROUP BY Acreage
				ORDER BY AcreMode DESC) res
				)
			ELSE Acreage
	   END
FROM HousingData_Cleaning;


UPDATE HousingData_Cleaning
SET Acreage = (CASE 
					WHEN Acreage IS NULL THEN 
						(
						SELECT Acreage FROM (SELECT TOP 1 Acreage, COUNT(Acreage) as AcreMode
						FROM HousingData_Cleaning
						GROUP BY Acreage
						ORDER BY AcreMode DESC) res
						)
					ELSE Acreage
			  END)

SELECT Acreage
FROM HousingData_Cleaning
WHERE Acreage IS NULL;



-- Filling the value of land, building and total with the average value of the column corresponding to the mode of Acreage.


DECLARE @AcreMode FLOAT;
SET @AcreMode = (
				SELECT Acreage FROM (SELECT TOP 1 Acreage, COUNT(Acreage) as AcreMode
				FROM HousingData_Cleaning
				GROUP BY Acreage
				ORDER BY AcreMode DESC) res
				)
SELECT @AcreMode AS AcreMode;

/*

We see that the mode is 0.17. We will use this further

*/

SELECT AVG(LandValue) from HousingData_Cleaning where Acreage = 0.17;

SELECT LandValue,
	CASE	
		WHEN LandValue IS NULL THEN
			(
			SELECT FLOOR(AVG(LandValue)) from HousingData_Cleaning where Acreage = 0.17
			)
		ELSE LandValue
	END
FROM HousingData_Cleaning;


SELECT AVG(BuildingValue) from HousingData_Cleaning where Acreage = 0.17;

SELECT BuildingValue,
	CASE	
		WHEN BuildingValue IS NULL THEN
			(
			SELECT FLOOR(AVG(BuildingValue)) from HousingData_Cleaning where Acreage = 0.17
			)
		ELSE BuildingValue
	END
FROM HousingData_Cleaning;


SELECT AVG(TotalValue) from HousingData_Cleaning where Acreage = 0.17;

SELECT TotalValue,
	CASE	
		WHEN TotalValue IS NULL THEN
			(
			SELECT FLOOR(AVG(TotalValue)) from HousingData_Cleaning where Acreage = 0.17
			)
		ELSE TotalValue
	END
FROM HousingData_Cleaning;


UPDATE HousingData_Cleaning
SET LandValue = (CASE	
					WHEN LandValue IS NULL THEN
						(
						SELECT FLOOR(AVG(LandValue)) from HousingData_Cleaning where Acreage = 0.17
						)
					ELSE LandValue
				END),
	BuildingValue = (CASE	
						WHEN BuildingValue IS NULL THEN
							(
							SELECT FLOOR(AVG(BuildingValue)) from HousingData_Cleaning where Acreage = 0.17
							)
						ELSE BuildingValue
					END),
	TotalValue = (CASE	
						WHEN TotalValue IS NULL THEN
							(
							SELECT FLOOR(AVG(TotalValue)) from HousingData_Cleaning where Acreage = 0.17
							)
						ELSE TotalValue
				  END)

SELECT * 
FROM HousingData_Cleaning
WHERE LandValue IS NULL OR BuildingValue IS NULL OR TotalValue IS NULL;


-- Filling mode values for YearBuilt, Bedrooms, FullBath, HalfBath according to mode of corresponding acreage.

-- Bedrooms

SELECT Bedrooms,Acreage
FROM HousingData_Cleaning
--WHERE Acreage = 0.04
ORDER BY Acreage,Bedrooms DESC;

/*

We take the mode if exists, else 0, for each acreage value. We see from above that 0.1 has all NULLs, and hence we will assign 0.
0.04 Acreage has 3 Bedrooms as the mode and we will assign 3 to all Bedroom NULLs for that particular Acreage value.

*/

--DROP FUNCTION IF EXISTS ModeFind;
CREATE FUNCTION BedroomMode(@AcreageVal FLOAT) RETURNS INT
BEGIN
	DECLARE @Mode INT;
	SET @Mode = ISNULL((
				SELECT top 1 Bedrooms 
				FROM HousingData_Cleaning
				WHERE Acreage = @AcreageVal
				GROUP BY Bedrooms
				ORDER BY COUNT(Bedrooms) DESC
				),0);
	RETURN @Mode
END

PRINT dbo.BedroomMode(0.04)

SELECT Bedrooms, Acreage, dbo.BedroomMode(Acreage) as BMode
FROM HousingData_Cleaning
WHERE Bedrooms IS NULL
ORDER BY Acreage,Bedrooms DESC;

UPDATE HousingData_Cleaning
SET Bedrooms =  dbo.BedroomMode(Acreage)
				WHERE Bedrooms IS NULL



-- Applying the same to the other columns in this set

-- FullBath

SELECT FullBath,Acreage
FROM HousingData_Cleaning
--WHERE Acreage = 0.04
ORDER BY Acreage,FullBath DESC;

CREATE FUNCTION FullBathMode(@AcreageVal FLOAT) RETURNS INT
BEGIN
	DECLARE @Mode INT;
	SET @Mode = ISNULL((
				SELECT top 1 FullBath
				FROM HousingData_Cleaning
				WHERE Acreage = @AcreageVal
				GROUP BY FullBath
				ORDER BY COUNT(FullBath) DESC
				),0);
	RETURN @Mode
END

PRINT dbo.FullBathMode(0.04)

SELECT FullBath, Acreage, dbo.FullBathMode(Acreage) as FBMode
FROM HousingData_Cleaning
WHERE FullBath IS NULL
ORDER BY Acreage,FullBath DESC;

UPDATE HousingData_Cleaning
SET FullBath =  dbo.FullBathMode(Acreage)
				WHERE FullBath IS NULL


-- HalfBath

SELECT HalfBath,Acreage
FROM HousingData_Cleaning
--WHERE Acreage = 0.04
----AND HalfBath IS NULL
ORDER BY Acreage,HalfBath DESC;

CREATE FUNCTION HalfBathMode(@AcreageVal FLOAT) RETURNS INT
BEGIN
	DECLARE @Mode INT;
	SET @Mode = ISNULL((
				SELECT top 1 HalfBath
				FROM HousingData_Cleaning
				WHERE Acreage = @AcreageVal
				GROUP BY HalfBath
				ORDER BY COUNT(HalfBath) DESC
				),0);
	RETURN @Mode
END

PRINT dbo.HalfBathMode(0.04)

SELECT HalfBath, Acreage, dbo.HalfBathMode(Acreage) as HBMode
FROM HousingData_Cleaning
WHERE HalfBath IS NULL
ORDER BY Acreage,HalfBath DESC;

UPDATE HousingData_Cleaning
SET HalfBath =  dbo.HalfBathMode(Acreage)
				WHERE HalfBath IS NULL


-- YearBuilt

/* 

For YearBuilt, We can't assign 0 to those that have all NULLs. In such case, we will assign the mode of the entire column.

*/

SELECT YearBuilt, COUNT(YearBuilt) as Cnt
FROM HousingData_Cleaning
GROUP BY YearBuilt
ORDER BY Cnt DESC

/*

We can see that the year 1950 is the mode of the YearBuilt field.

*/

SELECT YearBuilt,Acreage
FROM HousingData_Cleaning
--WHERE Acreage = 0.01
----AND YearBuilt IS NULL
ORDER BY Acreage,YearBuilt DESC;

--DROP FUNCTION IF EXISTS YearBuiltMode 
CREATE FUNCTION YearBuiltMode(@AcreageVal FLOAT) RETURNS INT
BEGIN
	DECLARE @Mode INT;
	SET @Mode = ISNULL(
				(
				SELECT top 1 YearBuilt
				FROM HousingData_Cleaning
				WHERE Acreage = @AcreageVal
				GROUP BY YearBuilt
				ORDER BY COUNT(YearBuilt) DESC
				),
				(SELECT TOP 1 YearBuilt
				FROM HousingData_Cleaning
				GROUP BY YearBuilt
				ORDER BY COUNT(YearBuilt) DESC)
				);
	RETURN @Mode
END

PRINT dbo.YearBuiltMode(0.01)

PRINT dbo.YearBuiltMode(0.04)

SELECT YearBuilt, Acreage, dbo.YearBuiltMode(Acreage) as YMode
FROM HousingData_Cleaning
WHERE YearBuilt IS NULL
ORDER BY Acreage,YearBuilt DESC;

UPDATE HousingData_Cleaning
SET YearBuilt =  dbo.YearBuiltMode(Acreage)
				WHERE YearBuilt IS NULL



SELECT * 
FROM HousingData_Cleaning
WHERE Bedrooms IS NULL OR FullBath IS NULL OR HalfBath IS NULL OR YearBuilt IS NULL;

