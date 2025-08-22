-- Creating helping features for analyisis

--Creating column named hours_stayed using CTE and ALTER UPDATE TABLE
ALTER TABLE fact_visits ADD COLUMN hours_stayed REAL
WITH stay_lenght AS
(SELECT visit_id, (strftime('%s',exit_time ) - strftime('%s', entry_time)) / 3600.0 AS stayed_hours
FROM fact_visits
ORDER BY stayed_hours) 
UPDATE fact_visits
SET hours_stayed = (SELECT ROUND(stayed_hours,2)
										FROM stay_lenght
										WHERE fact_visits.visit_id = stay_lenght.visit_id);
--Updating my column to category short time, medium_time, long_time
UPDATE fact_visits
SET hours_stayed = CASE
		WHEN hours_stayed < 7 THEN "Short Stay"
		WHEN hours_stayed BETWEEN 7 AND 10 THEN "Medium Stay"
		ELSE "Long Stay"
END

--Creating wait_bins 
ALTER TABLE fact_ride_events ADD COLUMN wait_bins TEXT;
UPDATE fact_ride_events
SET wait_bins = CASE
	WHEN wait_minutes <  30 THEN "Short Wait"
	WHEN wait_minutes BETWEEN 30 AND 70 THEN " Medium Wait"
	ELSE "Long Wait"
END
WHERE wait_minutes IS NOT NULL;

-- categorizing visits as basic, standard and premium based on the spendings they generated 
--Range is 0 to 245, and 2nd lowest is 71: so my labels are: Basic<70, no spending at ALL, Standard 71-160 (wide  but balanced middle), premium, > 160 which is approximately 1/3 of the range

ALTER TABLE fact_visits ADD COLUMN visit_segment TEXT;
UPDATE fact_visits
SET visit_segment = CASE
		WHEN spend_cents_clean_dollars < 70 THEN  "Basic"
		WHEN spend_cents_clean_dollars BETWEEN 70 AND 160 THEN "standard"
		ELSE "Premium"
END
WHERE spend_cents_clean_dollars IS NOT NULL -- making sure the null rows not include in premium

-- changing the column name spend_cents_clean_dollars to total_spend_dollars, more readable
ALTER TABLE fact_visits
RENAME COLUMN spend_cents_clean_dollars TO total_spend_dollars;

-- Categorizing the rides based on the ride time in order to find peak hours, morning ride, afternoon_ride, evening_ride
SELECT ride_event_id, ride_time
FROM fact_ride_events
ORDER BY ride_time; -- ride_time range is from 10 to 21, I will break it down into 4 groups
											-- Morning , 10 to 12:59, afternoon, 13 to 16:59, evening, 17 to 20:59, night, above 21
ALTER TABLE fact_ride_events ADD COLUMN ride_frame TEXT;
UPDATE fact_ride_events
SET ride_frame = CASE
    WHEN strftime('%H:%M', ride_time) BETWEEN '10:00' AND '12:59' THEN 'Morning'
    WHEN strftime('%H:%M', ride_time) BETWEEN '13:00' AND '16:59' THEN 'Afternoon'
    WHEN strftime('%H:%M', ride_time) BETWEEN '17:00' AND '20:59' THEN 'Evening'
    ELSE 'Night'
END

--summary of my sql file
-- performed 4 features engineering, creating 4 new columns to help analysis
--1 hours_stayed: duration of the visit :long short or medium
--2 wait_bins: lenght of waiting minutes : long short medium
--3 visit_segment: based on the spending by visits : basic standard and premium
--4 ride_frame: based on the time of the ride: morning afternoon evening or night


--REFLECTIONS:

--1 - Why would the GM or Ops care about stay_minutes?
--		Being aware of the stay minutes is important to GM or OPS because it gives them ideas on customer satisfaction and also help them schedule and organize events.
--		This is crucial to managing waiting time, avoiding overcrowding, and stimulating revenue generation as longer stay_minutes potentially lead to more spending.
--		For example, a long staying time suggest that guest will occupy the attraction for several hours,
--		potentially limiting the number of guest the attraction could receive, based on that information, 
--		they can have appropriate pricings, limiting the number of guests to avoid overcrowding or improve layout and flow in the attraction. This information can also help managing the staff, and it is a good indicator
--		of the overall service provided in the attraction. If the stay time is not proportional to spendings for example, this might suggest that there are delays in the services, such as food prep, or check out.

--2 - Why is spend_per_person useful to Marketing vs. raw spend
--		Spend per person helps flagging the guest who spend more or less in the park. The spend per person is specially useful for marketing because they can launch targeted 
--		operation marketing based on the the spendigs of the specifics guests.
--		raw spend, although usefull doesn't give that level of information.
--		For example, knowing high value individual help marketing design campaign for them by loyalty programs or VIP tickets.
--		One more thing about raw spend is that it doesn't say how many people contributes to the total, depending on the size of the party per 
--		visit, knowing how much each person contributes is valuable to evaluate weather the revenue is more driven by groups of people or individuals.

--3 - How might wait_bucket guide scheduling or staffing?
--		First, understanding in what buckets fall most visitors will alert Ops on how long most guests is waiting to get access to the ride_event.
--		Addiditionnaly, mapping those wait bucket to another metric such as the ride_frame will further inform them of the park peak times. based on these informations they will
--		 allocate more ressources and more staff in order to reduce these delays that can cause guest unsatisfaction.

--4-	Why normalize promotion_code before analysis?
-- 	inititally, the promotion_code column had lots of inconsistencies, although we have two categories of promotion which are SUMMER25, VIPDAY
--		the inconsistencies encountered in their spelling make the analysis harder because each promotion type writen differently is considered individually.
--		