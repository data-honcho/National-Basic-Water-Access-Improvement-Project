-- DATA CLEANING 
 -- investigating pollution issues from the National Basic Water Access Improvement Project

-- making a copy of well_pollution called well_pollution_copy ensuring original results table is retained before updating
CREATE TABLE md_water_services.well_pollution_copy
AS
SELECT * FROM md_water_services.well_pollution;
 
-- if biological column has value > 0.01 then water is contaminated hence value of results columns should be either 'Contaminated: Biological' or 'Contaminated: Chemical' not Clean
SELECT *
FROM md_water_services.well_pollution_copy
WHERE biological>0.01 AND results = 'Clean';

-- updating records in description column that mistakenly have Clean Bacteria: E. coli should updated to Bacteria: E. coli
-- updating records in description column that have Clean Bacteria: Giardia Lamblia should updated to Bacteria: Giardia Lamblia
-- updating results value to 'Contaminated: Biological' where biological > 0.01 and current results column value is 'Clean' 
-- checking rows mistake occured 
SELECT *
FROM md_water_services.well_pollution_copy
WHERE description LIKE 'Clean_%';

-- updating
UPDATE md_water_services.well_pollution_copy
SET description = 'Bacteria: E. coli'
WHERE description = 'Clean Bacteria: E. coli';

UPDATE md_water_services.well_pollution_copy
SET description = 'Bacteria: Giardia Lamblia'
WHERE description = 'Clean Bacteria: Giardia Lamblia';

UPDATE md_water_services.well_pollution_copy
SET results = 'Contaminated: Biological'
WHERE biological > 0.01 AND results = 'Clean';

-- verifying updates on description and results column for well_pollution_copy        
SELECT description, results, biological
FROM md_water_services.well_pollution_copy
WHERE description LIKE '%Clean %' AND results = 'Clean';

DROP TABLE IF EXISTS `well_pollution_copy`;

-- updating the well_pollution table
UPDATE md_water_services.well_pollution
SET description = 'Bacteria: E. coli'
WHERE description = 'Clean Bacteria: E. coli';

UPDATE md_water_services.well_pollution
SET description = 'Bacteria: Giardia Lamblia'
WHERE description = 'Clean Bacteria: Giardia Lamblia';

UPDATE md_water_services.well_pollution
SET results = 'Contaminated: Biological'
WHERE biological > 0.01 AND results = 'Clean';

-- verifying updates on description and results column         
SELECT description, results, biological
FROM md_water_services.well_pollution
WHERE description LIKE '%Clean %' AND results = 'Clean';


-- forming email address for employees on the employee table
SELECT
CONCAT(
LOWER(REPLACE(employee_name, ' ', '.')), '@ndogowater.gov') AS new_email
FROM
md_water_services.employee;

-- updating the email column on employee table
UPDATE md_water_services.employee
SET email = CONCAT(LOWER(REPLACE(employee_name, ' ', '.')), '@ndogowater.gov');

SELECT * 
FROM md_water_services.employee;

-- checking the phone number column
SELECT phone_number
FROM md_water_services.employee
WHERE phone_number LIKE ' %' OR phone_number LIKE '% ';

SELECT
LENGTH(phone_number)
FROM
employee;

-- removing trailing spaces from the phone number column
UPDATE md_water_services.employee
SET phone_number = TRIM(phone_number);

-- veryfying update
SELECT phone_number
FROM md_water_services.employee
WHERE phone_number LIKE ' %' OR phone_number LIKE '% ';
