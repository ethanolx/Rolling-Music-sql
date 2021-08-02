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