-- unique types of water sources
SELECT DISTINCT(type_of_water_source)
FROM md_water_services.water_source;

-- time spent in queue for different water_sources from visits table
SELECT *, time_in_queue/60 as hours_spent_in_queue
FROM 
md_water_services.visits
WHERE
time_in_queue >= 500;

-- type_of_water_source that having highest queue time from water_source table 
SELECT source_id, type_of_water_source, number_of_people_served
FROM water_source
WHERE source_id IN ('AkKi00881224','AkLu01628224','AkRu05234224','HaRu19601224',
'HaZa21742224','SoRu36096224','SoRu37635224','SoRu38776224');

-- records where subject_quality_score is 10 for home taps and where the source was visited a second time
SELECT record_id, subjective_quality_score, visit_count
FROM md_water_services.water_quality
WHERE subjective_quality_score = 10 AND visit_count > 1;


-- 09/12/2024
-- understanding how many of our employees live in each town
SELECT town_name, COUNT(assigned_employee_id) AS num_employee
FROM md_water_services.employee
GROUP BY
town_name;

-- looking at the number of records each employee collected
SELECT assigned_employee_id, COUNT(visit_count) as number_of_visits
FROM md_water_services.visits
GROUP BY assigned_employee_id
ORDER BY number_of_visits DESC;

-- getting more info of the top 3 employees who made the most visits and collected most record
SELECT assigned_employee_id, employee_name, email, phone_number
FROM md_water_services.employee
WHERE assigned_employee_id IN (1, 30, 34);

-- analysing number of records per town
SELECT COUNT(location_id) AS record_per_town, town_name 
FROM md_water_services.location
GROUP BY town_name
ORDER BY record_per_town DESC;
--  INSIGHT 1 Most water sources are rural.


-- analysing number of records per province
SELECT COUNT(location_id) AS record_per_province, province_name 
FROM md_water_services.location
GROUP BY province_name
ORDER BY record_per_province DESC;

-- analysing number of records per location_type (pg 23 no.1)
SELECT COUNT(location_id) AS record_per_location_type, location_type 
FROM md_water_services.location
GROUP BY location_type;
-- INSIGHT 1  Most water sources are rural area.


-- calculating percentage of rural water sources to urban water sources
SELECT ROUND((23740 / (15910 + 23740)) * 100, 0) AS pct_rural_water_source;
-- INSIGHT - 60% of all water sources in the data set are in rural communities.


-- analyzing number of people we surveyed in total
SELECT SUM(number_of_people_served) AS total_num_surveyed
FROM water_source;
-- INSIGHT  - Over 27,628,140 people were surveyed in total


-- analysis of how many wells, taps and rivers are there
SELECT  type_of_water_source, COUNT(source_id) as water_source_count
FROM water_source
GROUP BY type_of_water_source
ORDER BY water_source_count DESC;

-- How many people share particular types of water sources on average?
SELECT type_of_water_source, ROUND(AVG(number_of_people_served)) AS avg_num_served
FROM water_source
GROUP BY type_of_water_source
ORDER BY type_of_water_source DESC;

-- analysing population of people served by each type of water source 
SELECT type_of_water_source, SUM(number_of_people_served) as population_served 
FROM water_source
GROUP BY type_of_water_source
ORDER BY population_served DESC;

-- analysing population of people served by each type of water source in percentage (pg 23 no. 2, 3 and 4)
SELECT type_of_water_source, SUM(number_of_people_served) AS population_served, 
ROUND((SUM(number_of_people_served) / (SELECT SUM(number_of_people_served) FROM water_source) * 100), 0) AS population_served_pct
FROM water_source
GROUP BY type_of_water_source
ORDER BY population_served DESC;

-- Analyzing number of clean wells to Contaminated well (pg 23 no. 5)
SELECT 
ROUND((COUNT(CASE WHEN wp.results = 'Clean' THEN 1 END) * 100.0 / COUNT(wp.results)), 0) AS percentage_clean_wells
FROM water_source ws
JOIN well_pollution wp 
ON ws.source_id = wp.source_id
WHERE ws.type_of_water_source = 'well';

