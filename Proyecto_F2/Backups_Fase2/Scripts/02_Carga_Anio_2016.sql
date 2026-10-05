USE OlimpiadasDB_Anio;
GO

-- Insertar datos del año 2016 (Río 2016)
INSERT INTO POBLACION_PAIS
SELECT * FROM OlimpiadasDB.dbo.POBLACION_PAIS WHERE anio IN (2015, 2016);

INSERT INTO EDICION_JUEGOS
SELECT * FROM OlimpiadasDB.dbo.EDICION_JUEGOS WHERE anio = 2016;

INSERT INTO PARTICIPACION
SELECT PAR.*
FROM OlimpiadasDB.dbo.PARTICIPACION PAR
INNER JOIN OlimpiadasDB.dbo.EDICION_JUEGOS EJ ON EJ.id_edicion = PAR.id_edicion
WHERE EJ.anio = 2016;
GO

-- 1. SELECT COUNT(*) de cada tabla
SELECT CAST('PAIS' AS VARCHAR(20)) AS Tabla, COUNT(*) AS TotalRegistros FROM PAIS
UNION ALL SELECT 'POBLACION_PAIS', COUNT(*) FROM POBLACION_PAIS
UNION ALL SELECT 'SEDE', COUNT(*) FROM SEDE
UNION ALL SELECT 'EDICION_JUEGOS', COUNT(*) FROM EDICION_JUEGOS
UNION ALL SELECT 'DEPORTE', COUNT(*) FROM DEPORTE
UNION ALL SELECT 'EVENTO', COUNT(*) FROM EVENTO
UNION ALL SELECT 'FUENTE_DATOS', COUNT(*) FROM FUENTE_DATOS
UNION ALL SELECT 'ATLETA', COUNT(*) FROM ATLETA
UNION ALL SELECT 'PARTICIPACION', COUNT(*) FROM PARTICIPACION;

-- 2. SELECT * de validación (Muestra de datos recién cargados de 2016)
SELECT TOP 5 id_edicion, anio, CAST(temporada AS VARCHAR(15)) AS temporada, id_sede 
FROM EDICION_JUEGOS WHERE anio = 2016;

SELECT TOP 5 id_participacion, id_atleta, id_edicion, id_evento, id_pais_representado, CAST(ISNULL(medalla, 'NULL') AS VARCHAR(10)) AS medalla 
FROM PARTICIPACION WHERE id_edicion IN (SELECT id_edicion FROM EDICION_JUEGOS WHERE anio = 2016);

-- 3. Nivel de fragmentación de las tablas
SELECT 
    CAST(OBJECT_NAME(ips.object_id) AS VARCHAR(22)) AS NombreTabla,
    CAST(i.name AS VARCHAR(32)) AS NombreIndice,
    ROUND(ips.avg_fragmentation_in_percent, 2) AS Frag_Pct,
    ips.page_count AS Paginas
FROM sys.dm_db_index_physical_stats(DB_ID('OlimpiadasDB_Anio'), NULL, NULL, NULL, 'LIMITED') ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.object_id > 100;
GO