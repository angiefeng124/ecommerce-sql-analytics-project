/*
=========
Customer Report
Purpose:
- This report consolidates key customer metrics and behaviors
Highlights:
1. Gathers essential fields such as names, ages, and transaction details.
2. Segments customers into categories (VIP, Regular, New) and age groups.
3. Aggregates customer-level metrics:
- total orders
- total sales
- total quantity purchased
- total products
- lifespan (in months)
4. Calculates valuable KPIs:
- recency (months since last order)
- average order value
- average monthly spend
=========
*/
CREATE OR ALTER VIEW gold.report_customers AS
WITH base_query AS(
    --1) Base Query: Retrieves core columns from tables
SELECT
f.order_number,
f.product_key,
f.order_date,
f.sales_amount,
f.quantity,
c.customer_key,
c.customer_number,
CONCAT(c.first_name,' ', c.last_name) AS customer_name,
DATEDIFF(year, c.birthdate, GETDATE()) age
FROM fact_sales f
LEFT JOIN dim_customers c
ON c.customer_key = f.customer_key
WHERE order_date is not null)

,customer_aggregation AS(
-- 3. Aggregates customer-level metrics:
SELECT
customer_key,
customer_number,
customer_name,
age,
COUNT(distinct order_number) as total_orders,
SUM(sales_amount) as total_sales,
SUM(quantity) as total_quantity,
count(distinct product_key) as total_products,
MAX(order_date) AS last_order_date,
DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan
FROM base_query
GROUP BY
customer_key,
customer_number,
customer_name,
age
)

SELECT
customer_key,
customer_number,
customer_name,
age,
case when age < 20 then 'Under 20'
    when age between 20 and 29 then '20-29'
    when age between 30 and 39 then '30-39'
    when age between 40 and 49 then '40-49'
    else '50 and above'
    end as age_group,
case when lifespan >= 12 and total_sales > 5000 then 'VIP'
    when lifespan >= 12 and total_sales <= 5000 then 'Regular'
    else 'New'
    end customer_segment,
last_order_date,
DATEDIFF(month, last_order_date, GETDATE()) as recency,
total_orders,
total_sales,
total_quantity,
total_products,
lifespan,
--compute average order value
case when total_orders = 0 then 0
    else total_sales / total_orders
end as avg_order_value,

--compute average monthly spend
case when lifespan = 0 then total_sales
    else total_sales / lifespan
    end as avg_monthly_spe
FROM customer_aggregation
