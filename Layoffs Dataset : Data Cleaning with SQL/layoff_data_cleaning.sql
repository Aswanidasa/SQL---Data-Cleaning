-- Data Cleaning

SELECT 
    COUNT(*)
FROM
    layoffs.layoff_tab;

-- 1. Remove Duplicates
-- 2. Standardize the data
-- 3. Null values or Blank values
-- 4.Remove unnecessary columns

-- first thing we want to do is create a staging table. This is the one we will work in and clean the data. We want a table with the raw data in case something happens

USE layoffs;
CREATE TABLE layoffdata_new LIKE layoff_tab;

INSERT layoffdata_new
SELECT * FROM layoff_tab;

SELECT * FROM layoffdata_new;
-- ---------------------------------------------- Remove Duplicates ---------------------------------------------- --

# First check is there any duplicates are present

SELECT * FROM
(SELECT *,
ROW_NUMBER() OVER(PARTITION BY company,location,industry,total_laid_off,percentage_laid_off,'date',stage,country,funds_raised_millions) as row_no
FROM layoffdata_new) a 
WHERE row_no>1;

# Duplicates are present; these are the ones we want to delete where the row number is > 1

CREATE TABLE layoffdata_org
SELECT * FROM (SELECT *,
ROW_NUMBER() OVER(PARTITION BY company,location,industry,total_laid_off,percentage_laid_off,'date',stage,country,funds_raised_millions) as row_no
FROM layoffdata_new ) as a where row_no=1;

SELECT count(*) FROM layoffdata_org; -- layoffdata_org is the new table we created without duplicates


-- ---------------------------------------------- Standardizing data ---------------------------------------------- --


SELECT * FROM layoffdata_org; 

SET SQL_SAFE_UPDATES = 0;

-- Trim white space
UPDATE layoffdata_org
SET company=TRIM(company),
	location=TRIM(location),
    industry=TRIM(industry),
    stage=TRIM(stage),
    country=TRIM(country),
    country=TRIM(TRAILING '.' FROM country); -- some "United States" and some "United States." with a period at the end. Let's standardize this.

select distinct country from layoffdata_org order by 1;    
 DESCRIBE layoffdata_org; --  <date  is in text fromat
 
 UPDATE layoffdata_org
 SET date=STR_TO_DATE(date,'%m/%d/%Y');
 
ALTER TABLE layoffdata_org
MODIFY COLUMN `date` DATE; -- <Change to date fromat


-- ---------------------------------------------- Null values or Blank values ---------------------------------------------- --

-- >For the same company ,the industry columns are null also have values; Let's fix that column first


-- we should set the blanks to nulls since those are typically easier to work with
UPDATE layoffdata_org
SET industry=NULL
WHERE industry='';

-- now if we check those are all null

SELECT *
FROM layoffdata_org
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;



-- now we need to populate those nulls if possible

UPDATE layoffdata_org t1
JOIN layoffdata_org t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- and if we check it looks like Bally's was the only one without a populated row to populate this null values
SELECT company, industry
FROM layoffdata_org
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;


-- remove any columns and rows we need to

SELECT *
FROM layoffdata_org
WHERE total_laid_off IS NULL;


SELECT *
FROM layoffdata_org
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Delete Useless data we can't really use

DELETE FROM layoffdata_org
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT * 
FROM layoffdata_org;

ALTER TABLE layoffdata_org
DROP COLUMN row_no;

-- Final table


SELECT * 
FROM layoffdata_org;










