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

--1.) What is the total amount each customer spent at the restaurant?
select s.customer_id, sum(m.price) as total from sales s join menu m on(s.product_id=m.product_id) group by s.customer_id;

--2.) How many days has each customer visited the restaurant?
select customer_id, count(distinct order_date) from sales group by customer_id;

--3.) What was the first item from the menu purchased by each customer?

--Approach 1:
SELECT t.customer_id, m.product_name from (select s.customer_id, min(s.order_date) as Date from sales s Join members ms on(s.customer_id=ms.customer_id) where s.order_date>=ms.join_date group by s.customer_id ) as t , sales s , menu m where t.customer_id=s.customer_id AND s.product_id=m.product_id AND t.Date=s.order_date;

--Approach 2:

WITH RankedSales AS (
    SELECT
        s.customer_id,
        m.product_name,
        s.order_date,
        ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS RowNum
    FROM
        sales AS s
    JOIN
        menu AS m ON s.product_id = m.product_id
)

SELECT
    customer_id,
    product_name
FROM
    RankedSales
WHERE
    RowNum = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select Top 1 m.product_name as product, count(m.product_id) as Count from sales s left join menu m On(s.product_id=m.product_id) group by m.product_name order by Count DESC;

-- 5. Which item was the most popular for each customer?

WITH RankedItems AS (
    SELECT
        s.customer_id,
        m.product_name,
        COUNT(*) AS PopularityRank
    FROM
        sales AS s
    JOIN
        menu AS m ON s.product_id = m.product_id
    GROUP BY
        s.customer_id, m.product_name
    )
SELECT
    customer_id,
    product_name
FROM
    (
        SELECT
            customer_id,
            product_name,
            RANK() OVER (PARTITION BY customer_id ORDER BY PopularityRank DESC) AS Rank
        FROM
            RankedItems
    ) AS Ranked
WHERE
    Rank = 1;


-- 6. Which item was purchased first by the customer after they became a member?
--Approch 1:
WITH RankedSales AS (
    SELECT
        s.customer_id,
        m.product_name,
        s.order_date,
        ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS RowNum
    FROM
		members as ms
	Join 
        sales AS s on s.customer_id=ms.customer_id
    JOIN
        menu AS m ON s.product_id = m.product_id
	where s.order_date>ms.join_date
)

SELECT
    customer_id,
    product_name
FROM
    RankedSales
WHERE
    RowNum = 1;

--Approch 2:
SELECT t.customer_id, m.product_name from (select s.customer_id, min(s.order_date) as Date from sales s Join members ms on(s.customer_id=ms.customer_id) where s.order_date>ms.join_date group by s.customer_id ) as t , sales s , menu m where t.customer_id=s.customer_id AND s.product_id=m.product_id AND t.Date=s.order_date;


-- 7. Which item was purchased just before the customer became a member?

SELECT t.customer_id, m.product_name from (select s.customer_id, max(s.order_date) as Date from sales s Join members ms on(s.customer_id=ms.customer_id) where s.order_date<ms.join_date group by s.customer_id ) as t , sales s , menu m where t.customer_id=s.customer_id AND s.product_id=m.product_id AND t.Date=s.order_date;

-- 8. What is the total items and amount spent for each member before they became a member?
With temp as
( select ms.customer_id, s.order_date, s.product_id from members ms left join sales s on (ms.customer_id=s.customer_id) 
where s.order_date< ms.join_date)

select t.customer_id, count(t.product_id) as total_items, sum(m.price) as Amount_spent
from temp t Join menu m on (t.product_id=m.product_id)
group by t.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

select s.customer_id,
	sum(Case when m.product_name='sushi' then m.price*10*2
	else m.price*10
	End) as points
from sales s join menu m on(s.product_id=m.product_id)

group by s.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items,
--     not just sushi - how many points do customer A and B have at the end of January?
select s.customer_id,
	sum(m.price*10*2) as points
from members ms join
sales s on (s.customer_id=ms.customer_id)
join menu m on(s.product_id=m.product_id)
where s.order_date>=ms.join_date
group by s.customer_id;

