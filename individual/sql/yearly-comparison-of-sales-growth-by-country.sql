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