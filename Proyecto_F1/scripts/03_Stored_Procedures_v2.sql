USE OlimpiadasDB;
GO

DROP PROCEDURE IF EXISTS sp_ConsultarPais;
GO

CREATE PROCEDURE sp_ConsultarPais
    @codigo_o_nombre VARCHAR(255)
AS
BEGIN
    -- Consulta 1: Medallero real (sin inflar por eventos de equipo)
    SELECT 
        P.nombre AS NombrePais,
        P.codigo_noc AS CodigoOlimpico,
        SUM(CASE WHEN medalla_unica = 'Gold' THEN 1 ELSE 0 END) AS TotalOro,
        SUM(CASE WHEN medalla_unica = 'Silver' THEN 1 ELSE 0 END) AS TotalPlata,
        SUM(CASE WHEN medalla_unica = 'Bronze' THEN 1 ELSE 0 END) AS TotalBronce,
        COUNT(*) AS TotalMedallas
    FROM (
        SELECT DISTINCT
            PAR.id_pais_representado,
            PAR.id_evento,
            PAR.id_edicion,
            PAR.medalla AS medalla_unica
        FROM PARTICIPACION PAR
        INNER JOIN EVENTO E ON E.id_evento = PAR.id_evento
        WHERE PAR.medalla IS NOT NULL AND E.es_por_equipo = 1

        UNION ALL

        SELECT 
            PAR.id_pais_representado,
            PAR.id_evento,
            PAR.id_edicion,
            PAR.medalla
        FROM PARTICIPACION PAR
        INNER JOIN EVENTO E ON E.id_evento = PAR.id_evento
        WHERE PAR.medalla IS NOT NULL AND E.es_por_equipo = 0
    ) AS Medallero
    INNER JOIN PAIS P ON P.id_pais = Medallero.id_pais_representado
    WHERE P.nombre = @codigo_o_nombre OR P.codigo_noc = @codigo_o_nombre
    GROUP BY P.nombre, P.codigo_noc;

    -- Consulta 2: Historial como Sede
    SELECT 
        S.ciudad AS CiudadSede,
        EJ.anio AS AnioSede,
        EJ.temporada AS Temporada
    FROM PAIS P
    INNER JOIN SEDE S ON P.id_pais = S.id_pais
    INNER JOIN EDICION_JUEGOS EJ ON S.id_sede = EJ.id_sede
    WHERE P.nombre = @codigo_o_nombre OR P.codigo_noc = @codigo_o_nombre;

    -- Consulta 3: si nunca fue sede, decirlo explícitamente (regla del enunciado)
    IF NOT EXISTS (
        SELECT 1 FROM PAIS P
        INNER JOIN SEDE S ON P.id_pais = S.id_pais
        WHERE P.nombre = @codigo_o_nombre OR P.codigo_noc = @codigo_o_nombre
    )
    SELECT 'Este país nunca ha sido sede de una edición olímpica' AS InfoSede;
END;
GO

DROP PROCEDURE IF EXISTS sp_ConsultarAtleta;
GO

CREATE PROCEDURE sp_ConsultarAtleta
    @nombre_atleta VARCHAR(255),
    @deporte VARCHAR(255) = NULL,
    @pais VARCHAR(255) = NULL,
    @anio INT = NULL
AS
BEGIN
    SELECT 
        A.id_atleta AS IdAtleta,
        A.nombre AS NombreAtleta,
        P.nombre AS PaisRepresentado,
        EJ.anio AS AnioEdicion,
        D.nombre AS Deporte,
        E.nombre AS Prueba,
        PAR.medalla AS MedallaObtenida
    FROM PARTICIPACION PAR
    INNER JOIN ATLETA A ON PAR.id_atleta = A.id_atleta
    INNER JOIN PAIS P ON PAR.id_pais_representado = P.id_pais
    INNER JOIN EDICION_JUEGOS EJ ON PAR.id_edicion = EJ.id_edicion
    INNER JOIN EVENTO E ON PAR.id_evento = E.id_evento
    INNER JOIN DEPORTE D ON E.id_deporte = D.id_deporte
    WHERE A.nombre LIKE '%' + @nombre_atleta + '%'
      AND (@deporte IS NULL OR D.nombre = @deporte)
      AND (@pais IS NULL OR P.nombre = @pais OR P.codigo_noc = @pais)
      AND (@anio IS NULL OR EJ.anio = @anio)
    ORDER BY A.id_atleta, EJ.anio;
END;
GO