--Q1 – Card Launch Success [JPMorgan Chase SQL Interview Question]
--You are asked to estimate how many cards you'll issue in the first month.
--Write a query that outputs the name of the credit card, and how many cards were issued in its launch month. 
--The launch month is the earliest record in the monthly_cards_issued table for a given card. 
--Order the results starting from the biggest issued amount.

-- Table: monthly_cards_issued


SELECT card_name, issued_amount 
FROM
(
SELECT card_name,
	   issued_amount,
	   DENSE_RANK() OVER(PARTITION BY card_name ORDER BY issue_month) AS rank
FROM monthly_cards_issued
) card_rank
WHERE rank = 1
ORDER BY issued_amount DESC;


-- Output:

--card_name	issued_amount
--Chase Sapphire Reserve	170000
--Chase Freedom Flex	55000




--Q2 – Compressed Mode [Alibaba SQL Interview Question]

--You are trying to find the most common (aka the mode) 
--number of items bought per order on Alibaba.
--However, instead of doing analytics on all Alibaba orders, 
--you have access to a summary table, which describes how many items were in
--an order (item_count), and the number of orders that had that many items (order_occurrences).
--In case of multiple item counts, display the item_counts in ascending order.


-- Table: items_per_order


SELECT item_count FROM
(
SELECT item_count, 
	   RANK() OVER(ORDER BY order_occurrences DESC) AS rank
FROM items_per_order
) ranked_orders
WHERE rank = 1;


-- Output:

--item_count
--2
--4




--Q3 – Fill Missing Client Data [Accenture SQL Interview Question]
--When you log in to your retailer client's database, you notice that their 
--product catalog data is full of gaps in the category column. 
--Can you write a SQL query that returns the product catalog with the missing data filled in?


-- Table: products

WITH category_group AS
(
SELECT *,
	   COUNT(category) OVER(ORDER BY product_id) AS category_group
FROM products
)
SELECT product_id, 
	   CASE WHEN category IS NULL THEN FIRST_VALUE(category) OVER(PARTITION BY category_group ORDER BY product_id)
	   ELSE category END AS category,
	   name
FROM category_group;


-- Output:

--product_id	category	name
--1	Shoes	Sperry Boat Shoe
--2	Shoes	Adidas Stan Smith
--3	Shoes	Vans Authentic
--4	Jeans	Levi 511
--5	Jeans	Wrangler Straight Fit
--6	Shirts	Lacoste Classic Polo
--7	Shirts	Nautica Linen Shirt




--Q4 – Frequently Purchased Pairs [Walmart SQL Interview Question]

--Find the number of unique product combinations that are bought 
--together (purchased in the same transaction).

--For example, if I find two transactions where apples and bananas 
--are bought, & another transaction where bananas and soy milk are bought
--my output would be 2 to represent the 2 unique combinations. 
--Your output should be a single number.

-- Table: transactions


SELECT COUNT(t1.product_id) AS combo_num
FROM transactions t1 
JOIN transactions t2
ON t1.transaction_id = t2.transaction_id 
AND t1.user_id = t2.user_id 
AND t1.product_id < t2.product_id;


-- Output:

--combo_num
--4




--Q5 –  Highest-Grossing Items [Amazon SQL Interview Question]

--Assume you are given the table containing information on Amazon customers 
--and their spending on products in various categories.
--Identify the top two highest-grossing products within each category 
--in 2022. Output the category, product, and total spend.


-- Table: product_spend


SELECT category, product, total_spend
FROM
(
SELECT category,
	   product,
	   SUM(spend) AS total_spend,
	   RANK() OVER(PARTITION BY category ORDER BY SUM(spend) DESC) AS rank
FROM product_spend
WHERE YEAR(transaction_date) = '2022'
GROUP BY category, product
) ranked_products
WHERE rank <= 2;



-- Output:

--category	product	total_spend
--appliance	refrigerator	299.99
--appliance	washing machine	219.8
--electronics	vacuum	341
--electronics	wireless headset	249.9





--Q6 – Histogram of Users and Purchases [Walmart SQL Interview Question]

--Based on a user's most recent transaction date, write a query 
--to obtain the users and the number of products bought.
--Output the user's most recent transaction date, user ID & 
--the number of products sorted by the transaction date in chronological order.

-- Table: user_transactions



