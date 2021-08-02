--  File Name:
--      sales-distributions-by-genre-and-quarter.sql

--  Keywords:
--      Sales Distribution, Variation, Genre, Quarter

--  Description:
--      Analyse sales distributions over the 4 quarters of the year
--      Analyse variability in the sales distributions

--  Insights:
--      “Classical”, “Sci Fi & Fantasy” and “R&B/Soul” genres have the highest variation across the 4 quarters.

--      “Classical” had the highest sales in the 2nd and 4th quarters.

--      “Sci Fi & Fantasy” had the highest sales in the 2nd quarter.

--      “R&B/Soul” had the highest sales in the 3rd quarter.

--      Latin, Rock and Soundtrack genres have the lowest variation across the 4 quarters,
--      which implies that their sales are quite consistent.

--  Recommendations:
--      Rolling Music Store should stock up on records of the
--          - “Classical” and “Sci Fi & Fantasy” genres in the 2nd quarter
--          - “R&B/Soul” genre in the 3rd quarter
--          - “Classical” in the 4th quarter
--      To ensure sufficient inventory for sales.

--      Jackson Sam should not anticipate any violent fluctuations in Latin, Rock and Soundtrack sales.

--  Parameters:
--      @prefix:        Customize prefix for each quarter's label (default is 'Proportion (Q')
--      @postfix:       Customize postfix for each quarter's label (default is ')')
--      @top_count:     Select how many high-variability genres to view (default is 3)
--      @bottom_count:  Select how many low-variability genres to view (default is 3)


USE MusicStoreDWFYRE;
GO

DROP FUNCTION IF EXISTS dbo.STD_ROW;
GO

CREATE FUNCTION dbo.STD_ROW(@n1 FLOAT, @n2 FLOAT, @n3 FLOAT, @n4 FLOAT, @df BIT = 1) RETURNS FLOAT AS
BEGIN
    DECLARE @n INT = IIF(@df = 1, 3, 4);
    DECLARE @mean FLOAT = (@n1 + @n2 + @n3 + @n4) / 4;
    RETURN SQRT((SQUARE(@n1 - @mean) + SQUARE(@n2 - @mean) + SQUARE(@n3 - @mean) + SQUARE(@n4 - @mean)) / @n);
END;
GO

DROP FUNCTION IF EXISTS dbo.Get_Genre_By_Quarter;
GO

CREATE FUNCTION dbo.Get_Genre_By_Quarter(@quarter INT = 0) RETURNS VARCHAR(MAX) AS
BEGIN
    DECLARE @filter_condition VARCHAR(50) = IIF(@quarter = 0, '', 'WHERE t.[Quarter] = ' + CAST(@quarter AS CHAR(1)));
    DECLARE @label VARCHAR(20) = IIF(@quarter = 0, 'Total', 'Q' + CAST(@quarter AS CHAR(1)));
    RETURN
        'SELECT
            tr.Genre,
            SUM(Quantity) AS ' + @label + '
        FROM
            MusicFact m
                INNER JOIN
            TimeDIM t ON m.DateKey = t.DateKey
                INNER JOIN
            TrackDIM tr ON m.TrackKey = tr.TrackKey
        ' + @filter_condition + '
        GROUP BY
            tr.Genre'
END;
GO

DROP FUNCTION IF EXISTS dbo.Get_Total_Quarters;
GO

CREATE FUNCTION dbo.Get_Total_Quarters(@quarter INT = 0) RETURNS VARCHAR(MAX) AS
BEGIN
    DECLARE @label VARCHAR(20) = 'Number of Q' + CAST(@quarter AS CHAR(1));
    RETURN
        'SELECT
            COUNT(*) AS ''' + @label + '''
        FROM
            (SELECT
                [Year], [Quarter]
            FROM
                TimeDIM t
            WHERE
                t.[Quarter] = 1
            GROUP BY
                [Year],
                [Quarter]) tmp';
END;
GO

-- parameters --
DECLARE @prefix VARCHAR(30) = 'Proportion (Q';
DECLARE @postfix VARCHAR(10) = ')';

