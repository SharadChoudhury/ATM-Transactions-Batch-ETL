select * from atm_model.fact_atm_trans limit 10;

select distinct(year) from atm_model.dim_date;
-- records are only for year 2017



-- 1 . Top 10 ATMs where most transactions are in the ’inactive’ state

-- This query first fetches the top 10 rows with most inactive counts then joins them with atm, location tables
-- So it's cost is very low
SELECT atm_number,
       atm_manufacturer,
       L.location,
       F.total_transaction_count,
       F.inactive_count
FROM   (SELECT atm_id,
               weather_loc_id,
               Count(*) AS total_transaction_count,
               Sum(CASE
                     WHEN atm_status = 'Inactive' THEN 1
                     ELSE 0
                   end) AS inactive_count
        FROM   atm_model.fact_atm_trans
        GROUP  BY atm_id,
                  weather_loc_id
        ORDER  BY inactive_count DESC
        LIMIT  10)F
       LEFT JOIN atm_model.dim_atm A
              ON F.atm_id = A.atm_id
       LEFT JOIN atm_model.dim_location L
              ON F.weather_loc_id = L.location_id
ORDER BY inactive_count desc; 

-- This query joins all tables first then filters so, it is more costly
SELECT a.atm_number, a.atm_manufacturer, l.location, COUNT(*) AS total_transaction_count,
  SUM(CASE WHEN atm_status = 'Inactive' THEN 1 ELSE 0 END) AS inactive_count
FROM atm_model.fact_atm_trans f
LEFT JOIN atm_model.dim_atm a ON f.atm_id = a.atm_id
LEFT JOIN atm_model.dim_location l ON a.atm_location_id = l.location_id
GROUP BY a.atm_number, a.atm_manufacturer, l.location
ORDER BY inactive_count DESC
LIMIT 10;



-- 2. Number of ATM failures corresponding to the different weather conditions recorded at the time of the transactions
with cte as (
select weather_main, count(*) as total_transaction_count, 
sum(case when atm_status='Inactive' then 1 else 0 end) as inactive_count
from atm_model.fact_atm_trans group by weather_main 
) select *, ROUND((CAST(inactive_count AS DECIMAL) / total_transaction_count) * 100, 2) as inactive_count_percent
from cte order by inactive_count_percent desc;



-- 3. Top 10 ATMs with the most number of transactions throughout the year
select A.atm_number, A.atm_manufacturer, L.location, F.total_transaction_count
from 
(   select atm_id, weather_loc_id, count(*) as total_transaction_count
    from atm_model.fact_atm_trans
    group by atm_id, weather_loc_id
    order by total_transaction_count desc limit 10
)F left join atm_model.dim_atm A using(atm_id)
left join atm_model.dim_location L on F.weather_loc_id = L.location_id
order by total_transaction_count desc;




-- 4. Number of overall ATM transactions going inactive per month for each month
with cte as (
    select year, month, count(*) as total_transaction_count, 
    sum(case when atm_status = 'Inactive' then 1 else 0 end) inactive_count
    from atm_model.fact_atm_trans left join atm_model.dim_date using (date_id)
    group by year, month
)
select *, round(cast(inactive_count as decimal)/total_transaction_count * 100, 2) as inactive_count_percent
from cte 
order by month;



-- 5. Top 10 ATMs with the highest total amount withdrawn throughout the year 
select A.atm_number, A.atm_manufacturer, L.location, F.total_transaction_amount
from 
(   select atm_id, weather_loc_id, sum(transaction_amount) as total_transaction_amount
    from atm_model.fact_atm_trans
    where service='Withdrawal'
    group by atm_id, weather_loc_id
    order by total_transaction_amount desc
    limit 10
)F left join atm_model.dim_atm A using(atm_id)
left join atm_model.dim_location L on F.weather_loc_id = L.location_id
order by total_transaction_amount desc ;




-- 6. Number of failed ATM transactions across various card types
select card_type, total_transaction_count, inactive_count,
round(cast(inactive_count as decimal)/total_transaction_count * 100, 2) inactive_count_percent
from 
(   select card_type_id, count(*) as total_transaction_count,
    sum(case when atm_status='Inactive' then 1 else 0 end) as inactive_count
    from atm_model.fact_atm_trans 
    group by card_type_id
)F left join atm_model.dim_card_type using(card_type_id) 
order by inactive_count_percent desc ;



-- 7. Top 10 records with the number of transactions ordered by the ATM_number, ATM_manufacturer, location, weekend_flag and then total_transaction_count, on weekdays and on weekends throughout the year
select atm_number, atm_manufacturer, location, weekend_flag, total_transaction_count
from (
    select atm_id, weather_loc_id, 
    case 
        when weekday in ('Saturday', 'Sunday') then 1
        else 0
    end as weekend_flag,
    count(*) as total_transaction_count
    from atm_model.fact_atm_trans left join atm_model.dim_date using(date_id)
    group by atm_id, weather_loc_id, weekend_flag
)F left join atm_model.dim_atm using(atm_id)
left join atm_model.dim_location L on F.weather_loc_id = L.location_id
order by atm_number, atm_manufacturer, location, weekend_flag, total_transaction_count limit 10;


-- 8. Most active day in each ATMs from location "Vejgaard"
select atm_number, atm_manufacturer, 'Vejgaard' as location, weekday, total_transaction_count
from 
(   select atm_id, weekday, count(*) as total_transaction_count, 
    rank() over(partition by atm_id order by count(*) desc) as rank_
    from atm_model.fact_atm_trans left join atm_model.dim_date using(date_id)
    where weather_loc_id = (select location_id from atm_model.dim_location where location = 'Vejgaard')
    group by atm_id, weekday
)F left join atm_model.dim_atm using(atm_id)
where rank_ = 1;