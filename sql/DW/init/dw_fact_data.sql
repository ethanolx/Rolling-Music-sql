INSERT INTO MusicStoreFYREDW..MusicFact(
	EmployeeKey,
	CustomerKey,
	TrackKey,
	DateKey,
	UnitPrice,
	Quantity)
SELECT
	Employee.EmployeeId 'EmployeeKey',
	Customer.CustomerId 'CustomerKey',
	Track.TrackId 'TrackKey',
	CAST(CONVERT(VARCHAR(20), Invoice.InvoiceDate, 112) AS INT) 'DateKey',
	Track.UnitPrice,
	Quantity
FROM
	MusicStoreFYRE..Invoice
		INNER JOIN MusicStoreFYRE..Customer
		ON Invoice.CustomerId = Customer.CustomerId
		INNER JOIN MusicStoreFYRE..Employee
		ON Customer.SupportRepId = Employee.EmployeeId
		INNER JOIN MusicStoreFYRE..InvoiceLine
		ON Invoice.InvoiceId = InvoiceLine.InvoiceId
		INNER JOIN MusicStoreFYRE..Track
		ON InvoiceLine.TrackId = Track.TrackId;
