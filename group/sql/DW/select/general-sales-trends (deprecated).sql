--  File Name:
--      general-sales-trends (deprecated).sql

--  Keywords:
--      Sales, Seasons, Trends

--  Description:
--      Compare sales with previous quarter

--  Insights:
--      There seems to be a pattern where sales fall greatly,
--      a year (4 quarters) after a rise in sales.

--      For instance, sales have been successful from 2010 Q3 onwards until a year later,
--      where sales significantly fell for the following 2 quarters.

--  Recommendations:
--      Rolling Music Store can anticipate a drop in sales from Quarter 1 to Quarter 2 in 2014.
--      During this period of time, they could consider more aggressive promotional efforts
--      during that period like bundle and clearance sales, or advertising campaigns.


USE MusicStoreDWFYRE;
GO

SELECT
    [Year],
    [Quarter],
    [Current Sales] AS [Sales],
    [Current Sales] - [Previous Quarter Sales] AS [Sales Difference (Prev Q)],
    CAST(([Current Sales] - [Previous Quarter Sales]) / [Previous Quarter Sales] * 100.0 AS DECIMAL(5, 2)) AS [Percentage Change (Prev Q)]
FROM
    (SELECT
        [Year],
        [Quarter],
        SUM(M.Quantity * M.UnitPrice) AS [Current Sales],
        LAG(SUM(M.Quantity * M.UnitPrice), 1, SUM(M.Quantity * M.UnitPrice)) OVER(ORDER BY T.[Year], T.[Quarter]) AS [Previous Quarter Sales]
    FROM
        MusicFact M
            INNER JOIN
        TimeDIM T ON M.DateKey = T.DateKey
    GROUP BY
        T.[Year],
        T.[Quarter]) tmp
WHERE
    [Current Sales] - [Previous Quarter Sales] < 0
ORDER BY
    [Year],
    [Quarter];
GO
