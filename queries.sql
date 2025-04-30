-- Order Status Count
SELECT order_status, COUNT(*) AS total_orders
FROM customer_orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- Total Sales from Delivered Orders
SELECT SUM(order_amount) AS total_sales
FROM customer_orders
WHERE order_status = 'Delivered';

-- Monthly Sales Trend
SELECT strftime('%Y-%m', order_date) AS order_month,
       SUM(order_amount) AS monthly_sales
FROM customer_orders
WHERE order_status = 'Delivered'
GROUP BY order_month
ORDER BY order_month;

-- Top 5 Customers by Revenue
SELECT customer_id, COUNT(*) AS orders, SUM(order_amount) AS total_spent
FROM customer_orders
WHERE order_status = 'Delivered'
GROUP BY customer_id
ORDER BY total_spent DESC
LIMIT 5;

-- Repeat vs One-Time Customers
SELECT 
    CASE 
        WHEN order_count = 1 THEN 'One-Time'
        ELSE 'Repeat'
    END AS customer_type,
    COUNT(*) AS num_customers
FROM (
    SELECT customer_id, COUNT(*) AS order_count
    FROM customer_orders
    GROUP BY customer_id
)
GROUP BY customer_type;

-- Monthly Active Customers
SELECT strftime('%Y-%m', order_date) AS order_month,
       COUNT(DISTINCT customer_id) AS active_customers
FROM customer_orders
GROUP BY order_month
ORDER BY order_month;

-- Avg Orders per Customer
SELECT ROUND(AVG(order_count), 2) AS avg_orders_per_customer
FROM (
    SELECT customer_id, COUNT(*) AS order_count
    FROM customer_orders
    GROUP BY customer_id
);

-- Payment Status Counts
SELECT payment_status, COUNT(*) AS count
FROM payments
GROUP BY payment_status
ORDER BY count DESC;

-- Payment Failure Rate
SELECT 
  ROUND(
    SUM(CASE WHEN payment_status = 'Failed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
    2
  ) AS failure_rate_percentage
FROM payments;

-- Monthly Payment Success/Failure Trend
SELECT strftime('%Y-%m', payment_date) AS payment_month,
       SUM(CASE WHEN payment_status = 'Success' THEN 1 ELSE 0 END) AS success_count,
       SUM(CASE WHEN payment_status = 'Failed' THEN 1 ELSE 0 END) AS failure_count
FROM payments
GROUP BY payment_month
ORDER BY payment_month;

-- Order + Payment Report
SELECT
    o.order_id,
    o.customer_id,
    o.order_date,
    o.order_status,
    o.order_amount, 
    p.payment_status,
    p.payment_date
FROM customer_orders o
LEFT JOIN payments p ON o.order_id = p.order_id
ORDER BY o.order_date;

