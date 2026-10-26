USE ecommerce_db;

-- Query1

SELECT
    SUM(line_total)                          AS total_revenue,
    COUNT(DISTINCT order_id)                 AS total_orders,
    ROUND(SUM(line_total) / COUNT(DISTINCT order_id), 2) AS avg_order_value
FROM vw_delivered_sales;

-- Query2

SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS order_month,
    SUM(line_total)                  AS revenue
FROM vw_delivered_sales
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY order_month;

-- Query3

SELECT category, SUM(line_total) AS revenue, SUM(quantity) AS units_sold
FROM vw_delivered_sales
GROUP BY category
ORDER BY revenue DESC;

-- Query4

SELECT product_name, SUM(line_total) AS revenue
FROM vw_delivered_sales
GROUP BY product_name
ORDER BY revenue DESC
LIMIT 3;

-- Query5

SELECT city, COUNT(DISTINCT order_id) AS orders, SUM(line_total) AS revenue
FROM vw_delivered_sales
GROUP BY city
ORDER BY revenue DESC;

-- Query6

SELECT customer_name, COUNT(DISTINCT order_id) AS total_orders
FROM vw_delivered_sales
GROUP BY customer_id, customer_name
HAVING COUNT(DISTINCT order_id) >= 2
ORDER BY total_orders DESC;

-- Query7

SELECT c.customer_id, c.first_name, c.last_name, c.city
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;

-- Query8

SELECT
    status,
    COUNT(*) AS total_orders,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 2) AS pct_of_orders
FROM orders
GROUP BY status;

-- Query9

WITH customer_spend AS (
    SELECT customer_id, customer_name, SUM(line_total) AS total_spent
    FROM vw_delivered_sales
    GROUP BY customer_id, customer_name
)
SELECT
    customer_name,
    total_spent,
    CASE
        WHEN total_spent >= 7000 THEN 'High Value'
        WHEN total_spent >= 3000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS segment
FROM customer_spend
ORDER BY total_spent DESC;

-- Query10

WITH product_revenue AS (
    SELECT category, product_name, SUM(line_total) AS revenue
    FROM vw_delivered_sales
    GROUP BY category, product_name
),
ranked AS (
    SELECT
        category, product_name, revenue,
        RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS rnk
    FROM product_revenue
)
SELECT category, product_name, revenue
FROM ranked
WHERE rnk = 1;

-- Query11

WITH monthly AS (
    SELECT DATE_FORMAT(order_date, '%Y-%m') AS order_month,
           SUM(line_total) AS revenue
    FROM vw_delivered_sales
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)
SELECT
    order_month,
    revenue,
    LAG(revenue) OVER (ORDER BY order_month) AS prev_month_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY order_month)) * 100.0
        / LAG(revenue) OVER (ORDER BY order_month), 2
    ) AS mom_growth_pct
FROM monthly;

-- Query12

WITH monthly AS (
    SELECT DATE_FORMAT(order_date, '%Y-%m') AS order_month,
           SUM(line_total) AS revenue
    FROM vw_delivered_sales
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)
SELECT
    order_month,
    revenue,
    SUM(revenue) OVER (ORDER BY order_month) AS cumulative_revenue
FROM monthly;
