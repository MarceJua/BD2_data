USE OlimpiadasDB;
GO

-- 1. Verificar cómo quedaron las medallas de Guatemala en detalle
SELECT 
    A.nombre AS Atleta,
    EJ.anio AS Anio,
    EV.nombre AS Evento,
    PAR.medalla AS Medalla
FROM PARTICIPACION PAR
INNER JOIN ATLETA A ON A.id_atleta = PAR.id_atleta
INNER JOIN PAIS P ON P.id_pais = PAR.id_pais_representado
INNER JOIN EDICION_JUEGOS EJ ON EJ.id_edicion = PAR.id_edicion
INNER JOIN EVENTO EV ON EV.id_evento = PAR.id_evento
WHERE P.codigo_noc = 'GUA' AND PAR.medalla IS NOT NULL
ORDER BY EJ.anio;

-- 2. Revisar qué años existen en stg_summer vs qué años están en PARTICIPACION
SELECT Year AS Anio_en_stg_summer, COUNT(*) AS FilasStaging
FROM stg_summer
WHERE Year IN ('2020', '2024')
GROUP BY Year;

SELECT EJ.anio AS Anio_en_Participacion, COUNT(*) AS FilasParticipacion
FROM PARTICIPACION PAR
INNER JOIN EDICION_JUEGOS EJ ON EJ.id_edicion = PAR.id_edicion
WHERE EJ.anio >= 2016
GROUP BY EJ.anio
ORDER BY EJ.anio DESC;

-- 3. Auditoría de duplicidad: ¿Quedan atletas con la misma medalla duplicada el mismo año y deporte?
SELECT TOP 20
    P.codigo_noc AS Pais,
    EJ.anio AS Anio,
    D.nombre AS Deporte,
    PAR.medalla AS Medalla,
    STRING_AGG(A.nombre, ' / ') AS NombresRegistrados,
    STRING_AGG(EV.nombre, ' | ') AS EventosRegistrados,
    COUNT(*) AS CantidadRegistros
FROM PARTICIPACION PAR
INNER JOIN ATLETA A ON A.id_atleta = PAR.id_atleta
INNER JOIN PAIS P ON P.id_pais = PAR.id_pais_representado
INNER JOIN EDICION_JUEGOS EJ ON EJ.id_edicion = PAR.id_edicion
INNER JOIN EVENTO EV ON EV.id_evento = PAR.id_evento
INNER JOIN DEPORTE D ON D.id_deporte = EV.id_deporte
WHERE PAR.medalla IS NOT NULL
  AND EV.es_por_equipo = 0
GROUP BY 
    P.codigo_noc,
    EJ.anio,
    D.nombre,
    PAR.medalla,
    LOWER(TRANSLATE(LEFT(A.nombre, 5), 'áéíóúÁÉÍÓÚ', 'aeiouaeiou'))
HAVING COUNT(*) > 1
ORDER BY CantidadRegistros DESC;