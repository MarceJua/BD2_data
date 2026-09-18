USE OlimpiadasDB;
GO

-- Medallistas de Guatemala (todas las medallas obtenidas)
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


-- Medalla de oro en un evento y año dados (ejemplo: 100 metros planos)
SELECT 
    A.nombre AS Atleta,
    P.nombre AS Pais,
    EJ.anio AS Anio,
    EV.nombre AS Evento
FROM PARTICIPACION PAR
INNER JOIN ATLETA A ON A.id_atleta = PAR.id_atleta
INNER JOIN PAIS P ON P.id_pais = PAR.id_pais_representado
INNER JOIN EDICION_JUEGOS EJ ON EJ.id_edicion = PAR.id_edicion
INNER JOIN EVENTO EV ON EV.id_evento = PAR.id_evento
WHERE EV.nombre LIKE '%100 metres%' 
  AND EJ.anio = 2016
  AND PAR.medalla = 'Gold';


-- Top 10 con más medallas de oro
SELECT TOP 10
    A.nombre AS Atleta,
    COUNT(*) AS TotalOro
FROM PARTICIPACION PAR
INNER JOIN ATLETA A ON A.id_atleta = PAR.id_atleta
WHERE PAR.medalla = 'Gold'
GROUP BY A.id_atleta, A.nombre
ORDER BY TotalOro DESC;


-- Atletas con exactamente 1 medalla (el mínimo posible que no sea cero)
SELECT TOP 20
    A.nombre AS Atleta,
    COUNT(*) AS TotalMedallas
FROM PARTICIPACION PAR
INNER JOIN ATLETA A ON A.id_atleta = PAR.id_atleta
WHERE PAR.medalla IS NOT NULL
GROUP BY A.id_atleta, A.nombre
HAVING COUNT(*) = 1
ORDER BY A.nombre;


-- Atletas que ganaron medalla representando a más de un país distinto
SELECT 
    A.nombre AS Atleta,
    COUNT(DISTINCT PAR.id_pais_representado) AS PaisesDistintos
FROM PARTICIPACION PAR
INNER JOIN ATLETA A ON A.id_atleta = PAR.id_atleta
WHERE PAR.medalla IS NOT NULL
GROUP BY A.id_atleta, A.nombre
HAVING COUNT(DISTINCT PAR.id_pais_representado) > 1
ORDER BY PaisesDistintos DESC;


-- a) Total de medallas por edición (¿qué año tuvo más medallas repartidas?)
SELECT EJ.anio, COUNT(*) AS TotalMedallas
FROM PARTICIPACION PAR
INNER JOIN EDICION_JUEGOS EJ ON EJ.id_edicion = PAR.id_edicion
WHERE PAR.medalla IS NOT NULL
GROUP BY EJ.anio
ORDER BY TotalMedallas DESC;

-- b) Deporte con más eventos distintos
SELECT D.nombre AS Deporte, COUNT(*) AS TotalEventos
FROM EVENTO E
INNER JOIN DEPORTE D ON D.id_deporte = E.id_deporte
GROUP BY D.nombre
ORDER BY TotalEventos DESC;

-- c) Población de un país en un año específico (usa POBLACION_PAIS, tabla que nadie más usó en las consultas anteriores)
SELECT P.nombre, PP.anio, PP.cantidad_poblacion
FROM POBLACION_PAIS PP
INNER JOIN PAIS P ON P.id_pais = PP.id_pais
WHERE P.codigo_noc = 'GUA'
ORDER BY PP.anio DESC;