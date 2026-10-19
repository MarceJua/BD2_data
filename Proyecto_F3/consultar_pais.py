import pymongo
import argparse

parser = argparse.ArgumentParser(description="Consultar información de un país.")
parser.add_argument("pais", help="Nombre del país (ej. Guatemala)")
args = parser.parse_args()

db = pymongo.MongoClient("mongodb://localhost:27017/")["OlimpiadasNoSQL"]

# 1. Info de Sede y NOC
info_sede = db["Paises_Sedes"].find_one({"pais": {"$regex": f"^{args.pais}$", "$options": "i"}})

print(f"\n=== INFORMACIÓN DEL PAÍS: {args.pais.upper()} ===")
if info_sede:
    print(f"Código NOC: {info_sede['codigo_noc']}")
    if info_sede['ha_sido_sede']:
        sedes_str = ", ".join([f"{s['ciudad']} ({s['anio']})" for s in info_sede['historial_sedes']])
        print(f"¿Ha sido sede? SÍ -> {sedes_str}")
    else:
        print("¿Ha sido sede? NO")
else:
    print("El país no existe en los catálogos.")

# 2. Resumen de Medallas (Aggregation Pipeline de MongoDB)
pipeline = [
    {"$match": {"pais_representado.nombre": {"$regex": f"^{args.pais}$", "$options": "i"}, "medalla": {"$ne": None}}},
    {"$group": {"_id": "$medalla", "total": {"$sum": 1}}}
]
medallas = list(db["Participaciones"].aggregate(pipeline))

print("\n--- HISTORIAL DE MEDALLAS ---")
if medallas:
    for m in medallas:
        print(f"{m['_id']}: {m['total']}")
else:
    print("0 medallas registradas.")

# 3. Muestra de Participaciones
participaciones = list(db["Participaciones"].find(
    {"pais_representado.nombre": {"$regex": f"^{args.pais}$", "$options": "i"}}
).sort("edicion.anio", -1).limit(15)) # Muestra las últimas 15 por ej.

print("\n--- ÚLTIMAS PARTICIPACIONES ---")
if participaciones:
    for p in participaciones:
        medalla = p.get('medalla') or "--"
        print(f"{p['edicion']['anio']} - {p['atleta']['nombre']} | {p['deporte']} ({p['evento']}) | Medalla: {medalla}")
else:
    print("No hay participaciones registradas.")
print("===================================================\n")