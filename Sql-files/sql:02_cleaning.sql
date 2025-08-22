-- Already have the spend_cents_clean and amount_cents_clean columns in both fact_purchases and fact_visits...

-- creating new colums to convert cents in dollars
ALTER TABLE fact_visits ADD COLUMN spend_cents_clean_dollars INTEGER;
ALTER TABLE fact_purchases ADD COLUMN amount_cents_clean_dollars INTEGER;
-- filling the columns
UPDATE fact_visits
SET spend_cents_clean_dollars = (1.00*spend_cents_clean/100); 
UPDATE fact_purchases
SET amount_cents_clean_dollars = (1.00 * amount_cents_clean/100);

--Handling duplicates
SELECT *, COUNT(ride_event_id) AS count_of_duplicate
FROM fact_ride_events
GROUP BY visit_id,attraction_id,ride_time,wait_minutes,satisfaction_rating,photo_purchase
Having count (ride_event_id) >1
-- 16 duplicates found in fact_ride_events( 8 pairs)

-- Checking my_duplicates
SELECT *
FROM fact_ride_events
WHERE ROWID NOT  IN ( SELECT MIN(ROWID)
																FROM fact_ride_events
																GROUP BY visit_id,attraction_id,ride_time,wait_minutes,satisfaction_rating,photo_purchase)
-- deleting duplicates
DELETE FROM fact_ride_events
WHERE ROWID NOT IN ( SELECT MIN(ROWID)
																FROM fact_ride_events
																GROUP BY visit_id,attraction_id,ride_time,wait_minutes,satisfaction_rating,photo_purchase)
-- Checking if duplicates have been removed
SELECT *, COUNT(ride_event_id) AS count_of_duplicate
FROM fact_ride_events
GROUP BY visit_id,attraction_id,ride_time,wait_minutes,satisfaction_rating,photo_purchase
Having count (ride_event_id) >1 -- 0 duplicates

--C) Keys validation
-- Orphan visits (guest_id not in dim_guest) should be zero
SELECT v.visit_id, v.guest_id
FROM fact_visits v
LEFT JOIN dim_guest g ON g.guest_id = v.guest_id
WHERE g.guest_id IS NULL -- NO ORPHANS
 
-- Orphan visits (ticket_type_id not in dim_ticket) should be zero
SELECT v.visit_id, v.ticket_type_id
FROM fact_visits v
LEFT JOIN dim_ticket t ON v.ticket_type_id = t.ticket_type_id
WHERE t.ticket_type_id IS NULL; -- NO ORPHANS

-- Orphan events ( visit id not in fact_ride_events)
SELECT re.ride_event_id, v.visit_id
FROM fact_ride_events re
LEFT JOIN fact_visits v ON re.visit_id = v.visit_id
WHERE v.visit_id IS NULL;  -- NO ORPHANS

-- Orphan events ( attraction_id not in dim_attraction)
SELECT re.ride_event_id, a.attraction_id
FROM fact_ride_events re
LEFT JOIN dim_attraction a ON a.attraction_id = re.attraction_id
WHERE a.attraction_id IS NULL; -- NO ORPHANS

-- Orphan  visits ( date_id not dim_date)
SELECT v.visit_id, d.date_id
FROM fact_visits v
LEFT JOIN dim_date d ON v.date_id = d.date_id
WHERE d.date_id IS NULL; -- NO ORPHANS

-- Orphan visits ( purchase_id not fact_purchases)
SELECT v.visit_id, p.purchase_id,p.category, p.payment_method
FROM fact_visits v
RIGHT JOIN fact_purchases p ON v.visit_id=p.visit_id
WHERE p.purchase_id IS NULL -- NO ORPHANS

-- D) Handling missing values
-- CLEANING dim attraction
--Normalizing the attraction name in dim attraction
UPDATE dim_attraction
SET attraction_name = LOWER(TRIM(REPLACE(attraction_name,'!',''))); -- all names lower trim space and remove ! char

-- CLEANING dim_guest 
UPDATE dim_guest
SET email = TRIM(email), home_state = TRIM(UPPER(home_state));

-- normalizing the homestate column to NY, CA or FL...
UPDATE dim_guest
SET home_state = CASE
	WHEN home_state =  "NEW YORK" THEN "NY"
	WHEN home_state =  "CALIFORNIA" THEN "CA"
	ELSE home_state
	END;
	-- normalizing the marketing_opt_in column to YES or NO
UPDATE dim_guest
SET marketing_opt_in = CASE
	WHEN  TRIM(LOWER(marketing_opt_in)) LIKE "%Y%" THEN "YES"
	ELSE "NO"
	END
WHERE marketing_opt_in IS NOT NULL;
-- accidently assigned 'NO' to guest id 4 while it was null, reverting changes	
UPDATE dim_guest
SET marketing_opt_in = NULL
WHERE guest_id= 4;

--CLEANING fact_purchases
UPDATE fact_purchases
SET category = TRIM(category), 
		item_name = TRIM(item_name),
		payment_method = TRIM(LOWER(payment_method));

-- Dropping amount cents column as i have a cleanned one
ALTER TABLE fact_purchases
DROP COLUMN amount_cents;

-- Filling missing VALUES: here I calculate the average for each category of purchase
-- And then use that value to impute the missing amount scent, based on the category
WITH normalized AS (
SELECT ROUND(AVG(amount_cents_clean),0) AS mean, category
FROM fact_purchases
GROUP BY category)  -- using a CTE to calculate the average for each category and then use it to impute

UPDATE fact_purchases
SET amount_cents_clean = (SELECT mean
													FROM normalized
													WHERE normalized.category = fact_purchases.category)
WHERE amount_cents_clean IS NULL; -- fill only where the row is null 


-- CLEANING fact_visits
UPDATE fact_visits
SET promotion_code = TRIM(UPPER(promotion_code))

--exploring null spend_dollar
SELECT visit_date, COUNT(*), AVG(spend_cents_clean_dollars)
FROM fact_visits
GROUP BY visit_date
--the first day has 2 visits and they both have missing spending

-- distribution of the missing spending per day
SELECT visit_date, COUNT(*), AVG(spend_cents_clean_dollars)
FROM fact_visits
WHERE spend_cents_clean_dollars IS NULL
GROUP BY visit_date
--the highest count of null spending per day is 3

-- I will use the average spending per visit per day to fill in the missing values
WITH avg_spending_day AS
( SELECT  visit_date, ROUND(AVG(spend_cents_clean_dollars),2) AS average
FROM fact_visits
GROUP BY visit_date)

UPDATE fact_visits
SET spend_cents_clean_dollars = ( SELECT ROUND(average,2)
																	FROM avg_spending_day
																	WHERE fact_visits.visit_date = avg_spending_day.visit_date)
WHERE spend_cents_clean_dollars IS NULL	;	-- filling each row that is null by the average spending of that day



								
