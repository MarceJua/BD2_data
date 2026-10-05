USE OlimpiadasDB;
GO

BEGIN TRANSACTION;

-- =========================================================================
-- PASO 1: LIMPIAR DUPLICADOS RESTANTES (CASO 1956 Y MULTI-SEDE)
-- =========================================================================
WITH MedallasDuplicadasAnio AS (
    SELECT 
        PAR.id_participacion,
        ROW_NUMBER() OVER (
            PARTITION BY 
                PAR.id_pais_representado,
                EJ.anio,
                EJ.temporada,
                EV.id_deporte,
                PAR.medalla,
                LOWER(TRANSLATE(LEFT(A.nombre, 5), 'áéíóúÁÉÍÓÚ', 'aeiouaeiou'))
            ORDER BY 
                CASE WHEN EV.nombre LIKE '%(Olympic)%' THEN 2 ELSE 1 END ASC,
                LEN(A.nombre) DESC,
                PAR.id_participacion ASC
        ) AS rn
    FROM PARTICIPACION PAR
    INNER JOIN ATLETA A ON A.id_atleta = PAR.id_atleta
    INNER JOIN EDICION_JUEGOS EJ ON EJ.id_edicion = PAR.id_edicion
    INNER JOIN EVENTO EV ON EV.id_evento = PAR.id_evento
    WHERE PAR.medalla IS NOT NULL
      AND EV.es_por_equipo = 0
)
DELETE FROM PARTICIPACION
WHERE id_participacion IN (
    SELECT id_participacion 
    FROM MedallasDuplicadasAnio 
    WHERE rn > 1
);

-- =========================================================================
-- PASO 2: MIGRAR TOKIO 2020 Y PARÍS 2024 COMPLETO DESDE stg_summer
-- =========================================================================

-- Limpiamos las 2 filas manuales de 2024 previas para cargar todo 2020 y 2024 limpio desde stg_summer
DELETE PAR
FROM PARTICIPACION PAR
INNER JOIN EDICION_JUEGOS EJ ON EJ.id_edicion = PAR.id_edicion
WHERE EJ.anio IN (2020, 2024);

-- 2.1 Insertar países (NOC) nuevos que vengan en 2020/2024 y no estén en PAIS
INSERT INTO PAIS (nombre, codigo_noc, codigo_iso3)
SELECT DISTINCT 
    ISNULL(MAX(s.Team), s.NOC), 
    s.NOC, 
    NULL
FROM stg_summer s
LEFT JOIN PAIS p ON p.codigo_noc = s.NOC
WHERE s.Year IN ('2020', '2024')
  AND s.NOC IS NOT NULL
  AND p.id_pais IS NULL
GROUP BY s.NOC;

-- 2.2 Asegurar Sedes para Tokyo (2020) y Paris (2024)
DECLARE @id_jpn INT = (SELECT TOP 1 id_pais FROM PAIS WHERE codigo_noc = 'JPN');
DECLARE @id_fra INT = (SELECT TOP 1 id_pais FROM PAIS WHERE codigo_noc = 'FRA');

IF NOT EXISTS (SELECT 1 FROM SEDE WHERE ciudad = 'Tokyo')
    INSERT INTO SEDE (ciudad, id_pais) VALUES ('Tokyo', @id_jpn);

IF NOT EXISTS (SELECT 1 FROM SEDE WHERE ciudad = 'Paris')
    INSERT INTO SEDE (ciudad, id_pais) VALUES ('Paris', @id_fra);

DECLARE @id_sede_tokyo INT = (SELECT TOP 1 id_sede FROM SEDE WHERE ciudad = 'Tokyo');
DECLARE @id_sede_paris INT = (SELECT TOP 1 id_sede FROM SEDE WHERE ciudad = 'Paris');

-- 2.3 Asegurar Ediciones 2020 y 2024 en EDICION_JUEGOS
IF NOT EXISTS (SELECT 1 FROM EDICION_JUEGOS WHERE anio = 2020 AND temporada = 'Summer')
    INSERT INTO EDICION_JUEGOS (anio, temporada, id_sede) VALUES (2020, 'Summer', @id_sede_tokyo);

IF NOT EXISTS (SELECT 1 FROM EDICION_JUEGOS WHERE anio = 2024 AND temporada = 'Summer')
    INSERT INTO EDICION_JUEGOS (anio, temporada, id_sede) VALUES (2024, 'Summer', @id_sede_paris);