WITH user_cte AS
(
SELECT user_id, MAX(transaction_date) AS max_date
FROM user_transactions
GROUP BY user_id
)
SELECT u1.max_date AS most_recent_trans_date, u1.user_id, COUNT(*) AS no_of_products
FROM user_cte u1
JOIN user_transactions u2
ON u1.user_id = u2.user_id AND u1.max_date = u2.transaction_date
GROUP BY u1.user_id, u1.max_date
ORDER BY most_recent_trans_date;


-- Output:

--most_recent_trans_date	user_id	no_of_products
--2022-07-08 12:00:00.000	115	1
--2022-07-08 12:00:00.000	123	2
--2022-07-10 12:00:00.000	159	1






--Q7 – International Call Percentage [Verizon SQL Interview Question]
--A phone call is considered an international call when the person calling 
--is in a different country than the person receiving the call.
--What percentage of phone calls are international? Round the result to 1 decimal.

-- Tables: phone_calls, phone_info

-- solution 1

WITH callers_cte AS
(
SELECT DISTINCT pc.caller_id AS caller, 
	   pi.country_id AS caller_country
FROM phone_calls pc
JOIN phone_info pi
ON pc.caller_id = pi.caller_id
)
, receivers_cte AS (
SELECT DISTINCT pc.receiver_id AS receiver, 
	   pi.country_id AS receiver_country
FROM phone_calls pc
JOIN phone_info pi
ON pc.receiver_id = pi.caller_id
)
SELECT ROUND(CAST(100.0 * SUM(CASE WHEN caller_country != receiver_country THEN 1 ELSE 0 END) 
	   / COUNT(*) AS DECIMAL(5,2)), 1) AS intl_calls_pct
FROM phone_calls pc
JOIN callers_cte cc
ON pc.caller_id = cc.caller
JOIN receivers_cte rc
ON pc.receiver_id = rc.receiver;
 


-- solution 2

SELECT 
	  ROUND(
        CAST(100.0 * SUM(CASE WHEN caller_info.country_id != receiver_info.country_id THEN 1 ELSE 0 END)
        / COUNT(*) AS DECIMAL(5,2)), 1
    ) AS international_calls_pct
FROM 
    phone_calls
JOIN 
    phone_info AS caller_info 
ON phone_calls.caller_id = caller_info.caller_id
JOIN 
    phone_info AS receiver_info 
ON phone_calls.receiver_id = receiver_info.caller_id;


-- Output:

-- international_calls_pct
-- 50.00




--Q8 – Mean, Median, Mode [Microsoft SQL Interview Question]
--Output the mean, median and mode (in this order). 
--Round the mean to the the closest integer and assume that there are no ties for mode.

-- Table: inbox_stats



-- Solution 1:

WITH mode_val AS(
 SELECT email_count AS mode,
 DENSE_RANK() OVER(ORDER BY COUNT(user_id) DESC) AS rk
 FROM inbox_stats
 GROUP BY email_count
)
, mean_val AS(
 SELECT DISTINCT ROUND(AVG(email_count) OVER(), 1) AS mean, 1 AS counter
 FROM inbox_stats
)

, median_val AS(
 SELECT email_count,
 COUNT(user_id) OVER() AS cnt,
 ROW_NUMBER() OVER(ORDER BY email_count) AS rw
 FROM inbox_stats
)
, med AS(
 SELECT ROUND(AVG(email_count), 1) AS median, 1 AS counter
 FROM median_val
 WHERE rw BETWEEN cnt/2 AND (cnt/2)+1
)
SELECT mean, median, mode
FROM mean_val JOIN med
ON mean_val.counter = med.counter
JOIN mode_val
ON mean_val.counter = mode_val.rk;




-- Solution 2:


-- Step 1: Create a CTE to select all email counts from the inbox_stats table
WITH stats AS (
    SELECT email_count
    FROM inbox_stats
),

-- Step 2: Calculate the mean (average) email count and round it to the nearest integer
mean AS (
    SELECT ROUND(AVG(email_count), 0) AS mean_value
    FROM stats
),

-- Step 3: Calculate the median email count
median AS (
    -- Calculate row numbers and total count to determine the median
    SELECT AVG(email_count) AS median_value
    FROM (
        SELECT email_count,
               ROW_NUMBER() OVER (ORDER BY email_count) AS row_num,
               COUNT(*) OVER () AS total_count
        FROM stats
    ) sub
    -- Select the middle value(s) depending on whether the total count is odd or even
    WHERE row_num IN (
        (total_count + 1) / 2,  -- Handles odd number of rows
        (total_count + 2) / 2   -- Handles even number of rows
    )
),

