USE OlimpiadasDB;
GO

BEGIN TRANSACTION;

-- =========================================================================
-- 1. ELIMINAR DUPLICIDAD DE MEDALLAS ENTRE FUENTES (Ej. Erick Barrondo 2012)
-- =========================================================================
WITH MedallasDuplicadas AS (
    SELECT 
        PAR.id_participacion,
        ROW_NUMBER() OVER (
            PARTITION BY 
                PAR.id_pais_representado,
                PAR.id_edicion,
                EV.id_deporte,
                PAR.medalla,
                LOWER(TRANSLATE(LEFT(A.nombre, 4), 'áéíóúÁÉÍÓÚ', 'aeiouaeiou'))
            ORDER BY 
                CASE WHEN EV.nombre LIKE '%(Olympic)%' THEN 2 ELSE 1 END ASC,
                LEN(A.nombre) DESC
        ) AS rn
    FROM PARTICIPACION PAR
    INNER JOIN ATLETA A ON A.id_atleta = PAR.id_atleta
    INNER JOIN EDICION_JUEGOS EJ ON EJ.id_edicion = PAR.id_edicion
    INNER JOIN PAIS P ON P.id_pais = PAR.id_pais_representado
    INNER JOIN EVENTO EV ON EV.id_evento = PAR.id_evento
    INNER JOIN DEPORTE D ON D.id_deporte = EV.id_deporte
    WHERE PAR.medalla IS NOT NULL
      AND EV.es_por_equipo = 0
)
DELETE FROM PARTICIPACION
WHERE id_participacion IN (
    SELECT id_participacion 
    FROM MedallasDuplicadas 
    WHERE rn > 1
);

-- =========================================================================
-- 2. ASEGURAR LA EDICIÓN PARÍS 2024 Y MEDALLISTAS DE GUATEMALA (2024)
-- =========================================================================
DECLARE @id_pais_gua INT;
DECLARE @id_pais_fra INT;
DECLARE @id_sede_paris INT;
DECLARE @id_edicion_2024 INT;
DECLARE @id_deporte_shooting INT;
DECLARE @id_evento_trap_w INT;
DECLARE @id_evento_trap_m INT;
DECLARE @id_fuente INT;
DECLARE @id_adriana INT;
DECLARE @id_brol INT;

-- Obtener IDs de países
SELECT TOP 1 @id_pais_gua = id_pais FROM PAIS WHERE codigo_noc = 'GUA';
SELECT TOP 1 @id_pais_fra = id_pais FROM PAIS WHERE codigo_noc = 'FRA';

-- Buscar o insertar Sede Paris
SELECT TOP 1 @id_sede_paris = id_sede FROM SEDE WHERE ciudad = 'Paris' AND id_pais = @id_pais_fra;

IF @id_sede_paris IS NULL
BEGIN
    SELECT TOP 1 @id_sede_paris = id_sede FROM SEDE WHERE ciudad LIKE '%Paris%';
    IF @id_sede_paris IS NULL
    BEGIN
        INSERT INTO SEDE (ciudad, id_pais) VALUES ('Paris', @id_pais_fra);
        SET @id_sede_paris = SCOPE_IDENTITY();
    END
END

-- Asegurar Edición 2024 Summer
SELECT TOP 1 @id_edicion_2024 = id_edicion FROM EDICION_JUEGOS WHERE anio = 2024 AND temporada = 'Summer';
IF @id_edicion_2024 IS NULL
BEGIN
    INSERT INTO EDICION_JUEGOS (anio, temporada, id_sede) VALUES (2024, 'Summer', @id_sede_paris);
    SET @id_edicion_2024 = SCOPE_IDENTITY();
END

-- Asegurar Deporte 'Shooting'
SELECT TOP 1 @id_deporte_shooting = id_deporte FROM DEPORTE WHERE nombre = 'Shooting';
IF @id_deporte_shooting IS NULL
BEGIN
    INSERT INTO DEPORTE (nombre) VALUES ('Shooting');
    SET @id_deporte_shooting = SCOPE_IDENTITY();
END

-- Asegurar Eventos de Trap (Foso Olímpico)
SELECT TOP 1 @id_evento_trap_w = id_evento FROM EVENTO WHERE nombre = 'Shooting Women''s Trap';
IF @id_evento_trap_w IS NULL
BEGIN
    INSERT INTO EVENTO (nombre, id_deporte, es_por_equipo) VALUES ('Shooting Women''s Trap', @id_deporte_shooting, 0);
    SET @id_evento_trap_w = SCOPE_IDENTITY();
END

SELECT TOP 1 @id_evento_trap_m = id_evento FROM EVENTO WHERE nombre = 'Shooting Men''s Trap';
IF @id_evento_trap_m IS NULL
BEGIN
    INSERT INTO EVENTO (nombre, id_deporte, es_por_equipo) VALUES ('Shooting Men''s Trap', @id_deporte_shooting, 0);
    SET @id_evento_trap_m = SCOPE_IDENTITY();
END

-- Fuente de datos
SELECT TOP 1 @id_fuente = id_fuente FROM FUENTE_DATOS;

-- Insertar o buscar a Adriana Ruano Oliva
SELECT TOP 1 @id_adriana = id_atleta FROM ATLETA WHERE nombre LIKE '%Ruano%' AND nombre LIKE '%Adriana%';
IF @id_adriana IS NULL
BEGIN
    INSERT INTO ATLETA (nombre, genero, altura, peso) VALUES ('Adriana Ruano Oliva', 'F', 163, 60);
    SET @id_adriana = SCOPE_IDENTITY();
END

-- Insertar participación y Oro de Adriana Ruano en París 2024 si no existe
IF NOT EXISTS (SELECT 1 FROM PARTICIPACION WHERE id_atleta = @id_adriana AND id_edicion = @id_edicion_2024 AND medalla = 'Gold')
BEGIN
    INSERT INTO PARTICIPACION (id_atleta, id_edicion, id_evento, id_pais_representado, id_fuente, medalla, edad_participacion)
    VALUES (@id_adriana, @id_edicion_2024, @id_evento_trap_w, @id_pais_gua, @id_fuente, 'Gold', 29);
END

-- Insertar o buscar a Jean Pierre Brol
SELECT TOP 1 @id_brol = id_atleta FROM ATLETA WHERE nombre LIKE '%Brol%' AND nombre LIKE '%Jean%';
IF @id_brol IS NULL
BEGIN
    INSERT INTO ATLETA (nombre, genero, altura, peso) VALUES ('Jean Pierre Brol Cardenas', 'M', 178, 88);
    SET @id_brol = SCOPE_IDENTITY();
END

-- Insertar participación y Bronce de Jean Pierre Brol en París 2024 si no existe
IF NOT EXISTS (SELECT 1 FROM PARTICIPACION WHERE id_atleta = @id_brol AND id_edicion = @id_edicion_2024 AND medalla = 'Bronze')
BEGIN
    INSERT INTO PARTICIPACION (id_atleta, id_edicion, id_evento, id_pais_representado, id_fuente, medalla, edad_participacion)
    VALUES (@id_brol, @id_edicion_2024, @id_evento_trap_m, @id_pais_gua, @id_fuente, 'Bronze', 41);
END

COMMIT TRANSACTION;
GO