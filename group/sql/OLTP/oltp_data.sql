--  File Name:
--      oltp_data.sql

--  Run Order:
--      After:  oltp_init.sql

--	Keywords:
--      Load Data, CSV Files, OLTP Database

--	Description:
--      Load Data from CSV files into
--      1)  MusicStoreFYRE..Invoice
--      2)  MusicStoreFYRE..Artist
--      3)  MusicStoreFYRE..Album
--      4)  MusicStoreFYRE..MediaType
--      5)  MusicStoreFYRE..Genre
--      6)  MusicStoreFYRE..Track
--      7)  MusicStoreFYRE..InvoiceLine
--      8)  MusicStoreFYRE..Playlist
--      9)  MusicStoreFYRE..PlaylistTrack
--      10) MusicStoreFYRE..Employee
--      11) MusicStoreFYRE..Customer


USE MusicStoreFYRE;
GO

DECLARE @script_directory VARCHAR(100);
SET @script_directory = 'C:\\data\';

DECLARE @sql VARCHAR(MAX) = '

--   tables that do not require cleaning   --

-- Invoice Table
BULK INSERT Invoice
FROM ''' + @script_directory + 'Invoice.csv''
WITH
(
	FIELDTERMINATOR = '','',
    FORMAT = ''CSV'',
    FIELDQUOTE = ''"'',
    FIRSTROW = 2,
	DATAFILETYPE = ''widechar'',
    ROWTERMINATOR = ''\n'',
    TABLOCK
);

-- Artist Table
DECLARE @Artist NVARCHAR(MAX);
SELECT @Artist = BULKCOLUMN FROM OPENROWSET(BULK ''' + @script_directory + 'Artist.json'', SINGLE_NCLOB) JSON;

INSERT INTO Artist SELECT * FROM OPENJSON(@Artist, ''$'') WITH (
	ArtistId	INT				''$.ArtistId'',
	[Name]		NVARCHAR(120)	''$.Name''
);

-- Album Table
BULK INSERT Album
FROM ''' + @script_directory + 'Album.csv''
WITH
(
    FIELDTERMINATOR = ''|'',
    FORMAT = ''CSV'',
    FIELDQUOTE = ''"'',
    FIRSTROW = 2,
	DATAFILETYPE = ''widechar'',
    ROWTERMINATOR = ''\n'',
    TABLOCK
);

-- MediaType Table
BULK INSERT MediaType
FROM ''' + @script_directory + 'MediaType.csv''
WITH
(
    FIELDTERMINATOR = '','',
    FORMAT = ''CSV'',
    FIELDQUOTE = ''"'',
    FIRSTROW = 2,
	DATAFILETYPE = ''widechar'',
    ROWTERMINATOR = ''\n'',
    TABLOCK
);

