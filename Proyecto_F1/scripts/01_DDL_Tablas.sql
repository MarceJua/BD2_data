-- Crear la base de datos
CREATE DATABASE OlimpiadasDB;
GO
USE OlimpiadasDB;
GO

-- 1. Tabla PAIS (Cumple con tener código NOC e ISO3)
CREATE TABLE PAIS (
    id_pais INT IDENTITY(1,1) PRIMARY KEY, -- Auto-incremental para evitar colisiones
    nombre VARCHAR(255) NOT NULL,
    codigo_noc VARCHAR(10),  -- Ej. GUA
    codigo_iso3 VARCHAR(10)  -- Ej. GTM
);

-- 2. Tabla POBLACION_PAIS
CREATE TABLE POBLACION_PAIS (
    id_poblacion INT IDENTITY(1,1) PRIMARY KEY,
    id_pais INT NOT NULL,
    anio INT NOT NULL,
    cantidad_poblacion BIGINT NOT NULL,
    CONSTRAINT FK_Poblacion_Pais FOREIGN KEY (id_pais) REFERENCES PAIS(id_pais)
);

-- 3. Tabla SEDE (Entidad obligatoria según el manual)
CREATE TABLE SEDE (
    id_sede INT IDENTITY(1,1) PRIMARY KEY,
    ciudad VARCHAR(255) NOT NULL,
    id_pais INT NOT NULL, -- País anfitrión
    CONSTRAINT FK_Sede_Pais FOREIGN KEY (id_pais) REFERENCES PAIS(id_pais)
);

-- 4. Tabla EDICION_JUEGOS
CREATE TABLE EDICION_JUEGOS (
    id_edicion INT IDENTITY(1,1) PRIMARY KEY,
    anio INT NOT NULL,
    temporada VARCHAR(50) NOT NULL, -- Ej. Summer, Winter
    id_sede INT NOT NULL,
    CONSTRAINT FK_Edicion_Sede FOREIGN KEY (id_sede) REFERENCES SEDE(id_sede)
);

-- 5. Tabla DEPORTE
CREATE TABLE DEPORTE (
    id_deporte INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL
);

-- 6. Tabla EVENTO (Cumple con la bandera es_por_equipo para conteo real de medallas)
CREATE TABLE EVENTO (
    id_evento INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    id_deporte INT NOT NULL,
    es_por_equipo BIT NOT NULL DEFAULT 0, -- Bandera para evitar duplicación de medallas
    CONSTRAINT FK_Evento_Deporte FOREIGN KEY (id_deporte) REFERENCES DEPORTE(id_deporte)
);

-- 7. Tabla FUENTE_DATOS (Para trazabilidad del ETL)
CREATE TABLE FUENTE_DATOS (
    id_fuente INT IDENTITY(1,1) PRIMARY KEY,
    nombre_archivo VARCHAR(255) NOT NULL -- Ej. results.csv
);

-- 8. Tabla ATLETA (Cumple con trazabilidad y campos NULL permitidos)
CREATE TABLE ATLETA (
    id_atleta INT IDENTITY(1,1) PRIMARY KEY, -- Auto-incremental propio
    nombre VARCHAR(255) NOT NULL,
    genero VARCHAR(50) NULL, -- Permitir NULL si no viene en el origen
    altura FLOAT NULL,       -- Permitir NULL
    peso FLOAT NULL,         -- Permitir NULL
    id_origen_bios VARCHAR(100) NULL,   -- Trazabilidad origen 1
    id_origen_kaggle VARCHAR(100) NULL  -- Trazabilidad origen 2
);

-- 9. Tabla central de hechos: PARTICIPACION
CREATE TABLE PARTICIPACION (
    id_participacion INT IDENTITY(1,1) PRIMARY KEY,
    id_atleta INT NOT NULL,
    id_edicion INT NOT NULL,
    id_evento INT NOT NULL,
    id_pais_representado INT NOT NULL,
    id_fuente INT NOT NULL,
    medalla VARCHAR(50) NULL, -- Gold, Silver, Bronze, o NULL si no ganó
    edad_participacion INT NULL, -- Permitir NULL como indica el manual
    CONSTRAINT FK_Part_Atleta FOREIGN KEY (id_atleta) REFERENCES ATLETA(id_atleta),
    CONSTRAINT FK_Part_Edicion FOREIGN KEY (id_edicion) REFERENCES EDICION_JUEGOS(id_edicion),
    CONSTRAINT FK_Part_Evento FOREIGN KEY (id_evento) REFERENCES EVENTO(id_evento),
    CONSTRAINT FK_Part_Pais FOREIGN KEY (id_pais_representado) REFERENCES PAIS(id_pais),
    CONSTRAINT FK_Part_Fuente FOREIGN KEY (id_fuente) REFERENCES FUENTE_DATOS(id_fuente)
);
GO