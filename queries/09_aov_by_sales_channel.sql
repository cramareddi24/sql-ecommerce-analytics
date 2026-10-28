-- Question: Does average order value differ by sales channel, and is it changing?
-- Skills: two-level aggregation (order level, then channel level), pivot with CASE

WITH order_totals AS (
    SELECT
        o.order_id,
        o.sales_channel,
        strftime('%Y', o.order_date)                             AS year,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount))     AS order_value
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'Completed'
    GROUP BY o.order_id
)
SELECT
    sales_channel,
    COUNT(*)                                                          AS orders,
    ROUND(AVG(order_value), 2)                                        AS avg_order_value,
    ROUND(AVG(CASE WHEN year = '2024' THEN order_value END), 2)       AS aov_2024,
    ROUND(AVG(CASE WHEN year = '2025' THEN order_value END), 2)       AS aov_2025_h1
FROM order_totals
GROUP BY sales_channel
ORDER BY avg_order_value DESC;
