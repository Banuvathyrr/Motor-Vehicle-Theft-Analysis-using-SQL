USE stolen_vehicles_db;
SELECT * FROM stolen_vehicles;

-- HANDLING MISSING ROWS--
SELECT 
	*
FROM 
	stolen_vehicles
WHERE
	vehicle_type = 'NULL';
    
    
DELETE FROM 
	stolen_vehicles
WHERE 
	vehicle_type IS NULL;


-- CHECK FOR DUPLICATE ROWS--
WITH CTE AS
(
SELECT
	*,
    ROW_NUMBER() OVER(Partition by vehicle_id, vehicle_type, make_id, model_year, vehicle_desc, color, date_stolen, location_id ORDER BY vehicle_id ASC) as row_num
FROM stolen_vehicles
)
	SELECT COUNT(*) FROM CTE WHERE row_num > 1;
-- No duplicate rows--


-- EXTRACT YEAR, MONTH AND DAY NAME FROM COLUMN DATE_STOLEN AND MAKE A SEPARATE COLUMNS FOR EACH--
-- YEAR--
SELECT EXTRACT(Year FROM date_stolen) FROM stolen_vehicles;

ALTER TABLE stolen_vehicles
ADD COLUMN Year int after location_id; 

UPDATE stolen_vehicles
SET Year = EXTRACT(Year FROM date_stolen);

-- MONTH--
SELECT EXTRACT(Month FROM date_stolen) FROM stolen_vehicles;

ALTER TABLE stolen_vehicles
ADD COLUMN Month int after Year;

UPDATE stolen_vehicles
SET Month = EXTRACT(Month FROM date_stolen);

-- WEEK--
SELECT EXTRACT(Week FROM date_stolen) FROM stolen_vehicles;

ALTER TABLE stolen_vehicles
ADD COLUMN Week int after Month;

UPDATE stolen_vehicles
SET Week = EXTRACT(Week FROM date_stolen);

-- DAY NAME--
SELECT Dayname(date_stolen) FROM stolen_vehicles;

ALTER TABLE stolen_vehicles
MODIFY COLUMN `Day Name` character(15) after Week;

UPDATE stolen_vehicles
SET `Day Name` = Dayname(date_stolen);


-- 


-- DATA ANALYSIS--
-- 1) How many stolen vehicles were reported in each region?
SELECT
	loc.region, 
    count(*) as No_of_stolen_vehicles
FROM 
stolen_vehicles sv
INNER JOIN 
locations loc 
ON sv.location_id = loc.location_id
GROUP BY loc.region
ORDER BY No_of_stolen_vehicles desc;
-- Maximum number of theft happened in Auckland-- 


-- 2) What is the average population density in regions where stolen trailers were reported?
SELECT vehicle_type
FROM stolen_vehicles
WHERE vehicle_type LIKE '%trailer';

WITH CTE2 as 
(
SELECT 
	sv.vehicle_type, ROUND(AVG(loc.density),2) as Avg_pop_density_of_region_stolen, COUNT(*) as No_of_trailers_stolen
FROM
	stolen_vehicles sv
INNER JOIN
	locations loc
ON 
	sv.location_id = loc.location_id
GROUP BY 
	sv.vehicle_type
)
SELECT vehicle_type, Avg_pop_density_of_region_stolen, No_of_trailers_stolen
FROM CTE2
WHERE vehicle_type LIKE '%Trailer';


-- 3) Rank the boat trailer thefts based on the date stolen within each region--

SELECT
	loc.region, sv.date_stolen,
    RANK() OVER(Partition by loc.region ORDER BY sv.date_stolen asc) as rankn
FROM 
	stolen_vehicles sv
INNER JOIN
	locations loc
ON
	sv.location_id = loc.location_id
WHERE vehicle_type = 'Boat trailer'
;



-- 4) What is the average time interval between the successive thefts--
WITH CTE3 AS(
WITH CTE2 AS(
SELECT
    date_stolen,
    LEAD(date_stolen) OVER (ORDER BY date_stolen) AS next_stolen_date
FROM
    stolen_vehicles sv
INNER JOIN
	locations loc
ON
	sv.location_id = loc.location_id
    )
SELECT
	(DATEDIFF(next_stolen_date, date_stolen)) AS inter from CTE2
)
SELECT AVG(inter) FROM CTE3;

-- (OR)

WITH CTE2 AS (
    SELECT
        date_stolen,
        LEAD(date_stolen) OVER (ORDER BY date_stolen) AS next_stolen_date
    FROM
        stolen_vehicles sv
    INNER JOIN
        locations loc ON sv.location_id = loc.location_id
),
CTE3 AS (
    SELECT
        (DATEDIFF(next_stolen_date, date_stolen)) AS inter
    FROM
        CTE2
)
SELECT AVG(inter) AS avg_interval FROM CTE3;



-- 5) How many stolen vehicles have been reported in regions with a population greater than the average population?
WITH CTE3 AS(
SELECT 
	loc.region, COUNT(*) AS cnt
FROM stolen_vehicles sv
INNER JOIN
locations loc
ON sv.location_id= loc.location_id
WHERE loc.population > (SELECT AVG(population) FROM locations)
GROUP BY loc.region
) SELECT SUM(cnt) FROM CTE3;



-- 6) Classify stolen vehicles as 'High Risk' if their model year is before 2010, and 'Low Risk' otherwise.
SELECT * FROM stolen_vehicles;

ALTER TABLE stolen_vehicles
ADD COLUMN risk_status varchar(35) after `Day Name`;

UPDATE stolen_vehicles
SET risk_status =
CASE 
	WHEN model_year < 2010 THEN 'High Risk'
    ELSE 'Low Risk'
