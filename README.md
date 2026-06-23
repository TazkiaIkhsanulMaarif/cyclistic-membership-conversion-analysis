# [Cyclistic Bike-Share Case Study](https://drive.google.com/file/d/1NGzT_m9FjE2Mxp7oCho6dWnC_3flI47b/view?usp=sharing)

A data analytics case study exploring how annual members and casual riders use Cyclistic bikes differently, with the goal of informing marketing strategies to convert casual riders into annual members.

 **[View Power BI Dashboard](https://app.powerbi.com/reportEmbed?reportId=e4c18ac0-042c-463c-ac3a-6336a0e5ca00&autoAuth=true&ctid=75a8f28a-d996-48b0-8ec0-1b201a5c163e)**
 
 **[View Python Kaggle](https://www.kaggle.com/code/tazkiaikshanul/cyclistic-bike-share-analysis-2021)**

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
CREATE OR REPLACE VIEW cyclistic.tripdata_view AS

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

<img width="909" height="158" alt="image" src="https://github.com/user-attachments/assets/3a4193df-083d-49ad-bed1-9189b59d8f8e" />

The cleaned dataset (`cyclistic.cleaned_data`) excludes rides with implausible durations, ensuring downstream metrics like average ride length are not skewed by faulty records (e.g. maintenance check-outs or data entry errors).

---


### 3. Feature Engineering

Two additional features were created to support deeper behavioral analysis: a weekend/weekday flag, and a time-of-day category.

```sql
-- Weekend Flag
CASE
  WHEN EXTRACT(DAYOFWEEK FROM started_at) IN (1, 7)
  THEN 'Weekend'
  ELSE 'Weekday'
END AS weekend_flag

-- Time Of Day
CASE
  WHEN EXTRACT(HOUR FROM started_at) BETWEEN 5 AND 11 THEN 'Morning'
  WHEN EXTRACT(HOUR FROM started_at) BETWEEN 12 AND 16 THEN 'Afternoon'
  WHEN EXTRACT(HOUR FROM started_at) BETWEEN 17 AND 20 THEN 'Evening'
  ELSE 'Night'
END AS time_of_day
```

**Result:**

<img width="633" height="121" alt="image" src="https://github.com/user-attachments/assets/65051ca4-c13a-41ef-a8ae-728f9ccd7d90" /><img width="617" height="119" alt="image" src="https://github.com/user-attachments/assets/68a4f7e7-f317-44e5-b3eb-1a19ff7aa1c4" /><img width="632" height="122" alt="image" src="https://github.com/user-attachments/assets/e0c74b60-e77a-47c4-8f52-7bc7904267e4" /><img width="298" height="119" alt="image" src="https://github.com/user-attachments/assets/45fd8986-b027-40ea-93aa-0b76e912009f" />

These derived fields made it possible to analyze ride patterns by day type and time of day, both of which turned out to be key differentiators between member and casual riders.

---


### 4. Exploratory Data Analysis

Initial exploration looked at monthly and hourly ride volume, broken down by rider type, to identify visible patterns before deeper comparison.

```sql
SELECT
  FORMAT_DATE('%B', DATE(started_at)) AS month_name,
  member_casual,
  COUNT(*) AS total_rides
FROM cyclistic.cleaned_data
GROUP BY month_name, member_casual
ORDER BY total_rides DESC;
```

**Result:**

<img width="440" height="221" alt="image" src="https://github.com/user-attachments/assets/6303b66b-f709-476d-8929-e559356582d0" />

This stage revealed an early signal of seasonality in casual rider behavior, which was investigated further in the Business Insights stage.

---

### 5. Comparative Analysis

This stage directly compared ride duration, bike type preference, and weekend usage between members and casual riders.

```sql
SELECT
  member_casual,
  ROUND(AVG(ride_length), 2) AS avg_ride_duration
FROM cyclistic.cleaned_data
GROUP BY member_casual;
```

**Result:**

<img width="292" height="62" alt="image" src="https://github.com/user-attachments/assets/85bc3535-d349-4030-aa9b-0cc7e252855b" />

The comparison confirmed a consistent and substantial gap in ride duration between the two groups, forming the basis of Key Insight #1 below.

---

### 6. Business Insights

The final stage quantified the three strongest differentiators between rider types: ride duration, seasonality, and weekend concentration.

```sql
SELECT
  month_name,
  member_casual,
  COUNT(*) AS total_rides
FROM cyclistic.cleaned_data
GROUP BY month_name, member_casual;
```

**Result:**

<img width="439" height="222" alt="image" src="https://github.com/user-attachments/assets/7ee32167-8ced-4f6d-b28a-8bb30c76fe1e" />

These results were translated into the three key insights and three marketing recommendations summarized below.

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

<img width="290" height="61" alt="image" src="https://github.com/user-attachments/assets/e271816d-dab8-45e9-ad94-37086c128f84" />

Casual riders average **26.4 minutes** per ride, compared to just **12.9 minutes** for annual members — over 2× longer. This points to recreational use rather than routine transportation.

---

### 2. Seasonal Demand Strongly Influences Casual Rider Activity

```sql
WITH monthly_rides AS (
  SELECT
    FORMAT_DATE('%B', DATE(started_at)) AS month_name,
    member_casual,
    COUNT(*) AS total_rides
  FROM cyclistic.cleaned_data
  GROUP BY month_name, member_casual
),

ranked_months AS (
  SELECT
    member_casual,
    month_name,
    total_rides,
    RANK() OVER (PARTITION BY member_casual ORDER BY total_rides DESC) AS rank_desc,
    RANK() OVER (PARTITION BY member_casual ORDER BY total_rides ASC) AS rank_asc
  FROM monthly_rides
),

peak_and_low AS (
  SELECT
    member_casual,
    MAX(CASE WHEN rank_desc = 1 THEN month_name END) AS peak_month,
    MAX(CASE WHEN rank_desc = 1 THEN total_rides END) AS peak_month_rides,
    MAX(CASE WHEN rank_asc = 1 THEN month_name END) AS lowest_month,
    MAX(CASE WHEN rank_asc = 1 THEN total_rides END) AS lowest_month_rides
  FROM ranked_months
  GROUP BY member_casual
)

SELECT
  member_casual,
  lowest_month,
  lowest_month_rides,
  peak_month,
  peak_month_rides,
  ROUND(peak_month_rides * 1.0 / lowest_month_rides, 1) AS growth_multiplier
FROM peak_and_low
ORDER BY member_casual;
```

**Result:**

<img width="779" height="58" alt="image" src="https://github.com/user-attachments/assets/06d65315-b687-45eb-aba6-35cfea9e36bd" />

Casual ride volume increases roughly **43.8×** between the lowest month (February) and the peak month (July), while member activity grows only about **9.9×** over the same period — far less seasonal volatility.

---


### 3. Weekend Usage Represents a Major Conversion Opportunity

```sql
SELECT
  member_casual,
  day_type,
  COUNT(*) AS total_rides,
  ROUND(
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY member_casual),
    2
  ) AS percentage
FROM cyclistic.cleaned_data
GROUP BY member_casual, day_type
ORDER BY member_casual, day_type;
```

**Result:**

<img width="440" height="100" alt="image" src="https://github.com/user-attachments/assets/fd4c9144-ac3a-4df6-b14e-99f169a6a08a" />

**41.08%** of casual rides happen on weekends, compared to only **26.39%** of member rides — reinforcing that casual riders are largely recreational users.

---

## Recommendations

1. **Promote membership value through long-ride cost savings** — target casual riders with longer trip durations using in-app messaging about membership savings.
2. **Concentrate membership campaigns during peak summer months (May–August)** — when casual rider engagement and conversion potential are highest.
3. **Develop weekend-focused membership marketing** — geo-targeted promotions near parks, waterfronts, and recreational routes, emphasizing leisure value over commuting.
   
---

## Data Source

[Cyclistic trip data](https://divvy-tripdata.s3.amazonaws.com/index.html) is based on Chicago's Divvy bike-share public dataset, used here under Cyclistic's fictional business case.
