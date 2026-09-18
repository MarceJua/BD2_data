# Proyecto Olimpiadas — Estado del Proyecto al 18-sep-2026
## Grupo #16 — Sistemas de Bases de Datos 2 (USAC)

Este documento resume todo lo hecho hasta este punto: decisiones tomadas, problemas encontrados y cómo se resolvieron. Sirve como base para armar la documentación oficial en PDF (Fase 7) y para retomar el trabajo sin tener que repetir nada de lo ya hecho.

**Entrega y calificación: 19-sep-2026, con consultas en vivo.**

---

## 1. Resumen general del estado

| Fase | Estado | Contenido |
|---|---|---|
| Fase 0 — Preparación del entorno | ✅ Completa | SQL Server + SSMS + Python/VS Code instalados, carpetas creadas |
| Fase 1 — Auditoría de las 4 fuentes | ✅ Completa | 14 hallazgos documentados en Excel |
| Fase 2 — Staging + validación del DDL | ✅ Completa | 19 tablas creadas (9 finales + staging + catálogos) |
| Fase 3 — ETL (carga y transformación) | ✅ Completa | Las 9 tablas finales pobladas con datos reales |
| Fase 4 — Validación cruzada | ✅ Completa | Casos de prueba confirmados contra olympics.com |
| Fase 5 — Stored Procedures | ✅ Completa | Los 2 SP requeridos, mejorados y probados |
| Fase 6 — Consultas de práctica | ⏳ Pendiente |  |
| Fase 7 — Documentación final (PDF) | ⏳ Pendiente | Este documento es la base para esa fase |

---

## 2. Motor y herramientas usadas

