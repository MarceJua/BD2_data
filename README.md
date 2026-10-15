# Proyecto 2 — Respaldo y Restauración de Bases de Datos

**Curso:** Sistemas de Bases de Datos 2 · Universidad de San Carlos de Guatemala · 2.º semestre 2026
**Grupo:** #16 (Marcelo Andrés Juárez Alfaro, Carlos David de León Barrios, Ángel Rafael Barrios González)
**Motor:** Microsoft SQL Server 2025 · **Herramienta de respaldo y restauración:** `sqlcmd` (consola, sin interfaz gráfica)
**Base de datos:** `OlimpiadasDB`, la base unificada del Proyecto 1 (Juegos Olímpicos 1896–2024), depurada para esta fase.

Este repositorio contiene la implementación de tres escenarios de carga (por año, por deporte y por deportista). En cada uno se ejecuta una carga inicial, un respaldo **Full**, tres sub-cargas con un respaldo **Diferencial** después de cada una, y cuatro restauraciones con validación de integridad.

## Estructura

```
Backups_Fase2/
├── README.md                          Este archivo
├── OlimpiadasDB_Fase2_Limpia.bak      Base de partida (depurada) de los tres escenarios
├── Scripts/                           Escenario 1: Carga por Año
│   ├── 01_Carga_Inicial_Anio.sql
│   ├── 02_Carga_Anio_2016.sql
│   ├── 03_Carga_Anio_2020.sql
│   ├── 04_Carga_Anio_2024.sql
│   └── 05_Validar_Restauracion_Anio.sql
├── Scripts_Deporte/                   Escenario 2: Carga por Deporte (Athletics)
│   ├── 01_Carga_Inicial_Deporte.sql … 05_Validar_Restauracion_Deporte.sql
│   ├── comandos.txt                   Secuencia completa de comandos de consola
│   └── resultadosComandos.txt         Resultados de la ejecución
├── Scripts_Deportista/                Escenario 3: Carga por Deportista (Usain Bolt)
│   ├── 01_Carga_Inicial_Deportista.sql
│   ├── 02_Carga_Bolt_2004.sql · 03_Carga_Bolt_2008.sql · 04_Carga_Bolt_2012.sql
│   ├── 05_Validar_Restauracion_Deportista.sql
│   ├── comandos.txt                   Secuencia completa de comandos de consola
│   └── resultadosComandos.txt         Log de ejecución (comandos y salidas)
├── Carga_Anio/                        Respaldos generados: Full + Diferenciales 1 a 3
├── Carga_Deporte/                     Respaldos generados: Full + Diferenciales 1 a 3
├── Carga_Deportista/                  Respaldos generados: Full + Diferenciales 1 a 3
└── Documentacion/
    ├── Documentación Técnica (.md y .pdf)
    ├── Documentación De Usuario (.md y .pdf)
    └── img/                           Capturas de pantalla (con fecha y hora del sistema)
```

## Correspondencia por tipo de script

| Tipo | Dónde está |
| ---- | ---------- |
| **Creación de la base (DDL)** | `01_Carga_Inicial_*.sql`: crea la base del escenario en modelo de recuperación FULL y sus 9 tablas |
| **Carga de datos** | `01_Carga_Inicial_*.sql` (carga inicial) y `02_`, `03_`, `04_Carga_*.sql` (sub-cargas) |
| **Respaldo (Full y Diferencial)** | `comandos.txt` de cada escenario (`BACKUP DATABASE … WITH DIFFERENTIAL`); en el Escenario 1, secciones 5 y 6 de la Documentación Técnica |
| **Restauración** | `comandos.txt` (`RESTORE DATABASE … WITH NORECOVERY / RECOVERY`) |
| **Validación post-restauración** | `05_Validar_Restauracion_*.sql`: conteo de las 9 tablas y participaciones del criterio de cada escenario |
| **Logs de ejecución** | `resultadosComandos.txt` y capturas en `Documentacion/img/` |

## Cómo reproducir un escenario

1. **Restaurar la base de partida** (requiere SQL Server y `sqlcmd`; los archivos deben estar en `C:\Backups_Fase2\`):

```
sqlcmd -S localhost -E -C -Q "IF EXISTS (SELECT name FROM sys.databases WHERE name = N'OlimpiadasDB') BEGIN ALTER DATABASE OlimpiadasDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE; END RESTORE DATABASE OlimpiadasDB FROM DISK = N'C:\Backups_Fase2\OlimpiadasDB_Fase2_Limpia.bak' WITH REPLACE; ALTER DATABASE OlimpiadasDB SET MULTI_USER;"
```

2. **Dar permiso de escritura** a SQL Server en la carpeta de respaldos del escenario (una sola vez, en PowerShell como administrador), por ejemplo:

```
icacls "C:\Backups_Fase2\Carga_Deportista" /grant "NT SERVICE\MSSQLSERVER:(OI)(CI)F"
```

3. **Ejecutar la secuencia** de `comandos.txt` del escenario, desde el Símbolo del sistema (CMD), en este orden: carga inicial → Full → sub-carga 1 → Diferencial 1 → sub-carga 2 → Diferencial 2 → sub-carga 3 → Diferencial 3 → cuatro ciclos de `DROP DATABASE`, restauración y validación.

4. **Validar:** el script `05_Validar_Restauracion_*.sql` debe mostrar, tras cada restauración, el conteo esperado en `PARTICIPACION` (el último ciclo debe devolver 386,195 filas, igual que la base de partida).

> Importante: después de sacar el Full no se debe sacar otro Full, porque cambia la base contra la que se calculan los diferenciales y rompe la cadena de restauración.

## Documentación

- **Documentación Técnica:** metodología, especificaciones del servidor, modelo entidad-relación, plan de respaldo, resultados de los tres escenarios, análisis comparativo y conclusiones.
- **Documentación De Usuario:** guía paso a paso de respaldo Full y Diferencial por consola, restauración, lectura de logs de `sqlcmd` y validación post-restauración.

Todas las capturas de pantalla muestran la fecha y hora del sistema operativo.
