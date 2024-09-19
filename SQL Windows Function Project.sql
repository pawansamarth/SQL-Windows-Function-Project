-- Que 1)Rank the customers based on the total amount they've spent on rentals.
use mavenmovies;
SELECT customer_id, CONCAT(first_name, ' ', last_name) AS customer_name, 
amount, RANK() OVER (ORDER BY amount DESC) AS rank_by_amount
FROM (
	select c.customer_id, c.first_name, c.last_name, SUM(p.amount) AS amount
	FROM customer c
    JOIN payment p ON c.customer_id = p.customer_id
    GROUP BY c.customer_id
) AS total_amount_per_customer;

-- Que 2)Calculate the cumulative revenue generated by each film over time.
select f.film_id, f.title, p.payment_date, SUM(p.amount)
OVER(PARTITION BY f.film_id order by p.payment_date) AS cumulative_revenue
from payment p JOIN rental r ON p.rental_id = r.rental_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
ORDER BY f.film_id, p.payment_date;

-- Que 3)Determine the average rental duration for each film, considering films with similar lengths.
select film_id, title, rental_duration, 
avg(rental_duration) OVER(partition by length)
AS avg_rental_duration from film where length IS NOT NULL;

-- Que 4)Identify the top 3 films in each category based on their rental counts.
WITH RANKEDFILMS AS(
select fc.category_id, fc.film_id, f.title,
ROW_NUMBER() over(PARTITION BY fc.category_id ORDER BY COUNT(r.rental_id) DESC) 
AS ranking from film_category fc
join rental r ON fc.film_id = r.inventory_id
join film f on fc.film_id = f.film_id
GROUP BY fc.category_id, fc.film_id, f.title)
select category_id, film_id, title, ranking from RankedFilms where ranking <= 3;

-- Que 5)Calculate the difference in rental counts between each customer's total rentals and the average rentals across all customers.
WITH CustomerRentalDifference AS (
select customer_id, count(rental_id) AS total_rentals,
avg(count(rental_id)) over() as avg_rentals_across_customers,
count(rental_id) - avg(count(rental_id)) over() as rental_difference
from rental group by customer_id )
select customer_id,total_rentals, avg_rentals_across_customers, rental_difference from customerRentalDifference;

-- Que 6)Find the monthly revenue trend for the entire rental store over time.
WITH MonthlyRevenue AS(
select date_format(payment_date, '%Y-%M') AS month,
sum(amount) AS total_revenue from payment GROUP BY date_format(payment_date, '%Y-%M') )
select month, total_revenue, sum(total_revenue) over(order by month) as cumulative_revenue 
from MonthlyRevenue order by month;

-- Que 7)Identify the customers whose total spending on rentals falls within the top 20% of all customers.
WITH CustomerSpending as (
select customer_id, sum(amount) as total_spending, rank() over(order by sum(amount) desc) 
as customer_rank from payment group by customer_id )
select customer_id, total_spending from CustomerSpending 
where customer_rank <= (select 0.2 * count(distinct customer_id) +1 from CustomerSpending);

-- Que 8)Calculate the running total of rentals per category, ordered by rental count.
use mavenmovies;
select category_id, film_id, title, rental_count,
       SUM(rental_count) OVER (PARTITION BY category_id ORDER BY film_id) AS running_total
FROM (
    SELECT fc.category_id, f.film_id, f.title, COUNT(r.rental_id) AS rental_count
    FROM film f
	JOIN film_category fc ON f.film_id = fc.film_id
    JOIN inventory i ON f.film_id = i.film_id
    JOIN rental r ON i.inventory_id = r.inventory_id
    GROUP BY fc.category_id, f.film_id, f.title
    ) AS category_film_rentals;

-- Que 9)Find the films that have been rented less than the average rental count for their respective categories.
 WITH FilmRentalInfo AS (
 select fc.film_id, fc.category_id, count(r.rental_id) AS rental_count, 
 avg(count(r.rental_id)) over(partition by fc.category_id) as avg_rental_count
 from film_category fc join rental r on fc.film_id = r.inventory_id group by fc.film_id, fc.category_id )
 select fri.film_id, fri.category_id,fri.rental_count, fri.avg_rental_count from FilmRentalInfo fri
 where fri.rental_count < fri.avg_rental_count;
 
-- Que 10)Identify the top 5 months with the highest revenue and display the revenue generated in each month.
WITH MonthlyRevenue AS(
select date_format(payment_date, '%Y - %m') AS month,
sum(amount) AS total_revenue from payment group by date_format(payment_date, '%Y - %m') )
Select month, total_revenue from MonthlyRevenue order by total_revenue desc limit 5;