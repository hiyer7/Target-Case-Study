#1. Data type of all columns in the "customers" table.

select column_name, data_type
from information_schema.columns
where table_name = 'customers';

#2. Get the time range between which the orders were placed.
select * from orders limit 1;

select min(date_format(order_purchase_timestamp, '%D-%M-%Y %H:%i:%s')) as first_order,
	   max(date_format(order_purchase_timestamp, '%D-%M-%Y %H:%i:%s')) as last_order
from orders;

#3. Count the Cities & States of customers who ordered during the given period.

select orders.customer_id, order_id, order_purchase_timestamp, customer_city, customer_state
from orders
left join customers
on orders.customer_id = customers.customer_id;

select count(distinct customer_city), count(distinct customer_state)
from orders
left join customers
on orders.customer_id = customers.customer_id;
#group by order_purchase_timestamp
#having order_purchase_timestamp between min(order_purchase_timestamp) and max(order_purchase_timestamp);


#5. Is there a growing trend in the no. of orders placed over the past years?
select date_format(order_purchase_timestamp, '%Y') as Year, 
	   count(order_id) orders_per_year
from orders
group by 1;

#6. Can we see some kind of monthly seasonality in terms of the no. of orders being placed?

select date_format(order_purchase_timestamp, '%M') as Month, 
	   count(order_id) as Orders_per_Year,
       case when count(order_id) > 10000 then "High"
			when count(order_id) between 5000 and 10000 then "Medium"
            when count(order_id) < 5000 then "Low"
		end
        as Order_Buckets
from orders
group by 1
order by 2 desc;

#Q7 During what time of the day, do the Brazilian customers mostly place their orders? (Dawn, Morning, Afternoon or Night)
-- 0-6 hrs : Dawn
-- 7-12 hrs : Mornings
-- 13-18 hrs : Afternoon
-- 19-23 hrs : Night

select 
		case 
			when extract(hour from order_purchase_timestamp) between 0 and 6 then 'Dawn'
            when extract(hour from order_purchase_timestamp) between 7 and 12 then 'Mornings'
			when extract(hour from order_purchase_timestamp) between 13 and 18 then 'Afternoon'
            when extract(hour from order_purchase_timestamp) between 19 and 23 then 'Night'
		end as part_of_day,
        count(*) as total_orders
from orders
group by 1;

#Q8. Get the month on month no. of orders placed in each state.

select customer_state,
	   extract(Month from order_purchase_timestamp) as month,
       count(*)
from orders
left join 
customers
on orders.customer_id = customers.customer_id
where customer_state is not null
group by 1, 2
order by 1, 2;       

#Q9. How are the customers distributed across all the states?
select customer_state,
		count(*) as number_of_users
from customers
group by 1
order by 2 desc;


#Impact on Economy: Analyze the money movement by e-commerce by looking at order prices, freight and others.

#Q10. Get the % increase in the cost of orders from year 2017 to 2018 (include months between Jan to Aug only).
#You can use the "payment_value" column in the payments table to get the cost of orders.
select * from payments limit 1;

with 2017_payment_value_cte as
(
select  extract(year from order_purchase_timestamp) as Year,
        sum(payment_value) as total_payment_value
from orders
left join
payments
on orders.order_id = payments.order_id
where extract(month from order_purchase_timestamp) between 1 and 8
and extract(year from order_purchase_timestamp) = 2017
group by 1
),

2018_payment_value_cte as
(
select  extract(year from order_purchase_timestamp) as Year,
        sum(payment_value) as total_payment_value
from orders
left join
payments
on orders.order_id = payments.order_id
where extract(month from order_purchase_timestamp) between 1 and 8
and extract(year from order_purchase_timestamp) = 2018
group by 1
)		


select (2018_payment_value_cte.total_payment_value/2017_payment_value_cte.total_payment_value)*100
from 2018_payment_value_cte
join 2017_payment_value_cte;

with pyment_value_year_cte as
(select extract(year from order_purchase_timestamp) as Year,
		sum(payment_value) as total_payment_value
from orders
left join
payments
on orders.order_id = payments.order_id
where extract(month from order_purchase_timestamp) between 1 and 8
group by 1)

select *,
		lead(total_payment_value, 1) over (order by total_payment_value desc) as lead_total_payment_value,
        (total_payment_value - (lead(total_payment_value, 1) over (order by total_payment_value desc)))/(lead(total_payment_value, 1) over (order by total_payment_value desc))*100 as pct_increase
from pyment_value_year_cte


