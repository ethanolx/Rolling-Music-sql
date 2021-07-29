--  File Name:
--      yearly-comparison-of-sales-growth-by-country.sql

--  Keywords:
--      Country, Comparison by Year, Sales Growth

--  Description:
--      --

--  Insights:
--      There is an increase in tracks sold to customers in Argentina and Canada.
--      While there is a decrease in tracks sold to
--      customers in the United States and Germany.
--      Out of the 4 countries, the majority of Rolling Music Store’s
--      business is done with customers from the United States.

--  Recommendations:
--      Rolling Music Store should collect feedback from their customers
--      in these 4 countries to understand their flaws and strengths.
--      To improve customer loyalty in Argentina and Canada,
--      they should offer a small gift, such as vouchers,
--      to customers and express their gratitude.

--      For the United States and Germany, they should research on the
--      more popular artists in those countries, and investigate possible
--      causes for the drop in sales, such as overly-priced tracks.

--  Parameters:
--      @custom_min_year:   Select earlier year to compare against (default is earliest year)
--      @custom_max_year:   Select later year to compare (default is latest year)


USE MusicStoreDWFYRE;
GO

DROP FUNCTION IF EXISTS dbo.Get_Country_Sales_By_Year;
GO

CREATE FUNCTION dbo.Get_Country_Sales_By_Year() RETURNS TABLE AS
RETURN
    SELECT
        [Year],
        Country,
        SUM(Quantity) AS [Sales]
    FROM
        MusicFact M
            INNER JOIN
        CustomerDIM C ON M.CustomerKey = C.CustomerKey
            INNER JOIN
        TimeDIM T ON M.DateKey = T.DateKey
    GROUP BY
        [Year],
        Country;
GO

-- parameters --
DECLARE @custom_min_year SMALLINT = NULL;
DECLARE @custom_max_year SMALLINT = NULL;
-- parameters --

DECLARE @min_year CHAR(4) = CONVERT(CHAR(4), (SELECT ISNULL(@custom_min_year, MIN([Year])) FROM TimeDIM INNER JOIN MusicFact ON TimeDIM.DateKey = MusicFact.DateKey));
DECLARE @max_year CHAR(4) = CONVERT(CHAR(4), (SELECT ISNULL(IIF(@custom_max_year > @custom_min_year, @custom_max_year, NULL), MAX([Year])) FROM TimeDIM INNER JOIN MusicFact ON TimeDIM.DateKey = MusicFact.DateKey));

EXEC ('
    SELECT
        [Country],
        [Earlier Sales] AS [Sales (' + @min_year + ')],
        [Later Sales] AS [Sales (' + @max_year + ')],
        [Growth]
    FROM
        (SELECT
            *,
            [Later Sales] - [Earlier Sales] AS [Growth],
            RANK() OVER (ORDER BY [Later Sales] - [Earlier Sales] ASC) AS [Asc Rank],
            RANK() OVER (ORDER BY [Later Sales] - [Earlier Sales] DESC) AS [Desc Rank]
        FROM
            (SELECT
                ISNULL(Latest_Sales.[Country], Earliest_Sales.[Country]) AS [Country],
                ISNULL(Earliest_Sales.[Sales], 0) AS [Earlier Sales],
                ISNULL(Latest_Sales.[Sales], 0) AS [Later Sales]
            FROM
                (SELECT
                    *
                FROM
                    dbo.Get_Country_Sales_By_Year()
                WHERE
                    [Year] = ' + @min_year + '
                ) Earliest_Sales
                    FULL OUTER JOIN
                (SELECT
                    *
                FROM
                    dbo.Get_Country_Sales_By_Year()
                WHERE
                    [Year] = ' + @max_year + '
                ) Latest_Sales ON Earliest_Sales.Country = Latest_Sales.Country
            ) tmp
        ) temp
    WHERE
        [Asc Rank] <= 2 OR [Desc Rank] <= 2
    ORDER BY
        [Growth] DESC
');