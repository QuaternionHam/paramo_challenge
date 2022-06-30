WITH explode_and_remove AS (
SELECT 
		a.order_time,
		a.order_id,
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
		trim(d.value) is not null and 
		a.order_time >= '2021-03-11'
),
picking_first_five AS (
	SELECT TOP 5
		exploded_ingredients as ingredient, 
		count(exploded_ingredients) total
	FROM explode_and_remove
	GROUP BY exploded_ingredients
	ORDER BY total DESC
)
SELECT 
string_agg(ingredient, ',') within group (order by ingredient asc) new_pizza
FROM picking_first_five

