-- dedup query: returns one review per order_id from order_reviews, keeping the latest review.
with row_assign as
(
select order_id, review_score, row_number() over (partition by order_id order by review_answer_timestamp desc, review_id) as row_num
from order_reviews
)
select order_id, review_score
from row_assign 
where row_num = 1
;

-- how many orders have a NULL order_delivered_customer_date
select order_status, count(*) as n_order, count(*) - count(order_delivered_customer_date) as n_nulls
from orders
group by order_status;

-- only orders with order_status = 'delivered' and a non-NULL order_delivered_customer_date get a late flag. 
-- That leaves 96,478 - 8 = 96,470 orders
select order_id, case when date(order_delivered_customer_date) > date(order_estimated_delivery_date) then 1 else 0 end as is_late
from orders
where order_status = 'delivered' and order_delivered_customer_date is not null
;

-- a view that returns one row per delivered order with these columns:
-- customer_state, order_id, order_purchase_timestamp, is_late, review_score (from dedup query)
create view v_order_delivery_reviews_state as
with row_assign as
(
	select order_id, review_score, row_number() over (partition by order_id order by review_answer_timestamp desc, review_id) as row_num
	from order_reviews
),
dedup as
(
	select order_id, review_score
	from row_assign 
	where row_num = 1
),
late as
(
	select customer_state, order_id, order_purchase_timestamp, case when date(order_delivered_customer_date) > date(order_estimated_delivery_date) then 1 else 0 end as is_late
	from orders left join customers on orders.customer_id = customers.customer_id
	where order_status = 'delivered' and order_delivered_customer_date is not null
)
select late.customer_state, late.order_id, late.order_purchase_timestamp, late.is_late, dedup.review_score
from late left join dedup on late.order_id = dedup.order_id;

-- a view for late delivery by category analysis
create view v_category_late_gap as
select coalesce(pc.product_category_name_english, 'unknown') as product_category, 
	count(*) as n_items, 
    sum(v.is_late) as n_late_items, 
    round(avg(case when v.is_late = 1 then v.review_score end), 2) as avg_score_late,
    round(avg(case when v.is_late = 0 then v.review_score end), 2) avg_score_ontime,
    round(avg(case when v.is_late = 0 then v.review_score end), 2) - round(avg(case when v.is_late = 1 then v.review_score end), 2) as score_gap
from order_items oi 
	join v_order_delivery_reviews_state v on v.order_id = oi.order_id
	join products p on p.product_id = oi.product_id
    left join product_category_name_translation pc on pc.product_category_name = p.product_category_name 
group by product_category
having n_late_items >= 100
;

-- review score for late vs on-time orders.
select is_late, count(*) as n_orders, count(review_score) as n_reviewed, avg(review_score) as avg_score
from v_order_delivery_reviews_state
group by is_late;

-- late percentage by month
select date_format(order_purchase_timestamp, '%Y-%m') as purchase_month, count(*) as n_orders, round(100 * avg(is_late), 1) as late_pct
from v_order_delivery_reviews_state
group by purchase_month
order by purchase_month;

-- late rate and review score by state
select customer_state, count(*) as n_orders, sum(is_late) as n_late, round(100 * avg(is_late), 1) as late_pct, round(avg(review_score), 2) as avg_score
from v_order_delivery_reviews_state
group by customer_state
order by n_late desc;
