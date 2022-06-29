CREATE DATABASE global_store;

DROP TABLE IF EXISTS superstore;

CREATE TABLE superstore (
    row_id INT(5),
    order_id VARCHAR(20),
    order_date DATE,
    ship_date DATE,
    ship_mode VARCHAR(30),
    customer_id VARCHAR(8),
    customer_name VARCHAR(100),
    segment VARCHAR(15),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(50),
    postal_code VARCHAR(10),
    market VARCHAR(20),
    region VARCHAR(30),
    product_id VARCHAR(20),
    category VARCHAR(30),
    sub_category VARCHAR(30),
    product_name VARCHAR(300),
    sales DECIMAL(10 , 2 ),
    quantity INT(6),
    discount FLOAT,
    profit FLOAT(7 , 2 ),
    shipping_cost FLOAT(7 , 2 ),
    order_priority VARCHAR(15)
);
    
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Global_Superstore2.csv'
INTO TABLE superstore
CHARACTER SET LATIN1
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(row_id, order_id, @order_date, @ship_date, ship_mode, customer_id, customer_name, segment, city, state, country, postal_code, market, region, product_id, category, sub_category, product_name, sales, quantity, discount, profit, shipping_cost, order_priority)
SET order_date = STR_TO_DATE(@order_date, '%d-%m-%Y'),
ship_date = STR_TO_DATE(@ship_date, '%d-%m-%Y');

SELECT 
    *
FROM
    superstore
LIMIT 50 , 10;

DESCRIBE superstore;

-- drop field postal code since it not require

ALTER TABLE superstore DROP postal_code;

-- the customers profile based on their frequency of purchase
SELECT 
    customer_id,
    customer_name,
    segment,
    COUNT(quantity) frequency
FROM
    superstore
GROUP BY customer_id
ORDER BY frequency DESC;

-- find out whether the high frequent customers are contributing more revenue
SELECT 
    customer_id,
    customer_name,
    segment,
    COUNT(quantity) frequency,
    SUM(sales) revenue
FROM
    superstore
GROUP BY customer_id
ORDER BY frequency DESC;

-- profitable customer
SELECT 
    customer_id,
    customer_name,
    segment,
    COUNT(quantity) frequency,
    SUM(profit) total_profit
FROM
    superstore
GROUP BY customer_id
ORDER BY frequency DESC;

-- the most profitable customer segment in each year
SELECT 
    YEAR(order_date) year_profit,
    segment,
    SUM(profit) total_profit,
    AVG(profit) avg_profit
FROM
    superstore
GROUP BY segment , year_profit
ORDER BY year_profit , total_profit DESC;

-- customer distribution across the countries
SELECT 
    country,
    segment,
    COUNT(DISTINCT customer_id) total_customer,
    COUNT(DISTINCT order_id) total_order,
    (profit) total_profit
FROM
    superstore
GROUP BY country , segment;

-- country that has top sales
SELECT 
    country, SUM(sales) total_sales, AVG(sales) avg_sales
FROM
    superstore
GROUP BY country
ORDER BY total_sales DESC;

-- top 5 profit-making product types on a yearly basis
select year_order, sub_category, profit_gain from
(select year(order_date) year_order,
sub_category,
rank() over (partition by year(order_date) order by sum(profit) desc) profit_rank,
sum(profit) profit_gain
from superstore
group by year_order, sub_category
order by year_order) product_profit
where profit_rank <=10;

-- Is there any increase in sales product with the decrease in price at a day level
SELECT 
    order_date, product_id, sales, price
FROM
    (SELECT 
        order_date,
            product_id,
            ROUND(((sales - profit) / quantity), 2) price,
            quantity,
            sales,
            profit,
            (sales - profit) cogs
    FROM
        superstore) detail
GROUP BY order_date , product_id
ORDER BY product_id , order_date;

-- average delivery time across the countries
SELECT 
    country,
    order_date,
    ship_date,
    CONCAT(ROUND(AVG(DATEDIFF(ship_date, order_date)), 0),
            ' days') avg_delivery
FROM
    superstore
GROUP BY country
ORDER BY avg_delivery;