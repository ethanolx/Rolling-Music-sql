-- Databricks notebook source
-- MAGIC %fs mkdirs "/FileStore/tables/MusicStoreDW2012085"

-- COMMAND ----------

-- MAGIC %fs ls "/FileStore/tables/MusicStoreDW2012085"

-- COMMAND ----------

-- MAGIC %fs ls dbfs:/user/hive/warehouse/

-- COMMAND ----------

-- Create Database --
DROP DATABASE IF EXISTS MusicStoreDW2012085 CASCADE;
CREATE DATABASE MusicStoreDW2012085;
USE MusicStoreDW2012085;

-- COMMAND ----------

-- Create and Load Data into CustomerDIM Table --
CREATE TABLE CustomerDIM (
  CustomerKey INT,
  OLTPKey INT,
  FirstName VARCHAR(20),
  LastName VARCHAR(20),
  Company VARCHAR(80),
  `Address` VARCHAR(70),
  City VARCHAR(40),
  `State` VARCHAR(40),
  Country VARCHAR(40),
  PostalCode VARCHAR(10)
) USING CSV OPTIONS (
  path "/FileStore/tables/MusicStoreDW2012085/customerdim.csv",
  delimiter "|",
  header "true",
  encoding "utf-16"
);

SELECT
  *
FROM
  CustomerDIM
LIMIT
  3;

-- COMMAND ----------

-- Create and Load Data into EmployeeDIM Table --
CREATE TABLE EmployeeDIM (
  EmployeeKey INT,
  OLTPKey INT,
  FirstName VARCHAR(20),
  LastName VARCHAR(20),
  Title VARCHAR(30),
  BirthDate DATE,
  HireDate DATE
) USING CSV OPTIONS (
  path "/FileStore/tables/MusicStoreDW2012085/employeedim.csv",
  delimiter "|",
  header "true",
  encoding "utf-16"
);

SELECT
  *
FROM
  EmployeeDIM
LIMIT
  3;

-- COMMAND ----------

-- Create and Load Data into TrackDIM Table --
CREATE TABLE TrackDIM (
  TrackKey INT,
  OLTPKey INT,
  TrackName VARCHAR(160),
  MediaType VARCHAR(60),
  Genre VARCHAR(60),
  Composer VARCHAR(220),
  Duration_ms INT,
  Size_bytes INT,
  Album VARCHAR(160),
  Artist VARCHAR(120)
) USING CSV OPTIONS (
  path "/FileStore/tables/MusicStoreDW2012085/trackdim.csv",
  delimiter "|",
  header "true",
  encoding "utf-16"
);

SELECT
  *
FROM
  TrackDIM
LIMIT
  3;

-- COMMAND ----------

-- Create and Load Data into Temporary MusicFact Table --
CREATE TABLE MusicFact_tmp (
  SurrogateKey INT,
  CustomerKey INT,
  EmployeeKey INT,
  TrackKey INT,
  DateKey CHAR(8),
  Quantity INT,
  UnitPrice DECIMAL(5, 2)
) USING CSV OPTIONS (
  path "/FileStore/tables/MusicStoreDW2012085/musicfact.csv",
  delimiter "|",
  header "true",
  encoding "utf-16"
);

SELECT
  *
FROM
  MusicFact_tmp
LIMIT
  3;

-- COMMAND ----------

-- Create MusicFact Table --
CREATE TABLE MusicFact (
  SurrogateKey INT,
  CustomerKey INT,
  EmployeeKey INT,
  TrackKey INT,
  Quantity INT,
  UnitPrice DECIMAL(5, 2),
  DateValue DATE
);

-- Transfer Data over to the MusicFact Table --
-- Convert INT DateKey to DATE DateValue --
INSERT INTO
  MusicFact (
    SurrogateKey,
    CustomerKey,
    EmployeeKey,
    TrackKey,
    Quantity,
    UnitPrice,
    DateValue
  )
SELECT
  SurrogateKey,
  CustomerKey,
  EmployeeKey,
  TrackKey,
  Quantity,
  UnitPrice,
  CAST(
    CONCAT(
      SUBSTRING(DateKey, 1, 4),
      '-',
      SUBSTRING(DateKey, 5, 2),
      '-',
      SUBSTRING(DateKey, 7, 2)
    ) AS DATE
  ) AS DateValue
FROM
  MusicFact_tmp;

-- Drop Temporary MusicFact Table --
DROP TABLE MusicFact_tmp;

SELECT
  *
FROM
  MusicFact
LIMIT
  3;