-- Genre Table
DECLARE @Genre NVARCHAR(MAX);
SELECT @Genre = BULKCOLUMN FROM OPENROWSET(BULK ''' + @script_directory + 'Genre.json'', SINGLE_NCLOB) JSON;

INSERT INTO Genre
SELECT * FROM OPENJSON(@Genre, ''$'')
WITH (
	GenreId INT ''$.GenreId'',
	Name NVARCHAR(60) ''$.Name''
);


-- Track Table
BULK INSERT Track
FROM ''' + @script_directory + 'Track.csv''
WITH
(
	FIELDTERMINATOR = ''|'',
    FORMAT = ''CSV'',
    FIELDQUOTE = ''0X0FF2'',
    FIRSTROW = 2,
	DATAFILETYPE = ''widechar'',
    ROWTERMINATOR = ''\n'',
    TABLOCK
);

-- InvoiceLine Table
BULK INSERT InvoiceLine
FROM ''' + @script_directory + 'InvoiceLine.csv''
WITH
(
    FIELDTERMINATOR = '','',
    FORMAT = ''CSV'',
    FIELDQUOTE = ''"'',
    FIRSTROW = 2,
	DATAFILETYPE = ''widechar'',
    ROWTERMINATOR = ''\n'',
    TABLOCK
);


--   tables that require cleaning   --

------------- Playlist ---------------

-- create temporary table

CREATE TABLE Playlist_temp (
	PlaylistId	INT				NOT NULL,
	[Name]		NVARCHAR(120)	NOT NULL
);


-- load data into temporary table

BULK INSERT Playlist_temp
FROM ''' + @script_directory + 'Playlist.csv''
WITH
(
    FIELDTERMINATOR = '','',
    FORMAT = ''CSV'',
    FIELDQUOTE = ''"'',
    FIRSTROW = 2,
	DATAFILETYPE = ''widechar'',
    ROWTERMINATOR = ''\n'',
    TABLOCK
);

-- remove duplicates

WITH cte AS
	(SELECT
		*,
		ROW_NUMBER() OVER (PARTITION BY Name ORDER BY PlaylistId) AS Row_No
	FROM
		Playlist_temp)
DELETE FROM
	cte
WHERE
	Row_No > 1;

-- reorder PlaylistId in ascending order

WITH CTE AS
	(SELECT
		*,
		ROW_NUMBER() OVER (ORDER BY PlaylistId) AS RN
	FROM Playlist_temp)
UPDATE
	CTE
SET PlaylistId = RN

-- insert cleaned records into actual Playlist table

INSERT INTO
	Playlist
SELECT
	*
FROM
	Playlist_temp;

-- drop temporary Playlist table

DROP TABLE Playlist_temp;


------------- PlaylistTrack ---------------

-- create temporary table

USE tempdb;

CREATE TABLE PlaylistTrack_temp (
	PlaylistId	INT		NOT NULL,
	TrackId		INT		NOT NULL
);

-- insert records into PlaylistTrack

BULK INSERT PlaylistTrack_temp
FROM ''' + @script_directory + 'PlaylistTrack.csv''
WITH
(
    FIELDTERMINATOR = '','',
    FORMAT = ''CSV'',
    FIELDQUOTE = ''"'',
    FIRSTROW = 2,
	DATAFILETYPE = ''widechar'',
    ROWTERMINATOR = ''\n'',
    TABLOCK
)

-- update PlaylistId according to the new Playlist table

UPDATE
	PlaylistTrack_temp
SET
	PlaylistId =
		CASE PlaylistId
			WHEN 8 THEN 1
			WHEN 7 THEN 2
			WHEN 10 THEN 3
			WHEN 6 THEN 4
			WHEN 9 THEN 6
			WHEN 11 THEN 7
			WHEN 12 THEN 8
			WHEN 13 THEN 9
			WHEN 14 THEN 10
			WHEN 15 THEN 11
			WHEN 16 THEN 12
			WHEN 17 THEN 13
			WHEN 18 THEN 14
		END
WHERE
	PlaylistId IN (8, 7, 10, 6, 9, 11, 12, 13, 14, 15, 16, 17, 18);

-- remove duplicates

WITH ctept AS
	(SELECT
		*,
		ROW_NUMBER() OVER (PARTITION BY PlaylistId, TrackId ORDER BY PlaylistId, TrackId) AS Row_No
	FROM
		PlaylistTrack_temp)
DELETE FROM
	ctept
WHERE
	Row_No > 1;

-- insert cleaned records into actual PlaylistTrack table

INSERT INTO MusicStoreFYRE..PlaylistTrack SELECT * FROM tempdb..PlaylistTrack_temp;

-- drop temporary PlaylistTrack table

DROP TABLE tempdb..PlaylistTrack_temp;


------------- Employee ---------------

-- create temporary Employee table

USE tempdb;

CREATE TABLE Employee_temp (
	EmployeeId	INT				NOT NULL,
	LastName	NVARCHAR(20)	NOT NULL,
	FirstName	NVARCHAR(20)	NOT NULL,
	Title		NVARCHAR(30)	NOT NULL,
	ReportsTo	INT				NULL,
	BirthDate	DATE			NOT NULL,
	HireDate	DATE			NOT NULL,
	[Address]	NVARCHAR(70)	NOT NULL,
	City		NVARCHAR(40)	NOT NULL,
	[State]		NVARCHAR(40)	NOT NULL,
	Country		NVARCHAR(40)	NOT NULL,
	PostalCode	NVARCHAR(10)	NOT NULL,
	Phone		NVARCHAR(24)	NOT NULL,
	Fax			NVARCHAR(24)	NOT NULL,
	Email		NVARCHAR(60)	NOT NULL,
);

-- insert data into Employee table

BULK INSERT Employee_temp
FROM ''' + @script_directory + 'Employee.csv''
WITH (
	FIELDTERMINATOR = '','',
    FORMAT = ''CSV'',
    FIELDQUOTE = ''"'',
    FIRSTROW = 2,
	DATAFILETYPE = ''widechar'',
    ROWTERMINATOR = ''\n'',
    TABLOCK
);

-- correct data inconsistency in Phone and Fax

UPDATE
	Employee_temp
SET
	Phone = CONCAT(''+'', Phone),
	Fax = CONCAT(''+'', Fax)
WHERE
	EmployeeId = 5

-- insert cleaned records into actual Employee table

INSERT INTO MusicStoreFYRE..Employee SELECT * FROM tempdb..Employee_temp;

-- drop temporary Employee table

DROP TABLE tempdb..Employee_temp;


------------- Customer ---------------

-- create temporary Customer table

USE tempdb;

CREATE TABLE Customer_temp (
	CustomerId	INT,
	FirstName	NVARCHAR(20),
	LastName	NVARCHAR(20),
	Company		NVARCHAR(80),
	[Address]	NVARCHAR(70),
	City		NVARCHAR(40),
	[State]		NVARCHAR(40),
	Country		NVARCHAR(40),
	PostalCode	NVARCHAR(10),
	Phone		NVARCHAR(24),
	Fax			NVARCHAR(24),
	Email		NVARCHAR(60),
	SupportRepId	INT
);


-- insert data into temporary Customer table

BULK INSERT Customer_temp
FROM ''' + @script_directory + 'Customer.csv''
WITH (
	FIELDTERMINATOR = ''|'',
    FORMAT = ''CSV'',
    FIELDQUOTE = ''"'',
    FIRSTROW = 2,
	DATAFILETYPE = ''widechar'',
    ROWTERMINATOR = ''\n'',
    TABLOCK
);

-- insert cleaned records into actual Customer table

INSERT INTO
	MusicStoreFYRE..Customer
SELECT
	CustomerId,
	FirstName,
	LastName,
	Company,
	[Address],
	City,
	[State],
	IIF(Country = ''USA'', ''United States'', Country) ''Country'',
	PostalCode,
	Phone,
	Fax,
	Email,
	SupportRepId
FROM
	tempdb..Customer_temp;


-- drop temporary Customer table

DROP TABLE tempdb..Customer_temp;
';

EXEC (@sql);
GO