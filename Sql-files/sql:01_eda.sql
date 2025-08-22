-- Q1. Date range of visit_date; number of distinct dates; visits per date

SELECT MIN(visit_date), MAX(visit_date)
FROM fact_visits ;
-- the data range of visit_date is : 2025/07/01 - 2025/07/08

SELECT COUNT(DISTINCT(visit_date))
FROM fact_visits -- 8 distincts dates;

SELECT COUNT(*), visit_date
FROM fact_visits
GROUP BY visit_date; --2025/07/07 is the day with the highest number of visits

-- Q2. Visits by ticket_type_name (join to dim_ticket), ordered by most to least.
SELECT t.ticket_type_name
,COUNT(v.visit_id) AS number_of_visits, v.ticket_type_id
FROM fact_visits v
LEFT JOIN dim_ticket t ON v.ticket_type_id=t.ticket_type_id
GROUP BY t.ticket_type_name
ORDER BY number_of_visits DESC; -- The day_pass_ticket record more visits with 22, followed by VIP with 18, the family peak records only 8

-- Q3. Distribution of wait_minutes (include NULL count separately).
SELECT t.ticket_type_name
,COUNT(v.visit_id) AS number_of_visits, v.ticket_type_id
,ROUND(AVG(re.wait_minutes),2) AS average_wait_minutes
,COUNT(re.wait_minutes) AS count_of_wait_time
FROM fact_visits v
LEFT JOIN dim_ticket t ON v.ticket_type_id=t.ticket_type_id
LEFT JOIN fact_ride_events re ON  v.visit_id= re.visit_id
--WHERE re.wait_minutes IS NOT NULL
GROUP BY t.ticket_type_name
ORDER BY number_of_visits DESC;

-- Now looking for the null distributions per type of ticket. (ticket_type_name)
SELECT COUNT(*) AS number_of_null, v.visit_id, t.ticket_type_name
FROM fact_ride_events re
JOIN fact_visits v ON re.visit_id = v.visit_id
JOIN dim_ticket t ON v.ticket_type_id = t.ticket_type_id
WHERE wait_minutes IS NULL
GROUP  BY t.ticket_type_name
ORDER BY number_of_null DESC;
-- 72 null values in the wait_minutes column inside fact_ride_events table, 9 for family_peak,30 for VIP and 33 for Day pass
-- NULL might suggest that there was no waiting time

-- Q4. Average satisfaction_rating by attraction_name and by category

SELECT  a.attraction_name, a.category
,ROUND(AVG(re.satisfaction_rating),2) AS average_satisfaction_rating
FROM fact_ride_events re
LEFT JOIN dim_attraction a ON re.attraction_id = a.attraction_id
GROUP BY a.category, a.attraction_name;
-- the average satisfactiion_rating for all attractions is below 4.

--Q5. Duplicates check: exact duplicate fact_ride_events rows (match on all
--columns) with counts
SELECT *, COUNT(ride_event_id) AS count_of_duplicate
FROM fact_ride_events
GROUP BY visit_id,attraction_id,ride_time,wait_minutes,satisfaction_rating,photo_purchase
Having count (ride_event_id) >1
-- 16 duplicates found

--Q6. Null audit for key columns you care about (report counts)

SELECT COUNT(*) AS number_of_null_values
FROM fact_visits
WHERE spend_cents_clean IS NULL -- 10 nulls in spend_cents_clean


--Q7. Average party_size by day of week (dim_date.day_name)
SELECT d.day_name, AVG(v.party_size) AS average_party_size
FROM dim_date d
LEFT JOIN fact_visits v ON d.date_id = v.date_id
GROUP BY d.day_name
ORDER BY average_party_size

-- Additionnal explorations

-- number of visits by attraction_name
SELECT a.attraction_name, COUNT(v.visit_id) AS count_of_visits,  re.attraction_id
FROM dim_attraction a
LEFT JOIN fact_ride_events re ON a.attraction_id = re.attraction_id
LEFT JOIN fact_visits v ON re.visit_id = v.visit_id
GROUP BY a.attraction_name
ORDER BY count_of_visits DESC;
--pirate splash and tiny trucks lead the ranking with respectively 34 and 25 visits

-- spend by category of purchase (merch_food)
SELECT category, SUM(amount_cents_clean) as total_amount_cents
FROM fact_purchases
GROUP BY category
ORDER BY total_amount_cents DESC; --- Food generate more revenue than Merch  with 89901 cents vs 70426

--Average spending by party_size

SELECT v.party_size, avg(total_spend_dollars)
FROM dim_date d
LEFT JOIN fact_visits v ON d.date_id = v.date_id 
GROUP BY v.party_size
ORDER BY v.party_size
-- guest tend to spend more when they visited alone or in a paired group.
-- This is probably because th ticket type bought by larger group, maybe the family pack, cover some expenses that they won't need to buy once in park.