-- INSIGHTS
-- 43% of our people are using shared taps. 2000 people often share one tap.
-- 31% of our population has water infrastructure in their homes, but within that group, 45% face non-functional systems due to issues with pipes,pumps, and reservoirs.
-- 18% of our people are using wells of which, but within that, only 28% are clean..
-- fix shared taps first, then wells, and so on.


-- THE SOLUTION 
-- determining which water source is a priority to fix based on population the water source serve
SELECT type_of_water_source, SUM(number_of_people_served) as population_served, 
RANK() OVER (ORDER BY SUM(number_of_people_served) DESC) AS rank_by_mostly_affected
FROM water_source
GROUP BY type_of_water_source;

-- determining which tap or well is a priority to fix based on population the water source serve
SELECT source_id, type_of_water_source, number_of_people_served, 
RANK() OVER (ORDER BY number_of_people_served DESC) AS rank_by_mostly_affected
FROM water_source
WHERE type_of_water_source IN ('well', 'shared_tap')
GROUP BY source_id
ORDER BY rank_by_mostly_affected ASC
LIMIT 10;

-- determining how long the survey lasted in days and years Q1
SELECT 
TIMESTAMPDIFF(DAY, MIN(time_of_record), MAX(time_of_record)) AS survey_period_days,
TIMESTAMPDIFF(YEAR, MIN(time_of_record), MAX(time_of_record)) AS survey_period_years,
ROUND(TIMESTAMPDIFF(DAY, MIN(time_of_record), MAX(time_of_record)) / 365.25, 2) AS survey_period_years_fractional
FROM visits;

-- how long people have to queue on average in Maji Ndogo Q2
SELECT ROUND(AVG(time_in_queue),0) AS avg_queue_time
FROM visits
WHERE NULLIF(time_in_queue, 0) IS NOT NULL;
-- INSIGHT  - Our citizens often face long wait times for water, averaging more than 120 minutes.

-- What is the average queue times across different days of the week Q3 (pg 23 6a)
SELECT DAYNAME(time_of_record) AS day_of_week, SUM(time_in_queue) AS total_time_in_queue,
ROUND(AVG(NULLIF(time_in_queue, 0)),0) AS avg_time_in_queue
FROM visits
GROUP BY day_of_week;
-- INSIGHT - Queues are very long on Saturdays.

-- What time during the day people collect water./ what hour of the day is busiest Q4 (pg 23 no. 6b)
SELECT HOUR(time_of_record) AS time_of_day, SUM(time_in_queue) AS total_time_in_queue,
ROUND(AVG(NULLIF(time_in_queue, 0)),0) AS avg_time_in_queue
FROM visits
GROUP BY time_of_day
ORDER BY time_of_day;
-- INSIGHT - Queues are longer in the mornings and evenings

-- Analysing queue times for each hour of each day  (pg 23 no. 6c)
SELECT
    TIME_FORMAT(TIME(time_of_record), '%H:00') AS hour_of_day,
    -- Sunday
    ROUND(AVG(
        CASE
            WHEN DAYNAME(time_of_record) = 'Sunday' THEN time_in_queue
            ELSE NULL
        END
    ), 0) AS Sunday,
    -- Monday
    ROUND(AVG(
        CASE
            WHEN DAYNAME(time_of_record) = 'Monday' THEN time_in_queue
            ELSE NULL
        END
    ), 0) AS Monday,
    -- Tuesday
    ROUND(AVG(
        CASE
            WHEN DAYNAME(time_of_record) = 'Tuesday' THEN time_in_queue
            ELSE NULL
        END
    ), 0) AS Tuesday,
    -- Wednesday
    ROUND(AVG(
        CASE
            WHEN DAYNAME(time_of_record) = 'Wednesday' THEN time_in_queue
            ELSE NULL
        END
    ), 0) AS Wednesday,
    -- Thursday
    ROUND(AVG(
        CASE
            WHEN DAYNAME(time_of_record) = 'Thursday' THEN time_in_queue
            ELSE NULL
        END
    ), 0) AS Thursday,
    -- Friday
    ROUND(AVG(
        CASE
            WHEN DAYNAME(time_of_record) = 'Friday' THEN time_in_queue
            ELSE NULL
        END
    ), 0) AS Friday,
    -- Saturday
    ROUND(AVG(
        CASE
            WHEN DAYNAME(time_of_record) = 'Saturday' THEN time_in_queue
            ELSE NULL
        END
    ), 0) AS Saturday
