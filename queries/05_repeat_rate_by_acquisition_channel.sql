-- Question: Which acquisition channels bring in customers who come back?
-- Skills: subquery aggregation, conditional counting with CASE

WITH per_customer AS (
    SELECT
        c.customer_id,
        c.acquisition_channel,
        COUNT(o.order_id) AS completed_orders
    FROM customers c
    LEFT JOIN orders o ON o.customer_id = c.customer_id AND o.status = 'Completed'
    GROUP BY c.customer_id
)
SELECT
    acquisition_channel,
    COUNT(*)                                                             AS customers,
    SUM(CASE WHEN completed_orders >= 2 THEN 1 ELSE 0 END)               AS repeat_customers,
    ROUND(100.0 * SUM(CASE WHEN completed_orders >= 2 THEN 1 ELSE 0 END) / COUNT(*), 1) AS repeat_rate_pct,
    ROUND(AVG(completed_orders), 2)                                      AS avg_orders_per_customer
FROM per_customer
GROUP BY acquisition_channel
ORDER BY repeat_rate_pct DESC;
