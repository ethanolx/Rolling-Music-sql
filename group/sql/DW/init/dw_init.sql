-- RUN using <master> database --

/*
WARNING:
    - ALL data in MusicStoreDWFYRE will be erased
    - This is a potentially irreversible action
*/

--  File Name:
--      dw_init.sql

--  Run Order:
--      Before: dw_dim_data.sql, dw_time_dim_data.sql, dw_fact_data.sql

--  Keywords:
--      Create Tables, Data Warehouse

--  Description:
--      Create tables for MusicStoreDWFYRE


-- Database Initialisation --
DROP DATABASE IF EXISTS MusicStoreDWFYRE;
GO

CREATE DATABASE MusicStoreDWFYRE;
GO

USE MusicStoreDWFYRE;
GO

CREATE TABLE CustomerDIM (
    CustomerKey INT             IDENTITY(1, 1),
    OLTPKey     INT             NOT NULL,
    FirstName   NVARCHAR(20)    NOT NULL,
    LastName    NVARCHAR(20)    NOT NULL,
    Company     NVARCHAR(80)    NULL,
    [Address]   NVARCHAR(70)    NOT NULL,
    City        NVARCHAR(40)    NOT NULL,
    [State]     NVARCHAR(40)    NULL,
    Country     NVARCHAR(40)    NOT NULL,
    PostalCode  NVARCHAR(10)    NULL
    PRIMARY KEY (CustomerKey)
);
GO

CREATE TABLE EmployeeDIM (
    EmployeeKey INT             IDENTITY(1, 1),
    OLTPKey     INT             NOT NULL,
    FirstName   NVARCHAR(20)    NOT NULL,
    LastName    NVARCHAR(20)    NOT NULL,
    Title       NVARCHAR(30)    NOT NULL,
    BirthDate   DATE            NOT NULL,
    HireDate    DATE            NOT NULL,
    PRIMARY KEY (EmployeeKey)
);
GO

CREATE TABLE TrackDIM (
    TrackKey        INT             IDENTITY(1, 1),
    OLTPKey         INT             NOT NULL,
    TrackName       NVARCHAR(160)   NOT NULL,
    MediaType       NVARCHAR(60)    NOT NULL,
    Genre           NVARCHAR(60)    NOT NULL,
    Composer        NVARCHAR(220)   NULL,
    Duration_ms     INT             NOT NULL,
    Size_bytes      INT             NOT NULL,
    Album           NVARCHAR(160)   NOT NULL,
    Artist          NVARCHAR(120)   NOT NULL,
    PRIMARY KEY (TrackKey)
);
GO

CREATE TABLE TimeDIM (
    DateKey     INT         NOT NULL, -- 8 digit date key (YYYYMMDD)
    [Date]      DATE        NOT NULL, -- Date
    [Year]      INT         NOT NULL, -- Year value of Date
    [Quarter]   INT         NOT NULL, -- Quarter value of Date
    [Month]     INT         NOT NULL, -- Number of the Month 1 to 12
    [MonthName] CHAR(3)     NOT NULL, -- Jan, Feb etc
    [DayOfWkNo] INT         NOT NULL, -- Number of the week 1 to 7
    [DayOfWkName] CHAR(3)   NOT NULL, -- Contains name of the day (e.g. Sun, Mon)
    PRIMARY KEY (DateKey)
);
GO

CREATE TABLE MusicFact (
    SurrogateKey    INT IDENTITY(1, 1),
    CustomerKey     INT NOT NULL,
    EmployeeKey     INT NOT NULL,
    TrackKey        INT NOT NULL,
    DateKey         INT NOT NULL,
    Quantity        INT NOT NULL,
    UnitPrice       DECIMAL(5, 2) NOT NULL,
    PRIMARY KEY (SurrogateKey),
    FOREIGN KEY (CustomerKey) REFERENCES CustomerDIM (CustomerKey),
    FOREIGN KEY (EmployeeKey) REFERENCES EmployeeDIM (EmployeeKey),
    FOREIGN KEY (TrackKey) REFERENCES TrackDIM (TrackKey),
    FOREIGN KEY (DateKey) REFERENCES TimeDIM (DateKey),
);
GO