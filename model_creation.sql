create schema atm_model;

-- don't specify distkey if diststyle is ALL. As, distribution only makes sense for diststyle EVEN or KEY.

create table atm_model.dim_location (
    location_id INT PRIMARY KEY,
    location VARCHAR(50),
    streetname VARCHAR(255),
    street_number INT,
    zipcode INT,
    lat DECIMAL(10,3),
    lon DECIMAL(10,3)
) DISTSTYLE ALL;
 

create table atm_model.dim_atm (
    atm_id INT PRIMARY KEY,
    atm_number VARCHAR(20),
    atm_manufacturer VARCHAR(50),
    atm_location_id INT,
    FOREIGN KEY(atm_location_id) references atm_model.dim_location(location_id)
)
DISTSTYLE ALL;
 

create table atm_model.dim_date(
    date_id INT PRIMARY KEY,
    full_date_time timestamp,
    year INT,
    month VARCHAR(20),
    day INT,
    hour INT,
    weekday VARCHAR(20)
)
DISTSTYLE ALL;
 

create table atm_model.dim_card_type(
    card_type_id INT PRIMARY KEY,
    card_type VARCHAR(30)
)
DISTSTYLE ALL;
 

create table atm_model.fact_atm_trans(
    trans_id BIGINT PRIMARY KEY,
    atm_id INT,
    weather_loc_id INT,
    date_id INT,
    card_type_id INT,
    atm_status VARCHAR(20),
    currency VARCHAR(10),
    service VARCHAR(20),
    transaction_amount INT,
    message_code VARCHAR(255),
    message_text VARCHAR(255),
    rain_3h DECIMAL(10,3),
    clouds_all INT,
    weather_id INT,
    weather_main VARCHAR(50),
    weather_description VARCHAR(255),
    FOREIGN KEY(weather_loc_id) references atm_model.dim_location(location_id),
    FOREIGN KEY(atm_id) references atm_model.dim_atm(atm_id),
    FOREIGN KEY(date_id) references atm_model.dim_date(date_id),
    FOREIGN KEY(card_type_id) references atm_model.dim_card_type(card_type_id)
) ;
 


-- copying data from s3 to redshift tables 

-- First load data in dim_location, then in dim_atm table
copy atm_model.dim_location from
's3://atm-data-model/DIM_LOCATION/part-00000-f0b34689-afbe-47a3-9bf3-a3999784dc11-c000.csv'
iam_role 'arn:aws:iam::391707279775:role/myRedshiftRole'
delimiter ',' region 'us-east-1'
ignoreheader 1;

copy atm_model.dim_atm from
's3://atm-data-model/DIM_ATM/part-00000-75334a09-7af5-4a4f-8c06-840d9d29dc71-c000.csv'
iam_role 'arn:aws:iam::391707279775:role/myRedshiftRole'
delimiter ',' region 'us-east-1'
ignoreheader 1;

copy atm_model.dim_date from
's3://atm-data-model/DIM_DATE/part-00000-fa8da1dd-3b30-4ec2-abe6-0bcff634d411-c000.csv'
iam_role 'arn:aws:iam::391707279775:role/myRedshiftRole'
delimiter ',' region 'us-east-1'
TIMEFORMAT 'auto'
ignoreheader 1;
-- By default, the timestamp datatype in redshift is without timezone
-- So, set timeformat to auto. If no TIMEFORMAT is specified, the default format is YYYY-MM-DD HH:MI:SS 
-- for TIMESTAMP columns or YYYY-MM-DD HH:MI:SSOF for TIMESTAMPTZ columns


copy atm_model.dim_card_type from
's3://atm-data-model/DIM_CARD_TYPE/part-00000-6fea4a14-25e7-470d-a105-6bf1835fb4aa-c000.csv'
iam_role 'arn:aws:iam::391707279775:role/myRedshiftRole'
delimiter ',' region 'us-east-1'
ignoreheader 1;

copy atm_model.fact_atm_trans from
's3://atm-data-model/FACT_ATM_TRANS/part-00000-dc01a03a-b4a7-4fdf-a091-32e2250f3f1b-c000.csv'
iam_role 'arn:aws:iam::391707279775:role/myRedshiftRole'
delimiter ',' region 'us-east-1'
ignoreheader 1;
