-- 02_carga_modelo.sql : staging -> dimensiones -> hechos (ejecutar despues del ETL de Python)
INSERT INTO dim_fecha
SELECT DISTINCT to_char(d,'YYYYMMDD')::int, d, EXTRACT(year FROM d), EXTRACT(quarter FROM d),
       EXTRACT(month FROM d), EXTRACT(week FROM d), EXTRACT(day FROM d)
FROM (SELECT (created_date::timestamptz AT TIME ZONE 'UTC')::date AS d FROM stg_comentarios) x
WHERE d IS NOT NULL
ON CONFLICT (fecha_key) DO NOTHING;

INSERT INTO dim_articulo(article_id)
  SELECT DISTINCT article_id FROM stg_comentarios WHERE article_id IS NOT NULL
ON CONFLICT (article_id) DO NOTHING;
INSERT INTO dim_publicacion(publication_id)
  SELECT DISTINCT publication_id FROM stg_comentarios WHERE publication_id IS NOT NULL
ON CONFLICT (publication_id) DO NOTHING;
INSERT INTO dim_rating(rating, estado_homologado)
  SELECT DISTINCT rating, lower(trim(rating)) FROM stg_comentarios WHERE rating IS NOT NULL
ON CONFLICT (rating) DO NOTHING;

INSERT INTO fact_comentarios (id_origen, fecha_key, articulo_key, publicacion_key, rating_key,
  nivel_key, target, indicador_toxico, severe_toxicity, obscene, identity_attack, insult, threat,
  sexual_explicit, likes, funny, wow, sad, disagree, toxicity_annotator_count, identity_annotator_count)
SELECT s.id,
  to_char((s.created_date::timestamptz AT TIME ZONE 'UTC')::date,'YYYYMMDD')::int,
  a.articulo_key, p.publicacion_key, r.rating_key,
  CASE WHEN s.target >= 0.5 THEN 2 WHEN s.target IS NOT NULL THEN 1 END,
  s.target,
  CASE WHEN s.target >= 0.5 THEN 1 WHEN s.target IS NOT NULL THEN 0 END,
  s.severe_toxicity, s.obscene, s.identity_attack, s.insult, s.threat, s.sexual_explicit,
  s.likes, s.funny, s.wow, s.sad, s.disagree, s.toxicity_annotator_count, s.identity_annotator_count
FROM stg_comentarios s
LEFT JOIN dim_articulo a ON a.article_id = s.article_id
LEFT JOIN dim_publicacion p ON p.publication_id = s.publication_id
LEFT JOIN dim_rating r ON r.rating = s.rating
ON CONFLICT (id_origen) DO NOTHING;

-- Indices para consultas ROLAP (opcional si el espacio es limitado)
CREATE INDEX IF NOT EXISTS ix_fact_fecha ON fact_comentarios(fecha_key);
CREATE INDEX IF NOT EXISTS ix_fact_publicacion ON fact_comentarios(publicacion_key);
CREATE INDEX IF NOT EXISTS ix_fact_articulo ON fact_comentarios(articulo_key);

-- Vista base del dashboard
CREATE OR REPLACE VIEW vw_dashboard AS
SELECT f.id_origen, d.fecha, d.anio, d.trimestre, d.mes,
       p.publication_id, a.article_id, r.estado_homologado AS rating,
       n.nombre AS nivel_toxicidad, f.total_comentarios, f.target, f.indicador_toxico,
       f.insult, f.threat, f.likes, f.disagree
FROM fact_comentarios f
LEFT JOIN dim_fecha d USING (fecha_key)
LEFT JOIN dim_publicacion p USING (publicacion_key)
LEFT JOIN dim_articulo a USING (articulo_key)
LEFT JOIN dim_rating r USING (rating_key)
LEFT JOIN dim_nivel_toxicidad n USING (nivel_key);

-- Cuando todo este validado (03_calidad.sql) y se necesite espacio:
-- DROP TABLE stg_comentarios;
