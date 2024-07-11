USE db_datalemur;

-- Q1 -  App Click-through Rate (CTR) [Facebook SQL Interview Question]
-- Write a query to get the app’s click-through rate (CTR %) in 2022. 
-- Output the results in percentages rounded to 2 decimal places.
-- Percentage of click-through rate = 100.0 * Number of clicks / Number of impressions

-- Table: events


SELECT app_id, 
	   ROUND(CAST((100.0 * SUM(CASE WHEN event_type = 'click' THEN 1 END) / 
	   SUM(CASE WHEN event_type = 'impression' THEN 1 END)) AS DECIMAL(5, 2)), 2) AS ctr
FROM events
WHERE DATEPART(YEAR, timestamp) = '2022'
GROUP BY app_id;


--Output:

--app_id	ctr
--123	50.00
--234	100.00 




-- Q2 -  Average Post Hiatus (Part 1) [Facebook SQL Interview Question]
-- Given a table of Facebook posts, for each user who posted at 
-- least twice in 2021, write a query to find the number of days 
-- between each user’s first post of the year and last post of the year in the year 2021. 
-- Output the user and number of the days between each user's first and last post.

-- Tables: posts


-- solution 1 using cte:

WITH users_cte AS
(
SELECT user_id, 
	   COUNT(post_id) AS no_of_posts, 
	   MIN(post_date) AS min_post_date, 
	   MAX(post_date) AS max_post_date 
FROM posts
WHERE DATEPART(YEAR, post_date) = '2021'
GROUP BY user_id
HAVING COUNT(post_id) > 1
)
SELECT user_id, DATEDIFF(DAY, min_post_date, max_post_date) AS days_between
FROM users_cte;


-- Solution 2 using subquery:

SELECT user_id, 
	   DATEDIFF(DAY, min_post_date, max_post_date) AS days_between
FROM
(
SELECT user_id, 
	   COUNT(post_id) AS no_of_posts, 
	   MIN(post_date) AS min_post_date, 
	   MAX(post_date) AS max_post_date 
FROM posts
WHERE DATEPART(YEAR, post_date) = '2021'
GROUP BY user_id
HAVING COUNT(post_id) > 1
) fb_users;


-- Output:

--user_id	days_between
--151652	2
--661093	21




--Q3 -  Average Review Ratings [Amazon SQL Interview Question]

-- Given the reviews table, write a query to get the average stars 
-- for each product every month.
-- The output should include the month in numerical value, 
-- product id, and average star rating rounded to two decimal places. 
-- Sort the output based on month followed by the product id.

-- Table: reviews



SELECT 
    MONTH(submit_date) AS month, 
    product_id, 
    ROUND(CAST(AVG(1.0 * stars) AS DECIMAL(5, 2)), 2) AS avg_star_rating 
FROM reviews
GROUP BY MONTH(submit_date), product_id
ORDER BY month, product_id;


-- Output:

--month	product_id	avg_star_rating
--6	50001	3.50
--6	69852	4.00
--7	69852	2.50




-- Q4 - Cards Issued Difference [JPMorgan Chase SQL Interview Question]

--Your team at JPMorgan Chase is soon launching a new credit card, 
--and to gain some context, you are analyzing how many credit cards
--were issued each month.
--Write a query that outputs the name of each credit card & the 
--difference in issued amount between the month with the most cards issued,
--and the least cards issued. Order the results according to the biggest difference.

--Table: monthly_cards_issued



WITH card_issues AS (
    SELECT 
        card_name, 
        MAX(issued_amount) AS max_issued_amount,
        MIN(issued_amount) AS min_issued_amount
    FROM 
        monthly_cards_issued
    GROUP BY 
        card_name
)
SELECT 
    card_name, 
    max_issued_amount - min_issued_amount AS issued_amount_difference
FROM 
    card_issues
ORDER BY 
    issued_amount_difference DESC;



-- Output:

--card_name	issued_amount_difference
--Chase Freedom Flex	15000
--Chase Sapphire Reserve	10000




-- Q5 -  Cities With Completed Trades [Robinhood SQL Interview Question]
-- You are given the tables below containing information on 
-- Robinhood trades and users. 
-- Write a query to list the top three cities that have the 
-- most completed trade orders in descending order.

-- Tables: trades, users


SELECT u.city, COUNT(*) AS completed_trades FROM trades t
JOIN users u
ON t.user_id = u.user_id
WHERE t.status = 'Completed'
GROUP BY u.city
ORDER BY completed_trades DESC;


-- Output:

--city	completed_trades
--San Francisco	3
--Boston	2
--Denver	1





-- Q6 –   Compressed Mean [Alibaba SQL Interview Question]

--You are trying to find the mean number of items bought per order on Alibaba, 
--rounded to 1 decimal place.
--However, instead of doing analytics on all Alibaba orders, 
--you have access to a summary table, which describes how many items were in
--an order (item_count), and the number of orders that had that many items (order_occurrences).

-- Table: items_per_order


--Calculate the total number of items across all orders.
--Calculate the total number of orders.
--Divide the total number of items by the total number of orders to get the mean.


SELECT 
    ROUND(CAST(SUM(item_count * order_occurrences) * 1.0 
				/ SUM(order_occurrences) AS DECIMAL(5,2)), 1) AS mean_items_per_order
FROM 
    items_per_order;


-- Output:

--mean_items_per_order
--2.70




-- Q7 –   Given a table of candidates and their skills, you want to 
-- find candidates who are proficient in Python, Tableau, and PostgreSQL.

--Write a query to list the candidates who possess all of the required skills for the job. 
--Sort the the output by candidate ID in ascending order.

-- Table: candidates



