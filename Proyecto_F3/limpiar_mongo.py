import pymongo
client = pymongo.MongoClient("mongodb://localhost:27017/")
col = client["OlimpiadasNoSQL"]["Participaciones"]
# Eliminar toda la basura duplicada de results.csv que contiene "(Olympic)"
resultado = col.delete_many({"evento": {"$regex": r"\(Olympic\)"}})
print(f"Limpieza NoSQL: Se eliminaron {resultado.deleted_count} participaciones duplicadas sin medalla.")