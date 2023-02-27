use clinic;

-- TOTAL REVENUE PER MONTH
SELECT 
    MONTHNAME(a.app_date) AS 'month',
    SUM(t.price) AS total_revenue
FROM
    appointment a
        LEFT JOIN
    treatment t ON t.id = a.treatment_id
GROUP BY 1;

--    
/* Calculating how fully our treatment rooms were used each month by dividing time (in minutes) the rooms were occupied
by total time in minutes the room was available.
 
1. First I get the occupied time by adding the length of treatments each month.
2. Then I divide that number by total number of minutes we were open each month.

I calculate the latter number by using CASE statement to separate days into weekends and weekdays (as opening times are different).
On weekdays, 4 rooms are open 12h a day, which is 720*4 minutes.
On weekends 4 rooms are open 10h a day, which is 600*4 minutes.

Finally, the number is rounded to two decimal points.*/
SELECT 
    MONTHNAME(a.app_date) AS 'month',
    ROUND(SUM(t.length) / 
			CASE
                WHEN WEEKDAY(a.app_date) BETWEEN 0 AND 4 THEN COUNT(DISTINCT a.app_date)*(720*4)
                ELSE COUNT(DISTINCT a.app_date)*(600*4)
            END,
            2) AS perc_busy
FROM
    appointment a
        LEFT JOIN
    treatment t ON a.treatment_id = t.id
GROUP BY
	1
ORDER BY
	MONTH(a.app_date);

-- TOP TREATMENTS (by number of bookings)

SELECT 
    MONTHNAME(a.app_date) AS 'month',
    t.treatment_name,
    COUNT(t.treatment_name) AS cnt
FROM
    appointment a
        LEFT JOIN
    treatment t ON a.treatment_id = t.id
GROUP BY
	1, 2
ORDER BY
	MONTH(a.app_date),
    cnt DESC;
    
-- CLIENT ACQUISITION - how do most clients find us?

SELECT 
    how_discovered,
    COUNT(how_discovered) AS cnt
FROM
    client
GROUP BY
	1
ORDER BY
	cnt DESC;
    
-- REVENUE BY WEEKDAY / AM vs PM

SELECT 
    MONTHNAME(a.app_date) AS 'month',
    DAYNAME(a.app_date) AS 'day',
    CASE
        WHEN a.app_time BETWEEN '9:00:00' AND '15:00:00' THEN 'early'
        ELSE 'late'
    END AS time_of_day,
    SUM(t.price) AS revenue
FROM
    appointment a
        LEFT JOIN
    treatment t ON a.treatment_id = t.id
GROUP BY 
	1, 2, 3;
    
-- THERAPIST POPULARITY

 /* In this query I need to calculate the percentage of time that a therapist spends with a client
 every month. For this, I will need to divide the total treatment time by total shift time.
 
 Due to different levels of detail for aggregation I will need to join two subqueries.*/
 
-- an outer query - calculating the final percentage
SELECT 
    e.emp_name,
    a.month,
    ROUND(a.treatment_time / b.shift_time,
            2) AS perc
FROM
	-- first inner query. Calculating total treatment time
    (SELECT 
        emp_id,
		MONTHNAME(ap.app_date) AS month,
		ROUND(SUM(t.length) / 60, 2) AS treatment_time
    FROM
        appointment ap
			LEFT JOIN 
		treatment t ON ap.treatment_id = t.id
    GROUP BY
		1, 2) a
        LEFT JOIN
	-- Second inner query. Calculating total shift time and joining to previous table.
    (SELECT 
        emp_id,
		MONTHNAME(shift_date) AS 'month',
		SUM(TIMESTAMPDIFF(MINUTE, shift_start, shift_end)) / 60 AS shift_time
    FROM
        shift
    GROUP BY
		1, 2) b 
        ON a.emp_id = b.emp_id
        AND a.month = b.month
        -- final join to get employee name
        JOIN
    employee e ON a.emp_id = e.id;
    
-- NEW AND RETURNING CLIENTS PER THERAPIST

/* In this query I will calculate the percentage of all patients seen each month by each therapist
that are 'returning', i.e. they had seen that therapist before.*/

-- First CTE - get a list of new clients each month.
WITH cte_new AS (
SELECT
    MONTHNAME(app_date) as 'month',
	emp_id,
    COUNT(DISTINCT client_id) as new_clients
FROM
	appointment a
WHERE
	(emp_id, client_id, app_date) IN (
	SELECT
		emp_id,
		client_id,
		min(app_date)
	FROM
		appointment
	GROUP BY
		1, 2)
GROUP BY
	1, 2),

