-- Question: Which categories have the highest return rates, and what does that cost?
-- Skills: CASE inside aggregates, HAVING

SELECT
    p.category,
    COUNT(DISTINCT o.order_id)                                                         AS orders_with_category,
    COUNT(DISTINCT CASE WHEN o.status = 'Returned' THEN o.order_id END)                AS returned_orders,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN o.status = 'Returned' THEN o.order_id END)
          / COUNT(DISTINCT o.order_id), 1)                                             AS return_rate_pct,
    ROUND(SUM(CASE WHEN o.status = 'Returned'
                   THEN oi.quantity * oi.unit_price * (1 - oi.discount) ELSE 0 END), 2) AS returned_revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p     ON p.product_id = oi.product_id
WHERE o.status IN ('Completed', 'Returned')
GROUP BY p.category
HAVING COUNT(DISTINCT o.order_id) >= 50
ORDER BY return_rate_pct DESC;
