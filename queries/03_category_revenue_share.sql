-- Question: What share of revenue and profit does each category contribute?
-- Skills: window function over the full result set (SUM() OVER ())

WITH cat AS (
    SELECT
        p.category,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount))                 AS revenue,
        SUM(oi.quantity * (oi.unit_price * (1 - oi.discount) - p.unit_cost)) AS profit
    FROM order_items oi
    JOIN orders o   ON o.order_id = oi.order_id
    JOIN products p ON p.product_id = oi.product_id
    WHERE o.status = 'Completed'
    GROUP BY p.category
)
SELECT
    category,
    ROUND(revenue, 2)                                   AS net_revenue,
    ROUND(100.0 * revenue / SUM(revenue) OVER (), 1)    AS revenue_share_pct,
    ROUND(profit, 2)                                    AS gross_profit,
    ROUND(100.0 * profit / SUM(profit) OVER (), 1)      AS profit_share_pct
FROM cat
ORDER BY net_revenue DESC;
