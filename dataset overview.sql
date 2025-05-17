-- UNDERSTANDING THE DATA
-- selecting the database for use in the current session
USE md_water_services;

-- confirming currently selected (or active) database for the current session.
SELECT DATABASE();

-- checking all tables in the current active database
SHOW TABLES;

-- looking at the data_dictionary table
SELECT *
FROM 
md_water_services.data_dictionary;

-- looking at the location table
SELECT *
FROM 
md_water_services.location
LIMIT 10;

-- looking at the water_source table
SELECT *
FROM 
md_water_services.water_source
LIMIT 10;

-- looking at the water_quality table
SELECT *
FROM 
md_water_services.water_quality
LIMIT 10;

-- looking at the well_pollution table
SELECT *
FROM 
md_water_services.well_pollution
LIMIT 10;

-- looking at the employee table
SELECT *
FROM 
md_water_services.employee
LIMIT 20;

-- looking at the well_pollution table
SELECT *
FROM 
md_water_services.global_water_access
LIMIT 5;

-- CREATING CSV files for the tables 
SELECT * FROM md_water_services.well_pollution
INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/well_pollution.csv'
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n';