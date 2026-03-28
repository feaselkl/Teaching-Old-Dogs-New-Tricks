#!/bin/bash

# Start SQL Server in the background
/opt/mssql/bin/sqlservr &
MSSQL_PID=$!

# Wait for SQL Server to be ready
echo "Waiting for SQL Server to start..."
for i in {1..60}; do
    /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -Q "SELECT 1" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "SQL Server is ready."
        break
    fi
    sleep 1
done

# Run the TSQLV6 setup script
echo "Loading TSQLV6 database..."
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -i /usr/src/tsqlv6/TSQLV6.sql
echo "TSQLV6 database loaded."

# Keep SQL Server running in the foreground
wait $MSSQL_PID