-- Second CTE - total number of unique clients each month        
cte_total AS (
SELECT
    MONTHNAME(app_date) AS 'month',
	emp_id,
    COUNT(DISTINCT client_id) AS total_clients
FROM
	appointment
GROUP BY
	1, 2)

SELECT
	c1.month,
    e.emp_name,
    c1.new_clients,
    c2.total_clients - c1.new_clients AS returning_clients,
    (c2.total_clients - c1.new_clients) / c2.total_clients AS return_rate,
    c2.total_clients
FROM
	cte_new c1 
		JOIN 
	cte_total c2 ON c1.emp_id = c2.emp_id AND c1.month = c2.month
		JOIN 
	employee e ON c1.emp_id = e.id
ORDER BY
	2;
    
-- RETURN CLIENTS PER CLINIC

/* Calculating percentage of clients that have returned to the clinic at least once 
(2 or more visits per year)*/

-- First CTE - selecting clients that have returned at least twice (total visits >=3)
WITH cte_returning AS (
	SELECT count(client_id) AS returning
	FROM appointment
	GROUP BY client_id
	HAVING count(*) > 3),
    
-- Second CTE - count of all unique clients
cte_all AS
	(SELECT COUNT(distinct client_id) AS all_clients
	FROM appointment)

-- dividing count of returning clients by total unique clients
SELECT COUNT(r.returning) / a.all_clients AS return_rate
FROM cte_returning r, cte_all a;

-- How much each therapist EARNED FOR THE CLINC?

SELECT 
    e.emp_name,
    MONTHNAME(a.app_date) AS 'month',
    SUM(t.price) AS total,
    SUM(t.price)*e.payrate AS emp_share,
    SUM(t.price)*(1 - e.payrate) AS clinic_share
FROM
    appointment a
        LEFT JOIN
    treatment t ON a.treatment_id = t.id
        LEFT JOIN
    employee e ON a.emp_id = e.id
GROUP BY 1 , 2;

-- TIME OFF - how much time off does each therapist take? 

/* Here I will calculate percentage of time off by dividing total time off per month by original shift time that month
(regular shifts).*/

  
WITH days_off AS (
SELECT
	emp_id,
    MONTHNAME(off_date) as 'month',
    COUNT(reg_shift) as cnt
FROM
	day_off
WHERE
	reg_shift = 'yes'
GROUP BY
	1, 2)
    
SELECT
	e.emp_name,
    MONTHNAME(s.shift_date) as 'month',
	ROUND(IFNULL(o.cnt, 0) / (COUNT(s.emp_id) + IFNULL(o.cnt, 0)), 2) as off_rate
FROM
	shift s LEFT JOIN days_off o ON s.emp_id = o.emp_id AND MONTHNAME(s.shift_date) = o.month
    LEFT JOIN employee e ON e.id = s.emp_id
GROUP BY
	1, 2
ORDER BY
	1, MONTH(s.shift_date);
    
/* work time vs idle time. Calculating monthly hours per therapist that they spent
with a client vs ilde (no bookings). 
I store the values in separate rows indtead of columns as that will aid my visualisation later on.*/


WITH shift_time AS (
SELECT
	s.emp_id,
    MONTHNAME(s.shift_date) AS 'month',
	SUM(TIMESTAMPDIFF(MINUTE, s.shift_start, s.shift_end)) as shift_time
FROM
	shift s
GROUP BY
	1, 2),

work_time AS (
SELECT
	a.emp_id,
    MONTHNAME(a.app_date) AS 'month',
    SUM(t.length) AS time_worked
FROM
	appointment a LEFT JOIN treatment t ON a.treatment_id = t.id
GROUP BY
	1, 2),
    
idle_time AS (
SELECT
	c1.emp_id,
    c1.month,
    c1.shift_time - c2.time_worked AS idle_time
FROM
	shift_time c1 JOIN work_time c2 ON c1.emp_id = c2.emp_id AND c1.month = c2.month)
    
SELECT
	e.emp_name,
    c3.month,
    round(c3.idle_time/60, 2) AS 'hours',
    'idle time' AS 'type'
FROM
	idle_time c3 JOIN employee e ON c3.emp_id = e.id
UNION ALL
	SELECT
	e.emp_name,
    c2.month,
    round(c2.time_worked/60) as 'hours',
    'time worked' as 'type'
FROM
	work_time c2 JOIN employee e on c2.emp_id = e.id
ORDER BY
	emp_name, month, type;