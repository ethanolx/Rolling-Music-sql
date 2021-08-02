--  File Name:
--      year-on-year-comparison-of-sales-by-quarter.sql

--  Keywords:
--      Year-on-Year, By Quarter, Sales Comparison, Sales Growth

--  Description:
--      Compare each quarter's performance with the same quarter of the previous year

--  Insights:
--      In 2013, there was a fall in sales in quarters 1, 2 and 3, compared to 2012.
--      The greatest drop in sales was in quarter 3.

--      Nonetheless, sales improved from 2012 Q4 to 2013 Q4.

--  Recommendations:
--      Rolling Music Store should analyse their sales operations during the first 3 quarters of 2013 -
--      especially in quarter 3 - to understand what resulted in the drop in sales.

--      With their findings, they should take the necessary measures to increase sales in the under-performing quarters.

--      They ought to take note of what went well in the 4th quarter of 2013 too.
--      If any practices enhanced their sales during that time period, they should implement them in the future.

--      For instance, if the sales growth in 2013 Q4 (from 2012 Q4) was due to a holiday sale,
--      they should organise such events more often.

--  Parameter:
--      @custom_year:   Select the year for comparison (default is most recent year)


USE MusicStoreDWFYRE;
GO

DROP FUNCTION IF EXISTS dbo.Get_Quarterly_Performance_For_Year;
GO

CREATE FUNCTION dbo.Get_Quarterly_Performance_For_Year(@year SMALLINT) RETURNS TABLE AS
RETURN
    SELECT
        T.[Year],
        T.[Quarter],
        SUM(Quantity * UnitPrice) AS [Sales]
    FROM
        MusicFact M
            INNER JOIN
        TimeDIM T ON M.DateKey = T.DateKey
    WHERE
        T.[Year] = @year
    GROUP BY
        T.[Year],
        T.[Quarter];
GO

-- parameter --
DECLARE @custom_year SMALLINT = NULL;
-- parameter --

DECLARE @selected_year SMALLINT = (SELECT ISNULL(@custom_year, MAX([Year])) FROM TimeDIM INNER JOIN MusicFact ON TimeDIM.DateKey = MusicFact.DateKey);

SELECT
    Later.[Year] AS [Calendar Year],
    Later.[Quarter] AS [Calendar Quarter],
    Later.Sales AS [Selected Year Sales],
    Earlier.Sales AS [Previous Year Sales],
    CAST((Later.Sales - Earlier.Sales) / Earlier.Sales * 100.0 AS DECIMAL(5, 2)) AS [Percentage Growth]
FROM
    dbo.Get_Quarterly_Performance_For_Year(@selected_year) AS Later
        INNER JOIN
    dbo.Get_Quarterly_Performance_For_Year(@selected_year - 1) AS Earlier ON Later.[Quarter] = Earlier.[Quarter]
ORDER BY
    [Calendar Quarter] ASC;
GO