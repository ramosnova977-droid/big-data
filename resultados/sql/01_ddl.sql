-- 01_ddl.sql : modelo estrella (ejecutar una vez en Neon o pgAdmin)
CREATE TABLE IF NOT EXISTS dim_fecha (
  fecha_key INTEGER PRIMARY KEY,
  fecha DATE UNIQUE, anio SMALLINT, trimestre SMALLINT,
  mes SMALLINT, semana_iso SMALLINT, dia SMALLINT);
CREATE TABLE IF NOT EXISTS dim_articulo (articulo_key BIGSERIAL PRIMARY KEY, article_id BIGINT UNIQUE);
CREATE TABLE IF NOT EXISTS dim_publicacion (publicacion_key BIGSERIAL PRIMARY KEY, publication_id BIGINT UNIQUE);
CREATE TABLE IF NOT EXISTS dim_rating (rating_key SMALLSERIAL PRIMARY KEY, rating TEXT UNIQUE, estado_homologado TEXT);
CREATE TABLE IF NOT EXISTS dim_nivel_toxicidad (
  nivel_key SMALLINT PRIMARY KEY, nombre TEXT,
  limite_inferior NUMERIC, limite_superior NUMERIC, version_regla TEXT);

INSERT INTO dim_nivel_toxicidad VALUES
 (1,'No toxico',0,0.5,'v1'), (2,'Toxico',0.5,1,'v1')
ON CONFLICT (nivel_key) DO NOTHING;

CREATE TABLE IF NOT EXISTS fact_comentarios (
  comentario_key BIGSERIAL PRIMARY KEY,
  id_origen BIGINT UNIQUE NOT NULL,
  fecha_key INTEGER REFERENCES dim_fecha,
  articulo_key BIGINT REFERENCES dim_articulo,
  publicacion_key BIGINT REFERENCES dim_publicacion,
  rating_key SMALLINT REFERENCES dim_rating,
  nivel_key SMALLINT REFERENCES dim_nivel_toxicidad,
  total_comentarios INTEGER DEFAULT 1,
  target DOUBLE PRECISION, indicador_toxico SMALLINT,
  severe_toxicity DOUBLE PRECISION, obscene DOUBLE PRECISION,
  identity_attack DOUBLE PRECISION, insult DOUBLE PRECISION,
  threat DOUBLE PRECISION, sexual_explicit DOUBLE PRECISION,
  likes INTEGER, funny INTEGER, wow INTEGER, sad INTEGER, disagree INTEGER,
  toxicity_annotator_count INTEGER, identity_annotator_count INTEGER);

-- Tabla de staging (la llena etl/carga_staging.py con COPY)
CREATE TABLE IF NOT EXISTS stg_comentarios (
  id BIGINT, created_date TEXT, target DOUBLE PRECISION,
  severe_toxicity DOUBLE PRECISION, obscene DOUBLE PRECISION, identity_attack DOUBLE PRECISION,
  insult DOUBLE PRECISION, threat DOUBLE PRECISION, sexual_explicit DOUBLE PRECISION,
  publication_id BIGINT, article_id BIGINT, rating TEXT,
  funny INTEGER, wow INTEGER, sad INTEGER, likes INTEGER, disagree INTEGER,
  toxicity_annotator_count INTEGER, identity_annotator_count INTEGER);
