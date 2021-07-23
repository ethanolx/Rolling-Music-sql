USE MusicStoreFYREDW;
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

DROP FUNCTION IF EXISTS dbo.Create_Label;
GO

CREATE FUNCTION dbo.Create_Label(@quarter INT) RETURNS VARCHAR(MAX) AS
BEGIN
	RETURN
		'Proportion (Q' + CAST(@quarter AS CHAR(1)) + ')';
END;
GO


DECLARE @q1 VARCHAR(MAX) = dbo.Get_Genre_By_Quarter(1);
DECLARE @q2 VARCHAR(MAX) = dbo.Get_Genre_By_Quarter(2);
DECLARE @q3 VARCHAR(MAX) = dbo.Get_Genre_By_Quarter(3);
DECLARE @q4 VARCHAR(MAX) = dbo.Get_Genre_By_Quarter(4);
DECLARE @total VARCHAR(MAX) = dbo.Get_Genre_By_Quarter(DEFAULT);
DECLARE @label1 VARCHAR(20) = dbo.Create_Label(1);
DECLARE @label2 VARCHAR(20) = dbo.Create_Label(2);
DECLARE @label3 VARCHAR(20) = dbo.Create_Label(3);
DECLARE @label4 VARCHAR(20) = dbo.Create_Label(4);
DECLARE @num_of_q1 VARCHAR(MAX) = dbo.Get_Total_Quarters(1);
DECLARE @num_of_q2 VARCHAR(MAX) = dbo.Get_Total_Quarters(2);
DECLARE @num_of_q3 VARCHAR(MAX) = dbo.Get_Total_Quarters(3);
DECLARE @num_of_q4 VARCHAR(MAX) = dbo.Get_Total_Quarters(4);

EXEC ('
	SELECT
		Genre,
		[' + @label1 + '],
		[' + @label2 + '],
		[' + @label3 + '],
		[' + @label4 + '],
		[Average Annual Qty],
		[Standard Deviation]
	FROM
		(SELECT
			Genre,
			[' + @label1 + '],
			[' + @label2 + '],
			[' + @label3 + '],
			[' + @label4 + '],
			[Average Annual Qty],
			[Standard Deviation],
			RANK() OVER (ORDER BY [Standard Deviation] ASC) AS ''std asc'',
			RANK() OVER (ORDER BY [Standard Deviation] DESC) AS ''std desc''
		FROM
			(SELECT
				*,
				CAST(dbo.STD_ROW([' + @label1 + '], [' + @label2 + '], [' + @label3 + '], [' + @label4 + '], 0) AS DECIMAL(4, 2)) AS [Standard Deviation]
			FROM
				(SELECT
					Genre,
					CAST([' + @label1 + '] / [Average Annual Qty] * 100.0 AS DECIMAL(5, 2)) ''' + @label1 + ''',
					CAST([' + @label2 + '] / [Average Annual Qty] * 100.0 AS DECIMAL(5, 2)) ''' + @label2 + ''',
					CAST([' + @label3 + '] / [Average Annual Qty] * 100.0 AS DECIMAL(5, 2)) ''' + @label3 + ''',
					CAST([' + @label4 + '] / [Average Annual Qty] * 100.0 AS DECIMAL(5, 2)) ''' + @label4 + ''',
					[Average Annual Qty]
				FROM
					(SELECT
						*,
						[' + @label1 + '] + [' + @label2 + '] + [' + @label3 + '] + [' + @label4 + '] AS ''Average Annual Qty''
					FROM
						(SELECT
							A.Genre AS ''Genre'',
							CAST(CAST(A.[Q1] AS FLOAT) / [Number of Q1] AS DECIMAL(5, 2)) AS [' + @label1 + '],
							CAST(CAST(B.[Q2] AS FLOAT) / [Number of Q2] AS DECIMAL(5, 2)) AS [' + @label2 + '],
							CAST(CAST(C.[Q3] AS FLOAT) / [Number of Q3] AS DECIMAL(5, 2)) AS [' + @label3 + '],
							CAST(CAST(D.[Q4] AS FLOAT) / [Number of Q4] AS DECIMAL(5, 2)) AS [' + @label4 + ']
						FROM
							(' + @q1 + ') AS A
								INNER JOIN
							(' + @q2 + ') AS B ON A.Genre = B.Genre
								INNER JOIN
							(' + @q3 + ') AS C ON B.Genre = C.Genre
								INNER JOIN
							(' + @q4 + ') AS D ON C.Genre = D.Genre,
							(' + @num_of_q1 + ') Q1_no,
							(' + @num_of_q2 + ') Q2_no,
							(' + @num_of_q3 + ') Q3_no,
							(' + @num_of_q4 + ') Q4_no
						) tmp
					) temp
				) tmp
			) temp
		) tmp
	WHERE
		[std asc] <= 3 OR [std desc] <= 3
	ORDER BY
		[Standard Deviation] DESC;'
);
GO


