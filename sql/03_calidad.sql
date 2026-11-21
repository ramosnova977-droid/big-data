-- 03_calidad.sql : pruebas de calidad (copiar resultados al informe)
-- Reconciliacion (ejecutar ANTES de borrar staging)
SELECT (SELECT COUNT(*) FROM stg_comentarios) AS leidas,
       (SELECT COUNT(*) FROM fact_comentarios) AS cargadas;
-- Unicidad
SELECT COUNT(*) AS filas, COUNT(DISTINCT id_origen) AS ids_distintos FROM fact_comentarios;
-- Validez
SELECT COUNT(*) AS fuera_de_rango FROM fact_comentarios
WHERE target NOT BETWEEN 0 AND 1 OR severe_toxicity NOT BETWEEN 0 AND 1 OR obscene NOT BETWEEN 0 AND 1
   OR identity_attack NOT BETWEEN 0 AND 1 OR insult NOT BETWEEN 0 AND 1
   OR threat NOT BETWEEN 0 AND 1 OR sexual_explicit NOT BETWEEN 0 AND 1;
-- Integridad
SELECT COUNT(*) AS claves_nulas FROM fact_comentarios
WHERE fecha_key IS NULL OR articulo_key IS NULL OR publicacion_key IS NULL OR rating_key IS NULL;
-- Consistencia
SELECT COUNT(*) AS discrepancias FROM fact_comentarios
WHERE (target >= 0.5 AND (nivel_key <> 2 OR indicador_toxico <> 1))
   OR (target <  0.5 AND (nivel_key <> 1 OR indicador_toxico <> 0));
-- Completitud
SELECT COUNT(*) - COUNT(target) AS target_nulos, COUNT(*) - COUNT(likes) AS likes_nulos,
       COUNT(*) - COUNT(articulo_key) AS articulo_nulos, COUNT(*) - COUNT(fecha_key) AS fecha_nulos
FROM fact_comentarios;
-- Conteo de dimensiones (esperado con el archivo completo: 105380 articulos, 53 publicaciones, 2 ratings)
SELECT (SELECT COUNT(*) FROM dim_articulo) AS articulos, (SELECT COUNT(*) FROM dim_publicacion) AS publicaciones,
       (SELECT COUNT(*) FROM dim_rating) AS ratings, (SELECT COUNT(*) FROM dim_fecha) AS fechas;