END;

-- Count the number of vehicles based on the risk status--
SELECT 
	risk_status,
	COUNT(*) AS No_of_stolen_vehicles
FROM
	stolen_vehicles
GROUP BY risk_status;

ALTER TABLE stolen_vehicles
DROP COLUMN risk_status;


-- 7) How many stolen vehicles are reported in total?
WITH CTE AS(
SELECT
	loc.region,
    count(*) as No_of_stolen_vehicles
FROM 
stolen_vehicles sv
INNER JOIN 
locations loc 
ON sv.location_id = loc.location_id
GROUP BY loc.region
ORDER BY No_of_stolen_vehicles desc
)
SELECT SUM(No_of_stolen_vehicles) FROM CTE;
-- Totally 4527 vehicles are stolen--

-- 8) How many distinct vehicle types are reported as stolen?
SELECT 
	COUNT(DISTINCT vehicle_type) 
FROM stolen_vehicles;
-- There are 25 different vehicle types reported to be stolen--

--  9) What are the total number of regions in the dataset?
SELECT 
	COUNT(DISTINCT region) 
FROM 
	locations;
-- 16 regions

--  10) Which region has the highest population in the dataset?
SELECT 
	region, 
	population
FROM 
	locations
ORDER BY 
	population desc
LIMIT 5;
-- AUckland has highest population so no of thefts also high.

-- 11) What is the most common make of vehicles that was stole?
SELECT
	md.make_id,md.make_name,
    count(*) as No_of_makes
FROM 
stolen_vehicles sv
INNER JOIN 
make_details md 
ON sv.make_id = md.make_id
GROUP BY md.make_id
ORDER BY No_of_makes desc;
-- Toyota has been stolen more than any other make in New Zealand 

-- 12) How many stolen vehicles belong to the make "Audi"?
SELECT
	md.make_id,md.make_name,
    count(*) as No_of_stolen_vehicles
FROM 
stolen_vehicles sv
INNER JOIN 
make_details md 
ON sv.make_id = md.make_id
GROUP BY md.make_id
HAVING make_name = 'Audi'
ORDER BY No_of_stolen_vehicles desc;
-- Number of stolen vehicles in Audi is 40

-- 13) WHat are the common vehicle type prone to more threats--
WITH CTE2 as 
(
SELECT 
	sv.vehicle_type, ROUND(AVG(loc.density),2) as Avg_pop_density_of_region_stolen, COUNT(*) as No_of_stolen_vehicles
FROM
	stolen_vehicles sv
INNER JOIN
	locations loc
ON 
	sv.location_id = loc.location_id
GROUP BY 
	sv.vehicle_type
)
SELECT vehicle_type, Avg_pop_density_of_region_stolen, No_of_stolen_vehicles
FROM CTE2
ORDER BY No_of_stolen_vehicles desc;
-- Vehicle type 'Stationwagon' has been prone to more thefts which was followed by Saloon(Sedan), Hatchback..
-- Articulated truck and Special purpose vehicles has been least stolen


-- 14) population density, vehicle make, and frequency of stolen vehicles reported in different regions

WITH StolenVehicleCounts AS (
SELECT
	location_id,
    COUNT(*) as num_stolen_vehicles
FROM 
	stolen_vehicles
GROUP BY
	location_id
    ),
RegionPopulation AS (
SELECT 
	l.location_id,
    l.region,
    l.population,
    l.density, COALESCE(svc.num_stolen_vehicles, 0) AS num_stolen_vehicles
FROM 
	locations l
INNER JOIN
	StolenVehicleCounts svc 
ON 
	l.location_id = svc.location_id
    )  
SELECT 
	location_id,
    region,
    population, density,
    num_stolen_vehicles
FROM
	RegionPopulation
ORDER BY 
	num_stolen_vehicles desc;
 
 
 -- 15) What day of the week are vehicles most often and least often stolen?
  SELECT * FROM stolen_vehicles;
 
 SELECT 
	`Day Name`,
     COUNT(*) As No_vehicles_stolen
FROM 
	stolen_vehicles
GROUP BY 
	`Day Name`
ORDER BY No_vehicles_stolen DESC;
-- Monday and Tuesday are the days when the vehicles are most stolen..Saturday and Sunday are the days when the vehicles are least stolen.


-- 16) What types of vehicles are most often and least often stolen? Does this vary by region?
SELECT 
	sv.vehicle_type,
    loc.region,
    COUNT(*) AS No_of_stolen_vehicles
FROM
	stolen_vehicles sv
INNER JOIN
	locations loc
ON
	sv.location_id = loc.location_id
GROUP BY sv.vehicle_type, loc.region
ORDER BY No_of_stolen_vehicles DESC;
    
SELECT 
	loc.region, loc.density,
    COUNT(*) AS No_of_stolen_vehicles
FROM
	stolen_vehicles sv
INNER JOIN
	locations loc
ON
	sv.location_id = loc.location_id
GROUP BY loc.region, loc.density
ORDER BY No_of_stolen_vehicles DESC;
-- The region with more population density (Auckland) reported higher thefts and region with 
-- less population density(Southland) reported with lesser thefts.

-- 17) What is the average age of the vehicles that are stolen? Does this vary based on the vehicle type?
SELECT * FROM stolen_vehicles;

WITH Ageofvehicle AS (
SELECT 
	vehicle_type,
    (Year- model_year) AS Age
FROM
	stolen_vehicles
    ) 
SELECT 
	vehicle_type,
    AVG(Age) AS AvgAge
FROM Ageofvehicle
GROUP BY vehicle_type
ORDER BY AvgAge Desc;
    
        

