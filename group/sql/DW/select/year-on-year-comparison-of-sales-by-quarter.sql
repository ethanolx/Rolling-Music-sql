--  File Name:
--      year-on-year-comparison-of-sales-by-quarter.sql

--  Keywords:
--      Year-on-Year, By Quarter, Sales Comparison, Sales Growth

--  Description:
--      --

--  Insights:
--      --

--  Recommendations:
--      --

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