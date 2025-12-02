CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

SET search_path = dannys_diner;
SELECT * FROM menu;

#1.What is the total amount each customer spent at the restaurant?
SELECT
customer_id,
SUM(price) as total_spent
From dannys_diner.sales as S
INNER JOIN dannys_diner.menu as M ON S.product_id = M.product_id
GROUP BY customer_id;

#2.How many days has each customer visited the restaurant?
SELECT
customer_id,
COUNT(DISTINCT order_date) as days
From dannys_diner.sales
GROUP BY customer_id;

#3.What was the first item from the menu purchased by each customer?
WITH ordered_sales AS (
  SELECT
  sales.customer_id,
  sales.order_date,
  menu.product_name,
  DENSE_RANK() OVER (
    PARTITION BY sales.customer_id
    ORDER BY sales.order_date
  ) AS rank
  FROM dannys_diner.sales
  JOIN dannys_diner.menu
  ON sales.product_id = menu.product_id
)
SELECT
customer_id,
product_name
FROM ordered_sales
WHERE rank = 1
GROUP BY customer_id, product_name;

#4.What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT
product_name,
COUNT(order_date) as orders 
From dannys_diner.sales as S
INNER JOIN dannys_diner.menu as M ON S.product_id = M.product_id
GROUP BY product_name
ORDER BY COUNT(order_date) DESC
LIMIT 1;

#5.Which item was the most popular for each customer?
WITH counts AS(
  SELECT
  customer_id,
  product_name,
  COUNT(order_date) as orders
  From dannys_diner.sales as S
  INNER JOIN dannys_diner.menu as M ON S.product_id = M.product_id
  GROUP BY customer_id, product_name
),

ranked_sales AS (
  SELECT 
customer_id,
product_name,
orders,
DENSE_RANK() OVER (
  PARTITION BY customer_id
  ORDER BY orders DESC
) as rank
FROM counts
)

SELECT
customer_id,
product_name,
orders
FROM ranked_sales
WHERE rank=1;
