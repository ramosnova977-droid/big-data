-- 04_rolap.sql : consultas ROLAP P1 a P5

-- P1: roll-up / drill-down anio > mes
SELECT d.anio, d.mes, SUM(f.total_comentarios) AS comentarios,
       ROUND(100.0*SUM(f.indicador_toxico)/NULLIF(COUNT(f.indicador_toxico),0),2) AS pct_toxicos
FROM fact_comentarios f JOIN dim_fecha d USING (fecha_key)
GROUP BY ROLLUP (d.anio, d.mes)
ORDER BY d.anio, d.mes;

-- P2: ranking de publicaciones (minimo 100 comentarios)
SELECT p.publication_id, COUNT(*) AS comentarios,
       ROUND(100.0*SUM(f.indicador_toxico)/COUNT(f.indicador_toxico),2) AS pct_toxicos,
       ROUND(AVG(f.target)::numeric,4) AS target_medio
FROM fact_comentarios f JOIN dim_publicacion p USING (publicacion_key)
GROUP BY p.publication_id
HAVING COUNT(*) >= 100
ORDER BY pct_toxicos DESC
LIMIT 10;

-- P3 (slice por rating)
SELECT r.estado_homologado AS rating, SUM(f.total_comentarios) AS comentarios,
       SUM(f.indicador_toxico) AS comentarios_toxicos,
       ROUND(100.0*SUM(f.indicador_toxico)/NULLIF(COUNT(f.indicador_toxico),0),2) AS pct_toxicos,
       ROUND(AVG(f.target)::numeric,4) AS toxicidad_media
FROM fact_comentarios f JOIN dim_rating r USING (rating_key)
GROUP BY r.estado_homologado
ORDER BY pct_toxicos DESC;

-- P3 (pivot approved / rejected por publicacion)
SELECT p.publication_id,
  ROUND(100.0*SUM(f.indicador_toxico) FILTER (WHERE r.estado_homologado='approved')
        / NULLIF(COUNT(f.indicador_toxico) FILTER (WHERE r.estado_homologado='approved'),0),2) AS pct_approved,
  ROUND(100.0*SUM(f.indicador_toxico) FILTER (WHERE r.estado_homologado='rejected')
        / NULLIF(COUNT(f.indicador_toxico) FILTER (WHERE r.estado_homologado='rejected'),0),2) AS pct_rejected
FROM fact_comentarios f
JOIN dim_publicacion p USING (publicacion_key) JOIN dim_rating r USING (rating_key)
GROUP BY p.publication_id ORDER BY p.publication_id;

-- P4: articulos con mas comentarios (minimo 50) e insult/threat medio
SELECT a.article_id, COUNT(*) AS comentarios,
       ROUND(AVG(f.insult)::numeric,4) AS insult_medio,
       ROUND(AVG(f.threat)::numeric,4) AS threat_medio
FROM fact_comentarios f JOIN dim_articulo a USING (articulo_key)
GROUP BY a.article_id
HAVING COUNT(*) >= 50
ORDER BY comentarios DESC
LIMIT 20;
-- Variante: cambiar ORDER BY por insult_medio DESC o threat_medio DESC

-- P5: reacciones por nivel de toxicidad (sin filtro: reproduce los resultados del informe)
SELECT n.nombre AS nivel, COUNT(*) AS comentarios,
       ROUND(AVG(f.likes)::numeric,3) AS likes_medio,
       ROUND(AVG(f.disagree)::numeric,3) AS disagree_medio
FROM fact_comentarios f JOIN dim_nivel_toxicidad n USING (nivel_key)
GROUP BY n.nombre ORDER BY n.nombre;

-- P5 (dice): mismo analisis restringido a un rango de anios
SELECT n.nombre AS nivel, COUNT(*) AS comentarios,
       ROUND(AVG(f.likes)::numeric,3) AS likes_medio,
       ROUND(AVG(f.disagree)::numeric,3) AS disagree_medio
FROM fact_comentarios f
JOIN dim_nivel_toxicidad n USING (nivel_key) JOIN dim_fecha d USING (fecha_key)
WHERE d.anio BETWEEN 2016 AND 2017
GROUP BY n.nombre ORDER BY n.nombre;
