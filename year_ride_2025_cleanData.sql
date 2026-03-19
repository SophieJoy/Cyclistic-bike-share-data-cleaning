
-- What This Script Achieves --

-- Create a new table from the combined dataset 
-- Removes duplicates --
-- Removes invalid and incomplete records --
-- Handles NULL values properly --
-- Creates additional columns (ride_length, day_of_week, ride_month) -- 
-- Produces a clean dataset ready for analysis --
-- Note: The reason we replaced null values with 0 in "start_station_id" and "end_station_id" columns, 
-- is because we do not want to skew the analysis by removing rows that contain critical information.


SELECT 
    ride_id,
    COALESCE(rideable_type, 'unknown') AS rideable_type,
    started_at,
    ended_at,
    COALESCE(start_station_name, 'Unknown Station') AS start_station_name,
    COALESCE(TRY_CAST(start_station_id AS FLOAT), 0) AS start_station_id,
    COALESCE(end_station_name, 'Unknown Station') AS end_station_name,
    COALESCE(TRY_CAST(end_station_id AS FLOAT), 0) AS end_station_id,
    COALESCE(TRY_CAST(start_lat AS FLOAT), 0.0) AS start_lat,
    COALESCE(TRY_CAST(start_lng AS FLOAT), 0.0) AS start_lng,
    COALESCE(TRY_CAST(end_lat AS FLOAT), 0.0) AS end_lat,
    COALESCE(TRY_CAST(end_lng AS FLOAT), 0.0) AS end_lng,
    CASE 
        WHEN member_casual NOT IN ('member', 'casual') OR member_casual IS NULL 
        THEN 'casual' 
        ELSE member_casual 
    END AS member_casual
INTO dbo.cyclistic_2025
FROM 
   [2025_trip_combinedData].[dbo].[2025-data_combined]
 AS combined;


  -- Check duplicate records --
SELECT 
	ride_id, COUNT(*)AS DUPLICATES
    FROM cyclistic_2025
	GROUP BY ride_id
	HAVING COUNT(*)>1

-- Identify duplicate records
SELECT *
FROM cyclistic_2025
WHERE ride_id IN (
    SELECT ride_id
    FROM cyclistic_2025
    GROUP BY ride_id
    HAVING COUNT(*) > 1
)
ORDER BY ride_id;


-- Remove Duplicates (Keep One Record): This keeps the first occurrence and deletes the rest. --
WITH DuplicateCTE AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY ride_id
               ORDER BY started_at
           ) AS row_num
    FROM cyclistic_2025
)
DELETE FROM DuplicateCTE
WHERE row_num > 1;


-- Remove rows with critical NULL values -- 
-- These columns are essential for analysis: ride_id, started_at, ended_at, member_casual
DELETE FROM cyclistic_2025
WHERE ride_id IS NULL
   OR started_at IS NULL
   OR ended_at IS NULL
   OR member_casual IS NULL;


-- Remove invalid ride durations --
DELETE FROM cyclistic_2025
WHERE DATEDIFF(MINUTE, started_at, ended_at) <= 0
   OR DATEDIFF(MINUTE, started_at, ended_at) < 1
   OR DATEDIFF(MINUTE, started_at, ended_at) > 1440;


-- Check empty values 
SELECT COUNT(*)
FROM cyclistic_2025
WHERE start_station_name  =''
	OR end_station_name ='';


-- Validate Cleanup --
SELECT COUNT(*) AS total_rows FROM cyclistic_2025;

SELECT COUNT(DISTINCT ride_id) AS unique_rides
FROM cyclistic_2025;


-- Add ride length column (in minutes)
ALTER TABLE cyclistic_2025
ADD ride_length INT;
UPDATE cyclistic_2025
SET ride_length = DATEDIFF(MINUTE, started_at, ended_at)


-- Add day of week column
ALTER TABLE cyclistic_2025
ADD day_of_week VARCHAR(20);
UPDATE cyclistic_2025
SET day_of_week = DATENAME(WEEKDAY, started_at);


-- Add month column
ALTER TABLE cyclistic_2025
ADD ride_month VARCHAR(20);
UPDATE cyclistic_2025
SET ride_month = DATENAME(MONTH, started_at);





