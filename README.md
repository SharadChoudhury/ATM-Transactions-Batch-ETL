# ATM-Refill-Batch-ETL
Batch ETL pipeline using Apache Sqoop, Apache PySpark, Amazon S3 and Amazon RedShift to analyze ATM withdrawl behaviours to optimally manage the refill frequency.


# Project Outline

## RDS Connection Details

We have the ATM Transaction data hosted on a RDS instance within table SRC_ATM_TRANS in testdatabase.

- **RDS Connection String**: <your_rds_connection_string>
- **Username**: <username>
- **Password**: <password>
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

## Configure Sqoop in EMR Instance

To set up Sqoop to connect to RDS in the EMR instance, follow these steps:

```bash
sudo -i 

wget https://de-mysql-connector.s3.amazonaws.com/mysql-connector-java-8.0.25.tar.gz
tar -xvf mysql-connector-java-8.0.25.tar.gz
cd mysql-connector-java-8.0.25/
sudo cp mysql-connector-java-8.0.25.jar /usr/lib/sqoop/lib/
exit 
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


## Check Data Import

To check if the data is imported correctly, run the following command:

```bash
hadoop fs -ls /user/livy/data
```

## Spark Task

Run the `SparkETLCode.ipynb` notebook in Jupyter to create the fact and dimensions and store them into separate folders in S3.


## Redshift Task

- Create a Redshift cluster with two nodes of dc2.large instances. 
- Create the schema and tables. Then load data into these tables from an S3 bucket. 
- Follow the commands in `model_creation.sql` (S3 objects URI and region can be noted from their properties tab).
- Now analyze the data using the queries from `analysis.sql`.