FROM
    visits
WHERE
    time_in_queue != 0 -- this excludes entries with 0 queue times
GROUP BY
    hour_of_day
ORDER BY
    hour_of_day;
-- INSIGHT - - Wednesdays and Sundays have the shortest queues.


-- Integrating the Auditor's report 18/12/2024
DROP TABLE IF EXISTS `auditor_report`;
CREATE TABLE `auditor_report` (
`location_id` VARCHAR(32),
`type_of_water_source` VARCHAR(64),
`true_water_source_score` int DEFAULT NULL,
`statements` VARCHAR(255)
);

-- Are there differences in the auditor_report true_water_source_score table and field surveyors subjective_quality_score from water_quality table?
SELECT ar.location_id AS audit_location, ar.true_water_source_score, v.location_id AS visit_location, v.record_id, wq.subjective_quality_score AS surveyor_score
FROM auditor_report ar
JOIN visits v
ON  v.location_id = ar.location_id
JOIN water_quality wq
ON wq.record_id = v.record_id;

-- CHECKING IF THE auditor's and exployees' scores agree.
SELECT ar.location_id AS audit_location, ar.true_water_source_score, v.location_id AS visit_location, v.record_id, wq.subjective_quality_score AS surveyor_score
FROM auditor_report ar
JOIN visits v
ON  v.location_id = ar.location_id
JOIN water_quality wq
ON wq.record_id = v.record_id
WHERE ar.true_water_source_score = wq.subjective_quality_score;

-- REMOVING DUPLICATE VISITS
SELECT ar.location_id AS audit_location, ar.true_water_source_score, v.location_id AS visit_location, v.record_id, wq.subjective_quality_score AS surveyor_score
FROM auditor_report ar
JOIN visits v
ON  v.location_id = ar.location_id
JOIN water_quality wq
ON wq.record_id = v.record_id
WHERE ar.true_water_source_score = wq.subjective_quality_score AND v.visit_count=1;

-- CHECKING AND FIXING THE INCORRECT DATA
SELECT ar.location_id AS audit_location, ar.true_water_source_score, v.location_id AS visit_location, v.record_id, wq.subjective_quality_score AS surveyor_score
FROM auditor_report ar
JOIN visits v
ON  v.location_id = ar.location_id
JOIN water_quality wq
ON wq.record_id = v.record_id
WHERE ar.true_water_source_score != wq.subjective_quality_score AND v.visit_count=1;


-- CHECKING the 102 rows WHERE where type_of_water_source of auditor is the same but auditors true_water_source_score differs from the surveyor subjective_quality_score.
SELECT ar.location_id AS audit_location, 
ar.type_of_water_source AS auditor_source, 
ws.type_of_water_source AS survey_source, 
v.record_id, 
ar.true_water_source_score AS auditor_score, 
wq.subjective_quality_score AS surveyor_score
FROM auditor_report ar
JOIN visits v
ON  v.location_id = ar.location_id
JOIN water_source ws
ON ws.source_id = v.source_id
JOIN water_quality wq
ON wq.record_id = v.record_id
WHERE ar.true_water_source_score != wq.subjective_quality_score AND v.visit_count=1;
    