-- Step 4: Calculate the mode (most frequent) email count
mode AS (
    -- Group by email_count and order by frequency in descending order, selecting the top 1
    SELECT TOP 1 email_count AS mode_value
    FROM stats
    GROUP BY email_count
    ORDER BY COUNT(*) DESC
)
-- Step 5: Select and output the mean, median, and mode values
SELECT mean.mean_value AS mean,
       median.median_value AS median,
       mode.mode_value AS mode
FROM mean, median, mode;



-- Output:

--mean	median	mode
--200	200	200




--Q9 – Odd and Even Measurements [Google SQL Interview Question]
--Write a query to obtain the sum of the odd-numbered and even-numbered 
--measurements on a particular day, in two different columns.

--Refer to the Example Output below for the output format.

--1st, 3rd, and 5th measurements taken within a day are considered odd-numbered 
--measurements and the 2nd, 4th, and 6th measurements are
--even-numbered measurements.

-- Table: measurements



-- Explanation:
-- use The CAST function to convert a datetime to a date, which will remove the time part.
-- Partition the ROW_NUMBER() windows function by the measurement_day to get the even and
-- odd numbered measurements for each day

SELECT measurement_day,
	   SUM(CASE WHEN row_num % 2 != 0 THEN measurement_value END) AS odd_sum,
	   SUM(CASE WHEN row_num % 2 = 0 THEN measurement_value END) AS even_sum
FROM
(SELECT *, CAST(measurement_time AS DATE) AS measurement_day, 
		   ROW_NUMBER() OVER(PARTITION BY CAST(measurement_time AS DATE) ORDER BY measurement_time) AS row_num 
		   FROM measurements) measurement_rank
GROUP BY measurement_day;


-- Output:

--measurement_day	odd_sum	even_sum
--2022-07-10	2355.75	1662.74
--2022-07-11	1124.5	1234.14




--Q10 – Sending vs. Opening Snaps [Snapchat SQL Interview Question]
--Assume you are given the tables below containing information on Snapchat users, 
--ages, and their time spent sending and opening snaps.
--Write a query to obtain a breakdown of the time spent sending vs. opening snaps for each age group.
--Output the age bucket and percentage of sending and opening snaps. Round the percentage to 2 decimal places.

--You should calculate these percentages:
--time sending / (time sending + time opening)
--time opening / (time sending + time opening)



SELECT ab.age_bucket,
	   ROUND(CAST(100.0 * SUM(CASE WHEN a.activity_type = 'send' THEN a.time_spent END)
						/ SUM(a.time_spent) AS DECIMAL(5,2)), 2) AS sending_pct,
	   ROUND(CAST(100.0 * SUM(CASE WHEN a.activity_type = 'open' THEN a.time_spent END) 
						/ SUM(a.time_spent) AS DECIMAL(5,2)), 2) AS open_pct
FROM activities a
JOIN age_breakdown ab
ON a.user_id = ab.user_id
WHERE a.activity_type IN ('open', 'send')
GROUP BY ab.age_bucket;



-- Output:

--age_bucket	sending_pct	open_pct
--26-30	65.40	34.60
--31-35	43.75	56.25





--Q11 – Signup Activation Rate [TikTok SQL Interview Question]
--New TikTok users sign up with their emails. They confirmed their signup by replying 
--to the text confirmation to activate their accounts.
--Users may receive multiple text messages for account confirmation until they have confirmed their new account.
--Write a query to find the activation rate of the users. Round the percentage to 2 decimal places.

-- Table: tt_emails, tt_texts


-- Calculate the confirmation rate by comparing the number of confirmed signups to the total number of signups
-- Round the final result to 2 decimal places for the confirmation rate
-- Subquery to get the total count of distinct email IDs
-- Join with tt_texts table to get only confirmed actions
-- Filter for rows where the signup action is 'Confirmed'

SELECT 
    ROUND(CAST(100.0 * COUNT(e.email_id) / 
            (SELECT COUNT(DISTINCT email_id) FROM tt_emails) 
        AS DECIMAL(5,2)), 2) AS confirm_rate
FROM 
    tt_emails e 
    JOIN tt_texts t
    ON e.email_id = t.email_id 
    AND t.signup_action = 'Confirmed';



