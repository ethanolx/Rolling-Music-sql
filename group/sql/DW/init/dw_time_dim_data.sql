--  File Name:
--      dw_time_dim_data.sql

--  Run Order:
--      Before: dw_fact_data.sql
--      After:  dw_init.sql

--  Keywords:
--      Generate Data, Time Dimension Table

--  Description:
--      Generate Data for MusicStoreDWFYRE..TimeDIM


USE MusicStoreDWFYRE;
GO

DECLARE @StartDate DATE = '20090101';   -- Start value of Date Range
DECLARE @EndDate DATE = '20150101';     -- End Value of Date Range

DECLARE @CurDate DATE;

SET @CurDate = @StartDate;
WHILE @CurDate < @EndDate
BEGIN
    INSERT INTO [TimeDIM]
    SELECT
        CONVERT (CHAR(8),@CurDate,112) AS [DateKey],    -- 8 digit date key (YYYYMMDD)
        @CurDate AS [Date],                             -- Date

        DATEPART(YEAR, @CurDate) AS [Year],             -- Get Year value of Date
        DATEPART(QUARTER, @CurDate) AS [Quarter],       -- Get Quarter value of Date
        DATEPART(MONTH, @CurDate) AS [Month],           -- Get Month value (i.e. 1 to 12)
        FORMAT(@CurDate, 'MMM') AS [MonthName],         -- Get Month name (i.e. Jan, Feb)

        -- Get number of the Week 1 to 7
        CASE DATEPART(WEEKDAY, @CurDate)
            WHEN 1 THEN 7
            WHEN 2 THEN 1
            WHEN 3 THEN 2
            WHEN 4 THEN 3
            WHEN 5 THEN 4
            WHEN 6 THEN 5
            WHEN 7 THEN 6
        END AS DayOfWkNo,

        FORMAT(@CurDate, 'ddd') AS DayOfWkName;     -- Get Day of Week Name (i.e. Sun, Mon)

    -- Increment @CurDate by 1 day
    SET @CurDate = DATEADD(DAY, 1, @CurDate);
END;
GO