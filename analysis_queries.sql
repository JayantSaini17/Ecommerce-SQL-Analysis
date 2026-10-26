USE ecommerce_db;

-- ============================================================
-- E-Commerce Sales Analysis: 12 Analytical Queries
-- Note: Revenue queries use vw_delivered_sales (Delivered orders only)
-- ============================================================


-- Query1: Overall KPIs (total revenue, total orders, average order value)

SELECT
    SUM(line_total) AS total_revenue,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(line_total) / COUNT(DISTINCT order_id), 2) AS avg_order_value
FROM vw_delivered_sales;


-- Query2: Monthly revenue trend

SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS order_month,
    SUM(line_total) AS revenue
FROM vw_delivered_sales
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY order_month;


-- Query3: Revenue and units sold by category

SELECT category, SUM(line_total) AS revenue, SUM(quantity) AS units_sold
FROM vw_delivered_sales
GROUP BY category
ORDER BY revenue DESC;


-- Query4: Top 3 products by revenue

SELECT product_name, SUM(line_total) AS revenue
FROM vw_delivered_sales
GROUP BY product_name
ORDER BY revenue DESC
LIMIT 3;


-- Query5: Orders and revenue by city

SELECT city, COUNT(DISTINCT order_id) AS orders, SUM(line_total) AS revenue
FROM vw_delivered_sales
GROUP BY city
ORDER BY revenue DESC;


-- Query6: Repeat customers (2 or more delivered orders)

SELECT customer_name, COUNT(DISTINCT order_id) AS total_orders
FROM vw_delivered_sales
GROUP BY customer_id, customer_name
HAVING COUNT(DISTINCT order_id) >= 2
ORDER BY total_orders DESC;


-- Query7: Customers who registered but never placed an order

SELECT c.customer_id, c.first_name, c.last_name, c.city
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;


-- Query8: Order status breakdown (order count, share of orders, order value)
-- Uses the orders table (not the view) because Cancelled and Returned orders are needed

SELECT
    o.status,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(COUNT(DISTINCT o.order_id) * 100.0 / (SELECT COUNT(*) FROM orders), 2) AS pct_of_orders,
    SUM(oi.quantity * oi.unit_price) AS order_value,
    ROUND(SUM(oi.quantity * oi.unit_price) * 100.0
          / (SELECT SUM(quantity * unit_price) FROM order_items), 2) AS pct_of_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.status;


-- Query9: Customer segmentation by total spend (High / Medium / Low value)

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


-- Query10: Best-selling product in each category (RANK window function)

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


-- Query11: Month-over-month revenue growth (LAG window function)

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


-- Query12: Cumulative (running) revenue over time

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