-- Output:

--confirm_rate
--66.67




--Q12 – Spotify Streaming History [Spotify SQL Interview Question]

--Write a query to output the user id, song id, and cumulative count of song plays 
--as of 4 August 2022 sorted in descending order.
--song_weekly table currently holds data from 1 August 2022 to 7 August 2022.
--songs_history table currently holds data up to to 31 July 2022. 
--The output should include the historical data in this table.

-- Tables: songs_history, songs_weekly


WITH songs_cte AS (
 SELECT user_id, song_id, COUNT(listen_time) AS song_plays
 FROM songs_weekly
 WHERE listen_time < '2022/08/05'
 GROUP BY user_id, song_id
 
 UNION ALL
 SELECT user_id, song_id, song_plays
 FROM songs_history
)
SELECT user_id, song_id, SUM(song_plays) AS song_plays
FROM songs_cte
GROUP BY user_id, song_id
ORDER BY song_plays DESC;


-- Output:

--user_id	song_id	song_plays
--777	1238	12
--695	4520	2
--125	9630	1





-- --Q13 – Supercloud Customer [Microsoft SQL Interview Question]
--A Microsoft Azure Supercloud customer is a company which buys at least 1 product from each product category.
--Write a query to report the company ID which is a Supercloud customer.

-- Table: customer_contracts, azure_products



SELECT customer_id
FROM customer_contracts cc
JOIN azure_products ap
ON cc.product_id = ap.product_id
GROUP BY customer_id
HAVING COUNT(DISTINCT(product_category)) = (SELECT COUNT(DISTINCT product_category) FROM azure_products);


-- Output:

--customer_id
--1





--Q14 – Top 5 Artists [Spotify SQL Interview Question] 
--Write a query to determine the top 5 artists whose songs appear in the 
--Top 10 of the global_song_rank table the highest number of times.
--Output the top 5 artist names in ascending order along with their song 
--appearances ranking (not the number of song appearances, 
--but the rank of who has the most appearances). The order of the rank should take precedence.

-- Tables: artists, songs, global_song_rank


WITH cte AS (
 SELECT artists.artist_name,
 DENSE_RANK() OVER(ORDER BY COUNT(global_song_rank.song_id) DESC) AS artist_rank
 FROM songs 
 JOIN artists
 ON songs.artist_id = artists.artist_id
 JOIN global_song_rank
 ON songs.song_id = global_song_rank.song_id AND global_song_rank.rank < 11
 GROUP BY artists.artist_name
)
SELECT artist_name, artist_rank
FROM cte 
WHERE artist_rank < 6;


-- Output:

--artist_name	artist_rank
--Ed Sheeran	1
--Drake	2




-- Q15 – Tweets' Rolling Averages [Twitter SQL Interview Question]
--The table below contains information about tweets over a given period of time. 
--Calculate the 3-day rolling average of tweets published by each user for each date that a tweet was posted. 
--Output the user id, tweet date, and rolling averages rounded to 2 decimal places.

-- Table: tweets

-- user_id, tweet_date, rolling_avg


WITH cte AS (
 SELECT user_id, tweet_date, COUNT(tweet_id) AS cnt
 FROM tweets
 GROUP BY user_id, tweet_date
)
SELECT user_id,	tweet_date,
ROUND(CAST(AVG(1.0 * cnt) OVER(PARTITION BY user_id ORDER BY tweet_date 
		ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS DECIMAL(5,2)),2) AS rolling_avg_3days
FROM cte;


-- Output:

--user_id	tweet_date	rolling_avg_3days
--111	2022-06-01 12:00:00.000	2.00
--111	2022-06-02 12:00:00.000	1.50
--111	2022-06-04 12:00:00.000	1.33
--254	2022-06-02 12:00:00.000	1.00





--Q16 – User's Third Transaction [Uber SQL Interview Question]
--Write a query to obtain the third transaction of every user. Output the user id, spend and transaction date.

-- Table: uber_transactions


WITH cte AS(
 SELECT *,
 DENSE_RANK() OVER(PARTITION BY user_id ORDER BY transaction_date) AS rk
 FROM uber_transactions
)
SELECT user_id,	spend,	transaction_date
FROM cte 
WHERE rk=3;


-- Output:

--user_id	spend	transaction_date
--111	89.60	2022-02-05 12:00:00.000







--
