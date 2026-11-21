"""ETL: lee train.csv (dentro del ZIP) por bloques y lo carga a stg_comentarios con COPY.

Uso (local o Colab):
    export DW_URL="postgresql://USUARIO:CLAVE@HOST/neondb?sslmode=require"
    export ZIP_PATH="/ruta/train_csv.zip"
    export MAX_FILAS=300000        # opcional: carga de prueba; omitir para cargar todo
    python etl/carga_staging.py

Antes: ejecutar sql/01_ddl.sql (crea la tabla stg_comentarios).
En Colab: guardar DW_URL en Secrets y leerla con google.colab.userdata.
"""
import io, os, time, zipfile
import pandas as pd
import psycopg2

DW_URL = os.environ["DW_URL"].replace("postgresql+psycopg2://", "postgresql://")
ZIP_PATH = os.environ["ZIP_PATH"]
MAX_FILAS = int(os.environ["MAX_FILAS"]) if os.environ.get("MAX_FILAS") else None
TAM_BLOQUE = 100_000

COLS = ["id", "created_date", "target", "severe_toxicity", "obscene", "identity_attack",
        "insult", "threat", "sexual_explicit", "publication_id", "article_id", "rating",
        "funny", "wow", "sad", "likes", "disagree",
        "toxicity_annotator_count", "identity_annotator_count"]

conn = psycopg2.connect(DW_URL)
cur = conn.cursor()
cur.execute("TRUNCATE stg_comentarios")          # reproceso limpio
conn.commit()

leidas, t0 = 0, time.time()
with zipfile.ZipFile(ZIP_PATH) as z, z.open("train.csv") as f:
    for i, chunk in enumerate(pd.read_csv(f, usecols=COLS, chunksize=TAM_BLOQUE,
                                          dtype={"created_date": str, "rating": str})):
        chunk = chunk[COLS]                      # orden igual al de la tabla
        if MAX_FILAS is not None and leidas + len(chunk) > MAX_FILAS:
            chunk = chunk.iloc[: MAX_FILAS - leidas]
        buf = io.StringIO()
        chunk.to_csv(buf, index=False, header=False)
        buf.seek(0)
        cur.copy_expert(f"COPY stg_comentarios ({', '.join(COLS)}) FROM STDIN WITH CSV", buf)
        conn.commit()
        leidas += len(chunk)
        print(f"Bloque {i+1}: {leidas:,} filas acumuladas ({time.time()-t0:.0f} s)")
        if MAX_FILAS is not None and leidas >= MAX_FILAS:
            break

cur.execute("SELECT COUNT(*) FROM stg_comentarios")
print("Filas leidas:", leidas, "| filas en staging:", cur.fetchone()[0])
cur.close(); conn.close()
