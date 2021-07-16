USE MusicStoreFYREDW;
GO

--	Which day of the week performs the best (most transactions) on average?
--	(Recommendation would be to allocate more manpower during those days?)

--CREATE OR ALTER VIEW DayWithMostTransactions AS

SELECT
	DayOfWkName,
	[Mean Number of Transactions]
FROM
	(SELECT
		DayOfWkName,
		DayOfWkNo,
		AVG(t.[Number of Transactions]) 'Mean Number of Transactions',
		RANK() OVER (ORDER BY AVG(t.[Number of Transactions]) DESC) 'Rank'
	FROM
		(SELECT
			TimeDIM.DayOfWkName,
			TimeDIM.DayOfWkNo,
			SUM(Quantity) 'Number of Transactions'
		FROM
			MusicFact
				INNER JOIN
			TimeDIM ON MusicFact.DateKey = TimeDIM.DateKey
		GROUP BY
			TimeDIM.DateKey,
			TimeDIM.DayOfWkName,
			TimeDIM.DayOfWkNo) t
	GROUP BY
		DayOfWkName,
		DayOfWkNo) s
WHERE
	[Rank] = 1
ORDER BY
	[Mean Number of Transactions] DESC,
	DayOfWkNo;