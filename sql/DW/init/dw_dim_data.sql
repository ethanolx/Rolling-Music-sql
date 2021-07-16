-- EmployeeDIM
INSERT INTO	
	MusicStoreFYREDW..EmployeeDIM(
	EmployeeKey, 
	FirstName, 
	LastName,
	Title,
	BirthDate,
	HireDate)
SELECT
	EmployeeId, 
	FirstName, 
	LastName,
	Title,
	BirthDate,
	HireDate
FROM 
	MusicStoreFYRE..Employee

-- CustomerDIM
INSERT INTO 
	MusicStoreFYREDW..CustomerDIM(
	CustomerKey,
	FirstName,
	LastName,
	Company,
	[Address],
	City,
	[State],
	Country,
	PostalCode)
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
	MusicStoreFYRE..Customer

-- TrackDIM
INSERT INTO 
	MusicStoreFYREDW..TrackDIM(
	TrackKey,
	TrackName,
	MediaType,
	Genre,
	Composer,
	Duration_ms,
	Size_bytes,
	Album,
	Artist)
SELECT
	t.TrackId, t.Name, m.Name,
	g.Name, t.Composer, t.Milliseconds,
	t.Bytes, al.Title, ar.Name
FROM
	MusicStoreFYRE..Track t, 
	MusicStoreFYRE..Genre g, 
	MusicStoreFYRE..MediaType m,
	MusicStoreFYRE..Album al,
	MusicStoreFYRE..Artist ar
WHERE 
	t.GenreId = g.GenreId AND 
	t.MediaTypeId = m.MediaTypeId AND
	t.AlbumId = al.AlbumId AND
	al.ArtistId = ar.ArtistId