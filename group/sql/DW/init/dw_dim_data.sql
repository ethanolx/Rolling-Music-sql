--	File Name:
--      dw_dim_data.sql

--  Run Order:
--      Before: dw_fact_data.sql
--      After:  dw_init.sql

--	Keywords:
--      Transfer Data, Dimension Tables

--	Description:
--      Transfer Data from MusicStoreFYRE to
--      1)  MusicStoreDWFYRE..EmployeeDIM
--      2)  MusicStoreDWFYRE..CustomerDIM
--      3)  MusicStoreDWFYRE..TrackDIM


-- EmployeeDIM
INSERT INTO
	MusicStoreDWFYRE..EmployeeDIM (
		EmployeeKey,
		FirstName,
		LastName,
		Title,
		BirthDate,
		HireDate
	)
SELECT
	EmployeeId,
	FirstName,
	LastName,
	Title,
	BirthDate,
	HireDate
FROM
	MusicStoreFYRE..Employee;
GO

-- CustomerDIM
INSERT INTO
	MusicStoreDWFYRE..CustomerDIM (
		CustomerKey,
		FirstName,
		LastName,
		Company,
		[Address],
		City,
		[State],
		Country,
		PostalCode
	)
SELECT
	CustomerId,
	FirstName,
	LastName,
	Company,
	[Address],
	City,
	[State],
	Country,
	PostalCode
FROM
	MusicStoreFYRE..Customer;
GO

-- TrackDIM
INSERT INTO
	MusicStoreDWFYRE..TrackDIM (
		TrackKey,
		TrackName,
		MediaType,
		Genre,
		Composer,
		Duration_ms,
		Size_bytes,
		Album,
		Artist
	)
SELECT
	Tr.TrackId,
	Tr.[Name],
	M.[Name],
	G.[Name],
	Tr.Composer,
	Tr.Milliseconds,
	Tr.Bytes,
	Al.Title,
	Ar.[Name]
FROM
	MusicStoreFYRE..Track AS Tr,
	MusicStoreFYRE..Genre AS G,
	MusicStoreFYRE..MediaType AS M,
	MusicStoreFYRE..Album AS Al,
	MusicStoreFYRE..Artist AS Ar
WHERE
	Tr.GenreId = G.GenreId
		AND
	Tr.MediaTypeId = M.MediaTypeId
		AND
	Tr.AlbumId = Al.AlbumId
		AND
	Al.ArtistId = Ar.ArtistId;
GO