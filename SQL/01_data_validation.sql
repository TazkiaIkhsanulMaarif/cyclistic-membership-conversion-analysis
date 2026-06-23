-- Check Total Row Count
SELECT
  COUNT(*) AS total_rows
FROM cyclistic.tripdata_view;
 
-- Check Null Values
SELECT
  COUNTIF(ride_id IS NULL) AS null_ride_id,
  COUNTIF(started_at IS NULL) AS null_started_at,
  COUNTIF(ended_at IS NULL) AS null_ended_at,
  COUNTIF(member_casual IS NULL) AS null_member_type
FROM cyclistic.tripdata_view;
 
-- Check Duplicate Ride IDs
SELECT
  ride_id,
  COUNT(*) AS duplicate_count
FROM cyclistic.tripdata_view
GROUP BY ride_id
HAVING COUNT(*) > 1;
 
-- Check Invalid Duration (negative, zero, or longer than 24 hours)
WITH ride_duration AS (
  SELECT
    ride_id,
    started_at,
    ended_at,
    TIMESTAMP_DIFF(ended_at, started_at, MINUTE) AS ride_length
  FROM cyclistic.tripdata_view
)
 
SELECT
  COUNTIF(ride_length <= 0) AS negative_or_zero_duration,
  COUNTIF(ride_length > 1440) AS over_24_hours,
  COUNT(*) AS total_rows_checked
FROM ride_duration;
 
-- Check Outliers in Ride Duration (using percentile thresholds)
WITH ride_duration_valid AS (
  SELECT
    TIMESTAMP_DIFF(ended_at, started_at, MINUTE) AS ride_length
  FROM cyclistic.tripdata_view
  WHERE TIMESTAMP_DIFF(ended_at, started_at, MINUTE) > 0
)
 
SELECT
  MIN(ride_length) AS min_duration,
  MAX(ride_length) AS max_duration,
  ROUND(AVG(ride_length), 2) AS avg_duration,
  APPROX_QUANTILES(ride_length, 100)[OFFSET(50)] AS median_duration,
  APPROX_QUANTILES(ride_length, 100)[OFFSET(95)] AS p95_duration,
  APPROX_QUANTILES(ride_length, 100)[OFFSET(99)] AS p99_duration
FROM ride_duration_valid;
