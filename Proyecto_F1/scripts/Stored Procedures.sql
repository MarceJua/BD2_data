CREATE PROCEDURE sp_ConsultarAtleta
    @nombre_atleta VARCHAR(255),
    @deporte VARCHAR(255) = NULL, -- Parámetro opcional
    @pais VARCHAR(255) = NULL,    -- Parámetro opcional
    @anio INT = NULL              -- Parámetro opcional
AS
BEGIN
    -- Regla estricta: No usar SELECT *
    SELECT 
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
      AND (@pais IS NULL OR P.nombre = @pais)
      AND (@anio IS NULL OR EJ.anio = @anio);
END;
GO


CREATE PROCEDURE sp_ConsultarPais
    @codigo_o_nombre VARCHAR(255)
AS
BEGIN
    -- Consulta 1: Resumen de Medallas (tomando en cuenta eventos de equipo)
    -- Aquí deberás agregar la lógica para contar 1 sola medalla si es_por_equipo = 1
    SELECT 
        P.nombre AS NombrePais,
        P.codigo_noc AS CodigoOlimpico,
        COUNT(PAR.medalla) AS TotalMedallas
        -- (Aquí debes expandir para separar Oro, Plata y Bronce)
    FROM PAIS P
    LEFT JOIN PARTICIPACION PAR ON P.id_pais = PAR.id_pais_representado
    WHERE P.nombre = @codigo_o_nombre OR P.codigo_noc = @codigo_o_nombre
    GROUP BY P.nombre, P.codigo_noc;

    -- Consulta 2: Historial como Sede (Cuántas veces y qué años ha sido sede)
    SELECT 
        S.ciudad AS CiudadSede,
        EJ.anio AS AnioSede,
        EJ.temporada AS Temporada
    FROM PAIS P
    INNER JOIN SEDE S ON P.id_pais = S.id_pais
    INNER JOIN EDICION_JUEGOS EJ ON S.id_sede = EJ.id_sede
    WHERE P.nombre = @codigo_o_nombre OR P.codigo_noc = @codigo_o_nombre;
END;
GO