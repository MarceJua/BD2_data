import pandas as pd
from sqlalchemy import create_engine
import pymongo
import datetime

# Conexiones
sql_engine = create_engine("mssql+pyodbc://@localhost/OlimpiadasDB?driver=ODBC+Driver+18+for+SQL+Server&trusted_connection=yes&TrustServerCertificate=yes")
mongo_client = pymongo.MongoClient("mongodb://localhost:27017/")
db_mongo = mongo_client["OlimpiadasNoSQL"]

# 1. Crear Colección de Países y Sedes (Desnormalización para el inciso D)
print("Extrayendo historial de sedes desde SQL Server...")
query_paises = """
SELECT 
    P.nombre AS pais,
    P.codigo_noc,
    EJ.anio,
    EJ.temporada,
    S.ciudad
FROM PAIS P
LEFT JOIN SEDE S ON P.id_pais = S.id_pais
LEFT JOIN EDICION_JUEGOS EJ ON S.id_sede = EJ.id_sede
ORDER BY P.nombre, EJ.anio
"""
df_paises = pd.read_sql(query_paises, sql_engine)

paises_docs = []
for pais, group in df_paises.groupby(['pais', 'codigo_noc']):
    historial = []
    for _, row in group.iterrows():
        if pd.notnull(row['anio']):
            historial.append({
                "anio": int(row['anio']),
                "temporada": row['temporada'],
                "ciudad": row['ciudad']
            })
    
    doc = {
        "pais": pais[0],
        "codigo_noc": pais[1],
        "ha_sido_sede": len(historial) > 0,
        "historial_sedes": historial
    }
    paises_docs.append(doc)

col_paises = db_mongo["Paises_Sedes"]
col_paises.drop()
col_paises.insert_many(paises_docs)
print(f"Colección 'Paises_Sedes' creada con {len(paises_docs)} documentos.")

# 2. Creación de Índices
print("Creando índices para optimizar consultas de Atletas y Países...")
col_participaciones = db_mongo["Participaciones"]

# Índices simples y compuestos
col_participaciones.create_index("atleta.nombre")
col_participaciones.create_index("pais_representado.nombre")
col_paises.create_index("pais")

print(f"¡Índices creados exitosamente!")
print(f"*** FECHA Y HORA DE EJECUCIÓN (Para Documentación): {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')} ***")