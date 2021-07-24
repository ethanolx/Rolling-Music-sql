-- RUN using <master> database --

/*
WARNING:
	- ALL data in MusicStoreFYRE will be erased
	- This is a potentially irreversible action
*/

-- Database Initialisation --
DROP DATABASE IF EXISTS MusicStoreFYRE;
GO

CREATE DATABASE MusicStoreFYRE;
GO

USE MusicStoreFYRE;
GO

-- Employee Table --
CREATE TABLE Employee (
	EmployeeId	INT				NOT NULL,
	LastName	NVARCHAR(20)	NOT NULL,
	FirstName	NVARCHAR(20)	NOT NULL,
	Title		NVARCHAR(30)	NOT NULL,
	ReportsTo	INT				NULL,
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
    FOREIGN KEY (ReportsTo) REFERENCES Employee (EmployeeId) ON DELETE NO ACTION,
    CONSTRAINT InvalidBirthYear CHECK (YEAR(BirthDate) BETWEEN 1900 AND YEAR(GETDATE()) - 10), -- Customer at least 10 y.o.
    CONSTRAINT InvalidHireDate CHECK (HireDate > BirthDate), -- Hired after born
    CONSTRAINT InvalidEmpEmail CHECK (Email LIKE '%_@_%') -- Valid email format, at least 3 characters
);
GO

-- Customer Table --
CREATE TABLE Customer (
	CustomerId	INT				NOT NULL,
	FirstName	NVARCHAR(20)	NOT NULL,
	LastName	NVARCHAR(20)	NOT NULL,
	Company		NVARCHAR(80)	NULL,
	[Address]	NVARCHAR(70)	NOT NULL,
	City		NVARCHAR(40)	NOT NULL,
	[State]		NVARCHAR(40)	NULL,
	Country		NVARCHAR(40)	NOT NULL,
	PostalCode	NVARCHAR(10)	NULL,
	Phone		NVARCHAR(24)	NULL,
	Fax			NVARCHAR(24)	NULL,
	Email		NVARCHAR(60)	NOT NULL,
	SupportRepId	INT			NOT NULL,
	PRIMARY KEY (CustomerId),
    FOREIGN KEY (SupportRepId) REFERENCES Employee (EmployeeId) ON DELETE CASCADE,
    CONSTRAINT InvalidCustEmail CHECK (Email LIKE '%_@_%') -- Valid email format
);
GO

-- Invoice Table --
CREATE TABLE Invoice (
	InvoiceId	INT			NOT NULL,
	CustomerId	INT			NOT NULL,
	InvoiceDate	DATE		NOT NULL,
	PRIMARY KEY (InvoiceId),
    FOREIGN KEY (CustomerId) REFERENCES Customer (CustomerId) ON DELETE CASCADE,
    CONSTRAINT InvalidInvoiceDate CHECK (InvoiceDate < GETDATE()) -- Transaction occurred before present
);
GO

-- Artist Table --
CREATE TABLE Artist (
	ArtistId	INT				NOT NULL,
	[Name]		NVARCHAR(120)	NOT NULL,
	PRIMARY KEY (ArtistId)
);
GO

-- Album Table --
CREATE TABLE Album (
	AlbumId		INT				NOT NULL,
	Title		NVARCHAR(160)	NOT NULL,
	ArtistId	INT				NOT NULL,
	PRIMARY KEY (AlbumId),
    FOREIGN KEY (ArtistId) REFERENCES Artist (ArtistId) ON DELETE CASCADE
);
GO

-- MediaType Table --
CREATE TABLE MediaType (
	MediaTypeId	INT				NOT NULL,
	[Name]		NVARCHAR(60)	NOT NULL,
	PRIMARY KEY (MediaTypeId)
);
GO

-- Genre Table --
CREATE TABLE Genre (
	GenreId		INT				NOT NULL,
	[Name]		NVARCHAR(60)	NOT NULL,
	PRIMARY KEY (GenreId)
);
GO

-- Track Table --
CREATE TABLE Track (
	TrackId			INT				NOT NULL,
	[Name]			NVARCHAR(160)	NOT NULL,
	AlbumId			INT				NOT NULL,
	MediaTypeId		INT				NOT NULL,
	GenreId			INT				NOT NULL,
	Composer		NVARCHAR(220)	NULL,
	Milliseconds	INT				NOT NULL,
	Bytes			INT				NOT NULL,
	UnitPrice		DECIMAL(5, 2)	NOT NULL,
	PRIMARY KEY (TrackId),
    FOREIGN KEY (AlbumId) REFERENCES Album (AlbumId) ON DELETE NO ACTION,
    FOREIGN KEY (MediaTypeId) REFERENCES MediaType (MediaTypeId) ON DELETE NO ACTION,
    FOREIGN KEY (GenreId) REFERENCES Genre (GenreId) ON DELETE NO ACTION,
	CONSTRAINT InvalidTrackDuration CHECK (Milliseconds >= 10000), -- Track at least 10s long
	CONSTRAINT InvalidTrackSize CHECK (Bytes < 1000000000) -- Track less than 1GB
);
GO

-- Playlist Table --
CREATE TABLE Playlist (
	PlaylistId	INT				NOT NULL,	
	[Name]		NVARCHAR(120)	NOT NULL,
	PRIMARY KEY (PlaylistId)
);
GO

-- PlaylistTrack Table --
CREATE TABLE PlaylistTrack (
	PlaylistId	INT		NOT NULL,
	TrackId		INT		NOT NULL,
	PRIMARY KEY (PlaylistId, TrackId),
    FOREIGN KEY (PlaylistId) REFERENCES Playlist (PlaylistId) ON DELETE CASCADE,
    FOREIGN KEY (TrackId) REFERENCES Track (TrackId) ON DELETE CASCADE
);
GO

-- InvoiceLine Table
CREATE TABLE InvoiceLine (
	InvoiceLineId	INT				NOT NULL,
	InvoiceId		INT				NOT NULL,
	TrackId			INT				NOT NULL,
	UnitPrice		DECIMAL(5, 2)	NOT NULL,
	Quantity		INT				NOT NULL,
	PRIMARY KEY (InvoiceLineId),
    FOREIGN KEY (InvoiceId) REFERENCES Invoice (InvoiceId) ON DELETE CASCADE,
    FOREIGN KEY (TrackId) REFERENCES Track (TrackId) ON DELETE CASCADE,
	CONSTRAINT InvalidQuantity CHECK (Quantity < 1000000000) -- Quantity less than 1 Billion
);
GO