-- CHECKING THE EMPLOYEES WHO MADE THE ERRORS ON the 102 rows WHERE where type_of_water_source of auditor is the same but auditors true_water_source_score differs from the surveyor subjective_quality_score.
SELECT ar.location_id, 
v.record_id,
e.assigned_employee_id,
e.employee_name,
ar.true_water_source_score AS auditor_score, 
wq.subjective_quality_score AS surveyor_score
FROM auditor_report ar
JOIN visits v
ON ar.location_id = v.location_id
JOIN employee e
ON  v.assigned_employee_id = e.assigned_employee_id
JOIN water_quality wq
ON v.record_id = wq.record_id
JOIN water_source ws
ON ws.source_id = v.source_id
WHERE ar.true_water_source_score != wq.subjective_quality_score AND v.visit_count=1;


-- SAVING QUERY AS A CTE LOOKING AT ITS COMPLEXITY SO THAT WE CAN CALL THE CTE FOR FURTHER ANALYSIS
-- CHECKING THE EMPLOYEES WHO MADE THE ERRORS ON the 102 rows WHERE where type_of_water_source of auditor is the same but auditors true_water_source_score differs from the surveyor subjective_quality_score.
WITH incorrect_records AS (
SELECT ar.location_id, 
v.record_id,
e.assigned_employee_id,
e.employee_name AS employee_name,
ar.true_water_source_score AS auditor_score, 
wq.subjective_quality_score AS surveyor_score
FROM auditor_report ar
JOIN visits v
ON ar.location_id = v.location_id
JOIN employee e
ON  v.assigned_employee_id = e.assigned_employee_id
JOIN water_quality wq
ON v.record_id = wq.record_id
JOIN water_source ws
ON ws.source_id = v.source_id
WHERE ar.true_water_source_score != wq.subjective_quality_score AND v.visit_count=1

)
SELECT employee_name, COUNT(surveyor_score) AS number_of_mistakes
FROM incorrect_records
GROUP BY employee_name
ORDER BY number_of_mistakes DESC;

-- OR
-- using VIEW TO CHECK THE EMPLOYEES WHO MADE THE ERRORS ON the 102 rows WHERE where type_of_water_source of auditor is the same but auditors true_water_source_score differs from the surveyor subjective_quality_score.
-- finding all of the employees who have an above-average number of mistakes
CREATE VIEW incorrect_records AS (
SELECT ar.location_id, 
v.record_id,
e.employee_name AS employee_name,
ar.true_water_source_score AS auditor_score, 
wq.subjective_quality_score AS surveyor_score,
ar.statements AS statement
FROM auditor_report ar
JOIN visits v
ON ar.location_id = v.location_id
JOIN employee e
ON  v.assigned_employee_id = e.assigned_employee_id
JOIN water_quality wq
ON v.record_id = wq.record_id
-- JOIN water_source ws
-- ON ws.source_id = v.source_id
WHERE ar.true_water_source_score != wq.subjective_quality_score AND v.visit_count=1
);
SELECT *
FROM
incorrect_records;

-- USING CTE TO CHECK NUMBER OF ERRORS MADE BY EACH EMPLOYEE ON the 102 rows WHERE where type_of_water_source of auditor is the same but auditors true_water_source_score differs from the surveyor subjective_quality_score.
WITH error_count AS ( -- This CTE calculates the number of mistakes each employee made
SELECT employee_name, COUNT(employee_name) AS number_of_mistakes
FROM
incorrect_records
GROUP BY employee_name)
SELECT * FROM error_count;

-- CALCULATING THE AVERAGE NUMBER OF ERRORS 
WITH error_count AS ( -- This CTE calculates the number of mistakes each employee made
SELECT employee_name, COUNT(*) AS number_of_mistakes
FROM
incorrect_records
GROUP BY employee_name)
SELECT ROUND(AVG(number_of_mistakes),0)  
FROM error_count;

-- USING THE AVERAGE TO DETERMINE EMPLOYEES WHO MORE THAN THE AVREAGE MISTAKE
WITH error_count AS ( -- This CTE calculates the number of mistakes each employee made
SELECT employee_name, COUNT(*) AS mistake_count
FROM
incorrect_records
GROUP BY employee_name)
SELECT employee_name, mistake_count  
FROM error_count
WHERE mistake_count>6;

