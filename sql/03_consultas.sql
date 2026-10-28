-- =====================================================================
-- 03_consultas.sql — Consultas para revisar el modelo y calcular KPIs
-- =====================================================================
-- Cada SELECT de este archivo se muestra en la terminal al ejecutar
-- run_sql.py. Usalo para:
--   * comprobar que las tablas se cargaron bien (cantidad de filas, nulos...)
--   * escribir las consultas clave de los KPIs que pide la consigna
--     (ventas, usuarios activos, ticket promedio, NPS, ventas por provincia,
--     ranking mensual por producto) usando las tablas del modelo estrella.
-- =====================================================================


-- Ejemplo: revisar la dimensión producto
--SELECT product_key, name, category, family, list_price
--FROM dim_product
--ORDER BY product_key;


-- TU TURNO: agregá acá tus consultas.
-- =====================================================================
-- 03_consultas.sql — KPIs del dashboard y consultas de control
-- Regla: una venta es un pedido con status PAID o FULFILLED
-- =====================================================================

-- 1) VENTAS: tarjeta total y serie mensual
SELECT
    COUNT(*)          AS pedidos,
    SUM(total_amount) AS ventas_totales
FROM fact_sales
WHERE status IN ('PAID', 'FULFILLED');

SELECT
    d.year, d.month,
    COUNT(*)            AS pedidos,
    SUM(f.total_amount) AS ventas
FROM fact_sales AS f
JOIN dim_date AS d ON d.date_id = f.date_id
WHERE f.status IN ('PAID', 'FULFILLED')
GROUP BY d.year, d.month
ORDER BY d.year, d.month;

-- 2) TICKET PROMEDIO: mismas filas en numerador y denominador
SELECT
    d.year, d.month,
    ROUND(SUM(f.total_amount) / COUNT(*), 2) AS ticket_promedio
FROM fact_sales AS f
JOIN dim_date AS d ON d.date_id = f.date_id
WHERE f.status IN ('PAID', 'FULFILLED')
GROUP BY d.year, d.month
ORDER BY d.year, d.month;

-- 3) USUARIOS ACTIVOS: clientes distintos con sesión, por mes
--    Las sesiones anónimas (customer_id NULL) no entran en el conteo de
--    clientes; se informan aparte.
SELECT
    d.year, d.month,
    COUNT(DISTINCT w.customer_id)                           AS usuarios_activos,
    COUNT(*)                                                AS sesiones,
    SUM(CASE WHEN w.customer_id IS NULL THEN 1 ELSE 0 END)  AS sesiones_anonimas
FROM fact_web_session AS w
JOIN dim_date AS d ON d.date_id = w.date_id
GROUP BY d.year, d.month
ORDER BY d.year, d.month;

-- 4) NPS: (% de 9-10) - (% de 0-6), sobre TODAS las respuestas (incluye anónimas)
SELECT
    d.year, d.month,
    COUNT(*) AS respuestas,
    ROUND(100.0 * (SUM(CASE WHEN n.score >= 9 THEN 1 ELSE 0 END)
                 - SUM(CASE WHEN n.score <= 6 THEN 1 ELSE 0 END)) / COUNT(*), 1) AS nps
FROM fact_nps AS n
JOIN dim_date AS d ON d.date_id = n.date_id
GROUP BY d.year, d.month
ORDER BY d.year, d.month;

-- NPS por canal (total del período)
SELECT
    c.code AS canal,
    COUNT(*) AS respuestas,
    ROUND(100.0 * (SUM(CASE WHEN n.score >= 9 THEN 1 ELSE 0 END)
                 - SUM(CASE WHEN n.score <= 6 THEN 1 ELSE 0 END)) / COUNT(*), 1) AS nps
FROM fact_nps AS n
JOIN dim_channel AS c ON c.channel_id = n.channel_id
GROUP BY c.code;

-- 5) VENTAS POR PROVINCIA (por dirección de envío)
SELECT
    COALESCE(l.province_name, 'Sin provincia') AS provincia,
    COUNT(*)            AS pedidos,
    SUM(f.total_amount) AS ventas
FROM fact_sales AS f
LEFT JOIN dim_location AS l ON l.location_id = f.location_id
WHERE f.status IN ('PAID', 'FULFILLED')
GROUP BY COALESCE(l.province_name, 'Sin provincia')
ORDER BY ventas DESC;

-- 6) RANKING MENSUAL POR PRODUCTO
WITH ventas_mes AS (
    SELECT
        d.year, d.month,
        p.name AS producto,
        SUM(i.line_total) AS ventas
    FROM fact_sales_item AS i
    JOIN dim_date AS d    ON d.date_id = i.date_id
    JOIN dim_product AS p ON p.product_key = i.product_key
    WHERE i.status IN ('PAID', 'FULFILLED')
    GROUP BY d.year, d.month, p.name
)
SELECT
    year, month, producto, ventas,
    RANK() OVER (PARTITION BY year, month ORDER BY ventas DESC) AS ranking
FROM ventas_mes
ORDER BY year, month, ranking;