# Teaching Old Dogs New Tricks

This is the repository for my talk entitled [Teaching Old Dogs New Tricks:  Revitalizing a SQL Server Code Base One Version at a Time](https://csmore.info/on/olddogs).

## Running with Docker

The easiest way to run the demos is with the included Dockerfile, which sets up SQL Server 2025 and loads the TSQLV6 database automatically.

### Build the image

```bash
docker build -t olddogs .
```

### Run the container

```bash
docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=YourStr0ngP@ssword" \
    -p 1433:1433 --name olddogs \
    -d olddogs
```

The TSQLV6 database will be loaded automatically on first startup. Connect to `localhost,1433` with your preferred SQL client using the `sa` login and the password you specified.

### Environment variables

| Variable | Required | Description |
|---|---|---|
| `ACCEPT_EULA` | Yes | Set to `Y` to accept the SQL Server license agreement. |
| `MSSQL_SA_PASSWORD` | Yes | SA password. Must be 8+ characters with 3 of 4 character types (upper, lower, digit, symbol). |
| `MSSQL_PID` | No | SQL Server edition. Defaults to `Developer`. |

## Database Requirements (without Docker)

This code repository uses a modified version of the [TSQLV6](https://itziktsql.com/r-downloads) database for demos.  You will need to have a copy of it to run the scripts.  Additional tables are created by the `code/data/TSQLV6.sql` script.
