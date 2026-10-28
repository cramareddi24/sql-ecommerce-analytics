-- Question: Of customers who first ordered in a given quarter, how many ordered again later?
-- Skills: cohort analysis, month arithmetic, multiple CTEs

WITH first_order AS (
    SELECT customer_id, MIN(order_date) AS first_date
    FROM orders
    WHERE status <> 'Canceled'
    GROUP BY customer_id
),
activity AS (
    SELECT
        f.customer_id,
        strftime('%Y', f.first_date) || '-Q' || ((CAST(strftime('%m', f.first_date) AS INTEGER) + 2) / 3) AS cohort,
        (CAST(strftime('%Y', o.order_date) AS INTEGER) * 12 + CAST(strftime('%m', o.order_date) AS INTEGER))
      - (CAST(strftime('%Y', f.first_date) AS INTEGER) * 12 + CAST(strftime('%m', f.first_date) AS INTEGER)) AS months_since_first
    FROM first_order f
    JOIN orders o ON o.customer_id = f.customer_id AND o.status <> 'Canceled'
)
SELECT
    cohort,
    COUNT(DISTINCT customer_id)                                                        AS cohort_size,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN months_since_first BETWEEN 1 AND 3 THEN customer_id END)
          / COUNT(DISTINCT customer_id), 1)                                            AS returned_within_3mo_pct,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN months_since_first BETWEEN 1 AND 6 THEN customer_id END)
          / COUNT(DISTINCT customer_id), 1)                                            AS returned_within_6mo_pct
FROM activity
GROUP BY cohort
ORDER BY cohort;
