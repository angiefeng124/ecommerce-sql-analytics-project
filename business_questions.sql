--Which products generate the most revenue?
SELECT TOP 10
product_name,
category,
total_sales
FROM gold.report_products
ORDER BY total_sales DESC;

--How is the customer distribution (loyalty) like?
SELECT
customer_segment,
COUNT(customer_number) as total_customers,
SUM(total_sales) total_sales
FROM gold.report_customers
GROUP BY customer_segment

--Who are our highest value customers?
SELECT TOP 10
customer_name,
customer_segment,
total_sales,
total_orders
FROM gold.report_customers
ORDER BY total_sales DESC;

--Are customers becoming more valuable?
SELECT
customer_segment,
AVG(total_sales) avg_customer_value
FROM gold.report_customers
GROUP BY customer_segment;