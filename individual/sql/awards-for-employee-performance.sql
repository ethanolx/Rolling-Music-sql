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
        `Sales Rank` = 1
            OR
        `Consistency Rank` = 1
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