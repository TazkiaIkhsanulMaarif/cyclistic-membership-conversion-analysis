-- Business Insights: Ride Patterns by Month and User Type
SELECT
  month_name,
  member_casual,
  COUNT(*) AS total_rides
FROM cyclistic.cleaned_data
GROUP BY month_name, member_casual;