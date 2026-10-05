-- =========================================================================
-- ESCENARIO 1 (CARGA POR AÑO) - PASO 1: CREACIÓN Y CARGA INICIAL (1896-2012)
-- =========================================================================
USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = N'OlimpiadasDB_Anio')
BEGIN
    ALTER DATABASE OlimpiadasDB_Anio SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE OlimpiadasDB_Anio;
END
GO

CREATE DATABASE OlimpiadasDB_Anio;
GO

-- Importante: Poner en modo FULL para soportar todos los tipos de respaldo
ALTER DATABASE OlimpiadasDB_Anio SET RECOVERY FULL;
GO

USE OlimpiadasDB_Anio;
GO

-- 1. Crear estructura normalizada idéntica al Proyecto 1
CREATE TABLE PAIS (
    id_pais INT PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    codigo_noc VARCHAR(10),
    codigo_iso3 VARCHAR(10)
);

CREATE TABLE POBLACION_PAIS (
    id_poblacion INT PRIMARY KEY,
    id_pais INT NOT NULL FOREIGN KEY REFERENCES PAIS(id_pais),
    anio INT NOT NULL,
    cantidad_poblacion BIGINT NOT NULL
);

CREATE TABLE SEDE (
    id_sede INT PRIMARY KEY,
    ciudad VARCHAR(255) NOT NULL,
    id_pais INT NOT NULL FOREIGN KEY REFERENCES PAIS(id_pais)
);

CREATE TABLE EDICION_JUEGOS (
    id_edicion INT PRIMARY KEY,
    anio INT NOT NULL,
    temporada VARCHAR(50) NOT NULL,
    id_sede INT NOT NULL FOREIGN KEY REFERENCES SEDE(id_sede)
);

CREATE TABLE DEPORTE (
    id_deporte INT PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL
);

CREATE TABLE EVENTO (
    id_evento INT PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    id_deporte INT NOT NULL FOREIGN KEY REFERENCES DEPORTE(id_deporte),
    es_por_equipo BIT NOT NULL DEFAULT 0
);

CREATE TABLE FUENTE_DATOS (
    id_fuente INT PRIMARY KEY,
    nombre_archivo VARCHAR(255) NOT NULL
);

CREATE TABLE ATLETA (
    id_atleta INT PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    genero VARCHAR(50) NULL,
    altura FLOAT NULL,
    peso FLOAT NULL,
    id_origen_bios VARCHAR(100) NULL,
    id_origen_kaggle VARCHAR(100) NULL
);

CREATE TABLE PARTICIPACION (
    id_participacion INT PRIMARY KEY,
    id_atleta INT NOT NULL FOREIGN KEY REFERENCES ATLETA(id_atleta),
    id_edicion INT NOT NULL FOREIGN KEY REFERENCES EDICION_JUEGOS(id_edicion),
    id_evento INT NOT NULL FOREIGN KEY REFERENCES EVENTO(id_evento),
    id_pais_representado INT NOT NULL FOREIGN KEY REFERENCES PAIS(id_pais),
    id_fuente INT NOT NULL FOREIGN KEY REFERENCES FUENTE_DATOS(id_fuente),
    medalla VARCHAR(50) NULL,
    edad_participacion INT NULL
);
GO

-- 2. Insertar Carga Inicial (Catálogos base y Participaciones hasta el año 2014, excluyendo 2016, 2020 y 2024)
INSERT INTO PAIS SELECT * FROM OlimpiadasDB.dbo.PAIS;
INSERT INTO POBLACION_PAIS SELECT * FROM OlimpiadasDB.dbo.POBLACION_PAIS WHERE anio <= 2014;
INSERT INTO SEDE SELECT * FROM OlimpiadasDB.dbo.SEDE;
INSERT INTO EDICION_JUEGOS SELECT * FROM OlimpiadasDB.dbo.EDICION_JUEGOS WHERE anio NOT IN (2016, 2020, 2024);
INSERT INTO DEPORTE SELECT * FROM OlimpiadasDB.dbo.DEPORTE;
INSERT INTO EVENTO SELECT * FROM OlimpiadasDB.dbo.EVENTO;
INSERT INTO FUENTE_DATOS SELECT * FROM OlimpiadasDB.dbo.FUENTE_DATOS;
INSERT INTO ATLETA SELECT * FROM OlimpiadasDB.dbo.ATLETA;

INSERT INTO PARTICIPACION
SELECT PAR.*
FROM OlimpiadasDB.dbo.PARTICIPACION PAR
INNER JOIN OlimpiadasDB.dbo.EDICION_JUEGOS EJ ON EJ.id_edicion = PAR.id_edicion
WHERE EJ.anio NOT IN (2016, 2020, 2024);
GO

-- 3. Validación: SELECT COUNT(*) de cada tabla
SELECT 'PAIS' AS Tabla, COUNT(*) AS TotalRegistros FROM PAIS
UNION ALL SELECT 'POBLACION_PAIS', COUNT(*) FROM POBLACION_PAIS
UNION ALL SELECT 'SEDE', COUNT(*) FROM SEDE
UNION ALL SELECT 'EDICION_JUEGOS', COUNT(*) FROM EDICION_JUEGOS
UNION ALL SELECT 'DEPORTE', COUNT(*) FROM DEPORTE
UNION ALL SELECT 'EVENTO', COUNT(*) FROM EVENTO
UNION ALL SELECT 'FUENTE_DATOS', COUNT(*) FROM FUENTE_DATOS
UNION ALL SELECT 'ATLETA', COUNT(*) FROM ATLETA
UNION ALL SELECT 'PARTICIPACION', COUNT(*) FROM PARTICIPACION;

-- 4. Validación: Muestra SELECT * (TOP 5) de PARTICIPACION y EDICION_JUEGOS
SELECT TOP 5 * FROM EDICION_JUEGOS ORDER BY anio DESC;
SELECT TOP 5 * FROM PARTICIPACION ORDER BY id_participacion DESC;

-- 5. Nivel de fragmentación de las tablas (Requisito Fase 2)
SELECT 
    OBJECT_NAME(ips.object_id) AS NombreTabla,
    i.name AS NombreIndice,
    ROUND(ips.avg_fragmentation_in_percent, 2) AS Fragmentacion_Porcentaje,
    ips.page_count AS Paginas
FROM sys.dm_db_index_physical_stats(DB_ID('OlimpiadasDB_Anio'), NULL, NULL, NULL, 'LIMITED') ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.object_id > 100;
GO