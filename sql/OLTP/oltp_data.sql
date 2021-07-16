USE MusicStoreFYRE;
GO

DECLARE @script_directory VARCHAR(100);
SET @script_directory = 'C:\Users\ethanol\Documents\SP\Current\Data Engineering (DENG)\CA2\data\';

DECLARE @sql VARCHAR(8000);
SET @sql = '
BULK INSERT Invoice
FROM ''' + @script_directory + 'Invoice.csv''
WITH
(
    FORMAT = ''CSV'', 
    FIELDQUOTE = ''"'',
    FIRSTROW = 2,
	DATAFILETYPE = ''widechar'',
    FIELDTERMINATOR = '','',  --CSV field delimiter
    ROWTERMINATOR = ''\n'',   --Use to shift the control to next row
    TABLOCK
)

-- Artist Table
DECLARE @Artist nvarchar(max)
SELECT @Artist = BulkColumn FROM OPENROWSET(BULK ''' + @script_directory + 'Artist.json'', SINGLE_NCLOB) JSON
INSERT INTO Artist
SELECT * FROM OPENJSON(@Artist, ''$'')
WITH (
	ArtistId	int				''$.ArtistId'',
	[Name]		nvarchar(120)	''$.Name''
)

-- Album Table
BULK INSERT Album
FROM ''' + @script_directory + 'Album.csv''
WITH
(
    FORMAT = ''CSV'', 
    FIELDQUOTE = ''"'',
    FIRSTROW = 2,
	DATAFILETYPE = ''widechar'',
    FIELDTERMINATOR = ''|'',  --CSV field delimiter
    ROWTERMINATOR = ''\n'',   --Use to shift the control to next row
    TABLOCK
)

-- MediaType Table
BULK INSERT MediaType
FROM ''' + @script_directory + 'MediaType.csv''
WITH
(
    FORMAT = ''CSV'', 
    FIELDQUOTE = ''"'',
    FIRSTROW = 2,
	DATAFILETYPE = ''widechar'',
    FIELDTERMINATOR = '','',  --CSV field delimiter
    ROWTERMINATOR = ''\n'',   --Use to shift the control to next row
    TABLOCK
)

-- Genre Table
DECLARE @Genre nvarchar(max)
SELECT @Genre = BulkColumn FROM OPENROWSET(BULK ''' + @script_directory + 'Genre.json'', SINGLE_NCLOB) JSON
INSERT INTO Genre
SELECT * FROM OpenJSON(@Genre, ''$'')
WITH (
	GenreId int ''$.GenreId'',
	Name nvarchar(60) ''$.Name''
)

-- Track Table
BULK INSERT Track
FROM ''' + @script_directory + 'Track.csv''
WITH
(
    FORMAT = ''CSV'', 
	FIELDQUOTE = ''0X0FF2'',
    FIRSTROW = 2,
	DATAFILETYPE = ''widechar'',
    FIELDTERMINATOR = ''|'',  --CSV field delimiter
    ROWTERMINATOR = ''\n'',   --Use to shift the control to next row
    TABLOCK
)

-- InvoiceLine Table
BULK INSERT InvoiceLine
FROM ''' + @script_directory + 'InvoiceLine.csv''
WITH
(
    FORMAT = ''CSV'', 
    FIELDQUOTE = ''"'',
    FIRSTROW = 2,
	DATAFILETYPE = ''widechar'',
    FIELDTERMINATOR = '','',  --CSV field delimiter
    ROWTERMINATOR = ''\n'',   --Use to shift the control to next row
    TABLOCK
)

-- Insert data (Tables that require cleaning) --

------------- Playlist ---------------

-- Create temporary table
CREATE TABLE Playlist_temp (
	PlaylistId	INT				NOT NULL,	
	[Name]		NVARCHAR(120)	NOT NULL,
	PRIMARY KEY (PlaylistId)
);
--GO

-- Insert Data into Playlist table
BULK INSERT Playlist_temp
FROM ''' + @script_directory + 'Playlist.csv''
WITH
(
    FORMAT = ''CSV'', 
    FIELDQUOTE = ''"'',
    FIRSTROW = 2,
	DATAFILETYPE = ''widechar'',
    FIELDTERMINATOR = '','',
    ROWTERMINATOR = ''\n'',
    TABLOCK
);

-- Remove duplicates
WITH cte AS 
(SELECT *, ROW_NUMBER() OVER (PARTITION BY Name ORDER BY PlaylistId) Row_No FROM Playlist_temp)
DELETE FROM cte
WHERE Row_No > 1;
--GO

-- Reorder PlaylistId in ascending order
WITH CTE AS
(SELECT *, ROW_NUMBER() OVER (ORDER BY PlaylistId) AS RN FROM Playlist_temp)
UPDATE CTE SET PlaylistId = RN
--GO

-- Insert cleaned records into actual Playlist table
INSERT INTO Playlist SELECT * FROM Playlist_temp;
--GO

-- Drop temporary Playlist table
DROP TABLE Playlist_temp;
--GO

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
    FORMAT = ''CSV'', 
    FIELDQUOTE = ''"'',
    FIRSTROW = 2,
	DATAFILETYPE = ''widechar'',
    FIELDTERMINATOR = '','',
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
FORMAT = ''CSV'',
DATAFILETYPE = ''widechar'', 	-- To store unicode characters
FIRSTROW = 2,				-- First row in employee.csv is the column headers. Hence first row the contains data is second row.
FIELDTERMINATOR = '','',
ROWTERMINATOR = ''\n'')

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
	FORMAT=''CSV'',
	DATAFILETYPE=''widechar'',
	FIELDTERMINATOR=''|'',
	ROWTERMINATOR=''\n'',
	FIRSTROW=2
);

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