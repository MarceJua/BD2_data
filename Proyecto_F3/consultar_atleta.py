import pymongo
import argparse

parser = argparse.ArgumentParser(description="Consultar participaciones de un atleta.")
parser.add_argument("nombre", help="Nombre del atleta")
parser.add_argument("--deporte", help="Filtrar por deporte", default=None)
parser.add_argument("--pais", help="Filtrar por país", default=None)
parser.add_argument("--anio", help="Filtrar por año (entero)", type=int, default=None)
args = parser.parse_args()

client = pymongo.MongoClient("mongodb://localhost:27017/")
col = client["OlimpiadasNoSQL"]["Participaciones"]

# Armar la consulta de Mongo
query = {"atleta.nombre": {"$regex": args.nombre, "$options": "i"}} # Búsqueda flexible

if args.deporte: query["deporte"] = {"$regex": f"^{args.deporte}$", "$options": "i"}
if args.pais: query["pais_representado.nombre"] = {"$regex": f"^{args.pais}$", "$options": "i"}
if args.anio: query["edicion.anio"] = args.anio

resultados = list(col.find(query).sort("edicion.anio", 1))

print(f"\n=== Resultados para Atleta: '{args.nombre.upper()}' ===")
if not resultados:
    print("No se encontraron registros con esos criterios.")
else:
    print(f"Total de participaciones: {len(resultados)}\n")
    for r in resultados:
        medalla = r.get('medalla') or "Sin medalla"
        print(f"- {r['edicion']['anio']} {r['edicion']['temporada']} ({r['edicion']['ciudad_sede']}) | "
              f"País: {r['pais_representado']['codigo_noc']} | "
              f"Deporte: {r['deporte']} | Evento: {r['evento']} | Medalla: {medalla}")
print("===================================================\n")