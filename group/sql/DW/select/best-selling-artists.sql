USE MusicStoreFYREDW;
GO

--	Keywords:
--		Genre, Artist, Fluctuance

--	Description:
--		Best Selling Artists (ties are possible)
--		for each of the top x and bottom y genres
--		in terms of variability across the years

--	Insights:
--		U2

DECLARE @max_std_count TINYINT = 3;
DECLARE @min_std_count TINYINT = 3;
DECLARE @col VARCHAR(20) = 'Total Sales';

SELECT
	TOP (3)
	[Genre],
	[Best Selling Artist],
	[Total Sales],
	[Total Sales (this genre)],
	CAST([Proportion of Sales] AS DECIMAL(5, 2)) [Proportion of Sales / %]
FROM
	(SELECT
		Genre,
		[Best Selling Artist],
		[Total Sales],
		100.0 * [Total Sales] / SUM([Total Sales]) OVER (PARTITION BY Genre) AS [Proportion of Sales],
		SUM([Total Sales]) OVER (PARTITION BY Genre) [Total Sales (this genre)],
		[Sales Rank]
	FROM
		(SELECT
			tr.Genre,
			tr.Artist AS [Best Selling Artist],
			SUM(m.Quantity * m.UnitPrice) AS [Total Sales],
			RANK() OVER (PARTITION BY tr.Genre ORDER BY SUM(m.Quantity * m.UnitPrice) DESC) AS [Sales Rank]
		FROM
			MusicFact m
				INNER JOIN
			TrackDIM tr ON m.TrackKey = tr.TrackKey
		GROUP BY
			tr.Genre,
			tr.Artist
		) AS tmp
	) temp
WHERE
	[Sales Rank] = 1
ORDER BY
	[Total Sales (this genre)] DESC;
GO


-- old (kept for validation purposes)
SELECT Genre, Artist, [Total Sales] FROM
(
SELECT tr.Genre, tr.Artist, SUM(m.Quantity*m.UnitPrice) [Total Sales],
RANK() OVER (PARTITION BY tr.Genre ORDER BY SUM(m.Quantity*m.UnitPrice) DESC) AS [RankNo]
FROM MusicFact m
JOIN TrackDIM tr
ON m.TrackKey = tr.TrackKey
GROUP BY tr.Genre, tr.Artist
) AS FavArtist
WHERE FavArtist.RankNo = 1
AND Genre IN ('Classical', 'Sci Fi & Fantasy', 'R&B/Soul', 'Latin', 'Rock', 'Soundtrack');