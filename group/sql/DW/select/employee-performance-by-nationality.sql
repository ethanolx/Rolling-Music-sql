USE MusicStoreFYREDW;
GO

-- Keywords: s

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

-- old (kept for validation purposes)
SELECT
	A.[Employee Name],
	[Sales (Non-local)] + [Sales (Local)] AS 'Total Sales',
	[Sales (Non-local)], [Sales (Local)],
	CAST(CAST([Sales (Non-local)] AS DECIMAL(5, 2)) / CAST(([Sales (Non-local)] + [Sales (Local)]) AS DECIMAL(5, 2)) * 100 AS decimal(5, 2)) 
AS 'Percentange Non-local'
FROM
	(SELECT
		CONCAT(E.FirstName + ' ', E.LastName) AS [Employee Name],
		Count(*) AS 'Sales (Local)'
	FROM
		MusicFact M
			INNER JOIN
		EmployeeDIM E ON M.EmployeeKey = E.EmployeeKey
			INNER JOIN
		CustomerDIM C ON M.CustomerKey = C.CustomerKey
	WHERE Country = 'Canada'
GROUP BY CONCAT(E.FirstName + ' ', E.LastName)) AS A
LEFT JOIN (
SELECT CONCAT(E.FirstName + ' ', E.LastName) AS [Employee Name], Count(*) AS 'Sales (Non-local)'
FROM MusicFact M 
INNER JOIN EmployeeDIM E ON M.EmployeeKey = E.EmployeeKey
INNER JOIN CustomerDIM C ON M.CustomerKey = C.CustomerKey
WHERE Country != 'Canada'
GROUP BY CONCAT(E.FirstName + ' ', E.LastName)) AS B
ON A.[Employee Name] = B.[Employee Name]
ORDER BY 2 DESC