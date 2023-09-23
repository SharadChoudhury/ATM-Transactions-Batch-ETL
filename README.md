# ATM-Transactions-Batch-ETL
Performing Batch ETL of ATM transactions data using Apache Sqoop, Apache PySpark, loading the table data into Amazon S3 and warehousing using Amazon RedShift to analyze ATM withdrawl behaviours to optimally manage the refill frequency.


# Project Outline
<img width="1146" alt="Screenshot 2023-09-23 at 11 50 15" src="https://github.com/SharadChoudhury/ATM-Refill-Batch-ETL/assets/65325622/0b4af350-0947-4006-bf97-fbe01e3f9bc6">


## RDS Connection Details

We have the ATM Transaction data hosted on a RDS instance within table SRC_ATM_TRANS in testdatabase.

- **RDS Connection String**: <your_rds_connection_string>
- **Username**: username
- **Password**: password
- **Database**: testdatabase
- **Table Name**: SRC_TRANS


## EMR Cluster Setup

We have to ingest the data from RDS into HDFS in our EMR cluster and perform transformations using Spark. To do this, we need to create an EMR cluster with the following services installed:

- Hadoop
- Sqoop
- Spark
- Hue
- Jupyter Notebook
- Livy
- Zeppelin

Note that I am using Spark 2.4 for this project.

## Configure Sqoop in EMR Instance

To set up Sqoop to connect to RDS in the EMR instance, follow these steps (As Root user):

```bash
wget https://de-mysql-connector.s3.amazonaws.com/mysql-connector-java-8.0.25.tar.gz
tar -xvf mysql-connector-java-8.0.25.tar.gz
cd mysql-connector-java-8.0.25/
sudo cp mysql-connector-java-8.0.25.jar /usr/lib/sqoop/lib/
```

## Import Data into HDFS using Sqoop

Run the following Sqoop command (as the hadoop user) to import data into HDFS. Experiment with the number of mappers for optimization:

```bash
sqoop import \
--connect your_rds_connection_string/testdatabase \
--table SRC_ATM_TRANS \
--username username --password password \
--target-dir /user/livy/data \
--fields-terminated-by '|' \
--lines-terminated-by '\n' \
-m 1
```

- In the above method, the Sqoop job gets executed faster but the resulting file size is very large: 506 MB. Note that Sqoop creates a directory with the same name as the table in /user/hadoop if no target-dir is specified.
- If the target-dir lies in /user/hadoop/, then Sqoop creates a new directory with the table name within that. 
- Otherwise, it directly writes in the specified target-dir.


## Check Data Import in HDFS

To check if the data is imported correctly, run the following command:
```bash
hadoop fs -ls /user/livy/data
```

## Transformation using PySpark

- Run the `SparkETLCode.ipynb` notebook in Jupyter to create the fact and dimensions and store them into separate folders in S3. 
- Here, we need to ensure that our EMR cluster has IAM role that enables it to access S3 objects.


## Data Model
<img width="1252" alt="Screenshot 2023-09-23 at 12 23 29" src="https://github.com/SharadChoudhury/ATM-Refill-Batch-ETL/assets/65325622/8a8adce1-ade4-4bee-92d8-55375e698387">


## Data Warehousing with Redshift 
- Create a Redshift cluster with two nodes of dc2.large instances. 
- Create the schema and tables. Then load data into these tables from an S3 bucket. Ensure that the IAM role you associate with the Redshift cluster has appropriate permissions to read from S3. 
- Follow the commands in `model_creation.sql` (S3 objects URI and region can be noted from their properties tab).
- Now analyze the data using the queries from `analysis.sql`.
Feel free to analyze more on the data to derive insights.


### Parent-child relationships between tables as per our Data Model:
- Parent table: When foreign key of a table references some attribute of this table
- Child table : The table that contains the foreign key referencing the parent table

Note that [Uniqueness, primary key, and foreign key constraints are informational only; they are not enforced by Amazon Redshift when you populate a table. For example, if you insert data into a table with dependencies, the insert can succeed even if it violates the constraint. Nonetheless, primary keys and foreign keys are used as planning hints and they should be declared if your ETL process or some other process in your application enforces their integrity.](https://docs.aws.amazon.com/redshift/latest/dg/t_Defining_constraints.html#:~:text=Uniqueness%2C%20primary%20key,enforces%20their%20integrity.)


Since the tables have parent-child relationships between them, it is important to remember that:
- We should first upload data to parent table then into child table.
- We should first delete the child table, then the parent table.

To delete a table with dependencies you can also use:
```sql
drop table <table-name> cascade;
```
