USE MusicStoreFYREDW;
GO

--Which customers are the most loyal/bought the most CD’s?

SELECT
	c.FirstName + ' ' + c.LastName 'Customer Name',
	SUM([CDs Purchased]) 'Total CDs Bought',
	DATEDIFF(DAY, MIN([Date]), MAX([Date])) 'Number of Days Loyal'
FROM
	(SELECT
		c.CustomerKey,
		--t.[Quarter],
		t.[Date],
		SUM(m.Quantity) 'CDs Purchased'
	FROM
		MusicFact m
			INNER JOIN
		CustomerDIM c ON m.CustomerKey = c.CustomerKey
			INNER JOIN
		TimeDIM t ON m.DateKey = t.DateKey
	GROUP BY
		t.[Date], c.CustomerKey) p
		INNER JOIN
	CustomerDIM c ON p.CustomerKey = c.CustomerKey
GROUP BY
	c.CustomerKey, c.FirstName, c.LastName
ORDER BY
	[Total CDs Bought] DESC,
	[Number of Days Loyal] DESC;