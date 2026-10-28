-- Question: Which products drive the most revenue, and how profitable are they?
-- Skills: multi-table JOIN, aggregation, calculated margin

SELECT
    p.product_name,
    p.category,
    SUM(oi.quantity)                                                        AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2)          AS net_revenue,
    ROUND(SUM(oi.quantity * (oi.unit_price * (1 - oi.discount) - p.unit_cost)), 2) AS gross_profit,
    ROUND(100.0 * SUM(oi.quantity * (oi.unit_price * (1 - oi.discount) - p.unit_cost))
          / SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 1)        AS gross_margin_pct
FROM order_items oi
JOIN orders o   ON o.order_id = oi.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE o.status = 'Completed'
GROUP BY p.product_id
ORDER BY net_revenue DESC
LIMIT 10;
