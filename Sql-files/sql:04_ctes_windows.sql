--1 Daily performance
CREATE VIEW daily_performance AS
WITH visit_performance AS 
(SELECT d.date_iso AS dates,d.date_id, d.is_weekend
					,v.visit_id AS visits, v.guest_id, v.party_size, v.total_spend_dollars AS visit_spend
FROM dim_date d
LEFT JOIN fact_visits v ON d.date_id = v.date_id),

		daily_performance AS
(SELECT dates,is_weekend, COUNT(visits) as daily_visits, ROUND(SUM(visit_spend),2) AS daily_spend
FROM visit_performance
GROUP BY dates)
		
SELECT dates,is_weekend, daily_visits, daily_spend, ROUND(daily_spend/daily_visits,2) AS spend_per_visit
, SUM(daily_spend) OVER ( ORDER BY dates) AS running_total
FROM daily_performance;



-- INTERPRETATION : in this summer season, the opening day recorded only two guests, and we don't have any data related to their spendings.
-- 	based on our observation, daily_visits is proportionnal to daily_spend, therefore even without data, we could assume that the first day was the less productive giving
-- 	its low vist_counts.
-- 	The busiest and most high_spending day was 2025-07-07 with 1138 dollars for 10 visits. However in terms of productivity, the second and third busiest days with respectively
--		7 and 6 have almost the same revenues. so the productivity column spend_per_visit help highlighting this pattern. This suggest that fewer visits can still generate more revenues
--		if staff are more effective, so quality over quantity. 2025-07-07 having 10 visits but lower spend per visit among the top 3 peak days suggest that staff was overloaded, less effective or the visitors were more price sensitive guest who spend less in park
-- 	confirming the early campaign data suggestion.


--2 RFM & CLV:
--CLV_revenue_proxy =SUM(spend_cents_clean) per guest.
CREATE VIEW guest_df AS
WITH RFM AS
(SELECT
 g.guest_id, g.first_name, g.home_state, g.marketing_opt_in
,v.visit_id, COUNT(v.visit_id) AS count_of_visits_F
,CAST(julianday('NOW') - julianday(MAX(strftime('%Y-%m-%d', d.date_iso))) AS INTEGER) AS days_since_last_visit_R 
,ROUND(SUM(v.total_spend_dollars),2) AS CLV_revenue_proxy_M
,AVG(v.total_spend_dollars) Average_spending
FROM dim_guest g
LEFT JOIN fact_visits v ON g.guest_id = v.guest_id
LEFT JOIN dim_date d ON v.date_id = d.date_id
GROUP BY g.guest_id)

SELECT * 
, RANK() OVER ( PARTITION BY home_state ORDER BY CLV_revenue_proxy_M DESC) AS ranking
, SUM(CLV_revenue_proxy_M) OVER (PARTITION BY home_state) AS home_state_revenue
FROM RFM

--INTERPRETATION: note: from today ( 2025/08/20) the latest guest_visit is 44 days aago
-- the top 2 home_state based on the revenues generated are:
 --	1- California, 2- New York, and the bottom 1 is TX with only 14% of the total revenue
-- the highest valued guest is Ivy, guest_id 9  with 8 visits and $1030 revenue wich represent 18% of the total revenue, higher than entire TX or FL states.
-- In the top 3 highest valued customers, Only the third one Ava from New York is subject to marketing_opt_in. Questionning the marketing efficiency.
-- Guest's Recency shows that from the last date data have been collected, all guests visited the first or second latest day. since the latest date in the data is 2025-07-08,
-- all customers have either visited that day, or the day before... suggesting good Recency
-- Each guest has visited at least 3 times during the observed period 8 days.

--3 Behavior change

CREATE VIEW behaviour_change AS
WITH behaviour_change1 AS -- CTE 1
(
SELECT v.visit_id
,g.guest_id, g.first_name
,v.party_size
,v.ticket_type_id
,t.ticket_type_name
,d.date_iso
,v.total_spend_dollars
,v.hours_stayed
FROM dim_guest g
LEFT JOIN fact_visits v ON g.guest_id = v.guest_id
LEFT JOIN dim_date d ON v.date_id = d.date_id
LEFT JOIN dim_ticket t ON v.ticket_type_id = t.ticket_type_id
GROUP BY v.visit_id
),

behaviour_change AS --CTE2
(
SELECT *
, LAG(total_spend_dollars,1,0) OVER (PARTITION BY guest_id ORDER BY date_iso) AS lag_spend
FROM behaviour_change1
)


SELECT *
,total_spend_dollars - lag_spend AS delta
FROM behaviour_change;

-- INTERPRETATION 
 -- based on guest's spending over their visits, we can classify them in 3 category
 -- 1- High_value stable such as Ben who spend consistently for any one of his visits
 --2- High_potential volatile like Ava despite spending a lot on some visits, didn't spent on anything for some.
 --3 -Low value such as grace who account for 5 visits one of the highest, spent on only 2 of them
 -- The average total_spend is 123, 46% of the total_spend per visit is above average, therefore there is a fair spending distribution accross visits. If average is taken as reference, 
 -- we can't say that most visits is low spending or high spending, mentionning that 2 of the visits do not have values.
 -- The total count of visits is 45, 23 from visits with party_size>2. however, most of the total_spend 3000+ / 5200 come from the visits with party size <= 2. 
 -- Conlusion guest tend to spend more with small party_size
 
 
WITH ticket_switching_1 AS (
    SELECT 
        v.visit_id,
        g.guest_id,
        g.first_name,
        v.ticket_type_id,
        t.ticket_type_name,
        d.date_iso,
        v.total_spend_dollars
    FROM dim_guest g
    LEFT JOIN fact_visits v ON g.guest_id = v.guest_id
    LEFT JOIN dim_date d ON v.date_id = d.date_id
    LEFT JOIN dim_ticket t ON v.ticket_type_id = t.ticket_type_id
),

ticket_switching AS (
    SELECT 
        *,
        FIRST_VALUE(ticket_type_name) OVER (
            PARTITION BY guest_id 
            ORDER BY date_iso
        ) AS first_guest_ticket,
        LAST_VALUE(ticket_type_name) OVER (
            PARTITION BY guest_id 
            ORDER BY date_iso 
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS last_guest_ticket
    FROM ticket_switching_1
)
SELECT *
FROM ticket_switching;

--REFLECTION 
-- Each person updated at least once their ticket. Even though some of them went back to their first_ticket, none of them went back to a less valued ticket compared 
--	to their first one. For example, if Ben's first_ticket is VIP, his last ticket is rather VIP or Family Pack, never Day_pass.
-- 

