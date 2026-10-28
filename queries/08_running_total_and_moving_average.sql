-- Question: What's cumulative revenue year to date, and what's the 3-month trend?
-- Skills: running total with PARTITION BY, moving average with a window frame

WITH monthly AS (
    SELECT
        strftime('%Y', o.order_date)                                 AS year,
        strftime('%Y-%m', o.order_date)                              AS month,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount))         AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'Completed'
    GROUP BY month
)
SELECT
    month,
    ROUND(revenue, 2)                                                            AS net_revenue,
    ROUND(SUM(revenue) OVER (PARTITION BY year ORDER BY month), 2)               AS ytd_revenue,
    ROUND(AVG(revenue) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS moving_avg_3mo
FROM monthly
ORDER BY month;
