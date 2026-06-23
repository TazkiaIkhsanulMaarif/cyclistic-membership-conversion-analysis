# Cyclistic Bike-Share Case Study

A data analytics case study exploring how annual members and casual riders use Cyclistic bikes differently, with the goal of informing marketing strategies to convert casual riders into annual members.

📊 **[View Interactive Power BI Dashboard](https://app.powerbi.com/reportEmbed?reportId=e4c18ac0-042c-463c-ac3a-6336a0e5ca00&autoAuth=true&ctid=75a8f28a-d996-48b0-8ec0-1b201a5c163e)**

---

## Project Overview

This project follows the complete data analysis workflow from historical trip records to actionable business recommendations using Google BigQuery for data processing and Power BI for visualization.

### Business Task

Cyclistic's finance team has concluded that annual members are more profitable than casual riders. This analysis examines behavioral differences between the two rider segments to support marketing strategies aimed at increasing annual membership conversions.

---

## Tools Used

- **Google BigQuery** — data validation, cleaning, feature engineering, and analysis
- **Power BI** — interactive dashboard and data visualization

---

## SQL Analysis

The analysis was conducted using Google BigQuery and organized into six stages:

1. Data Validation
2. Data Cleaning
3. Feature Engineering
4. Exploratory Data Analysis
5. Comparative Analysis
6. Business Insights

The complete SQL scripts can be found in the [`/SQL`](./SQL) directory.

| File | Stage | Description |
|---|---|---|
| `01_data_validation.sql` | Data Validation | Checks for null values and duplicate ride IDs |
| `02_data_cleaning.sql` | Data Cleaning | Calculates ride length and removes invalid durations |
| `03_feature_engineering.sql` | Feature Engineering | Creates weekend flag and time-of-day categories |
| `04_exploratory_analysis.sql` | Exploratory Analysis | Monthly and hourly ride trends |
| `05_comparative_analysis.sql` | Comparative Analysis | Ride duration, bike type, and weekend usage by rider type |
| `06_business_insights.sql` | Business Insights | Seasonality and key differentiator queries |

---

## Example SQL Query

```sql
SELECT
  member_casual,
  ROUND(AVG(ride_length), 2) AS avg_ride_duration
FROM cyclistic.cleaned_data
GROUP BY member_casual;
```

This query compares average ride duration between annual members and casual riders, one of the strongest differentiators found in this analysis.

---

## Key Insights

**1. Casual riders use bikes primarily for leisure activities**
Casual riders average **26.4 minutes** per ride, compared to just **12.9 minutes** for annual members — over 2× longer. This points to recreational use rather than routine transportation.

**2. Seasonal demand strongly influences casual rider activity**
Casual ride volume increases roughly **44×** between the lowest month (February) and the peak month (July), while member activity grows only about **9.7×** over the same period — far less seasonal volatility.

**3. Weekend usage represents a major conversion opportunity**
**41.08%** of casual rides happen on weekends, compared to only **26.39%** of member rides — reinforcing that casual riders are largely recreational users.

---

## Recommendations

1. **Promote membership value through long-ride cost savings** — target casual riders with longer trip durations using in-app messaging about membership savings.
2. **Concentrate membership campaigns during peak summer months (May–August)** — when casual rider engagement and conversion potential are highest.
3. **Develop weekend-focused membership marketing** — geo-targeted promotions near parks, waterfronts, and recreational routes, emphasizing leisure value over commuting.
   
---

## Data Source

Cyclistic trip data is based on Chicago's Divvy bike-share public dataset, used here under Cyclistic's fictional business case as part of the Google Data Analytics Certificate capstone project.
