# Theme_park_analytics by Thierno Barry

## Business Problem
Over the past two quarters, Supernova Theme Park has seen uneven guest satisfaction scores and fluctuating revenue. Guest experience data collected during the summer season reveals recurring issues: long and inconsistent wait times, ride availability challenges, and overcrowding during peak hours — all of which reduce guest satisfaction.

At the same time, there are open questions around guest behavior: how frequently they visit, how recently, and what drives their in-park spending. The Park General Manager and the Marketing team need clear patterns to guide decisions — such as which ticket types, party sizes, purchase categories, ride times, or attraction states most strongly influence guest spending and satisfaction.

Given all the issues listed above and stakeholders' preoccupation, the central question becomes:
❓ How do operational efficiency and ticketing strategies work together to shape guest satisfaction, guest value, and ultimately park revenue?

## Stakeholders

Primary Stakeholder:
Park General Manager (GM)

Supporting Stakeholders:
Operations Director (staffing & queues), Marketing Director (promos & ticket mix)

## Overview of Database & Schema 
### Star Schema Explanation
This database uses a **star schema** design, with central **fact tables** (`fact_visits`, `fact_ride_events`, `fact_purchases`) linked to **dimension tables** (`dim_guest`, `dim_ticket`, `dim_attraction`) via foreign keys.  

**Benefits of this schema:**  
- Simplifies analytics by separating **measures** (spend, revenue, wait times) from **descriptors** (guest details, ticket type, attraction info).  
- Improves performance for queries and aggregations.  
- Easy to extend by adding new dimensions.  
- Business-friendly structure for answering questions such as revenue by ticket type, guest demographics, or attraction satisfaction.  

### Tables Overview
<img width="943" height="712" alt="Screenshot 2025-08-21 at 12 49 47 PM" src="https://github.com/user-attachments/assets/7d91ff07-d9b0-4007-8bc5-b9b3595f50d3" />

## Exploratory Data Analysis (SQL)

### Key Explorations
1. distribution of the waiting minutes across ticket type – short description and why it was done **hypothesis, waiting time corelation ticket type, leading unsatisfaction**
2. Daily visits and daily spending – short description and why it was done **overall performance for each day pointing Ops**
3. EDA Guest_behaviour( spending by category or purchasea and by party size) – short description and why it was done  **helping marketing understanding guest spending for example to drive their decisions going forward**

> SQL queries can be linked: [/sql/01_eda.sql](sql/01_eda.sql)

## Feature Engineering (SQL)

### Created Features & Rationale
<!-- List features created in SQL and short reasoning behind each -->
1. **hours_stayed:** duration of the visit :long short or medium
2. **wait_bins:** lenght of waiting minutes : long short medium
3. **visit_segment:** based on the spending by visits : basic standard and premium
4. **ride_frame:** based on the time of the ride: morning afternoon evening or night

# CTEs & Window Functions (SQL)

## Key Queries & Snippets
<!-- Include short snippets of key CTE or window function queries -->
> Full queries: [/sql/02_cte_window.sql](sql/02_cte_window.sql)

# Visuals (Python)

## Figure 1
![Figure 1](figures/figure1.png)  
*Caption for Figure 1*

## Figure 2
![Figure 2](figures/figure2.png)  
*Caption for Figure 2*

## Figure 3
![Figure 3](figures/figure3.png)  
*Caption for Figure 3*

# Insights & Recommendations

## For GM
<!-- Recommendations for General Management -->

## For Operations
<!-- Recommendations for Operations -->

## For Marketing
<!-- Recommendations for Marketing -->

# Ethics & Bias
<!-- Data quality, missing values, duplicates, margin not modeled, time window, etc. -->

# Repo Navigation

## /sql
<!-- SQL scripts -->

## /notebooks
<!-- Jupyter notebooks -->

## /figures
<!-- Saved figures/images -->

## /data
<!-- Raw or processed datasets -->
