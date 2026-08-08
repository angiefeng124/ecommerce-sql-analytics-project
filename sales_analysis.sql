USE DataWareHouseAnalytics2
--Change over time
SELECT 
YEAR(order_date) as order_year,
MONTH(order_date) as order_month,
SUM(sales_amount) AS total_sales,
Count(Distinct customer_key) as total_customers,
sum(quantity) as total_quantity
From fact_sales
where order_date is NOT NULL
group by YEAR(order_date), MONTH(order_date)
order by YEAR(order_date), MONTH(order_date)

--Cumulative analysis
--calculate he total sales per month and the running total of sales over time
SELECT
order_date,
total_sales,
SUM(total_sales) Over (ORDER BY order_date) as running_total_sales,
AVG(avg_price) Over (ORDER BY order_date) as moving_average_price
FROM
(
SELECT
DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1) AS order_date,
SUM(sales_amount) AS total_sales,
AVG(price) AS avg_price
From fact_sales
where order_date is NOT NULL
group by YEAR(order_date), MONTH(order_date)
)t;

--Analyze the yearly performance of products by comparing their sales 
--to both the average sales performance of the product and the previous year's sales
WITH yearly_product_sales AS(
    Select YEAR(f.order_date) as order_year, p.product_name, 
    SUM(f.sales_amount) as current_sales
    From fact_sales f
    LEFT JOIN dim_products p
    On f.product_key = p.product_key
    WHERE f.order_date is not null
    GROUP BY YEAR(f.order_date), p.product_name
)

SELECT 
order_year, product_name, current_sales,
AVG(current_sales) OVER (PARTITION BY product_name) as avg_sales,
current_sales - AVG(current_sales) OVER (PARTITION BY product_name) as diff_avg,
CASE WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above Avg'
     WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below Avg'
     ELSE 'Avg'
END avg_change,
--Year over year analysis
LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) as py_years,
current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) as diff_py,
CASE WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
     WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
     ELSE 'No change'
END py_change
FROM yearly_product_sales
ORDER BY product_name, order_year;

--Which categories contribute the most to overall sales
WITH category_sales AS(
SELECT
category,
SUM(sales_amount) total_sales
FROM fact_sales f  
LEFT JOIN dim_products p
ON p.product_key = f.product_key
GROUP BY category)

SELECT
category,
total_sales,
SUM(total_sales) Over() overall_sales,
CONCAT(ROUND((CAST(total_sales as float) / SUM(total_sales) Over()) * 100, 2), '%') AS percentage_of_total
FROM category_sales
ORDER BY total_sales DESC;

--Segment products into cost ranges and count how many products fall into each segment
WITH product_segments AS (
SELECT 
product_key,
product_name,
cost,
CASE WHEN cost<100 THEN 'below 100'
    WHEN cost BETWEEN 100 and 500 then '100-500'
    WHEN cost BETWEEN 500 and 1000 then '500-1000'
    ELSE 'above 1000'
END cost_range
FROM dim_products
)
SELECT
cost_range,
COUNT(product_key) as total_products
FROM product_segments
GROUP BY cost_range
ORDER BY total_products DESC;

/*Group customers into three segments based on their spending behavior:
- VIP: Customers with at least 12 months of history and spending more than €5,000.
- Regular: Customers with at least 12 months of history but spending €5,000 or less.
- New: Customers with a lifespan less than 12 months.
And find the total number pt customers by each group
*/
WITH customer_spending AS (
SELECT
c.customer_key,
SUM(f.sales_amount) AS total_spending,
MIN(order_date) AS first_order,
MAX(order_date) AS last_order,
DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan
FROM fact_sales f  
LEFT JOIN dim_customers c 
ON f.customer_key = c.customer_key
GROUP BY c.customer_key
)

SELECT
customer_segment,
COUNT(customer_key) AS total_customers
FROM (
    select 
    customer_key,
    case when lifespan >= 12 and total_spending > 5000 then 'VIP'
    when lifespan >= 12 and total_spending <= 5000 then 'Regular'
    else 'New'
    end customer_segment
    from customer_spending
)t 
GROUP BY customer_segment
ORDER BY total_customers DESC





