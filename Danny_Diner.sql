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

#6.Which item was purchased first by the customer after they became a member?
WITH member_sales_cte AS (
  SELECT
    s.customer_id,
    m.join_date,
    s.order_date,
    s.product_id,
    menu.product_name,
    DENSE_RANK() OVER (
      PARTITION BY s.customer_id
      ORDER BY s.order_date ASC
    ) AS rank
  FROM dannys_diner.sales AS s
  JOIN dannys_diner.members AS m
    ON s.customer_id = m.customer_id
  JOIN dannys_diner.menu AS menu
    ON s.product_id = menu.product_id
  WHERE s.order_date >= m.join_date
)

SELECT
  customer_id,
  order_date,
  product_name
FROM member_sales_cte
WHERE rank = 1;

#7.Which item was purchased just before the customer became a member?
WITH prior_purchase_cte AS (
  SELECT
    s.customer_id,
    m.join_date,
    s.order_date,
    s.product_id,
    menu.product_name,
    DENSE_RANK() OVER (
      PARTITION BY s.customer_id
      ORDER BY s.order_date DESC
    ) AS rank
  FROM dannys_diner.sales AS s
  JOIN dannys_diner.members AS m
    ON s.customer_id = m.customer_id
  JOIN dannys_diner.menu AS menu
    ON s.product_id = menu.product_id
  WHERE s.order_date < m.join_date
)

SELECT
  customer_id,
  order_date,
  product_name
FROM prior_purchase_cte
WHERE rank = 1;

#8.What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, count(s.product_id) as total_items, sum(menu.price) as total_spent
FROM dannys_diner.sales as s 
JOIN dannys_diner.menu as menu
ON s.product_id = menu.product_id
JOIN dannys_diner.members as m 
ON s.customer_id = m.customer_id
WHERE s.order_date < m.join_date
GROUP BY s.customer_id;

#9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT s.customer_id,
sum(
  CASE 
    WHEN m.product_name = 'sushi' THEN m.price * 20  
    ELSE m.price * 10
  END
) AS total_points
FROM dannys_diner.sales as s 
JOIN dannys_diner.menu as m
ON s.product_id = m.product_id
GROUP BY s.customer_id;

#10.In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT 
s.customer_id,
SUM(
  CASE 
    WHEN s.order_date BETWEEN m.join_date AND (m.join_date + 6) THEN menu.price * 20
    WHEN menu.product_name = 'sushi' THEN menu.price * 20
    ELSE menu.price * 10
  END
) AS total_points
FROM dannys_diner.sales as s
JOIN dannys_diner.menu as menu
ON s.product_id = menu.product_id
JOIN dannys_diner.members as m
ON s.customer_id = m.customer_id
WHERE s.order_date <= '2021-01-31'
GROUP BY s.customer_id;

#Bonus 1
SELECT 
s.customer_id,
s.order_date,
menu.product_name,
menu.price,
CASE 
  WHEN m.join_date IS NULL THEN 'N'
  WHEN s.order_date < m.join_date THEN 'N'
  ELSE 'Y'
END as member 
FROM dannys_diner.sales as s
LEFT JOIN dannys_diner.menu as menu
ON s.product_id = menu.product_id
LEFT JOIN dannys_diner.members as m
ON s.customer_id = m.customer_id
ORDER BY s.customer_id, s.order_date;

#Bonus 2
WITH summary_cte AS (
  SELECT
    s.customer_id,
    s.order_date,
    menu.product_name,
    menu.price,
    CASE
      WHEN m.join_date IS NULL THEN 'N'
      WHEN s.order_date < m.join_date THEN 'N'
      ELSE 'Y'
    END AS member
  FROM dannys_diner.sales AS s
  LEFT JOIN dannys_diner.menu AS menu
    ON s.product_id = menu.product_id
  LEFT JOIN dannys_diner.members AS m
    ON s.customer_id = m.customer_id
)

SELECT
  *,
  CASE
    WHEN member = 'N' THEN NULL
    ELSE DENSE_RANK() OVER (
      PARTITION BY customer_id, member
      ORDER BY order_date
    )
  END AS ranking
FROM summary_cte;