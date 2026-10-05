BACKUP DATABASE OlimpiadasDB
TO DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\Backup\OlimpiadasDB_Fase2_Limpia.bak'
WITH FORMAT, INIT,
     NAME = N'OlimpiadasDB Limpia Fase 2',
     COMPRESSION,
     STATS = 10;
GO