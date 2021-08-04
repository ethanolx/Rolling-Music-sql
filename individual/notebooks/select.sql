-- Databricks notebook source
USE MusicStoreDW2012085;

SELECT
    Later.`Year` AS `Calendar Year`,
    Later.`Quarter` AS `Calendar Quarter`,
    Later.Sales AS `Selected Year Sales`,
    Earlier.Sales AS `Previous Year Sales`,
    CAST((Later.Sales - Earlier.Sales) / Earlier.Sales * 100.0 AS DECIMAL(5, 2)) AS `Percentage Growth`
FROM
    (SELECT
        YEAR(DateValue) AS `Year`,
        QUARTER(DateValue) AS `Quarter`,
        SUM(Quantity * UnitPrice) AS `Sales`
    FROM
        MusicFact M
    WHERE
        YEAR(DateValue) = 2013
    GROUP BY
        `Year`,
        `Quarter`) AS Later
        INNER JOIN
    (SELECT
        YEAR(DateValue) AS `Year`,
        QUARTER(DateValue) AS `Quarter`,
        SUM(Quantity * UnitPrice) AS `Sales`
    FROM
        MusicFact M
    WHERE
        YEAR(DateValue) = 2012
    GROUP BY
        `Year`,
        `Quarter`) AS Earlier ON Later.`Quarter` = Earlier.`Quarter`
ORDER BY
    `Calendar Quarter` ASC;

-- COMMAND ----------

USE MusicStoreDW2012085;

WITH tmp (min_year, max_year) AS (SELECT 2009, 2013)

SELECT
    `Country`,
    `Earlier Sales` AS `Sales (2009)`,
    `Later Sales` AS `Sales (2013)`,
    `Growth`
FROM
    (SELECT
        *,
        `Later Sales` - `Earlier Sales` AS `Growth`,
        RANK() OVER (ORDER BY `Later Sales` - `Earlier Sales` ASC) AS `Asc Rank`,
        RANK() OVER (ORDER BY `Later Sales` - `Earlier Sales` DESC) AS `Desc Rank`
    FROM
        (SELECT
            IFNULL(Latest_Sales.`Country`, Earliest_Sales.`Country`) AS `Country`,
            IFNULL(Earliest_Sales.`Sales`, 0) AS `Earlier Sales`,
            IFNULL(Latest_Sales.`Sales`, 0) AS `Later Sales`
        FROM
            (SELECT
                *
            FROM
                (SELECT
                    YEAR(DateValue) AS `Year`,
                    Country,
                    SUM(Quantity) AS `Sales`
                FROM
                    MusicFact M
                        INNER JOIN
                    CustomerDIM C ON M.CustomerKey = C.CustomerKey
                GROUP BY
                    `Year`,
                    Country), tmp
            WHERE
                `Year` = min_year
            ) Earliest_Sales
                FULL OUTER JOIN
            (SELECT
                *
            FROM
                (SELECT
                    YEAR(DateValue) AS `Year`,
                    Country,
                    SUM(Quantity) AS `Sales`
                FROM
                    MusicFact M
                        INNER JOIN
                    CustomerDIM C ON M.CustomerKey = C.CustomerKey
                GROUP BY
                    `Year`,
                    Country), tmp
            WHERE
                `Year` = max_year
            ) Latest_Sales ON Earliest_Sales.Country = Latest_Sales.Country
        )
    )
WHERE
    `Asc Rank` <= 2 OR `Desc Rank` <= 2
ORDER BY
    `Growth` DESC;

-- COMMAND ----------

USE MusicStoreDW2012085;

WITH employee_performance AS (
    SELECT
        `Employee`,
        `Year`,
        `Mean Sales`,
        `Std of Sales`,
        `Sales Rank`,
        `Consistency Rank`
    FROM
        (SELECT
            `Employee`,
            `Year`,
            ROUND(AVG(`Sales`), 2) AS `Mean Sales`,
            ROUND(STD(`Sales`), 2) AS `Std of Sales`,
            RANK() OVER (PARTITION BY `Year` ORDER BY AVG(`Sales`) DESC) `Sales Rank`,
            RANK() OVER (PARTITION BY `Year` ORDER BY STD(`Sales`) ASC) `Consistency Rank`
        FROM
            (SELECT
                Complete_Time.`Year`,
                Complete_Time.`Month`,
                CONCAT(FirstName, ' ', LastName) AS `Employee`,
                IFNULL(Sales_Info.`Sales`, 0.0) AS `Sales`
            FROM
                (SELECT
                    YEAR(DateValue) AS `Year`,
                    MONTH(DateValue) AS `Month`,
                    EmployeeKey,
                    SUM(Quantity * UnitPrice) AS `Sales`
                FROM
                    MusicFact
                GROUP BY
                    `Year`,
                    `Month`,
                    EmployeeKey
                ) Sales_Info
                    RIGHT OUTER JOIN
                (SELECT
                    *
                FROM
                    (SELECT DISTINCT YEAR(DateValue) AS `Year` FROM MusicFact) Y
                        FULL OUTER JOIN
                    (SELECT DISTINCT MONTH(DateValue) AS `Month` FROM MusicFact) M
                        FULL OUTER JOIN
                    (SELECT DISTINCT EmployeeKey FROM MusicFact) E
                ) Complete_Time ON
                    Sales_Info.`Year` = Complete_Time.`Year`
                        AND
                    Sales_Info.`Month` = Complete_Time.`Month`
                        AND
                    Sales_Info.`EmployeeKey` = Complete_Time.`EmployeeKey`
                        INNER JOIN
                    EmployeeDIM ON Complete_Time.EmployeeKey = EmployeeDIM.EmployeeKey)
        GROUP BY
            `Employee`,
            `Year`)
    WHERE
        (`Sales Rank` = 1
            OR
        `Consistency Rank` = 1) AND `Mean Sales` >= 1000
)

SELECT
    IFNULL(Best_Sales.Employee, Most_Consistent.Employee) AS `Employee`,
    `Best Performing Salesperson of`,
    `Most Consistent Salesperson of`
FROM
    ((SELECT
        `Employee`,
        COLLECT_SET(CONCAT(`Year`, ' with mean monthly sales of $', `Mean Sales`)) AS `Best Performing Salesperson of`
    FROM
        employee_performance
    WHERE
        `Sales Rank` = 1
    GROUP BY
        `Employee`) Best_Sales
        FULL OUTER JOIN
    (SELECT
        `Employee`,
        COLLECT_SET(`Year`) AS `Most Consistent Salesperson of`
    FROM
        employee_performance
    WHERE
        `Consistency Rank` = 1
    GROUP BY
        `Employee`) Most_Consistent ON Best_Sales.`Employee` = Most_Consistent.`Employee`
);