-- 2.4 Insertar Deportes nuevos de 2020/2024
INSERT INTO DEPORTE (nombre)
SELECT DISTINCT s.Sport
FROM stg_summer s
LEFT JOIN DEPORTE d ON d.nombre = s.Sport
WHERE s.Year IN ('2020', '2024')
  AND s.Sport IS NOT NULL
  AND d.id_deporte IS NULL;

-- 2.5 Insertar Eventos nuevos de 2020/2024
INSERT INTO EVENTO (nombre, id_deporte, es_por_equipo)
SELECT DISTINCT 
    s.Event,
    d.id_deporte,
    0
FROM stg_summer s
INNER JOIN DEPORTE d ON d.nombre = s.Sport
LEFT JOIN EVENTO e ON e.nombre = s.Event AND e.id_deporte = d.id_deporte
WHERE s.Year IN ('2020', '2024')
  AND s.Event IS NOT NULL
  AND e.id_evento IS NULL;

-- 2.6 Insertar Atletas nuevos de 2020/2024 que no existan aún en ATLETA
INSERT INTO ATLETA (nombre, genero, altura, peso, id_origen_bios, id_origen_kaggle)
SELECT 
    s.Name,
    MAX(s.Sex),
    NULL,
    NULL,
    NULL,
    MAX(s.player_id)
FROM stg_summer s
LEFT JOIN ATLETA a ON a.nombre = s.Name
WHERE s.Year IN ('2020', '2024')
  AND s.Name IS NOT NULL
  AND a.id_atleta IS NULL
GROUP BY s.Name;

-- 2.7 Obtener fuente de datos para registrar en PARTICIPACION
DECLARE @id_fuente_summer INT;
SELECT TOP 1 @id_fuente_summer = id_fuente FROM FUENTE_DATOS WHERE nombre_archivo LIKE '%summer%' OR nombre_archivo LIKE '%olympics%';
IF @id_fuente_summer IS NULL
    SELECT TOP 1 @id_fuente_summer = id_fuente FROM FUENTE_DATOS;

-- 2.8 Insertar todas las participaciones de 2020 y 2024 desde stg_summer
;WITH AtletaUnico AS (
    SELECT nombre, MIN(id_atleta) AS id_atleta
    FROM ATLETA
    GROUP BY nombre
),
PaisUnico AS (
    SELECT codigo_noc, MIN(id_pais) AS id_pais
    FROM PAIS
    GROUP BY codigo_noc
),
EventoUnico AS (
    SELECT e.nombre AS evento_nombre, d.nombre AS deporte_nombre, MIN(e.id_evento) AS id_evento
    FROM EVENTO e
    INNER JOIN DEPORTE d ON d.id_deporte = e.id_deporte
    GROUP BY e.nombre, d.nombre
),
EdicionUnica AS (
    SELECT anio, temporada, MIN(id_edicion) AS id_edicion
    FROM EDICION_JUEGOS
    GROUP BY anio, temporada
)
INSERT INTO PARTICIPACION (id_atleta, id_edicion, id_evento, id_pais_representado, id_fuente, medalla, edad_participacion)
SELECT DISTINCT
    au.id_atleta,
    edu.id_edicion,
    evu.id_evento,
    pu.id_pais,
    @id_fuente_summer,
    CASE WHEN s.Medal IN ('Gold', 'Silver', 'Bronze') THEN s.Medal ELSE NULL END,
    NULL
FROM stg_summer s
INNER JOIN AtletaUnico au ON au.nombre = s.Name
INNER JOIN EdicionUnica edu ON edu.anio = CAST(s.Year AS INT) AND edu.temporada = s.Season
INNER JOIN EventoUnico evu ON evu.evento_nombre = s.Event AND evu.deporte_nombre = s.Sport
INNER JOIN PaisUnico pu ON pu.codigo_noc = s.NOC
WHERE s.Year IN ('2020', '2024');

-- 2.9 Marcar es_por_equipo = 1 en los eventos nuevos de 2020/2024 que sean de equipo
UPDATE EV
SET EV.es_por_equipo = 1
FROM EVENTO EV
WHERE EV.id_evento IN (
    SELECT PAR.id_evento
    FROM PARTICIPACION PAR
    WHERE PAR.medalla IS NOT NULL
    GROUP BY PAR.id_evento, PAR.id_edicion, PAR.id_pais_representado, PAR.medalla
    HAVING COUNT(*) > 1
);

COMMIT TRANSACTION;
GO