DECLARE @top_count TINYINT = 3;
DECLARE @bottom_count TINYINT = 3;
-- parameters --

DECLARE @q1 VARCHAR(MAX) = dbo.Get_Genre_By_Quarter(1);
DECLARE @q2 VARCHAR(MAX) = dbo.Get_Genre_By_Quarter(2);
DECLARE @q3 VARCHAR(MAX) = dbo.Get_Genre_By_Quarter(3);
DECLARE @q4 VARCHAR(MAX) = dbo.Get_Genre_By_Quarter(4);
DECLARE @num_of_q1 VARCHAR(MAX) = dbo.Get_Total_Quarters(1);
DECLARE @num_of_q2 VARCHAR(MAX) = dbo.Get_Total_Quarters(2);
DECLARE @num_of_q3 VARCHAR(MAX) = dbo.Get_Total_Quarters(3);
DECLARE @num_of_q4 VARCHAR(MAX) = dbo.Get_Total_Quarters(4);

EXEC ('
    SELECT
        Genre,
        [q1] AS [' + @prefix + '1' + @postfix + '],
        [q2] AS [' + @prefix + '2' + @postfix + '],
        [q3] AS [' + @prefix + '3' + @postfix + '],
        [q4] AS [' + @prefix + '4' + @postfix + '],
        [Average Annual Qty],
        [Standard Deviation]
    FROM
        (SELECT
            Genre,
            [q1],
            [q2],
            [q3],
            [q4],
            [Average Annual Qty],
            [Standard Deviation],
            RANK() OVER (ORDER BY [Standard Deviation] ASC) AS ''std asc'',
            RANK() OVER (ORDER BY [Standard Deviation] DESC) AS ''std desc''
        FROM
            (SELECT
                *,
                CAST(dbo.STD_ROW([q1], [q2], [q3], [q4], 0) AS DECIMAL(4, 2)) AS [Standard Deviation]
            FROM
                (SELECT
                    Genre,
                    CAST([q1] / [Average Annual Qty] * 100.0 AS DECIMAL(5, 2)) AS [q1],
                    CAST([q2] / [Average Annual Qty] * 100.0 AS DECIMAL(5, 2)) AS [q2],
                    CAST([q3] / [Average Annual Qty] * 100.0 AS DECIMAL(5, 2)) AS [q3],
                    CAST([q4] / [Average Annual Qty] * 100.0 AS DECIMAL(5, 2)) AS [q4],
                    [Average Annual Qty]
                FROM
                    (SELECT
                        *,
                        [q1] + [q2] + [q3] + [q4] AS ''Average Annual Qty''
                    FROM
                        (SELECT
                            A.Genre AS ''Genre'',
                            CAST(CAST(A.[Q1] AS FLOAT) / [Number of Q1] AS DECIMAL(5, 2)) AS [q1],
                            CAST(CAST(B.[Q2] AS FLOAT) / [Number of Q2] AS DECIMAL(5, 2)) AS [q2],
                            CAST(CAST(C.[Q3] AS FLOAT) / [Number of Q3] AS DECIMAL(5, 2)) AS [q3],
                            CAST(CAST(D.[Q4] AS FLOAT) / [Number of Q4] AS DECIMAL(5, 2)) AS [q4]
                        FROM
                            (' + @q1 + ') AS A
                                INNER JOIN
                            (' + @q2 + ') AS B ON A.Genre = B.Genre
                                INNER JOIN
                            (' + @q3 + ') AS C ON B.Genre = C.Genre
                                INNER JOIN
                            (' + @q4 + ') AS D ON C.Genre = D.Genre,
                            (' + @num_of_q1 + ') AS Q1_no,
                            (' + @num_of_q2 + ') AS Q2_no,
                            (' + @num_of_q3 + ') AS Q3_no,
                            (' + @num_of_q4 + ') AS Q4_no
                        ) tmp
                    ) temp
                ) tmp
            ) temp
        ) tmp
    WHERE
        [std asc] <= ' + @bottom_count + ' OR [std desc] <= ' + @top_count + '
    ORDER BY
        [Standard Deviation] DESC;'
);
GO