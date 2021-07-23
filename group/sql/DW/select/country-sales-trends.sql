USE MusicStoreFYREDW;
GO

--	Keywords:

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

DECLARE @custom_min_year SMALLINT = NULL;
DECLARE @custom_max_year SMALLINT = NULL;
DECLARE @min_year CHAR(4) = CONVERT(CHAR(4), (SELECT ISNULL(@custom_min_year, MIN([Year])) FROM TimeDIM));
DECLARE @max_year CHAR(4) = CONVERT(CHAR(4), (SELECT ISNULL(IIF(@custom_max_year > @custom_min_year, @custom_max_year, NULL), MAX([Year])) FROM TimeDIM));

EXEC ('
	SELECT
		[Country],
		[Sales (' + @min_year + ')],
		[Sales (' + @max_year + ')],
		[Growth]
	FROM
		(SELECT
			*,
			[Sales (' + @max_year + ')] - [Sales (' + @min_year + ')] AS [Growth],
			RANK() OVER (ORDER BY [Sales (' + @max_year + ')] - [Sales (' + @min_year + ')] ASC) AS [Asc Rank],
			RANK() OVER (ORDER BY [Sales (' + @max_year + ')] - [Sales (' + @min_year + ')] DESC) AS [Desc Rank]
		FROM
			(SELECT
				ISNULL(Latest_Sales.[Country], Earliest_Sales.[Country]) AS [Country],
				ISNULL(Earliest_Sales.[Sales], 0.0) AS [Sales (' + @min_year + ')],
				ISNULL(Latest_Sales.[Sales], 0.0) AS [Sales (' + @max_year + ')]
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


-- old (kept for validation purposes)
SELECT Country, [Sales (2009)], [Sales (2013)], Growth
FROM (
SELECT *, 
RANK() OVER (ORDER BY Growth) AS 'ASC Rank',
RANK() OVER (ORDER BY Growth DESC) AS 'DESC Rank'
FROM (
SELECT ISNULL(A.Country, B.Country) [Country], 
ISNULL([Sales (2009)], 0) [Sales (2009)], 
ISNULL([Sales (2013)], 0) [Sales (2013)],
ISNULL([Sales (2013)], 0) - ISNULL([Sales (2009)], 0) [Growth]
FROM (
SELECT T.Year, C.Country, COUNT(*) AS [Sales (2009)]
FROM MusicFact M 
INNER JOIN CustomerDIM C ON C.CustomerKey = M.CustomerKey 
INNER JOIN TimeDIM T ON T.DateKey = M.DateKey
WHERE Year = 2009
GROUP BY Country, Year) AS A
FULL JOIN (
SELECT T.Year, C.Country, COUNT(*) AS [Sales (2013)]
FROM MusicFact M 
INNER JOIN CustomerDIM C ON C.CustomerKey = M.CustomerKey 
INNER JOIN TimeDIM T ON T.DateKey = M.DateKey
WHERE Year = 2013
GROUP BY Country, Year) AS B ON A.Country = B.Country) AS S) AS S
WHERE [ASC Rank] IN (1, 2) OR [DESC Rank] IN (1, 2)

