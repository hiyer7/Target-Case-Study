select *
from target.customers;

#----Column listings
select COLUMN_NAME
from information_schema.columns
where table_name = 'customers';

select COLUMN_NAME
from information_schema.columns
where table_name = 'geolocation';

select COLUMN_NAME
from information_schema.columns
where table_name = 'order_items';

select COLUMN_NAME
from information_schema.columns
where table_name = 'order_reviews';

select COLUMN_NAME
from information_schema.columns
where table_name = 'orders';


select COLUMN_NAME
from information_schema.columns
where table_name = 'payments';

select COLUMN_NAME
from information_schema.columns
where table_name = 'products';

select COLUMN_NAME
from information_schema.columns
where table_name = 'sellers';

#----All about ORDERS
select * from orders;

select * from orders limit 1;

#----Total orders
select count(*) from orders; 
#99441

#----Count of orders under each category
select order_status, count(*) as num_orders
from orders
group by order_status;

#----Counts of different order statuses across different years
select date_format(order_purchase_timestamp, '%Y') as Year,
	   #date_format(order_purchase_timestamp, '%m') as Month,
       order_status,
       count(*) as num_orders
from orders
group by 1, 2#, 3
order by 1;#, date_format(order_purchase_timestamp, '%m');


#----First and Last order
select min(date_format(order_purchase_timestamp, '%D-%M-%Y')) as first_order,
	   max(date_format(order_purchase_timestamp, '%D-%M-%Y')) as last_order
from orders;

#----Total orders per year
select date_format(order_purchase_timestamp, '%Y') as Year,
		count(*) as Total
from orders
group by 1;

#----Total and average order month wise distribution
select date_format(order_purchase_timestamp, '%m') as ind,
	   date_format(order_purchase_timestamp, '%M') as Month,
		count(*) total_orders,
        round(count(*)/3,2) as avg_orders
from orders
group by 1,2
order by 1;

#----Total and average order day wise distribution
select date_format(order_purchase_timestamp, '%d') as day,
		count(*) total_orders
        #round(count(*)/3,2) as avg_orders
from orders
group by 1
order by 1;

#----difference between the purchase time and approved time where the difference is more than a day
select order_id, timestampdiff(hour, order_purchase_timestamp, order_approved_at) as diff1
 from orders
 where timestampdiff(hour, order_purchase_timestamp, order_approved_at) > 24
 order by 2 desc;
 
 #----Year wise most time taken between the estimated delivery time and actual delivery time
 select date_format(order_purchase_timestamp, '%Y') as Year,
		avg(timestampdiff(day, order_delivered_customer_date, order_estimated_delivery_date)) as estimated_diff
from orders
group by 1
order by 2 desc;
 
 #----Most wise most time taken between the estimated delivery time and actual delivery time
 select date_format(order_purchase_timestamp, '%M') as Month,
		avg(timestampdiff(day, order_delivered_customer_date, order_estimated_delivery_date)) as estimated_diff
from orders
group by 1
order by 2 desc; 