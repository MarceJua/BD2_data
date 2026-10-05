USE OlimpiadasDB_Atleta;
GO

INSERT INTO PARTICIPACION
SELECT PAR.*
FROM OlimpiadasDB.dbo.PARTICIPACION PAR
INNER JOIN OlimpiadasDB.dbo.ATLETA A ON A.id_atleta = PAR.id_atleta
INNER JOIN OlimpiadasDB.dbo.EDICION_JUEGOS EJ ON EJ.id_edicion = PAR.id_edicion
WHERE A.nombre LIKE '%Usain%Bolt%' AND EJ.anio = 2012;
GO

SELECT CAST('PAIS' AS VARCHAR(20)) AS Tabla, COUNT(*) AS TotalRegistros FROM PAIS
UNION ALL SELECT 'POBLACION_PAIS', COUNT(*) FROM POBLACION_PAIS
UNION ALL SELECT 'SEDE', COUNT(*) FROM SEDE
UNION ALL SELECT 'EDICION_JUEGOS', COUNT(*) FROM EDICION_JUEGOS
UNION ALL SELECT 'DEPORTE', COUNT(*) FROM DEPORTE
UNION ALL SELECT 'EVENTO', COUNT(*) FROM EVENTO
UNION ALL SELECT 'FUENTE_DATOS', COUNT(*) FROM FUENTE_DATOS
UNION ALL SELECT 'ATLETA', COUNT(*) FROM ATLETA
UNION ALL SELECT 'PARTICIPACION', COUNT(*) FROM PARTICIPACION;

SELECT PAR.id_participacion, CAST(A.nombre AS VARCHAR(25)) AS Atleta, EJ.anio, CAST(EV.nombre AS VARCHAR(35)) AS Evento, CAST(ISNULL(PAR.medalla, 'NULL') AS VARCHAR(10)) AS Medalla
FROM PARTICIPACION PAR
INNER JOIN ATLETA A ON A.id_atleta = PAR.id_atleta
INNER JOIN EDICION_JUEGOS EJ ON EJ.id_edicion = PAR.id_edicion
INNER JOIN EVENTO EV ON EV.id_evento = PAR.id_evento
WHERE A.nombre LIKE '%Usain%Bolt%' ORDER BY EJ.anio;

SELECT 
    CAST(OBJECT_NAME(ips.object_id) AS VARCHAR(22)) AS NombreTabla,
    CAST(i.name AS VARCHAR(32)) AS NombreIndice,
    ROUND(ips.avg_fragmentation_in_percent, 2) AS Frag_Pct,
    ips.page_count AS Paginas
FROM sys.dm_db_index_physical_stats(DB_ID('OlimpiadasDB_Atleta'), NULL, NULL, NULL, 'LIMITED') ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.object_id > 100;
GO