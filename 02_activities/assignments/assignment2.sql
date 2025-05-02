/* ASSIGNMENT 2 */
/* SECTION 2 */

-- COALESCE
/* 1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 
We tell them, no problem! We can produce a list with all of the appropriate details. 

Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product

But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a 
blank for the first problem, and 'unit' for the second problem. 

HINT: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same.) */

SELECT 
    product_name || ', ' || COALESCE(product_size, '') || ' (' || COALESCE(product_qty_type, 'unit') || ')'
FROM product


--Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 

You can either display all rows in the customer_purchases table, with the counter changing on
each new market date for each customer, or select only the unique market dates per customer 
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). */

SELECT 
    customer_id,
    market_date,
    product_id,
    ROW_NUMBER() OVER (
        PARTITION BY customer_id 
        ORDER BY market_date
    ) AS visit_lable
FROM customer_purchases
ORDER BY customer_id, market_date;


/* 2. Reverse the numbering of the query from a part so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit. */

SELECT *
FROM
(
SELECT 
    customer_id,
    market_date,
    product_id,
    ROW_NUMBER() OVER (
        PARTITION BY customer_id 
        ORDER BY market_date DESC
    ) AS visit_lable
FROM customer_purchases
ORDER BY customer_id, market_date DESC
)
WHERE visit_lable=1


/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. */

SELECT 
    customer_purchases.*,
    COUNT(*) OVER (
        PARTITION BY customer_id, product_id
    ) AS purchase_count
FROM 
    customer_purchases;


-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */

SELECT 
    product_name,
    CASE 
        WHEN INSTR(product_name, '-') > 0 
        THEN TRIM(SUBSTR(product_name, INSTR(product_name, '-') + 1))
        ELSE NULL
    END AS description
FROM product;


/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */

SELECT *
FROM product
WHERE product_size REGEXP '[0-9]'


-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */

WITH DailySales AS (
    SELECT 
        market_date,
        SUM(quantity * cost_to_customer_per_qty) AS total_sales
    FROM customer_purchases
    GROUP BY market_date
),

RankedSales AS (
    SELECT 
        market_date,
        total_sales,
        ROW_NUMBER() OVER(ORDER BY total_sales DESC) AS rn_max,
        ROW_NUMBER() OVER(ORDER BY total_sales ASC) AS rn_min
    FROM DailySales
)

SELECT market_date, total_sales, 'best_day' AS day_status
FROM RankedSales
WHERE rn_max = 1

UNION

SELECT market_date, total_sales, 'worst_day' AS day_status  
FROM RankedSales
WHERE rn_min = 1
ORDER BY total_sales DESC;


/* SECTION 3 */

-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */



-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */

DROP TABLE IF EXISTS TEMP.product_units;
CREATE TEMP TABLE product_units AS 
SELECT 
  *,
  CURRENT_TIMESTAMP AS snapshot_timestamp
FROM product 
WHERE product_qty_type = 'unit';

SELECT *
FROM product_units

/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */

DROP TABLE IF EXISTS TEMP.product_units;
CREATE TEMP TABLE product_units AS 
SELECT 
  *,
  CURRENT_TIMESTAMP AS snapshot_timestamp
FROM product 
WHERE product_qty_type = 'unit';

INSERT INTO TEMP.product_units
SELECT 
  555 AS product_id,        
  'Cheese Cake' AS product_name,
  '6 slice' AS product_size,
  3 AS product_category_id,
  'unit' AS product_qty_type,
  -- Include any other columns that exist in the product table
  CURRENT_TIMESTAMP AS snapshot_timestamp
;

SELECT *
FROM product_units;

-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/

DROP TABLE IF EXISTS TEMP.product_units;
CREATE TEMP TABLE product_units AS 
SELECT 
  *,
  CURRENT_TIMESTAMP AS snapshot_timestamp
FROM product 
WHERE product_qty_type = 'unit';

INSERT INTO TEMP.product_units
SELECT 
  555 AS product_id,        
  'Cheese Cake' AS product_name,
  '6 slice' AS product_size,
  3 AS product_category_id,
  'unit' AS product_qty_type,
  -- Include any other columns that exist in the product table
  CURRENT_TIMESTAMP AS snapshot_timestamp
;

DELETE FROM TEMP.product_units
WHERE product_id = 555 
AND snapshot_timestamp < '2025-04-27 20:14:38';

SELECT *
FROM product_units;


-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */


ALTER TABLE product_units
ADD current_quantity INT;

UPDATE product_units
SET current_quantity = (
    --  last quantity for each product
    SELECT COALESCE(vi.quantity, 0)
    FROM vendor_inventory vi
    WHERE vi.product_id = product_units.product_id
    -- Order by date to get the most recent 
    ORDER BY vi.market_date DESC
    -- Limit 1 to get only the most recent record
    LIMIT 1
);
UPDATE product_units
SET current_quantity = 0
WHERE current_quantity IS NULL;

SELECT *
FROM product_units






