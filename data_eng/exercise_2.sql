WITH explode_and_remove AS (
SELECT 
		a.order_time,
		a.order_id,
		a.customer_id,
		a.pizza_id, 
		b.ingredients,
		a.exclusions,
		a.extras,
		d.value exploded_ingredients
	FROM [dbo].[Orders] a
	INNER JOIN [dbo].[Pizza] b ON a.pizza_id=b.id
	CROSS APPLY STRING_SPLIT(TRIM(concat_ws(',',b.ingredients,a.extras)),',') d
	where trim(coalesce(a.exclusions,'')) not like '%'+trim(d.value)+'%' and 
		trim(d.value)!='' and 
		trim(d.value) is not null
),
counting_ingredients AS (
SELECT DISTINCT
	a.order_time,
	a.order_id,
	a.customer_id,
	a.pizza_id, 
	a.exclusions,
	a.extras,
	a.exploded_ingredients,
	b.name ingredient_name,
	count(a.exploded_ingredients) over (partition by order_time, order_id, customer_id, pizza_id, exclusions, extras,exploded_ingredients) amount
FROM explode_and_remove a
INNER JOIN [dbo].[Ingredients] b on a.exploded_ingredients=b.id
)
SELECT
	a.order_time,
	a.order_id,
	a.customer_id,
	a.pizza_id, 
	a.exclusions,
	a.extras,
	string_agg(CASE WHEN amount>1 then concat_ws('x',a.amount,a.ingredient_name) else a.ingredient_name end, ',') within group (order by a.ingredient_name asc) recipe
FROM counting_ingredients a
GROUP BY a.order_time,a.order_id,a.customer_id,a.pizza_id,a.exclusions,a.extras

