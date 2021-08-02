# Rolling Music

Class: DAAA/FT/2A/03

Team: FYRE

Members:
|   Name            |   Register    |   Admin Number    |
|-------------------|---------------|-------------------|
|   Fleming Siow    |   03          |   2011828         |
|   Pek Yi Chern    |   14          |   2012184         |
|   Rachel Tan      |   02          |   2011802         |
|   Ethan Tan       |   10          |   2012085         |

## File Structure

```
FYRE ---- data ---- Album.csv
      |         |-- Artist.json
      |         |-- Customer.csv
      |         |-- Employee.csv
      |         |-- Genre.json
      |         |-- Invoice.csv
      |         |-- InvoiceLine.csv
      |         |-- MediaType.csv
      |         |-- Playlist.csv
      |         |-- PlaylistTrack.csv
      |         `-- Track.csv
      |
      |-- doc ---- documentation.docx
      |        |-- dw-erd.png
      |        `-- presentation.pptx
      |
      |-- sql ---- DW ---- init ---- dw_dim_data.sql
      |        |       |         |-- dw_fact_data.sql
      |        |       |         |-- dw_init.sql
      |        |       |         `-- dw_time_dim_data.sql
      |        |       |
      |        |       `-- select ---- best-selling-artists-for-most-popular-genres.sql
      |        |                   |-- employee-performance-by-customer-nationality.sql
      |        |                   |-- sales-distributions-by-genre-and-quarter.sql
      |        |                   |-- year-on-year-comparison-of-sales-by-quarter.sql
      |        |                   `-- yearly-comparison-of-sales-growth-by-country.sql
      |        |
      |        `-- OLTP ---- oltp_data.sql
      |                  `-- oltp_init.sql
      |
      `-- README.md
```

## Setup

### OLTP Database

1.  Run `sql/OLTP/oltp_init.sql`
2.  Modify `@data_directory` in `sql/OLTP/oltp_data.sql` to indicate directory of data files
3.  Run `sql/OLTP/oltp_data.sql`

### OLAP Database / Data Warehouse

1.  Run `sql/DW/init/dw_init.sql`
2.  Run `sql/DW/init/dw_dim_data.sql` and `sql/DW/init/dw_time_dim_data.sql`
3.  Run `sql/DW/init/dw_fact_data.sql`

## Documentation

For further detail, please refer to:
1.  `doc/documentation.docx` for the full documentation, or
2.  `doc/dw-erd.png` for the Data Warehouse schema, or
3.  `doc/presentation.pptx` for the presentation slides

## Queries

The 5 insightful SELECT queries can be found in `sql/DW/select`.

## Credits

Equal credit goes to each of the members in this group.

We would also like to thank Mr Steven Ng for his help and guidance throughout this project.
