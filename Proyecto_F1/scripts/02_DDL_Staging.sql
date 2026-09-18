USE OlimpiadasDB;
GO

-- STAGING 1: bios.csv (Galli)
CREATE TABLE stg_bios (
    Roles VARCHAR(500),
    Sex VARCHAR(100),
    FullName VARCHAR(500),
    UsedName VARCHAR(500),
    Born VARCHAR(500),
    Died VARCHAR(500),
    NOC VARCHAR(200),
    athlete_id VARCHAR(50),
    Measurements VARCHAR(200),
    Affiliations VARCHAR(1000),
    NickPetnames VARCHAR(500),
    Titles VARCHAR(500),
    OtherNames VARCHAR(500),
    Nationality VARCHAR(200),
    OriginalName VARCHAR(500),
    NameOrder VARCHAR(200)
);

-- STAGING 2: bios_locs.csv (Galli)
CREATE TABLE stg_bios_locs (
    athlete_id VARCHAR(50),
    name VARCHAR(500),
    born_date VARCHAR(100),
    born_city VARCHAR(300),
    born_region VARCHAR(300),
    born_country VARCHAR(200),
    NOC VARCHAR(200),
    height_cm VARCHAR(50),
    weight_kg VARCHAR(50),
    died_date VARCHAR(100),
    lat VARCHAR(50),
    long VARCHAR(50)
);

-- STAGING 3: results.csv (Galli)
CREATE TABLE stg_results (
    Games VARCHAR(300),
    Event VARCHAR(500),
    Team VARCHAR(500),
    Pos VARCHAR(100),
    Medal VARCHAR(100),
    As_Name VARCHAR(500),
    athlete_id VARCHAR(50),
    NOC VARCHAR(200),
    Discipline VARCHAR(300),
    Nationality VARCHAR(200),
    Unnamed7 VARCHAR(500)
);

-- STAGING 4: noc_regions.csv (se usa solo UNO, Hallazgo #9)
CREATE TABLE stg_noc_regions (
    NOC VARCHAR(50),
    region VARCHAR(300),
    notes VARCHAR(500)
);

-- STAGING 5: athlete_events.csv (Kaggle 120 años)
CREATE TABLE stg_athlete_events (
    ID VARCHAR(50),
    Name VARCHAR(500),
    Sex VARCHAR(50),
    Age VARCHAR(50),
    Height VARCHAR(50),
    Weight VARCHAR(50),
    Team VARCHAR(300),
    NOC VARCHAR(50),
    Games VARCHAR(200),
    Year VARCHAR(50),
    Season VARCHAR(100),
    City VARCHAR(300),
    Sport VARCHAR(300),
    Event VARCHAR(500),
    Medal VARCHAR(100)
);

-- STAGING 6: kaggle_olympics_dataset.csv (Summer 1896-2024)
CREATE TABLE stg_summer (
    player_id VARCHAR(50),
    Name VARCHAR(500),
    Sex VARCHAR(50),
    Team VARCHAR(300),
    NOC VARCHAR(50),
    Year VARCHAR(50),
    Season VARCHAR(100),
    City VARCHAR(300),
    Sport VARCHAR(300),
    Event VARCHAR(500),
    Medal VARCHAR(100)
);

-- STAGING 7: datacamp (r-olympics)
CREATE TABLE stg_datacamp (
    id VARCHAR(50),
    name VARCHAR(500),
    sex VARCHAR(50),
    age VARCHAR(50),
    height VARCHAR(50),
    weight VARCHAR(50),
    team VARCHAR(300),
    noc VARCHAR(50),
    games VARCHAR(200),
    year VARCHAR(50),
    season VARCHAR(100),
    city VARCHAR(300),
    sport VARCHAR(300),
    event VARCHAR(500),
    medal VARCHAR(100)
);

-- STAGING 8: populations.csv YA DESPIVOTADO (Hallazgo #10)
-- No se replica el formato ancho de 66 columnas; Python lo despivota antes de cargar.
CREATE TABLE stg_poblacion (
    country_name VARCHAR(300),
    country_code VARCHAR(50),
    anio VARCHAR(50),
    poblacion VARCHAR(100)
);


CREATE TABLE stg_catalogo_sedes (
    ciudad VARCHAR(300),
    anio VARCHAR(50),
    temporada VARCHAR(100),
    pais_anfitrion VARCHAR(300),
    codigo_noc_anfitrion VARCHAR(50)
);


CREATE TABLE stg_equivalencia_paises (
    codigo_noc VARCHAR(50),
    nombre_noc VARCHAR(300),
    codigo_iso3 VARCHAR(50),
    nombre_iso3 VARCHAR(300),
    revisado VARCHAR(10)
);
GO