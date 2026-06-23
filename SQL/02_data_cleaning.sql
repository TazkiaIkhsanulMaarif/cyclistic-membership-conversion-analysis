-- Creates a view called `cyclistic.cleaned_data` that contains cleaned trip data from the `cyclistic.tripdata_view`.
CREATE OR REPLACE VIEW cyclistic.cleaned_data AS

SELECT *,
  TIMESTAMP_DIFF(ended_at, started_at, MINUTE) AS ride_length
FROM cyclistic.tripdata_view
WHERE TIMESTAMP_DIFF(ended_at, started_at, MINUTE) > 0
  AND TIMESTAMP_DIFF(ended_at, started_at, MINUTE) <= 1440;