-- pull up all of the records where the employee_name is in the suspect list
WITH error_count AS ( -- This CTE calculates the number of mistakes each employee made
SELECT
employee_name,
COUNT(employee_name) AS number_of_mistakes
FROM
incorrect_records
/*
Incorrect_records is a view that joins the audit report to the database
for records where the auditor and
employees scores are different*/

GROUP BY
employee_name),
suspect_list AS (-- This CTE SELECTS the employees with above−average mistakes
SELECT
employee_name,
number_of_mistakes
FROM
error_count
WHERE
number_of_mistakes > (SELECT AVG(number_of_mistakes) FROM error_count))
-- This query filters all of the records where the "corrupt" employees gathered data.
SELECT
employee_name,
location_id,
statements
FROM
Incorrect_records
WHERE
employee_name in (SELECT employee_name FROM suspect_list);

-- 16.2
CREATE VIEW combined_analysis_table AS
-- This view assembles data from different tables into one to simplify analysis
SELECT ws.type_of_water_source AS source_type, l.town_name, l.province_name,  l.location_type, ws.number_of_people_served as people_served, v.time_in_queue, wp.results
FROM visits v
LEFT JOIN
well_pollution wp  
ON wp.source_id = v.source_id
INNER JOIN location l
ON l.location_id = v.location_id 
INNER JOIN water_source ws
ON ws.source_id = v.source_id
WHERE v.visit_count = 1;



