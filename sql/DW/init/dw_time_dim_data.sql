/* Script: CreateTableForTimeDimension.sql
   Purpose: To create the Time dimension table
   Date Written: July 2021
*/

-- CREATE DATABASE MusicStoreFYREDW;
USE MusicStoreFYREDW;

--IF NOT EXISTS (SELECT * FROM sysobjects WHERE NAME='TimeDIM' AND xtype='U')
--	CREATE TABLE TimeDIM (
--		DateKey		INT			NOT NULL, -- 8 digit date key (YYYYMMDD)
--		[Date]		DATE		NOT NULL, -- Date
--		[Year]		INT			NOT NULL, -- Year value of Date
--		[Quarter]	INT			NOT NULL, -- Quarter value of Date
--		[Month]		INT			NOT NULL, -- Number of the Month 1 to 12
--		[MonthName] CHAR(3)		NOT NULL, -- Jan, Feb etc
--		[DayOfWkNo] INT			NOT NULL, -- Number of the week 1 to 7
--		[DayOfWkName] CHAR(3)	NOT NULL, -- Contains name of the day (e.g. Sun, Mon) 
--		PRIMARY KEY (DateKey)
--	);
--GO

DECLARE @StartDate DATE = '20090101' --Starting value of Date Range
DECLARE @EndDate DATE = '20140101' --End Value of Date Range

DECLARE @curDate DATE

SET @curdate = @StartDate
WHILE @curDate < @EndDate 
BEGIN
		   
	INSERT INTO [TimeDIM]
    SELECT 
	  CONVERT (char(8),@curDate,112) as DateKey, -- 8 digit date key (YYYYMMDD)
	  @CurDate AS [Date], -- Date
	  
	  DatePart(Year, @curDate) as [Year], -- Get Year value of Date
	  DatePart(Quarter, @curDate) as [Quarter], -- Get Quarter value of Date
	  DatePart(Month, @curDate) AS [Month], -- Get number of the Month 1 to 12
	  Format(@curDate, 'MMM') AS [MonthName], -- Get Month name Jan, Feb etc

	  -- Get number of the Week 1 to 7
	  CASE DATEPART(WeekDay, @curDate)
		WHEN 1 THEN 7
		WHEN 2 THEN 1
		WHEN 3 THEN 2
		WHEN 4 THEN 3
		WHEN 5 THEN 4
		WHEN 6 THEN 5
		WHEN 7 THEN 6
	  END AS DayOfWkNo,

	  Format(@curDate, 'ddd') AS DayOfWkName -- Get Day of Week Name (e.g. Sun, Mon) 

    /* Increate @curDate by 1 day */
	SET @curDate = DateAdd(Day, 1, @curDate)
END

SELECT * FROM TimeDIM;