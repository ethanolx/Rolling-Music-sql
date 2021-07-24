USE MusicStoreFYRE;
GO

DECLARE @script_directory VARCHAR(100);
SET @script_directory = 'C:\Users\ethanol\Documents\SP\Current\Data Engineering (DENG)\CA2\data\';

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
GO

-- Artist Table
DECLARE @Artist NVARCHAR(MAX) =
	BulkColumn
FROM
	OPENROWSET(BULK ''' + @script_directory + 'Artist.json'', SINGLE_NCLOB) JSON;

INSERT INTO Artist
SELECT * FROM OPENJSON(@Artist, ''$'')
WITH (
	ArtistId	int				''$.ArtistId'',
	[Name]		nvarchar(120)	''$.Name''
);
GO

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
GO

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
GO

-- Genre Table
DECLARE @Genre NVARCHAR(MAX) = 
	BulkColumn
FROM
	OPENROWSET(BULK ''' + @script_directory + 'Genre.json'', SINGLE_NCLOB) JSON;

INSERT INTO Genre
SELECT * FROM OpenJSON(@Genre, ''$'')
WITH (
	GenreId int ''$.GenreId'',
	Name nvarchar(60) ''$.Name''
);
GO

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
GO

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
GO

--   tables that require cleaning   --

------------- Playlist ---------------

-- create temporary table

CREATE TABLE Playlist_temp (
	PlaylistId	INT				NOT NULL,	
	[Name]		NVARCHAR(120)	NOT NULL,
	PRIMARY KEY (PlaylistId)
);
GO

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
GO

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

-- Create temporary table
CREATE TABLE PlaylistTrack_temp (
	PlaylistId	INT		NOT NULL,
	TrackId		INT		NOT NULL
);
--GO

-- Insert records into PlaylistTrack
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
--GO

-- Update PlaylistId according to the new Playlist table
UPDATE PlaylistTrack_temp
SET PlaylistId = 
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
WHERE PlaylistId IN (8, 7, 10, 6, 9, 11, 12, 13, 14, 15, 16, 17, 18);
--GO

-- Remove duplicated values
WITH ctept AS
(SELECT *, ROW_NUMBER() OVER (PARTITION BY PlaylistId, TrackId ORDER BY PlaylistId, TrackId) Row_No FROM PlaylistTrack_temp)
DELETE FROM ctept
WHERE Row_No > 1;
--GO

-- Insert cleaned records into actual PlaylistTrack table
INSERT INTO PlaylistTrack SELECT * FROM PlaylistTrack_temp;
--GO

-- Drop temporary PlaylistTrack table
DROP TABLE PlaylistTrack_temp;
--GO

------------- Employee ---------------

-- Create temporary table
CREATE TABLE Employee_temp (
	EmployeeId	INT				NOT NULL,
	LastName	NVARCHAR(20)	NOT NULL,
	FirstName	NVARCHAR(20)	NOT NULL,
	Title		NVARCHAR(30)	NOT NULL,
	ReportsTo	INT				NULL
		CONSTRAINT Fk_ReportsTo
		REFERENCES Employee_temp(EmployeeId) ON DELETE NO ACTION,
	BirthDate	DATETIME		NOT NULL,
	HireDate	DATETIME		NOT NULL,
	[Address]	NVARCHAR(70)	NOT NULL,
	City		NVARCHAR(40)	NOT NULL,
	[State]		NVARCHAR(40)	NOT NULL,	
	Country		NVARCHAR(40)	NOT NULL,
	PostalCode	NVARCHAR(10)	NOT NULL,
	Phone		NVARCHAR(24)	NOT NULL,
	Fax			NVARCHAR(24)	NOT NULL,
	Email		NVARCHAR(60)	NOT NULL,
	PRIMARY KEY (EmployeeId),
    CONSTRAINT InvalidBirthYear_temp CHECK (YEAR(BirthDate) BETWEEN 1900 AND YEAR(GETDATE()) - 10), -- Customer at least 10 y.o.
    CONSTRAINT InvalidHireDate_temp CHECK (HireDate > BirthDate), -- Hired after born
    CONSTRAINT InvalidEmpEmail_temp CHECK (Email LIKE ''%_@_%'') -- Valid email format, at least 3 characters
);
--GO

-- Insert Data into Employee table
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
GO

-- Correcting Data Inconsistency in Phone and Fax
UPDATE Employee_temp
SET Phone = CONCAT(''+'', Phone), Fax = CONCAT(''+'', Fax)
WHERE EmployeeId = 5

-- Insert cleaned records into actual Employee table
INSERT INTO Employee SELECT * FROM Employee_temp;
--GO

-- Drop temporary Employee table
ALTER TABLE Employee_temp
DROP CONSTRAINT FK_ReportsTo

DROP TABLE Employee_temp;
--GO

------------- Customer ---------------

-- Create temporary table
CREATE TABLE Customer_tmp (
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
--GO

-- Insert Data into Customer table
BULK INSERT
	Customer_tmp
FROM
	''' + @script_directory + 'Customer.csv''
WITH (
	FIELDTERMINATOR = ''|'',
    FORMAT = ''CSV'', 
    FIELDQUOTE = ''"'',
    FIRSTROW = 2,
	DATAFILETYPE = ''widechar'',
    ROWTERMINATOR = ''\n'',
    TABLOCK
);
GO

-- Insert cleaned records into actual Customer table
INSERT INTO
	Customer 
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
	Customer_tmp;


-- Drop temporary Customer table
DROP TABLE Customer_tmp;
';

EXEC (@sql)