-- old (kept for validation purposes)
SELECT
*,
dbo.STD_ROW([% of Total (Q1)], [% of Total (Q2)], [% of Total (Q3)], [% of Total (Q4)], 0) 'Standard Deviation'
FROM (
SELECT A.Genre, CAST(CAST(A.[Sales (Quarter 1)] AS decimal(5, 2))/[Sales (Total)] * 100 AS decimal(4, 2)) AS [% of Total (Q1)], 
CAST(CAST(B.[Sales (Quarter 2)] AS decimal(5, 2))/[Sales (Total)] * 100 AS decimal(4, 2)) AS [% of Total (Q2)],
CAST(CAST(C.[Sales (Quarter 3)] AS decimal(5, 2))/[Sales (Total)] * 100 AS decimal(4, 2)) AS [% of Total (Q3)],
CAST(CAST(D.[Sales (Quarter 4)] AS decimal(5, 2))/[Sales (Total)] * 100 AS decimal(4, 2)) AS [% of Total (Q4)],
[Sales (Total)] AS 'Qty' FROM (
SELECT Tr.Genre, SUM(Quantity) AS [Sales (Quarter 1)] FROM MusicFact M, TimeDIM T, TrackDIM Tr
WHERE M.DateKey = T.DateKey AND T.Quarter = 1 AND M.TrackKey = Tr.TrackKey
GROUP BY Tr.Genre) AS A
INNER JOIN (
SELECT Tr.Genre, COUNT(*) AS [Sales (Quarter 2)] FROM MusicFact M, TimeDIM T, TrackDIM Tr
WHERE M.DateKey = T.DateKey AND T.Quarter = 2 AND M.TrackKey = Tr.TrackKey
GROUP BY Tr.Genre) AS B
ON A.Genre = B.Genre
INNER JOIN (
SELECT Tr.Genre, COUNT(*) AS [Sales (Quarter 3)] FROM MusicFact M, TimeDIM T, TrackDIM Tr
WHERE M.DateKey = T.DateKey AND T.Quarter = 3 AND M.TrackKey = Tr.TrackKey
GROUP BY Tr.Genre) AS C
ON A.Genre = C.Genre
INNER JOIN (
SELECT Tr.Genre, COUNT(*) AS [Sales (Quarter 4)] FROM MusicFact M, TimeDIM T, TrackDIM Tr
WHERE M.DateKey = T.DateKey AND T.Quarter = 4 AND M.TrackKey = Tr.TrackKey
GROUP BY Tr.Genre) AS D
ON A.Genre = D.Genre
INNER JOIN (
SELECT T.Genre, COUNT(*) AS [Sales (Total)] FROM
MusicFact M INNER JOIN TrackDIM T ON M.TrackKey = T.TrackKey
GROUP BY T.Genre) AS E
ON E.Genre = A.Genre
) s
INNER JOIN 
(SELECT
	Genre,
	[Salesperson],
	[Total Sold]
FROM(
SELECT
	Genre,
	FirstName + ' ' + LastName 'Salesperson',
	SUM(Quantity) 'Total Sold',
	RANK() OVER (PARTITION BY Genre ORDER BY SUM(Quantity) DESC) 'Rank'
FROM
	MusicFact m INNER JOIN TrackDIM tr ON m.TrackKey = tr.TrackKey INNER JOIN EmployeeDIM e ON m.EmployeeKey = e.EmployeeKey
GROUP BY
	Genre, e.FirstName, e.LastName) d WHERE [Rank] = 1) p ON s.Genre = p.Genre
ORDER BY [Standard Deviation] DESC;