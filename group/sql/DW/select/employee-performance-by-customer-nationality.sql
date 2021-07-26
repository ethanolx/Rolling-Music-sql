--  File Name:
--      employee-performance-by-customer-nationality.sql

--  Keywords:
--      Employee, Sales Performance, Local, Foreign

--  Description:
--      --

--  Insights:
--      Overall, Jane Peacock is the top sales support agent.
--      She performs the best in selling music tracks to locals.

--      Conversely, Margaret Park performs the best in selling music tracks to foreigners.

--  Recommendations:
--      Jane Peacock should be given a bonus to encourage
--      her to keep up her good sales performance.

--      If there are local customers, they should be assigned to Jane Peacock
--      while Margaret Park should handle foreign customers.


USE MusicStoreDWFYRE;
GO

DROP FUNCTION IF EXISTS dbo.Get_Sales_By_Salesperson_And_Nationality;
GO

CREATE FUNCTION dbo.Get_Sales_By_Salesperson_And_Nationality() RETURNS TABLE AS
RETURN
    SELECT
        EmployeeKey,
        IIF(Country = 'Canada', 'Local', 'Foreign') AS [Nationality],
        SUM(Quantity) AS [Sales]
    FROM
        MusicFact M
            INNER JOIN
        CustomerDIM C ON M.CustomerKey = C.CustomerKey
    GROUP BY
        M.EmployeeKey,
        IIF(Country = 'Canada', 'Local', 'Foreign');
GO

SELECT
    E.FirstName + ' ' + E.LastName AS [Employee Name],
    L.Sales + F.Sales AS [Total Sales],
    L.Sales AS [Local Sales],
    F.Sales AS [Foreign Sales],
    CAST(F.[Sales Float] / (L.[Sales Float] + F.[Sales Float]) * 100.0 AS DECIMAL(5, 2)) AS [Foreign Sales Proportion]
FROM
    (SELECT
        *,
        CAST([Sales] AS FLOAT) AS [Sales Float]
    FROM
        dbo.Get_Sales_By_Salesperson_And_Nationality()
    WHERE
        [Nationality] = 'Local') AS L
        INNER JOIN
    (SELECT
        *,
        CAST([Sales] AS FLOAT) AS [Sales Float]
    FROM
        dbo.Get_Sales_By_Salesperson_And_Nationality()
    WHERE [Nationality] = 'Foreign') F ON L.EmployeeKey = F.EmployeeKey
        INNER JOIN
    EmployeeDIM E ON L.EmployeeKey = E.EmployeeKey
ORDER BY
    [Total Sales] DESC;
GO