-- Filter for the required skills: Only include rows where the 
-- skill is one of the three required skills.
-- Group by candidate_id: Group the results by the candidate's ID to aggregate their skills.
-- Count distinct skills: Ensure each candidate has exactly three distinct skills.
-- Sort the results: Order the candidates by their IDs.



SELECT candidate_id
FROM candidates
WHERE skill IN ('Python', 'Tableau', 'PostgreSQL')
GROUP BY candidate_id
HAVING COUNT(DISTINCT skill) = 3
ORDER BY candidate_id;


-- Output:

--candidate_id
--123





-- Q8 – Duplicate Job Listings [Linkedin SQL Interview Question]
--Assume you are given the table below that shows job postings for all companies on the LinkedIn platform. 
--Write a query to get the number of companies that have posted duplicate job listings.
--Duplicate job listings refer to two jobs at the same company with the same title and description.



SELECT COUNT(DISTINCT company_id) AS duplicate_companies
FROM (
    SELECT company_id
    FROM job_listings
    GROUP BY company_id, title, description
    HAVING COUNT(*) > 1
) AS duplicates;



-- Output:

--duplicate_companies
--1





--Q9 - Final Account Balance [PayPal SQL interview question]
--Given a table of bank deposits and withdrawals, return the final balance for each account

-- Table: account


SELECT account_id,
	   COALESCE(SUM(CASE WHEN transaction_type='deposit' THEN amount END), 0) - 
	   COALESCE(SUM(CASE WHEN transaction_type='withdrawal' THEN amount END), 0) AS final_balance
FROM account
GROUP BY account_id;

--  Output:

--account_id	final_balance
--101	25
--201	10




-- Q10 - Laptop vs. Mobile Viewership [New York Times SQL Interview Question] 

--Assume that you are given the table below containing information 
--on viewership by device type (where the three types are laptop,
--tablet, and phone). Define “mobile” as the sum of tablet and phone viewership numbers. 

--Write a query to compare the viewership on laptops versus mobile devices.
--Output the total viewership for laptop and mobile devices in the format 
--of "laptop_views" and "mobile_views".

-- Table: viewership



SELECT SUM(CASE WHEN device_type='laptop' THEN 1 ELSE 0 END) AS laptop_views,
	   SUM(CASE WHEN device_type IN ('tablet', 'phone') THEN 1 ELSE 0 END) AS mobile_views
FROM viewership;


--laptop_views	mobile_views
--2	3




--Q11 – Page With No Likes [Facebook SQL Interview Question]
--Write a query to return the page IDs of all the Facebook pages 
--that don't have any likes. The output should be in ascending order.

-- Tables: pages, page_likes


SELECT p.page_id
FROM pages p
LEFT JOIN page_likes l
ON p.page_id = l.page_id
WHERE l.user_id IS NULL AND
l.page_id IS NULL
ORDER BY p.page_id;


-- Output:

--page_id
--20701





--Q12 – Patient Support Analysis (Part 1) [UnitedHealth SQL Interview Question]
--UnitedHealth has a program called Advocate4Me, which allows members to call 
--an advocate and receive support for their health care needs
-- whether that's behavioural, clinical, well-being, health care financing, 
-- benefits, claims or pharmacy help.

--Write a query to find how many UHG members made 3 or more calls. 
--case_id column uniquely identifies each call made.

-- Table: callers


SELECT COUNT(DISTINCT policy_holder_id) AS member_count
FROM callers
GROUP BY policy_holder_id
HAVING COUNT(case_id) >= 3;


-- Output:

--member_count
--1





--Q13 –  Patient Support Analysis (Part 2) [UnitedHealth SQL Interview Question]
--UnitedHealth Group has a program called Advocate4Me, which allows members to 
-- call an advocate and receive support for their health
--care needs – whether that's behavioural, clinical, well-being, health care 
-- financing, benefits, claims or pharmacy help.

--Calls to the Advocate4Me call centre are categorised, but sometimes they can't fit neatly into a category. 
--These uncategorised calls are labelled “n/a”, or are just empty (when 
--a support agent enters nothing into the category field).

--Write a query to find the percentage of calls that cannot be categorised. 
--Round your answer to 1 decimal place.



SELECT ROUND(CAST(100.0 * SUM(CASE WHEN call_category IS NULL OR call_category = 'n/a' THEN 1 ELSE 0 END) 
			/ COUNT(*) AS DECIMAL(5, 2)), 1) AS call_percentage
FROM callers2;

-- Output:

--call_percentage
--40.00



--Q14 – Second Day Confirmation [TikTok SQL Interview Question]
--Write a query to display the ids of the users who did not confirm on the first day 
--of sign-up, but confirmed on the second day.

-- Table: emails, texts


SELECT e.user_id FROM emails e
LEFT JOIN texts t
ON e.email_id = t.email_id
WHERE DATEADD(DAY, 1, e.signup_date) = t.action_date
AND t.signup_action = 'Confirmed';


-- Output:

--user_id
--1052




-- Q15 – Teams Power Users [Microsoft SQL Interview Question]
--Write a query to find the top 2 power users who sent the 
--most messages on Microsoft Teams in August 2022. 
--Display the IDs of these 2 users along with the total number of messages they sent.

--Output the results in descending count of the messages.

-- Table: messages



SELECT sender_id, COUNT(*) AS total_no_of_messages FROM messages
WHERE DATENAME(MONTH, sent_date) = 'August'
AND DATENAME(YEAR, sent_date) = '2022'
GROUP BY sender_id
ORDER BY total_no_of_messages DESC;


-- Output:

--sender_id	total_no_of_messages
--3601	2
--4500	1







--