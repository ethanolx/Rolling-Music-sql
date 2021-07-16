USE MusicStoreFYREDW;
GO

--Which customers are the most loyal/bought the most CD’s?

SELECT
	CustomerKey,
	[Quarter],
	AVG([CDs Purchased]) 'Avg No. Of CDs Purchased each quarter (that one actly bought)',
	AVG([CDs Purchased]) - LAG(AVG([CDs Purchased]), 1, AVG([CDs Purchased])) OVER (ORDER BY CustomerKey, [Quarter])
FROM
	(SELECT
		c.CustomerKey,
		t.[Quarter],
		t.[Year],
		SUM(m.Quantity) 'CDs Purchased'
	FROM
		MusicFact m
			INNER JOIN
		CustomerDIM c ON m.CustomerKey = c.CustomerKey
			INNER JOIN
		TimeDIM t ON m.DateKey = t.DateKey
	GROUP BY
		t.[Year], c.CustomerKey, t.[Quarter]) p
GROUP BY
	CustomerKey, [Quarter]
ORDER BY
	CustomerKey, [Quarter];