-- Question: How is net revenue trending month over month?
-- Skills: CTE, date grouping, LAG window function
-- Net revenue = completed orders only, after discounts.

WITH monthly AS (
    SELECT
        strftime('%Y-%m', o.order_date)                          AS month,
        COUNT(DISTINCT o.order_id)                               AS orders,
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2) AS net_revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'Completed'
    GROUP BY month
)
SELECT
    month,
    orders,
    net_revenue,
    LAG(net_revenue) OVER (ORDER BY month)                       AS prior_month_revenue,
    ROUND(100.0 * (net_revenue - LAG(net_revenue) OVER (ORDER BY month))
          / LAG(net_revenue) OVER (ORDER BY month), 1)           AS mom_growth_pct
FROM monthly
ORDER BY month;
