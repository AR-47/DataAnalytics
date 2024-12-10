/*

Data Cleaning in SQL

*/

-- Display the original dataset to examine the data

SELECT *
FROM HousingProjectData


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Standardizing Date Format
-- Convert the 'SaleDate' column to a proper Date format and update the dataset

SELECT SaleDate, CONVERT(Date, SaleDate)
FROM HousingProjectData

-- Update the 'SaleDate' column to a standard Date format

UPDATE HousingProjectData	
SET SaleDate = CONVERT(Date, SaleDate)

-- Add a new column 'SaleDateConverted' to store the converted Date format for future use

ALTER TABLE HousingProjectData  
ADD SaleDateConverted Date;

-- Populate the 'SaleDateConverted' column with the standardized Date values

UPDATE HousingProjectData		
SET SaleDateConverted = CONVERT(Date, SaleDate)

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Populating missing Property Address data
-- Check rows where 'PropertyAddress' is NULL

SELECT *
FROM HousingProjectData
WHERE PropertyAddress IS NULL

-- Identify potential matches for missing addresses using ParcelID

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM HousingProjectData a
JOIN HousingProjectData b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

-- Update missing 'PropertyAddress' values by copying data from related rows

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM HousingProjectData a
JOIN HousingProjectData b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- Splitting 'PropertyAddress' into individual components (Address, State, City)
-- Preview the 'PropertyAddress' to understand its structure

SELECT PropertyAddress
FROM HousingProjectData

-- Extract Address and City using SUBSTRING and CHARINDEX functions

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress) -1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) +1, LEN(PropertyAddress)) AS Address
FROM HousingProjectData

-- Add a new column for the extracted Address component

ALTER TABLE HousingProjectData
ADD PropertySplitAddress nvarchar(255);

-- Update the new column with the extracted Address

UPDATE HousingProjectData
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress) -1)

-- Add a new column for the extracted City component

ALTER TABLE HousingProjectData
ADD PropertySplitCity nvarchar(255);

-- Update the new column with the extracted City

UPDATE HousingProjectData
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) +1, LEN(PropertyAddress))

-- Verify the updated dataset

SELECT *
FROM HousingProjectData

-- Process 'OwnerAddress' to split it into components (Address, City, State)

SELECT OwnerAddress
FROM HousingProjectData

-- Use PARSENAME to extract Address, City, and State from 'OwnerAddress'

SELECT
PARSENAME(REPLACE(OwnerAddress, ',','.'), 3)
,PARSENAME(REPLACE(OwnerAddress, ',','.'), 2)
,PARSENAME(REPLACE(OwnerAddress, ',','.'), 1)
FROM HousingProjectData

-- Add and populate columns for split components of 'OwnerAddress'

ALTER TABLE HousingProjectData
ADD OwnerSplitAddress nvarchar(255);

UPDATE HousingProjectData
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',','.'), 3)

ALTER TABLE HousingProjectData
ADD OwnerSplitCity nvarchar(255);

UPDATE HousingProjectData
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',','.'), 2)

ALTER TABLE HousingProjectData
ADD OwnerSplitState nvarchar(255);

UPDATE HousingProjectData
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',','.'), 1)

-- Verify the updated dataset

SELECT *
FROM HousingProjectData

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Chnage Y and N to Yes and No in "SoldAsVacant" column
-- Check distinct values in the 'SoldAsVacant' column


SELECT DISTINCT(SoldAsVacant)
FROM HousingProjectData

-- Count occurrences of each distinct value in 'SoldAsVacant'

SELECT SoldAsVacant, COUNT(SoldAsVacant)
FROM HousingProjectData
GROUP BY SoldAsVacant
ORDER BY 2

-- Replace 'Y' with 'Yes' and 'N' with 'No' using CASE

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END
FROM HousingProjectData

-- Update the column with standardized values

UPDATE HousingProjectData
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Removing Duplicate Records
-- Use ROW_NUMBER() to identify duplicates within the dataset

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
					UniqueID
					) row_num
FROM HousingProjectData
)

-- Preview duplicate records (row_num > 1)

SELECT *
FROM RowNumCTE
WHERE row_num > 1

-- Verify the dataset

SELECT *
FROM HousingProjectData


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- Deleting Unused Columns [This step is irreversible for the raw dataset; proceed with caution]
-- Review the dataset before dropping columns

SELECT *
FROM HousingProjectData

-- Drop unnecessary columns after confirming their redundancy

ALTER TABLE HousingProjectData
DROP COLUMN OwnerAddress, PropertyAddress, TaxDistrict

-- Drop the 'SaleDate' column as it's replaced by 'SaleDateConverted'

ALTER TABLE HousingProjectData
DROP COLUMN SaleDate