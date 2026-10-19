import pandas as pd
from sqlalchemy import create_engine
import pymongo

# 1. Conexión a SQL Server (usando el driver ODBC 18 y TrustServerCertificate=yes para evitar el error SSL)
sql_engine = create_engine("mssql+pyodbc://@localhost/OlimpiadasDB?driver=ODBC+Driver+18+for+SQL+Server&trusted_connection=yes&TrustServerCertificate=yes")

# 2. Conexión a MongoDB local
mongo_client = pymongo.MongoClient("mongodb://localhost:27017/")
db_mongo = mongo_client["OlimpiadasNoSQL"]
col_participaciones = db_mongo["Participaciones"]

print("Extrayendo datos de SQL Server...")

# 3. Consulta de extracción (Uniendo todas las tablas clave)
query = """
SELECT 
    A.nombre AS atleta_nombre,
    A.genero AS atleta_genero,
    P.nombre AS pais_nombre,
    P.codigo_noc AS pais_noc,
    EJ.anio AS edicion_anio,
    EJ.temporada AS edicion_temporada,
    S.ciudad AS sede_ciudad,
    D.nombre AS deporte_nombre,
    EV.nombre AS evento_nombre,
    PAR.medalla AS medalla
FROM PARTICIPACION PAR
INNER JOIN ATLETA A ON PAR.id_atleta = A.id_atleta
INNER JOIN PAIS P ON PAR.id_pais_representado = P.id_pais
INNER JOIN EDICION_JUEGOS EJ ON PAR.id_edicion = EJ.id_edicion
INNER JOIN SEDE S ON EJ.id_sede = S.id_sede
INNER JOIN EVENTO EV ON PAR.id_evento = EV.id_evento
INNER JOIN DEPORTE D ON EV.id_deporte = D.id_deporte
"""

df = pd.read_sql(query, sql_engine)
print(f"Se extrajeron {len(df)} registros de SQL. Transformando a formato documental BSON...")

# 4. Transformación de filas relacionales a documentos anidados
documentos = []
for index, row in df.iterrows():
    doc = {
        "atleta": {
            "nombre": row["atleta_nombre"],
            "genero": row["atleta_genero"] if pd.notnull(row["atleta_genero"]) else None
        },
        "pais_representado": {
            "nombre": row["pais_nombre"],
            "codigo_noc": row["pais_noc"]
        },
        "edicion": {
            "anio": int(row["edicion_anio"]),
            "temporada": row["edicion_temporada"],
            "ciudad_sede": row["sede_ciudad"]
        },
        "deporte": row["deporte_nombre"],
        "evento": row["evento_nombre"],
        "medalla": row["medalla"] if pd.notnull(row["medalla"]) else None
    }
    documentos.append(doc)

# 5. Carga masiva a MongoDB
print("Cargando a MongoDB...")
col_participaciones.drop() # Limpiamos la colección por si corres el script varias veces
col_participaciones.insert_many(documentos)

print(f"¡Éxito! Se migró la colección 'Participaciones' a MongoDB con {col_participaciones.count_documents({})} documentos.")