
--1.) What is the total amount each customer spent at the restaurant?
SELECT 
	s.customer_id, 
	sum(m.price) AS total 
FROM 
	sales s 
JOIN 
	menu m 
ON
	(s.product_id=m.product_id)
GROUP BY 
	s.customer_id;

--2.) How many days has each customer visited the restaurant?
SELECT 
	customer_id, 
	count(distinct order_date) 
FROM 
	sales 
GROUP BY 
	customer_id;

--3.) What was the first item from the menu purchased by each customer?

--Approach 1:
SELECT 
	t.customer_id, 
	m.product_name 
FROM 
	(SELECT 
		s.customer_id, 
		min(s.order_date) AS Date 
	FROM 
		sales s 
	JOIN 
		members ms on(s.customer_id=ms.customer_id) 
	WHERE 
		s.order_date>=ms.join_date 
	GROUP BY 
		s.customer_id ) as t, 
	sales s, menu m 
WHERE 
	t.customer_id=s.customer_id 
AND 
	s.product_id=m.product_id 
AND 
	t.Date=s.order_date;

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
SELECT 
	Top 1 m.product_name AS product, 
	count(m.product_id) as Count 
FROM 
	sales s 
LEFT JOIN 
	menu m On(s.product_id=m.product_id) 
GROUP BY 
	m.product_name 
ORDER BY 
	Count DESC;

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
--Approach 1:
WITH RankedSales AS (
    SELECT
        s.customer_id,
        m.product_name,
        s.order_date,
        ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS RowNum
    FROM
	members AS ms
    JOIN 
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

--Approach 2:
SELECT 
	t.customer_id, m.product_name 
FROM 
	(SELECT 
		s.customer_id, 
		min(s.order_date) AS Date 
	FROM 
		sales s 
	JOIN 
		members ms on(s.customer_id=ms.customer_id) 
	WHERE 
		s.order_date>ms.join_date 
	GROUP BY 
		s.customer_id ) as t, 
	sales s, 
	menu m 
WHERE 
	t.customer_id=s.customer_id 
AND 
	s.product_id=m.product_id 
AND 
	t.Date=s.order_date;


-- 7. Which item was purchased just before the customer became a member?

SELECT t.customer_id, m.product_name 
FROM (SELECT 
		s.customer_id,
		max(s.order_date) AS Date 
	FROM 
		sales s 
	JOIN 
		members ms on(s.customer_id=ms.customer_id) 
	WHERE 
		s.order_date<ms.join_date 
	GROUP BY 
		s.customer_id ) as t, 
	sales s, menu m 
WHERE 
	t.customer_id=s.customer_id 
AND 
	s.product_id=m.product_id 
AND 
	t.Date=s.order_date;

-- 8. What is the total items and amount spent for each member before they became a member?
WITH temp AS( 
	SELECT 
		ms.customer_id, 
		s.order_date, 
		s.product_id 
	FROM 
		members ms 
	LEFT JOIN 
		sales s on (ms.customer_id=s.customer_id) 
	WHERE 
		s.order_date< ms.join_date
)
SELECT 
	t.customer_id, 
	count(t.product_id) AS total_items, 
	sum(m.price) AS Amount_spent
FROM 
	temp t 
JOIN 
	menu m ON (t.product_id=m.product_id)
GROUP BY 
	t.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT 
	s.customer_id,
	sum(CASE WHEN 
		m.product_name='sushi' 
	    THEN 
		m.price*10*2
	    ELSE 
		m.price*10
	    END) AS points
FROM 
	sales s 
JOIN 
	menu m on(s.product_id=m.product_id)

GROUP BY 
	s.customer_id;

-- 10. In the first week after a customer joins the program (including their join date), they earn 2x points on all items,
--     not just sushi - how many points do customers A and B have at the end of January?
SELECT s.customer_id, 
       sum(m.price*10*2) AS points
FROM 
	members ms 
JOIN
	sales s on (s.customer_id=ms.customer_id)
JOIN 
	menu m on(s.product_id=m.product_id)
WHERE 
	s.order_date>=ms.join_date
GROUP BY 
	s.customer_id;

