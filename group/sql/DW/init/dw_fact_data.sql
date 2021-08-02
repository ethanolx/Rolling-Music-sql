--  File Name:
--      dw_fact_data.sql

--  Run Order:
--      After:  dw_init.sql, dw_dim_data.sql, dw_time_dim_data.sql

--  Keywords:
--      Transfer Data, Fact Table

--  Description:
--      Transfer Data from MusicStoreFYRE to MusicStoreDWFYRE..MusicFact


INSERT INTO
    MusicStoreDWFYRE..MusicFact (
        EmployeeKey,
        CustomerKey,
        TrackKey,
        DateKey,
        UnitPrice,
        Quantity
    )
SELECT
    EmployeeDIM.EmployeeKey AS [EmployeeKey],
    CustomerDIM.CustomerKey AS [CustomerKey],
    TrackDIM.TrackKey AS [TrackKey],
    CAST(CONVERT(VARCHAR(20), Invoice.InvoiceDate, 112) AS INT) AS [DateKey],
    Track.UnitPrice AS [UnitPrice],
    InvoiceLine.Quantity AS [DateKey]
FROM
    MusicStoreFYRE..Invoice
        INNER JOIN
    MusicStoreFYRE..Customer ON Invoice.CustomerId = Customer.CustomerId
        INNER JOIN
    MusicStoreFYRE..Employee ON Customer.SupportRepId = Employee.EmployeeId
        INNER JOIN
    MusicStoreFYRE..InvoiceLine ON Invoice.InvoiceId = InvoiceLine.InvoiceId
        INNER JOIN
    MusicStoreFYRE..Track ON InvoiceLine.TrackId = Track.TrackId
        INNER JOIN
    MusicStoreDWFYRE..CustomerDIM ON Customer.CustomerId = CustomerDIM.OLTPKey
        INNER JOIN
    MusicStoreDWFYRE..EmployeeDIM ON Employee.EmployeeId = EmployeeDIM.OLTPKey
        INNER JOIN
    MusicStoreDWFYRE..TrackDIM ON Track.TrackId = TrackDIM.OLTPKey;
GO
