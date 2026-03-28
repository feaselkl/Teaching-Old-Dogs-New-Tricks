FROM mcr.microsoft.com/mssql/server:2025-latest

USER root

# Copy the database setup script
COPY code/data/TSQLV6.sql /usr/src/tsqlv6/TSQLV6.sql

# Copy the entrypoint script
COPY entrypoint.sh /usr/src/entrypoint.sh
RUN chmod +x /usr/src/entrypoint.sh

USER mssql

ENTRYPOINT ["/usr/src/entrypoint.sh"]
