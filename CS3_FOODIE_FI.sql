/*

A. Customer Journey

Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.

Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!

customer_id | description

01 | Began free trial and downgraded to a basic plan during trial period
02 | Began free trial and upgraded to a pro annual plan during trial period
11 | Began free trial and cancelled during trial period
13 | Began free trial and downgraded to a basic plan during trial period. Later upgraded to pro monthly plan 
15 | Began free trial and upgraded to a pro monthly plan during trial period. Cancelled plan after a month
16 | Began free trial and downgraded to a basic plan during trial period. Later upgraded to pro annual plan
18 | Began free trial and upgraded to a pro monthly plan during trial period
19 | Began free trial and upgraded to a pro monthly plan during trial period. Later upgraded to pro annual plan

*/

select 
  s.*, 
  p.plan_name 
from 
  subscriptions s 
  left join plans p on p.plan_id = s.plan_id 
where 
  customer_id in (1, 2, 11, 13, 15, 16, 18, 19);

--1. Q) How many custoemrs has Foodie-Fi ever had? A) 1000

select
    count (distinct customer_id) as total_customers
from
    subscriptions;

--2. Q) What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value.

select
    monthname(start_date) as month,
    count(*) as trial_plans
from
    subscriptions
where
    plan_id = 0
group by month;

--3. Q) What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name.

select
    p.plan_name,
    count(s.*) as "Plans after 2020"
from
    subscriptions s
    left join plans p on p.plan_id = s.plan_id
where
    start_date >= '2021-01-01'
group by p.plan_name;

--4. Q) What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

select
    count(distinct customer_id) as churned_customers,
    (select count(distinct customer_id) from subscriptions) as total_customers,
    round(churned_customers / total_customers, 1) as churn_rate
from
    subscriptions
where
    plan_id = 4;

--5. Q) How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

with cte as (
  select 
    customer_id, 
    plan_name, 
    row_number() over (
      partition by customer_id 
      order by 
        start_date asc
    ) as rn 
  from 
    subscriptions s 
    inner join plans p on p.plan_id = s.plan_id
) 
select 
  count(distinct customer_id) as churned_trial_customers, 
  ROUND(
    (
      COUNT(DISTINCT customer_id) / (
        SELECT 
          COUNT(DISTINCT customer_id) 
        FROM 
          subscriptions
      )
    )* 100, 
    0
  ) as percent_churn_after_trial 
FROM 
  CTE 
WHERE 
  rn = 2 
  AND plan_name = 'churn';


--6. Q) What is the number and percentage of customer plans after their initial free trial?

with cte as (
  select 
    customer_id, 
    plan_name, 
    row_number() over (
      partition by customer_id 
      order by 
        start_date asc
    ) as rn 
  from 
    subscriptions s 
    inner join plans p on p.plan_id = s.plan_id
) 
select 
  plan_name, 
  count(customer_id) as customer_count, 
  ROUND(
    (
      COUNT(customer_id) / (
        SELECT 
          COUNT(DISTINCT customer_id) 
        FROM 
          CTE
      )
    )* 100, 
    1
  ) as customer_percent 
FROM 
  CTE 
WHERE 
  rn = 2 
GROUP BY 
  plan_name;

--7. Q) What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

WITH CTE AS (
  SELECT 
    *, 
    ROW_NUMBER() OVER(
      PARTITION BY customer_id 
      ORDER BY 
        start_date DESC
    ) as rn 
  FROM 
    subscriptions 
  WHERE 
    start_date <= '2020-12-31'
) 
SELECT 
  plan_name, 
  COUNT(customer_id) as customer_count, 
  ROUND(
    (
      COUNT(customer_id)/(
        SELECT 
          COUNT(DISTINCT customer_id) 
        FROM 
          CTE
      )
    )* 100, 
    1
  ) as percent_of_customers 
FROM 
  CTE 
  INNER JOIN plans as P on CTE.plan_id = P.plan_id 
WHERE 
  rn = 1 
GROUP BY 
  plan_name;

--8. Q) How many customers upgraded to an annual plan in 2020?

select 
  count(customer_id) 
from 
  subscriptions 
where 
  plan_id = 3 
  and year(start_date) = 2020;

--9. Q) How many days on average does it take for a customer to upgrade to an annual plan from the day they join Foodie-Fi?

with trial as (
  select 
    customer_id, 
    start_date as trial_start 
  from 
    subscriptions 
  where 
    plan_id = 0
), 
annual as (
  select 
    customer_id, 
    start_date as annual_start 
  from 
    subscriptions 
  where 
    plan_id = 3
) 
select 
  round(
    avg(
      datediff(
        'days', trial_start, annual_start
      )
    ), 
    0
  ) as days_to_upgrade 
from 
  annual 
  left join trial on trial.customer_id = annual.customer_id;

--10. Q) Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

with trial as (
  select 
    customer_id, 
    start_date as trial_start 
  from 
    subscriptions 
  where 
    plan_id = 0
), 
annual as (
  select 
    customer_id, 
    start_date as annual_start 
  from 
    subscriptions 
  where 
    plan_id = 3
) 
select 
    case
        when datediff('days', trial_start, annual_start) < 31 then '< 30 days'
        when datediff('days', trial_start, annual_start) < 61 then 'Between 30 and 60 days'
        when datediff('days', trial_start, annual_start) < 91 then 'Between 60 and 90 days'
        when datediff('days', trial_start, annual_start) < 121 then 'Between 90 and 120 days'
        when datediff('days', trial_start, annual_start) < 151 then 'Between 120 and 150 days'
        when datediff('days', trial_start, annual_start) < 181 then 'Between 150 and 180 days'
        else 'Other' 
    end as days_to_upgrade,
    count(annual.customer_id) as customer_count
from annual
    left join trial on trial.customer_id = annual.customer_id
group by days_to_upgrade;

--11. Q) How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

with cte as (
  SELECT 
    *, 
    ROW_NUMBER() OVER(
      PARTITION BY customer_id 
      ORDER BY 
        start_date asc
    ) as rn 
  FROM 
    subscriptions 
  where 
    plan_id in (1, 2)
) 
select 
  count(customer_id) as downgrade_count 
from 
  cte 
where 
  plan_id = 1 
  and rn = 2
  and year(start_date) = 2020
  