-- Using a CTE to calculate the population of each province and main query checks percentage population using a particular type of water source to the total population other water source types. 
WITH province_totals AS (-- This CTE calculates the population of each province
SELECT
province_name,
SUM(people_served) AS total_ppl_serv
FROM
combined_analysis_table
GROUP BY
province_name
)
SELECT
ct.province_name,
-- These case statements create columns for each type of source.
-- The results are aggregated and percentages are calculated
ROUND((SUM(CASE WHEN source_type = 'river'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS river,
ROUND((SUM(CASE WHEN source_type = 'shared_tap'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS shared_tap,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN source_type = 'well'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS well
FROM
combined_analysis_table ct
JOIN
province_totals pt ON ct.province_name = pt.province_name
GROUP BY
ct.province_name
ORDER BY
ct.province_name;


-- Using a CTE to calculate the population of each town and main query checks percentage population in a town using a particular type of water source to the total population using other water source types in the town.
WITH town_totals AS (-- This CTE calculates the population of each town
-- Since there are two Harare towns, we have to group by province_name and town_name
SELECT province_name, town_name, SUM(people_served) AS total_ppl_serv
FROM combined_analysis_table
GROUP BY province_name,town_name
)
SELECT
ct.province_name,
ct.town_name,
ROUND((SUM(CASE WHEN source_type = 'river'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS river,
ROUND((SUM(CASE WHEN source_type = 'shared_tap'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS shared_tap,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN source_type = 'well'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS well
FROM
combined_analysis_table ct
JOIN -- Since the town names are not unique, we have to join on a composite key
town_totals tt ON ct.province_name = tt.province_name AND ct.town_name = tt.town_name
GROUP BY -- We group by province first, then by town.
ct.province_name,
ct.town_name
ORDER BY
ct.town_name;


-- CONVERTING OUR PREVIOUS QUERY CTE TO A TABLE
CREATE TEMPORARY TABLE town_aggregated_water_access AS
-- Subquery to calculate town-level water source percentages
SELECT
    ct.province_name,
    ct.town_name,
    ROUND((SUM(CASE WHEN source_type = 'river'
        THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS river,
    ROUND((SUM(CASE WHEN source_type = 'shared_tap'
        THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS shared_tap,
    ROUND((SUM(CASE WHEN source_type = 'tap_in_home'
        THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home,
    ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken'
        THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken,
    ROUND((SUM(CASE WHEN source_type = 'well'
        THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS well
FROM
    combined_analysis_table ct
JOIN 
    ( -- Subquery to calculate town-level population totals
        SELECT 
            province_name, 
            town_name, 
            SUM(people_served) AS total_ppl_serv
        FROM combined_analysis_table
        GROUP BY province_name, town_name
    ) tt 
    ON ct.province_name = tt.province_name AND ct.town_name = tt.town_name
GROUP BY 
    ct.province_name, 
    ct.town_name
ORDER BY 
    ct.town_name;

-- CHECKING NUMBER OF BROKEN TAPS FROM OUR NEW TABLE town_aggregated_water_access
SELECT
province_name,
town_name,
ROUND(tap_in_home_broken / (tap_in_home_broken + tap_in_home) * 100,0) AS Pct_broken_taps
FROM
town_aggregated_water_access;

/**
Insights
Ok, so let's sum up the data we have.
A couple of weeks ago we found some interesting insights:
1. Most water sources are rural in Maji Ndogo.
2. 43% of our people are using shared taps. 2000 people often share one tap.
3. 31% of our population has water infrastructure in their homes, but within that group,
4. 45% face non-functional systems due to issues with pipes, pumps, and reservoirs. Towns like Amina, the rural parts of Amanzi, and a couple
of towns across Akatsi and Hawassa have broken infrastructure.
5. 18% of our people are using wells of which, but within that, only 28% are clean. These are mostly in Hawassa, Kilimani and Akatsi.
6. Our citizens often face long wait times for water, averaging more than 120 minutes:
• Queues are very long on Saturdays.
• Queues are longer in the mornings and evenings.
• Wednesdays and Sundays have the shortest queues.


Plan of action
1. We want to focus our efforts on improving the water sources that affect the most people.
• Most people will benefit if we improve the shared taps first.
2. Wells are a good source of water, but many are contaminated. Fixing this will benefit a lot of people.
3. Fixing existing infrastructure will help many people. If they have running water again, they won't have to queue, thereby shorting queue times
for others. So we can solve two problems at once.
4. Installing taps in homes will stretch our resources too thin, so for now if the queue times are low, we won't improve that source.
5. Most water sources are in rural areas. We need to ensure our teams know this as this means they will have to make these repairs/upgrades in
rural areas where road conditions, supplies, and labour are harder challenges to overcome.

Practical solutions:
1. If communities are using rivers, we will dispatch trucks to those regions to provide water temporarily in the short term, while we send out
crews to drill for wells, providing a more permanent solution. Sokoto is the first province we will target.
2. If communities are using wells, we will install filters to purify the water. For chemically polluted wells, we can install reverse osmosis (RO)
filters, and for wells with biological contamination, we can install UV filters that kill microorganisms - but we should install RO filters too. In
the long term, we must figure out why these sources are polluted.
3. For shared taps, in the short term, we can send additional water tankers to the busiest taps, on the busiest days. We can use the queue time
pivot table we made to send tankers at the busiest times. Meanwhile, we can start the work on installing extra taps where they are needed.
According to UN standards, the maximum acceptable wait time for water is 30 minutes. With this in mind, our aim is to install taps to get
queue times below 30 min. Towns like Bello, Abidjan and Zuri have a lot of people using shared taps, so we will send out teams to those
towns first.
4. Shared taps with short queue times (< 30 min) represent a logistical challenge to further reduce waiting times. The most effective solution,
installing taps in homes, is resource-intensive and better suited as a long-term goal.
5. Addressing broken infrastructure offers a significant impact even with just a single intervention. It is expensive to fix, but so many people can
benefit from repairing one facility. For example, fixing a reservoir or pipe that multiple taps are connected to. We identified towns like Amina,
Lusaka, Zuri, Djenne and rural parts of Amanzi seem to be good places to start.


A practical plan
Our final goal is to implement our plan in the database.
We have a plan to improve the water access in Maji Ndogo, so we need to think it through, and as our final task, create a table where our teams
have the information they need to fix, upgrade and repair water sources. They will need the addresses of the places they should visit (street
address, town, province), the type of water source they should improve, and what should be done to improve it.
We should also make space for them in the database to update us on their progress. We need to know if the repair is complete, and the date it was
completed, and give them space to upgrade the sources. Let's call this table Project_progress.

**/
USE md_water_services;
/**
-- OUR GOAL
Our final goal is to implement our plan in the database.
We have a plan to improve the water access in Maji Ndogo, so we need to think it through, and as our final task, create a table where our teams
have the information they need to fix, upgrade and repair water sources. They will need the addresses of the places they should visit (street
address, town, province), the type of water source they should improve, and what should be done to improve it.
We should also make space for them in the database to update us on their progress. We need to know if the repair is complete, and the date it was
completed, and give them space to upgrade the sources. Let's call this table Project_progress.
**/

CREATE TABLE Project_progress (
Project_id SERIAL PRIMARY KEY,
source_id VARCHAR(20) NOT NULL REFERENCES water_source(source_id) ON DELETE CASCADE ON UPDATE CASCADE,
Address VARCHAR(50),
Town VARCHAR(30),
Province VARCHAR(30),
Source_type VARCHAR(50),
Improvement VARCHAR(50),
Source_status VARCHAR(50) DEFAULT 'Backlog' CHECK (Source_status IN ('Backlog', 'In progress', 'Complete')),
Date_of_completion DATE,
Comments TEXT 
);

/**
At a high level, the Improvements are as follows:
1. Rivers → Drill wells
2. wells: if the well is contaminated with chemicals → Install RO filter
3. wells: if the well is contaminated with biological contaminants → Install UV and RO filter
4. shared_taps: if the queue is longer than 30 min (30 min and above) → Install X taps nearby where X number of taps is calculated using X
= FLOOR(time_in_queue / 30).
5. tap_in_home_broken → Diagnose local infrastructure
**/

-- Filtering the data to only contain sources we want to improve
SELECT
l.address,
l.town_name,
l.province_name,
ws.source_id,
ws.type_of_water_source,
wp.results
FROM
water_source ws
LEFT JOIN
well_pollution wp ON ws.source_id = wp.source_id
INNER JOIN
visits v ON ws.source_id = v.source_id
INNER JOIN
location l ON l.location_id = v.location_id
WHERE
    v.visit_count = 1 
    AND (v.time_in_queue > 30 AND ws.type_of_water_source = 'shared_tap') 
    OR (ws.type_of_water_source = 'well' AND wp.results != 'Clean') 
    OR ws.type_of_water_source IN ('river', 'tap_in_home_broken');
  
-- Adding the data to Project_progress table
INSERT INTO md_water_services.project_progress (
    source_id,
    Address,
    Town,
    Province,
    Source_type,
    Improvement
)
SELECT
    ws.source_id,
    l.address,
    l.town_name,
    l.province_name,
    ws.type_of_water_source,
    CASE
        WHEN ws.type_of_water_source = 'well' AND wp.results = 'Contaminated: Biological' THEN 'Install UV filter'
        WHEN ws.type_of_water_source = 'well' AND wp.results = 'Contaminated: Chemical' THEN 'Install RO filter'
        WHEN ws.type_of_water_source = 'river' THEN 'Drill well'
        WHEN ws.type_of_water_source = 'shared_tap' AND v.time_in_queue > 30 THEN CONCAT('Install ', FLOOR(v.time_in_queue / 30), ' taps')
        WHEN ws.type_of_water_source = 'tap_in_home_broken' THEN 'Diagnose local infrastructure'
        ELSE NULL
    END AS Improvement
FROM
    water_source ws
LEFT JOIN
    well_pollution wp ON ws.source_id = wp.source_id
INNER JOIN
    visits v ON ws.source_id = v.source_id
INNER JOIN
    location l ON l.location_id = v.location_id
WHERE
    v.visit_count = 1 -- This must always be true
    AND (
       wp.results != 'Clean'-- Include wells
        OR ws.type_of_water_source IN ('tap_in_home_broken', 'river') -- Include specified types
        OR (ws.type_of_water_source = 'shared_tap' AND v.time_in_queue > 30) -- Shared taps with queue times > 30
    );



SELECT * 
FROM md_water_services.project_progress
WHERE Source_type IN ('river','well') AND Improvement IS NULL;