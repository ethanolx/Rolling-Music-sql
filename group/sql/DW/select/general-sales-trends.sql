USE MusicStoreFYREDW;
GO

--	Keywords:
--		Sales, Seasons, Trends

--	Description:
--		Compare sales with previous quarter

--	Insights:
--		

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


-- old (kept for validation purposes)
WITH RunningDiff AS
(
	SELECT
	ROW_NUMBER() OVER (ORDER BY t.Year, t.Quarter) AS RowYr,
	t.Year, t.Quarter, SUM(m.Quantity*m.UnitPrice) AS [Sales]
	FROM MusicFact m, TimeDim t
	WHERE m.DateKey = t.DateKey
	GROUP BY t.Year, t.Quarter
)
SELECT Cur.Year, Cur.Quarter, Cur.Sales, (Cur.Sales - Prev.Sales) [Cumulative Diff (Prev Quarter)],
ISNULL((Cur.Sales - Prev.Sales)/Prev.Sales, NULL)*100 [% Diff (Q)]
FROM RunningDiff Cur
LEFT OUTER JOIN RunningDiff Prev
ON Cur.RowYr = Prev.RowYr + 1
WHERE ISNULL((Cur.Sales - Prev.Sales), Cur.Sales) < 0;
