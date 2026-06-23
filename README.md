# Cyclistic Bike-Share Case Study

A data analytics case study exploring how annual members and casual riders use Cyclistic bikes differently, with the goal of informing marketing strategies to convert casual riders into annual members.

📊 **[View Power BI Dashboard](https://app.powerbi.com/reportEmbed?reportId=e4c18ac0-042c-463c-ac3a-6336a0e5ca00&autoAuth=true&ctid=75a8f28a-d996-48b0-8ec0-1b201a5c163e)**

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
| [`00_data_union.sql`](./SQL/00_data_union.sql) | Data Union | Combines monthly raw trip tables into a single unified view |
| [`01_data_validation.sql`](./SQL/01_data_validation.sql) | Data Validation | Checks for null values and duplicate ride IDs |
| [`02_data_cleaning.sql`](./SQL/02_data_cleaning.sql) | Data Cleaning | Calculates ride length and removes invalid durations |
| [`03_feature_engineering.sql`](./SQL/03_feature_engineering.sql) | Feature Engineering | Creates weekend flag and time-of-day categories |
| [`04_exploratory_analysis.sql`](./SQL/04_exploratory_analysis.sql) | Exploratory Analysis | Monthly and hourly ride trends |
| [`05_comparative_analysis.sql`](./SQL/05_comparative_analysis.sql) | Comparative Analysis | Ride duration, bike type, and weekend usage by rider type |
| [`06_business_insights.sql`](./SQL/06_business_insights.sql) | Business Insights | Seasonality and key differentiator queries |

---


## Process

### 0. Data Union

Twelve monthly raw trip tables (January–December 2021) were combined into a single unified view to enable analysis across the full year.

```sql
SELECT * FROM cyclistic.raw_202101
UNION ALL
SELECT * FROM cyclistic.raw_202102
UNION ALL
SELECT * FROM cyclistic.raw_202103
UNION ALL
SELECT * FROM cyclistic.raw_202104
UNION ALL
SELECT * FROM cyclistic.raw_202105
UNION ALL
SELECT * FROM cyclistic.raw_202106
UNION ALL
SELECT * FROM cyclistic.raw_202107
UNION ALL
SELECT * FROM cyclistic.raw_202108
UNION ALL
SELECT * FROM cyclistic.raw_202109
UNION ALL
SELECT * FROM cyclistic.raw_202110
UNION ALL
SELECT * FROM cyclistic.raw_202111
UNION ALL
SELECT * FROM cyclistic.raw_202112;
```

**Result:**

<img width="884" height="151" alt="image" src="https://github.com/user-attachments/assets/372efa8a-3c26-4f73-8268-6d2e55af5f56" />

All monthly tables were successfully combined into `cyclistic.tripdata_view`, providing a single source for all downstream validation and cleaning steps.

---

### 1. Data Validation

Before cleaning, the unified dataset was checked for total row count, null values, duplicate ride IDs, invalid ride durations, and outliers to assess overall data quality.

```sql
-- Check Total Row Count
SELECT
  COUNT(*) AS total_rows
FROM cyclistic.tripdata_view;
```
**Result:**

<img width="140" height="41" alt="image" src="https://github.com/user-attachments/assets/0a2f2e04-1256-4216-91db-4dd098e658b7" />

This establishes the baseline row count of the combined dataset, used later to measure how many rows are removed during cleaning.

---

**Null Values**

```sql
SELECT
  COUNTIF(ride_id IS NULL) AS null_ride_id,
  COUNTIF(started_at IS NULL) AS null_started_at,
  COUNTIF(ended_at IS NULL) AS null_ended_at,
  COUNTIF(member_casual IS NULL) AS null_member_type
FROM cyclistic.tripdata_view;
```

**Result:**

<img width="418" height="38" alt="image" src="https://github.com/user-attachments/assets/33ab2a20-a7be-44b6-a4e1-9bf537ae2915" />

This step confirmed the extent of missing values across key columns in the raw combined dataset.

---


**Duplicate Ride IDs**

```sql
SELECT
  ride_id,
  COUNT(*) AS duplicate_count
FROM cyclistic.tripdata_view
GROUP BY ride_id
HAVING COUNT(*) > 1;
```

**Result:**

<img width="502" height="103" alt="image" src="https://github.com/user-attachments/assets/8a6b4f4e-e6af-4c12-99f3-8a85207deff0" />

This checks whether the same `ride_id` appears more than once, which could indicate duplicate records introduced during the union of monthly tables.

---


**Invalid Duration**

Since `ride_length` is not yet a stored column at this stage, a CTE is used to calculate it on the fly and flag rides with negative, zero, or unreasonably long durations.

```sql
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
```

**Result:**

<img width="330" height="38" alt="image" src="https://github.com/user-attachments/assets/69fed434-b4ca-49b0-bf95-70e5b46bab8c" />

This identifies rides with implausible durations — such as system maintenance check-outs (zero or negative duration) or bikes left undocked for over 24 hours — which are excluded during cleaning.

---


**Outliers in Ride Duration**

```sql
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
```

**Result:**

<img width="607" height="42" alt="image" src="https://github.com/user-attachments/assets/7946ff77-6109-4002-ad51-ae8cb469aa05" />

Comparing the median against the 95th and 99th percentiles reveals how far the distribution is skewed by extreme ride durations, informing the upper bound threshold used in the cleaning stage.

Together, these checks guided the cleaning rules applied in the next stage.

---

### 2. Data Cleaning

Ride length was calculated from the timestamp difference between `started_at` and `ended_at`, and trips with invalid durations (negative, zero, or longer than 24 hours) were removed.

```sql
CREATE OR REPLACE VIEW cyclistic.cleaned_data AS

SELECT *,
  TIMESTAMP_DIFF(ended_at, started_at, MINUTE) AS ride_length
FROM cyclistic.tripdata_view
WHERE TIMESTAMP_DIFF(ended_at, started_at, MINUTE) > 0
  AND TIMESTAMP_DIFF(ended_at, started_at, MINUTE) <= 1440;
```

**Result:**

![Data cleaning result](./images/02_data_cleaning_result.png)

The cleaned dataset (`cyclistic.cleaned_data`) excludes rides with implausible durations, ensuring downstream metrics like average ride length are not skewed by faulty records (e.g. maintenance check-outs or data entry errors).

---


## Key Insights

### 1. Casual Riders Use Bikes Primarily for Leisure Activities

```sql
SELECT
  member_casual,
  ROUND(AVG(ride_length), 2) AS avg_ride_duration
FROM cyclistic.cleaned_data
GROUP BY member_casual;
```
**Result:**

<img width="507" height="65" alt="image" src="https://github.com/user-attachments/assets/76a08b0b-071c-43d8-b1bc-661c3f2841ce" />

Casual riders average **26.4 minutes** per ride, compared to just **12.9 minutes** for annual members — over 2× longer. This points to recreational use rather than routine transportation.

---

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
