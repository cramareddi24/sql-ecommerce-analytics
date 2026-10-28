-- Question: Who are the top 3 customers in each region by lifetime spend?
-- Skills: RANK() with PARTITION BY, filtering on a window result

WITH spend AS (
    SELECT
        c.customer_id,
        c.first_name || ' ' || c.last_name                              AS customer,
        c.region,
        COUNT(DISTINCT o.order_id)                                      AS orders,
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2)  AS lifetime_spend
    FROM customers c
    JOIN orders o       ON o.customer_id = c.customer_id
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'Completed'
    GROUP BY c.customer_id
),
ranked AS (
    SELECT *, RANK() OVER (PARTITION BY region ORDER BY lifetime_spend DESC) AS region_rank
    FROM spend
)
SELECT region, region_rank, customer, orders, lifetime_spend
FROM ranked
WHERE region_rank <= 3
ORDER BY region, region_rank;
