# Data Warehouse para el análisis de contenido tóxico (Civil Comments / Jigsaw)

Proyecto de aula · Data Warehouse y Big Data · Politécnico Grancolombiano · 2026

Bodega de datos dimensional (esquema estrella) sobre `train.csv` de *Jigsaw Unintended Bias in Toxicity
Classification* (Kaggle), con consultas ROLAP en PostgreSQL y un dashboard en Streamlit.

## Estructura

```
sql/        01_ddl.sql · 02_carga_modelo.sql · 03_calidad.sql · 04_rolap.sql
etl/        carga_staging.py   (lectura por bloques del ZIP + COPY a staging)
dashboard/  app.py · requirements.txt
resultados/ CSV con los resultados de P1 a P5 (archivo completo, calculados con Pandas)
figuras/    gráficos de apoyo generados con matplotlib
```

## Reproducción paso a paso

1. **Datos:** descargar `train.csv` (ZIP) desde Kaggle. No se sube a GitHub.
2. **Base de datos:** crear un proyecto PostgreSQL (por ejemplo, en Neon) y copiar su cadena de conexión.
3. **Variable de conexión** (nunca en el código ni en GitHub):
   - Linux/macOS: `export DW_URL="postgresql://USUARIO:CLAVE@HOST/neondb?sslmode=require"`
   - Windows (PowerShell): `$env:DW_URL="postgresql://USUARIO:CLAVE@HOST/neondb?sslmode=require"`
   - Colab: guardar `DW_URL` en *Secrets* y leerla con `google.colab.userdata.get("DW_URL")`.
4. **Esquema:** ejecutar `sql/01_ddl.sql` en el SQL Editor de Neon (o pgAdmin).
5. **ETL a staging:**
   ```
   pip install pandas psycopg2-binary
   export ZIP_PATH="/ruta/train_csv.zip"
   export MAX_FILAS=300000      # carga de prueba; omitir para cargar todo
   python etl/carga_staging.py
   ```
6. **Modelo estrella:** ejecutar `sql/02_carga_modelo.sql`.
7. **Calidad:** ejecutar `sql/03_calidad.sql` y guardar los resultados para el informe.
8. **ROLAP:** ejecutar `sql/04_rolap.sql` y comparar con `resultados/*.csv` (si se cargó el archivo completo, deben coincidir).
9. **Dashboard:**
   ```
   pip install -r dashboard/requirements.txt
   streamlit run dashboard/app.py
   ```

## Nota sobre el plan gratuito de Neon

El archivo completo tiene 1.804.874 filas; staging + hechos + índices pueden superar el almacenamiento gratuito.
Opciones: cargar un subconjunto con `MAX_FILAS`, o ejecutar `DROP TABLE stg_comentarios;` después de validar
(paso 7) y antes de crear los índices. Las cifras del informe deben corresponder al volumen realmente cargado.

## Práctica en Killercoda (PostgreSQL con Docker)

```
docker run --name pg -e POSTGRES_PASSWORD=clave_local -p 5432:5432 -d postgres:16
docker exec -it pg psql -U postgres -c "CREATE DATABASE dw_toxicidad;"
docker cp sql/01_ddl.sql pg:/tmp/ && docker exec -it pg psql -U postgres -d dw_toxicidad -f /tmp/01_ddl.sql
```

Cadena de conexión local (sin credenciales reales en el repositorio):
`postgresql://postgres:CLAVE@localhost:5432/dw_toxicidad`

## Convenciones analíticas

- Toxicidad elevada: `target >= 0,50` (umbral de la competencia; no es una norma editorial).
- Los porcentajes se calculan con su denominador; los promedios, con observaciones válidas.
- `rating` es un metadato de origen: su relación con la toxicidad es descriptiva, no prueba errores de moderación.
- No se muestran textos de comentarios.

## Fuentes

Jigsaw. (2019). *Jigsaw unintended bias in toxicity classification*. Kaggle.
https://www.kaggle.com/competitions/jigsaw-unintended-bias-in-toxicity-classification/data
