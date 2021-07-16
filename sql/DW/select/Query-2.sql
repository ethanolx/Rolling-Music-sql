USE MusicStoreFYREDW;
GO

--What is the running difference of the sales since the start of the business?

SELECT
	[Year],
	[Quarter],
	[Sales],
	[Sales] - LAG([Sales], 1, [Sales]) OVER (ORDER BY [Year], [Quarter]) 'Cumulative Difference',
	([Sales] - LAG([Sales], 1, [Sales]) OVER (ORDER BY [Year], [Quarter])) / LAG([Sales], 1, [Sales]) OVER (ORDER BY [Year], [Quarter]) * 100 'Percentage Change'
FROM
	(SELECT
		[Year],
		[Quarter],
		SUM(UnitPrice * Quantity) 'Sales'
	FROM
		MusicFact
			INNER JOIN
		TimeDIM ON MusicFact.DateKey = TimeDIM.DateKey
	GROUP BY
		[Year],
		[Quarter]) s
ORDER BY
	[Year],
	[Quarter];