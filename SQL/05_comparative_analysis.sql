-- Comparative Analysis: Average Ride Duration by User Type
SELECT
  member_casual,
  ROUND(AVG(ride_length), 2) AS avg_ride_duration
FROM cyclistic.cleaned_data
GROUP BY member_casual;

