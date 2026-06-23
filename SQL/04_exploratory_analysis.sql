-- Exploratory Analysis: Ride Patterns by Month and User Type
SELECT
  FORMAT_DATE('%B', DATE(started_at)) AS month_name,
  member_casual,
  COUNT(*) AS total_rides
FROM cyclistic.cleaned_data
GROUP BY month_name, member_casual
ORDER BY total_rides DESC;