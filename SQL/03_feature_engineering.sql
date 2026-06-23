-- Feature Engineering for Cyclistic Bike Share Data
SELECT *,
  TIMESTAMP_DIFF(ended_at, started_at, MINUTE) AS ride_length,

  -- Weekend Flag
  CASE
    WHEN EXTRACT(DAYOFWEEK FROM started_at) IN (1, 7)
    THEN 'Weekend'
    ELSE 'Weekday'
  END AS weekend_flag,

  -- Time Of Day
  CASE
    WHEN EXTRACT(HOUR FROM started_at) BETWEEN 5 AND 11 THEN 'Morning'
    WHEN EXTRACT(HOUR FROM started_at) BETWEEN 12 AND 16 THEN 'Afternoon'
    WHEN EXTRACT(HOUR FROM started_at) BETWEEN 17 AND 20 THEN 'Evening'
    ELSE 'Night'
  END AS time_of_day

FROM cyclistic.tripdata_view
WHERE TIMESTAMP_DIFF(ended_at, started_at, MINUTE) > 0
  AND TIMESTAMP_DIFF(ended_at, started_at, MINUTE) <= 1440;