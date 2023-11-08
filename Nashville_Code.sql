-- Data Cleaning of the Nashville_Housing 

SET AUTOCOMMIT = 0;

-- View The Nashville_Housing Data
SELECT * FROM Nash;

-- Totoal Row or Entries in the data
SELECT COUNT(*) FROM Nash;
-- There are 24007 enteries.

-- Get the description of the data
DESCRIBE Nash;

-- Rectify incorrect labeling or spelling of the columns
ALTER TABLE Nash
RENAME COLUMN ï»¿UniqueID TO UniqueID;

-- Convert to correct Data Type
-- From the 'DESCRIBE' function, we can see that the SaleDate is not on the proper data-type and not in a standard date format as we want. So we rectify.

-- Firstly we convert to date format in form of '%Y-%m-%d'
UPDATE Nash
SET SaleDate = CASE 
					WHEN SaleDate Like '% , %' THEN date_format(str_to_date(SaleDate, '%M %d, %Y'), '%Y-%m-%d')
                    ELSE date_format(str_to_date(SaleDate, '%M %d, %Y'), '%Y-%m-%d')
				END;

-- Then set data type to date
ALTER TABLE Nash
MODIFY SaleDate Date;

-- View Empty Columns
SELECT * FROM Nash
WHERE PropertyAddress LIKE '' OR OwnerName LIKE '';

-- It can be seen above that '' is an empty attribute. We should assign it a 'null'

UPDATE Nash
SET PropertyAddress = CASE 
						WHEN PropertyAddress LIKE '' THEN null 
                        ELSE PropertyAddress
					  END,
    OwnerName = CASE 
					WHEN OwnerName LIKE '' THEN null
					ELSE OwnerName
				END;


SELECT DISTINCT SoldAsVacant FROM Nash;
-- There are Two outcome, so we could just make everything uniform by either Yes or No
UPDATE Nash
SET SoldAsVacant = CASE
						WHEN SoldAsVacant LIKE 'N%' THEN 'No'
                        WHEN SoldAsVacant LIKE 'Y%' THEN 'Yes'
                        ELSE null
					END;
                    
-- Let's remove duplicates and fill the NULL values
SELECT a.ParcelID, a.PropertyAddress, b.PropertyAddress, a.OwnerName, b.OwnerName FROM Nash a
INNER JOIN Nash b
	ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID;
-- From the above querry, we can see some duplicates in which the PropertyAddress exist in one while missing in the other in the same table
-- So let's replace the null with the right address

UPDATE Nash AS a
	LEFT JOIN Nash AS b
		ON a.ParcelID = b.ParcelID 
        AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = COALESCE(a.PropertyAddress, b.PropertyAddress)
WHERE a.PropertyAddress IS NULL;

SELECT * FROM Nash;
-- Removing Duplicates 
SELECT ParcelID, PropertyAddress, OwnerName, COUNT(*) FROM Nash
GROUP BY ParcelID, PropertyAddress, OwnerName
HAVING COUNT(*) > 1 ;


WITH DuplCTE AS (
	Select *, 
			ROW_NUMBER() OVER(
								PARTITION BY ParcelID, PropertyAddress, OwnerName, SalePrice
                                ORDER BY UniqueID) Duplicated
		FROM Nash)
DELETE FROM DuplCTE
WHERE Duplicated >1;

DELETE a FROM Nash a
	INNER JOIN Nash b
		WHERE a.PropertyAddress < b.PropertyAddress AND a.ParcelID = b.ParcelID;
    

                    
SELECT PropertyAddress, COUNT(*) FROM Nash
GROUP BY PropertyAddress
HAVING COUNT(*) >1;
SELECT OwnerAddress, COUNT(*) FROM Nash
GROUP BY OwnerAddress
HAVING COUNT(*) >1;


-- Creating Columns City, and State

ALTER TABLE Nash
ADD COLUMN ( City VARCHAR (50),
			State VARCHAR (30));
 
 -- Insert values into created tables
UPDATE Nash
SET City = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ', ', -2), ',', 1),
	State = SUBSTRING_INDEX(OwnerAddress, ',', -1),
	PropertyAddress = SUBSTRING_INDEX(PropertyAddress, ',', 1);

-- Removing Unnecessary Columns 
ALTER TABLE Nash
DROP COLUMN ParcelID, 
DROP COLUMN UniqueID,
DROP COLUMN LegalReference,
DROP COLUMN OwnerName;

