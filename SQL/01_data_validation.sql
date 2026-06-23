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