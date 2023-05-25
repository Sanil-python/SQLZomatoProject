drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'09-22-2017'),
(3,'04-21-2017');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'05-20-2016',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3);

drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);

select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;
-----------------------------------------------------------------------------------------------------------
--What is the total amount each customer spends on zomato?
select s.userid, sum(p.price)
from PortfolioProject..sales as s
join PortfolioProject..product as p
on s.product_id = p.product_id
group by userid
-----------------------------------------------------------------------------------------------------------
--How many days has each customer visited zomato?
select userid, count(distinct created_date) as distinct_days from PortfolioProject..sales group by userid
-----------------------------------------------------------------------------------------------------------
--What is the first product purchased by each customer?
select * from
(select *, RANK() over(partition by userid order by created_date) rnk from PortfolioProject..sales) as a where rnk = 1
-----------------------------------------------------------------------------------------------------------
--What is the most purchased item on the menu and how many times is it purchased by all customers?
select userid, COUNT(product_id) cnt from PortfolioProject..sales where product_id = 
(select top 1 product_id
from PortfolioProject..sales
group by product_id
order by COUNT(product_id) desc)
group by userid
-----------------------------------------------------------------------------------------------------------
--Which item is the most popular for each customer?
select * from
(select *, RANK() over(partition by userid order by cnt desc) as rnk from
(select userid, product_id, COUNT(product_id) cnt from PortfolioProject..sales group by userid, product_id) as a) as b
where rnk = 1
-----------------------------------------------------------------------------------------------------------
--Which item is purchased first by the customer after they become a gold member?
select * from
(select a.*, rank() over(partition by userid order by created_date) as rnk from
(select s.userid, s.created_date, g.gold_signup_date from PortfolioProject..sales as s
join PortfolioProject..goldusers_signup as g
on s.userid = g.userid and s.created_date >= g.gold_signup_date) as a) as b where rnk = 1
-----------------------------------------------------------------------------------------------------------
--Which item is purchased just before the customer become the gold member?
select * from
(select a.*, RANK() over(partition by userid order by created_date desc) as rnk from
(select s.userid, s.product_id, s.created_date, g.gold_signup_date from PortfolioProject..sales as s
join PortfolioProject..goldusers_signup as g
on s.userid = g.userid and s.created_date <= g.gold_signup_date) as a) as b where rnk = 1
-----------------------------------------------------------------------------------------------------------
--What is the total orders and amount spent for each member before they become a member?
select userid, COUNT(created_date) as order_purchased, sum(price) as total_amt_spent from
(select a.*, p.price from
(select s.userid, s.product_id, s.created_date, g.gold_signup_date
from PortfolioProject..sales as s
join PortfolioProject..goldusers_signup as g
on s.userid = g.userid and s.created_date <= g.gold_signup_date) as a
join PortfolioProject..product as p on a.product_id = p.product_id) as b
group by userid
-----------------------------------------------------------------------------------------------------------
--If buying each product generates points for eg 5rs=2 zomato points and each product has different purchasing points for 
--eg for p1 5rs=1 zomato point, for p2 10rs=5 zomato points and for p3 5rs=1 zomato point,
--calculate points collected by each customers and for which product most points have been given till now.
select userid, SUM(total_points)*2.5 as total_cashback_earned from
(select c.*, amt/points as total_points from
(select b.*, case
				when product_id = 1 then 5
				when product_id = 2 then 2
				when product_id = 3 then 5
				else 0
			end as points
from
(select a.userid, a.product_id, SUM(price) as amt from
(select s.*, p.price
from PortfolioProject..sales as s
join PortfolioProject..product as p
on s.product_id = p.product_id) as a
group by userid, product_id) as b) as c) as d
group by userid

select * from
(select *, rank() over(order by total_points_earned desc) rnk from
(select product_id, SUM(total_points) as total_points_earned from
(select c.*, amt/points as total_points from
(select b.*, case
				when product_id = 1 then 5
				when product_id = 2 then 2
				when product_id = 3 then 5
				else 0
			end as points
from
(select a.userid, a.product_id, SUM(price) as amt from
(select s.*, p.price
from PortfolioProject..sales as s
join PortfolioProject..product as p
on s.product_id = p.product_id) as a
group by userid, product_id) as b) as c) as d
group by product_id) as e) as f where rnk = 1