select * from atm_model.fact_atm_trans limit 10;

select distinct(year) from atm_model.dim_date;



--Top 10 ATMs where most transactions are in the ’inactive’ state
select a.atm_number, a.atm_manufacturer, l.location, count(*) as total_transaction_count,
sum(if(atm_status = 'inactive', 1, 0)) as inactive_count
from atm_model.fact_atm_trans f left join atm_model.dim_atm a on f.atm_id = a.atm_id
left join atm_model.dim_location l on a.atm_location_id = l.location_id
group by atm_id order by inactive_count desc limit 10;

select atm_number, atm_manufacturer, L.location, F.total_transaction_count, F.inactive_count 
from 
(   select atm_id, weather_loc_id, count(*) as total_transaction_count,
    sum(if(atm_status = 'inactive', 1, 0)) as inactive_count
    from atm_model.fact_atm_trans 
    group by atm_id,weather_loc_id 
    order by inactive_count desc limit 10
)F, atm_model.dim_atm A using(atm_id)
join atm_model.dim_location L on F.weather_loc_id = L.location_id
; 


--Number of ATM failures corresponding to the different weather conditions recorded at the time of the transactions
select distinct(message_code) from atm_model.fact_atm_trans;
select distinct(message_text) from atm_model.fact_atm_trans;




--Top 10 ATMs with the most number of transactions throughout the year
select d.year, a.atm_number, a.atm_manufacturer, l.location, count(*) as total_transaction_count
from atm_model.fact_atm_trans f left join atm_model.dim_atm a on f.atm_id = a.atm_id
left join atm_model.dim_location l on a.atm_location_id = l.location_id
left join atm_model.dim_date d on f.date_id = d.date_id
group by atm_id,d.year 
order by total_transaction_count desc limit 10;

select F.year, A.atm_number, A.atm_manufacturer, L.location, F.total_transaction_count
from 
(
    select d.year, atm_id, weather_loc_id count(*) as total_transaction_count
    from atm_model.fact_atm_trans, atm_model.dim_date d using(date_id)
    group by d.year, atm_id, weather_loc_id
    order by total_transaction_count desc limit 10
)F, atm_model.dim_atm A using(atm_id)
join atm_model.dim_location L on F.weather_loc_id = L.location_id;



--Number of overall ATM transactions going inactive per month for each month
with cte as (
    select d.year, d.month, count(*) as total_transaction_count, 
    sum(if(f.atm_status = 'inactive', 1, 0)) inactive_count
    from atm_model.fact_atm_trans f, atm_model.dim_date d using(date_id)
    group by d.year, d.month
)
select *, round(inactive_count/total_transaction_count, 2) as inactive_count_percent
from cte 
order by inactive_count desc limit 10;



--Top 10 ATMs with the highest total amount withdrawn throughout the year 
select A.atm_number, A.atm_manufacturer, L.location, F.total_transaction_amount
from 
(
    select atm_id, weather_loc_id, sum(transaction_amount) as total_transaction_amount
    from atm_model.fact_atm_trans
    group by atm_id, weather_loc_id
    limit 10
)F, atm_number.dim_atm using(atm_id)
join atm_number.dim_location L on F.weather_loc_id = L.location_id;



--Number of failed ATM transactions across various card types
with cte as (
select card_type from 
( 
    select card_type_id, count(*) as total_transaction_count,
    sum(if(atm_status='inactive', 1, 0)) as inactive_count
    from atm_model.fact_atm_trans 
    group by card_type_id
)F, atm_model.dim_card_type using(card_type_id) 
)
select *, round(inactive_count/total_transaction_count, 2) inactive_count_percent
from cte;



--Top 10 records with the number of transactions ordered by the ATM_number, ATM_manufacturer, location, weekend_flag and then total_transaction_count, on weekdays and on weekends throughout the year



--Most active day in each ATMs from location "Vejgaard"
select A.atm_number, A.atm_manufacturer, L.location, D.weekday, count(*) as total_transaction_count
from atm_model.fact_atm_trans F join atm_model.dim_atm A using(atm_id)
join atm_model.dim_location L on F.weather_loc_id = L.location_id
join atm_model.dim_date D using(date_id)
where L.location = 'Vejgaard'
group by F.atm_id, D.weekday;
