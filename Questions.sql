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

with payment_value_year_cte as
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
from payment_value_year_cte;

#Q11. Calculate the Total & Average value of order price for each state.

select customer_state,
		round(sum(payment_value),2) as total_payment,
		round(avg(payment_value),2) as avg_payment
from payments
join orders
using (order_id)
join customers
using(customer_id)
group by 1;

#Q12. Calculate the Total & Average value of order freight for each state.
select customer_state,
		round(sum(freight_value),2) as total_frieght,
        round(avg(freight_value),2) as avg_frieght
from order_items
join orders
using (order_id)

join
customers
using(customer_id)
group by 1;

#Analysis based on sales, freight and delivery time.

#Q13. Find the no. of days taken to deliver each order from the order’s purchase date as delivery time.
#Also, calculate the difference (in days) between the estimated & actual delivery date of an order.
#Do this in a single query.

select order_id, 
	   timestampdiff(day, order_purchase_timestamp, order_delivered_customer_date) as time_to_deliver,
       timestampdiff(day, order_delivered_customer_date, order_estimated_delivery_date) as diff_estimated_delivery
 from orders;

#Q14. Find out the top 5 states with the highest & lowest average freight value.
with avg_freight_value as
(select customer_state,
		round(avg(freight_value),2) as average_frieght_value
from orders
join order_items
using (order_id)
join customers
using (customer_id)
group by 1)

(select * from avg_freight_value order by 2 asc limit 5)
union
(select * from avg_freight_value order by 2 desc limit 5)
order by 2;

#Q15. Find out the top 5 states with the highest & lowest average delivery time.
with delivery_time_cte as
(
select customer_state,
		round(avg(timestampdiff(hour, order_purchase_timestamp, order_delivered_customer_date)),2) as delivery_time
from orders
join customers
using (customer_id)
group by 1)

(select * from delivery_time_cte order by 2 asc limit 5)
union
(select * from delivery_time_cte order by 2 desc limit 5)
order by 2;


#Q16. Find out the top 5 states where the order delivery is really fast as compared to the estimated date of delivery.

with faster_than_estimated_delivery_cte as
(
select customer_state,
		round(avg(timestampdiff(hour, order_delivered_customer_date, order_estimated_delivery_date)),2) as delivery_time
from orders
join customers
using (customer_id)
group by 1)

select * from faster_than_estimated_delivery_cte order by 2 asc limit 5;

#--Analysis based on the payments:
#Q17. Find the month on month no. of orders placed using different payment types.
select payment_type,
		count(*)
from payments
group by 1;

select date_format(order_purchase_timestamp, "%M") as Month,
	   payment_type,
       count(*) order_count
from orders
join
payments
using (order_id)
group by 1, 2 
order by 1, 2;

#Q18. Find the no. of orders placed on the basis of the payment installments that have been paid.
select * from payments limit 5;
select payment_installments, count(*) from payments
group by 1;
#8 4268
select payment_installments, 
count(distinct order_id) as total_orders_placed
from payments
group by 1
order by 2 desc;