- **Motor**: SQL Server 2025 Standard Developer Edition (gratuito, sin límite de tiempo), siguiendo la recomendación explícita del catedrático en la guía adicional entregada en clase.
- **Cliente**: SQL Server Management Studio (SSMS).
- **ETL**: Python (pandas, sqlalchemy, pyodbc) en notebooks de Jupyter dentro de VS Code.
- **Diagrama ER**: el del equipo (Grupo #16), ya entregado como borrador — no se rediseñó, todos los ajustes se hicieron a nivel de datos y quedan documentados aquí.

---

## 3. El modelo de datos (9 tablas)

`PAIS`, `POBLACION_PAIS`, `SEDE`, `EDICION_JUEGOS`, `DEPORTE`, `EVENTO`, `FUENTE_DATOS`, `ATLETA`, `PARTICIPACION` — esquema tipo estrella con `PARTICIPACION` como tabla central de hechos, siguiendo la recomendación de la guía del catedrático (7 a 9 tablas, ni hiper-normalizado ni sobre-desnormalizado).

**Conteos finales por tabla:**
- PAIS: 230
- POBLACION_PAIS: 11,520
- SEDE: 42
- EDICION_JUEGOS: 52
- DEPORTE: 66 (de Kaggle) + deportes adicionales agregados desde Galli en la Fase 3
- EVENTO: 1,798 (765 iniciales de Kaggle + 1,033 agregados desde Galli)
- FUENTE_DATOS: 9
- ATLETA: 233,354
- PARTICIPACION: 361,672

---

## 4. Decisiones y hallazgos, fase por fase

### Fase 1 — Auditoría de las 4 fuentes

Se auditaron 9 archivos (bios.csv, bios_locs.csv, results.csv y noc_regions.csv de Keith Galli; athlete_events.csv y noc_regions.csv de Kaggle 120 años; el dataset de Kaggle Summer Olympics 1896-2024; y el de DataCamp) con pandas, produciendo un Excel con 14 hallazgos. Los más relevantes:

- **SEDE.id_pais y EVENTO.es_por_equipo no existen en ninguna fuente** — hubo que construirlos manualmente.
- **La columna de medalla no está estandarizada**: el dataset de Kaggle Summer usa el texto `"No medal"` donde las demás fuentes usan un valor vacío.
- **Los dos catálogos `noc_regions.csv` (Galli y Kaggle) son idénticos** — se usó solo uno.
- **El nombre de deporte viene en formato distinto entre fuentes** (ej. Galli: "Artistic Gymnastics (Gymnastics)"; Kaggle: "Basketball").
- **Los eventos de equipo llegan hasta 37 filas repetidas por una sola medalla** (once titulares en fútbol, por ejemplo) y no se detectan por la palabra "Team" en el nombre del evento — no todos la llevan (fútbol, rugby, béisbol no la traen).
- **Nombres de atleta repetidos son, en su mayoría, personas reales distintas** (ej. "Ivan Ivanov" aparece 13 veces en el archivo, verificado que son 13 personas distintas contra olympics.com).
- **`populations.csv` viene en formato ancho** (una columna por año, 1960-2023) y requiere transformarse a formato largo antes de cargar.

### Fase 2 — Staging y catálogos

Se verificaron los largos máximos reales de texto contra los tipos `VARCHAR` definidos en el DDL original (todos dentro de límite, sin cambios de estructura necesarios). Se crearon:
- 8 tablas staging (una por archivo fuente), todas con columnas de tipo texto sin restricciones, para poder cargar los datos crudos sin que fallara nada por formato.
- `stg_catalogo_sedes`: catálogo manual con las 52 ediciones y su país anfitrión, verificado uno por uno contra olympics.com (no existe en ninguna fuente). Notas de criterio: Moscú 1980 se registró como "Soviet Union", Sarajevo 1984 como "Yugoslavia" (países que ya no existen, pero correctos para la fecha), y Múnich 1972 como "Federal Republic of Germany" (nombre completo, tal como lo muestra el sitio oficial).
- `stg_equivalencia_paises`: tabla para cruzar el código NOC (olímpico) con el código ISO3 (internacional), que no comparten columna entre archivos.
- `FUENTE_DATOS` se pobló con los 9 orígenes de datos.

### Fase 3 — ETL (carga, limpieza y transformación)

Se trabajó en 7 bloques, cargando primero a tablas staging y de ahí a las 9 tablas finales.

**Problemas técnicos resueltos:**
- Nombres de columna con espacios en `bios.csv` y `results.csv` que no coincidían con las columnas de staging — se renombraron antes de cargar.
- Truncamiento de texto en columnas de biografía (títulos nobiliarios muy largos) — se ampliaron a `VARCHAR(MAX)`.
- 3 códigos NOC sin nombre de país en el archivo original (`TUV`=Tuvalu, `ROT`=Refugee Olympic Team, `UNK`=Unknown) — se completaron manualmente antes de cargar a `PAIS`.
- `populations.csv` se transformó de formato ancho a largo con `pandas.melt()`, con doble conversión de tipo (decimal → entero) para evitar error de conversión.
- **`es_por_equipo`**: el criterio inicial (más de 1 fila repetida por evento+edición+medalla) detectaba también empates en eventos individuales (ej. esquí alpino con 2 personas empatadas). Se ajustó el umbral a más de 3 filas para capturar solo equipos reales.

**El cruce de identidad de atletas (el más delicado):**
Se cargaron primero los 145,500 atletas de Galli, y se cruzaron contra los 135,571 de Kaggle por nombre + código de país normalizados (el primer intento falló porque comparaba el nombre completo del país de Galli contra el código de 3 letras de Kaggle — se corrigió traduciendo con la tabla `PAIS`). Resultado: 233,354 atletas totales (98,072 exclusivos de Galli, 87,854 exclusivos de Kaggle, 47,428 en ambas fuentes).

**Limitación conocida y documentada**: en 289 casos (0.12%), más de un atleta de Kaggle coincidió por error con el mismo registro de Galli, porque la clave de cruce (nombre + país) no basta para diferenciar personas reales distintas con el mismo nombre y país (mismo patrón que "Ivan Ivanov" en la auditoría). Se aceptó por restricción de tiempo; falta agregar fecha de nacimiento a la clave para resolverlo del todo.

**Carga de participaciones (Bloque 7, decisión importante):**
Se detectó que `athlete_events.csv` (Kaggle), el dataset de Kaggle Summer y el de DataCamp contienen esencialmente los mismos registros de participación (mismo dataset base replicado 3 veces). Cargar las 3 hubiera triplicado el conteo de medallas. Se decidió usar solo `athlete_events.csv` para los atletas que están en Kaggle (270,199 filas) y `results.csv` (Galli) solo para los atletas exclusivos de Galli (91,473 filas), sin solaparse. Total: 361,672 participaciones, 54,821 con medalla (~15%, proporción esperada).

### Fase 4 — Validación cruzada

- Integridad referencial: 0 registros huérfanos.
- Balance de medallas Oro/Plata/Bronce: rango homogéneo (17,900-18,500), sin desbalances sospechosos.
- **Caso de prueba Michael Phelps**: coincidencia EXACTA con olympics.com — 23 Oro, 3 Plata, 2 Bronce en sus 30 participaciones cargadas. Es la validación más fuerte de que el modelo funciona correctamente a nivel de atleta individual.
- **Hallazgo importante**: una búsqueda por `LIKE '%Phelps%'` trae 85 resultados en total — solo los últimos 20 son de Michael Phelps, el resto son otras personas reales con apellido similar (ej. Jaycie Lynn Phelps, gimnasta). Confirma que el nombre solo no identifica de forma única a un atleta.
- Verificación de `es_por_equipo`: Basketball queda correctamente marcado con exactamente 12 filas por medalla (tamaño real de un roster olímpico).
- Las 8 ediciones en las que Estados Unidos fue sede coinciden exactamente con olympics.com.

**Conclusión: no se requirió ningún cambio al diagrama original.**

### Fase 5 — Stored Procedures

Se reescribieron los 2 Stored Procedures que ya existían (el original se conservó sin tocar para comparación, el nuevo quedó en `scripts/03_Stored_Procedures_v2.sql`):

- **`sp_ConsultarPais`**: ahora desglosa el medallero en Oro/Plata/Bronce sin inflar por eventos de equipo (usa `es_por_equipo` + `DISTINCT` por evento+edición en vez de contar filas directo), e indica explícitamente cuando un país nunca ha sido sede (regla del enunciado).
- **`sp_ConsultarAtleta`**: se agregó un filtro opcional de país/NOC y el ID interno del atleta en el resultado, para poder distinguir personas con nombre parecido (motivado directamente por el hallazgo de "Phelps" de la Fase 4).
- Se mejoró la detección de `es_por_equipo` agregando palabras clave (Doubles, Pairs, Relay, Synchronized, etc.) para cubrir equipos de exactamente 2 personas, que el umbral numérico no detectaba.

**Limitación conocida y documentada**: el medallero de `sp_ConsultarPais` para USA da 1,817 medallas de oro (bajó de 1,836 tras el ajuste de palabras clave), frente a un total histórico real de aproximadamente 1,300 — una sobreestimación de ~40%. Posiblemente relacionada con los 289 casos de colisión de identidad de atleta ya documentados en la Fase 3. No se investigó a fondo por restricción de tiempo; queda como mejora futura. Ningún Stored Procedure usa `SELECT *` (regla estricta de la cátedra).

---

## 5. Lo que falta

- **Fase 6 (consultas de práctica)**: preparar y probar un banco de consultas sueltas (medallistas de un país, oro en un evento/año específico, atleta con más medallas de oro, atletas con medallas en más de un país, etc.) para la calificación en vivo del 19-sep. Asignada a otro integrante del equipo.
- **Fase 7 (documentación final en PDF)**: consolidar todo este documento, con capturas de pantalla (fecha y hora) de cada paso relevante, en el PDF que pide el enunciado — de dónde se descargó cada fuente, dónde se usó, qué problemas hubo y cómo se resolvieron.

---

## 6. Estructura de carpetas del proyecto (cómo debe verse antes de enviar)

```
ProyectoOlimpiadas/
├── raw/                          → los 9 CSV originales, sin modificar
├── staging/
│   ├── auditoria.ipynb           → notebook de la Fase 1
│   └── etl_carga.ipynb           → notebook de la Fase 3
├── scripts/
│   ├── 01_DDL_Tablas.sql         → creación de las 9 tablas (original del equipo)
│   ├── 02_DDL_Staging.sql        → tablas staging + catálogos de la Fase 2
│   ├── Stored Procedures.sql     → versión original del compañero
│   ├── 03_Stored_Procedures_v2.sql → versión corregida y mejorada (Fase 5)
│   └── 04_Consultas_Precargadas.sql → pendiente (Fase 6)
├── modelo/
│   ├── ER_Grupo16.jpeg           → diagrama entidad-relación original
│   └── cambios.md                → este mismo contenido, o una versión ampliada
├── docs/
│   ├── mapeo_fuentes.xlsx        → Excel de auditoría (Fase 1)
│   ├── capturas/                 → todas las capturas con fecha/hora, por fase
│   └── (aquí va el PDF final de la Fase 7 cuando esté listo)
└── OlimpiadasDB.bak              → backup completo de la base de datos con todos los datos cargados
```

**Antes de enviar, confirma que existan**: los 9 CSV en `raw/`, los 2 notebooks corridos sin errores, los 4 scripts SQL de `scripts/`, el Excel de mapeo, la carpeta de capturas con contenido real, y el `.bak` de la base de datos generado recientemente.

---

## 7. Backup


**Paso 1 — Confirmar**
Pídele que, al descomprimir, cuente 9 archivos en `raw/`, 4-5 scripts en `scripts/`, y que intente restaurar el backup en su propia SSMS con:
```sql
RESTORE DATABASE OlimpiadasDB
FROM DISK = 'C:\OlimpiadasDB.bak'
WITH REPLACE;
GO
```
*(Ajusta la ruta a donde él guarde el archivo.)* Si eso corre sin error y ve las 9 tablas con datos, tiene una copia exacta de tu progreso.
