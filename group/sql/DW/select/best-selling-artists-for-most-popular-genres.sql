--  File Name:
--      best-selling-artists-for-most-popular-genres.sql

--  Keywords:
--      Genre, Artist, Most Popular, Best-Selling

--  Description:
--      Best Selling Artists (ties are possible)
--      for each of the top x and bottom y genres
--      in terms of variability across the years

--  Insights:
--      Rock, Latin and Metal are the genres with the highest total sales.
--      Compared to Rock and Latin, the best selling artist for Metal, Metallica,
--      has the most significant contribution (34.47%) to the total sales for the Metal genre.

--  Recommendations:
--      Rolling Music Store should organise a promotional event,
--      such as offering a 10-20% discount for songs or bundle sales
--      (Buy 2 get 1 free) that belong to these artists.
--      This event would likely attract many customers into the store
--      as these are the most popular artists and genres.

--  Parameter:
--      @top_genre_count:   Select how many genres to compare (default is 3)


USE MusicStoreDWFYRE;
GO

-- parameter --
DECLARE @top_genre_count TINYINT = 3;
-- parameter --

SELECT
    TOP (@top_genre_count)
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