----- Basic SQL -----

--We are conducting a marketing campaign targeting female customers living in the 
--United States.  Which female customers have purchased something from us (through our 
--web site) in calendar year 2008?  Be sure to return a distinct list of customers. 
--Return the CustomerAlternateKey as well as some friendlier customer identifying 
--information in your results.(5 pts)
SELECT DISTINCT 
   b.FirstName + ' ' + b.LastName as Name,
   b.CustomerAlternateKey
FROM FactInternetSales a
LEFT JOIN DimCustomer b
   ON a.CustomerKey = b.CustomerKey
INNER JOIN DimDate c
   ON a.OrderDateKey = c.DateKey
WHERE c.CalendarYear = 2008
   AND b.Gender = 'F'
   AND b.EnglishCountryRegionName = 'United States';


--We commonly seek to trigger reseller purchases of bicycles through the use of promotions
--that discount the price of the bikes. Do we have any bicycle sales from resellers where
--the 'No Discount' promotion was applied?  Provide the sales order number, product SKU, order date 
--and quantity sold if any of these sales are found.  Use column aliasing to make sure field 
--names clearly identify each of these elements and return data with the most recent of these
--sales first. Please note that 'No Discount' is an actual entry in DimPromotion. (5 pts)
SELECT
   a.SalesOrderNumber as [Order Number],
   b.ProductAlternateKey as [Product SKU],
   c.FullDateAlternateKey as [Order Date],
   a.OrderQuantity as [Quantity Sold]
FROM FactResellerSales a
INNER JOIN DimProduct b
   ON a.ProductKey = b.ProductKey
INNER JOIN DimDate c
   ON a.OrderDateKey = c.DateKey
INNER JOIN DimPromotion d
   ON a.PromotionKey = d.PromotionKey
WHERE b.EnglishProductCategoryName = 'Bikes'
	AND d.EnglishPromotionName = 'No Discount'
ORDER BY c.FullDateAlternateKey DESC;


-- Our portfolio of bicycles has become quite large, maybe too large.  
-- Management has asked that we evaluate sales of bicycles over the last 
-- two years, i.e. calendar years 2007 & 2008, to identify the 20 bicycle 
-- SKUs with the lowest number of units sold through our resellers channel. 
-- We intend to use the information on these SKUs to evaluate a portfolio
-- rationalization plan. Ignore for now product SKUs that sold no units 
-- during this period; this does not require any additional SQL logic to 
-- be applied. 
SELECT TOP 20 WITH TIES
	SUM(a.OrderQuantity) as [Order Quantity],
	b.ProductAlternateKey as [Product SKU]
FROM FactResellerSales a
INNER JOIN DimProduct b
   ON a.ProductKey = b.ProductKey
INNER JOIN DimDate c
   ON a.OrderDateKey = c.DateKey
WHERE b.EnglishProductCategoryName = 'Bikes'
	AND c.CalendarYear IN (2007, 2008)
GROUP BY b.ProductAlternateKey
HAVING SUM(a.OrderQuantity) > 0
ORDER BY SUM(a.OrderQuantity);


-- In the US, sales of products in the 'Caps' product subcategory
-- are a good indicator of market awareness of our brand. Adventure
-- Works has only recently begun selling caps and other clothing items
-- online so that the quantity of caps sold through this channel is 
-- expected to be fairly low. Still, we know that some US states 
-- are generating cap sales in higher quantities than others.
--
-- We intend to launch a marketing campaign soon to drive greater 
-- awareness of our online site.  Help us identify in which states we
-- already have good awareness so that we can focus our investment on
-- the others. Let's use sales of 100 or more caps within a state as 
-- an indicator that no more marketing investment is required in that
-- geography. 
SELECT 
	c.StateProvinceName as States,
	SUM(a.OrderQuantity) as [Order Quantity]
FROM FactInternetSales a
INNER JOIN DimProduct b
	ON a.ProductKey = b.ProductKey
INNER JOIN DimCustomer c
	ON a.CustomerKey = c.CustomerKey
WHERE b.EnglishProductSubcategoryName = 'Caps'
	AND c.EnglishCountryRegionName = 'United States'
GROUP BY c.StateProvinceName
HAVING SUM(a.OrderQuantity) >= 100
ORDER BY SUM(a.OrderQuantity) DESC;


--In calendar year 2006, the CMO of Adventure Works executed a series of 
--promotions extending larger than normal discount amounts to resellers' 
--purchases of products across our Bikes category to drive larger orders 
--through this channel. These promotions were scaled back in 2007 and 
--replaced with a series of smaller promotional offers still targeting 
--the sale of Bikes but applicable across a wider range of order sizes. 
--Some of our larger resellers complained about this shift in promotional 
--practices, stating that their average discount amount on Bikes is smaller 
--in 2007 than in 2006. However, our CMO contends that the average discount 
--amount applied to Bicycle purchases across the reseller channel has 
--remained about the same between 2006 and 2007. How could both parties have
--such differing views of the situation?

--Provide me a SQL query evaluating discount amounts applied to 'Bikes' in
--calendar years 2006 & 2007. Include averages of discount amount at the line
--item level (with no consideration of order quantity) that reflect both the 
--CMO and the reseller's point of views.

-- NOTE: The only aggregation function you may use is the AVG() function. Use of
-- SUM() and COUNT() will result in a deduction.
SELECT 
   b.CalendarYear as Year,
   AVG(a.DiscountAmount) as [Reseller POV],
   AVG(COALESCE(a.DiscountAmount, 0)) as [CMO POV]
FROM FactResellerSales a
INNER JOIN DimDate b
   ON a.OrderDateKey = b.DateKey
INNER JOIN DimProduct c
   ON a.ProductKey = c.ProductKey
WHERE b.CalendarYear in (2006, 2007)
   AND c.EnglishProductCategoryName = 'Bikes'
GROUP BY
   b.CalendarYear;


--You've been asked to compare the average number of lines per sales order
--by calendar year for sales orders to resellers. Perform your average calculations in 
--a manner that preserves a consistent level of accuracy.  Present the results with two
--decimal places present.
WITH CountLines as(-- count number of lines in each calendar year by sales order number
   SELECT
      CAST(COUNT(a.SalesOrderLineNumber) AS FLOAT) AS NumberLines,
      b.CalendarYear,
      a.SalesOrderNumber
   FROM FactResellerSales a
   INNER JOIN DimDate b
      ON a.OrderDateKey = b.DateKey
   GROUP BY a.SalesOrderNumber, b.CalendarYear
   )
SELECT 
   CalendarYear,
   CAST(AVG(NumberLines) as NUMERIC(9,3)) as [Average Number of Lines]
FROM CountLines
GROUP BY CalendarYear
ORDER BY CalendarYear;


--Our marketing department believes online customers order bicycles
-- more frequently on some days of the week than on others. Write a query that
-- returns the number of bicycles sold to online customers by weekday. The result
-- set should provide a friendly name for the day of the week along with the number
-- of units sold and nothing more.  The days of the week should be sorted from Sunday
-- through Saturday.  Only one nested query may be used (though it is certainly possible
-- to write the query with no nesting at all.)
SELECT 
   x.OQ as [Number of Bikes],
   x.WD as [Weekday]
FROM
   (SELECT 
      SUM(a.OrderQuantity) as OQ,
      DATENAME(dw, c.FullDateAlternateKey) as WD,
      DATEPART(dw, c.FullDateAlternateKey) as R
   FROM FactInternetSales a
   INNER JOIN DimProduct b
      ON a.ProductKey = b.ProductKey
   INNER JOIN DimDate c
      ON a.OrderDateKey = c.DateKey
   WHERE b.EnglishProductCategoryName = 'Bikes'
   GROUP BY 
      DATENAME(dw, c.FullDateAlternateKey),
      DATEPART(dw, c.FullDateAlternateKey)
   ) x
ORDER BY x.R;





----- Nesting and Windowing -----

--Assemble a data set containing nothing more than the unique ProductAlternateKey
--values for each bicycle in our DimProducts dimension.  Assemble another data
--set summarizing annual reseller sales amount for each bicycle (using its
--ProductAlternateKey) in calendar year 2007. Assemble one more data set 
--summarizing reseller sales amount for each bicycle (using its 
--ProductAlternateKey) in calendar year 2006.
--Using nesting techniques, bring together these data sets so that you 
--can show annual sales by ProductAlternateKey in 2007 side-by-side with 
--the corresponding sales for 2006. Be sure to join your nested queries 
--in a way so that each product in the first set is preserved in the 
--final results, regardless of whether that product had sales in either 
--2006 or 2007.
SELECT 
   x.ProductAlternateKey as [Product Alternate Key],
   y.SA06 as [2006 Sales Amount],
   z.SA07 as [2007 Sales Amount]
FROM
   (SELECT DISTINCT 
      ProductAlternateKey
   FROM DimProduct
   WHERE EnglishProductCategoryName = 'Bikes'
   ) x
LEFT OUTER JOIN
   (SELECT 
      SUM(a.SalesAmount) as SA06,
      c.ProductAlternateKey
   FROM FactResellerSales a
   INNER JOIN DimDate b 
      ON a.OrderDateKey = b.DateKey
   INNER JOIN DimProduct c
      ON a.Productkey = c.ProductKey
   WHERE b.CalendarYear = 2006
   GROUP BY c.ProductAlternateKey
   ) y
ON x.ProductAlternateKey = y.ProductAlternateKey
LEFT OUTER JOIN
   (SELECT 
      SUM(a.SalesAmount) as SA07,
      c.ProductAlternateKey
   FROM FactResellerSales a
   INNER JOIN DimDate b 
      ON a.OrderDateKey = b.DateKey
   INNER JOIN DimProduct c
      ON a.Productkey = c.ProductKey
   WHERE b.CalendarYear = 2007
   GROUP BY c.ProductAlternateKey
   ) z
ON x.ProductAlternateKey = z.ProductAlternateKey;


/* Does an Internet customer's orders increase after their first 
purchase from the Clothing category? Build a set showing a customer's purchase 
history with sales amount reflecting all items in the order, clothing and non-clothing.
Flag orders with 0 indicating the order is one taking place before the first purchase
of clothing in the customer's purchase history or 1 indicating the order is one that 
includes or takes place after the first purchase of clothing. Be mindful that 
Customer is a Type 2 SCD so that the CustomerKey (surrogate key) value for that
customer varies over time.  You may assume that a customer does not submit more than
one order on a given date.  In addition, some customers may never purchase clothing;
they should not be excluded from this result set. 

   NOTE Your result set should contain the customer identifier, the order date, 
   a flag for the logic described above and a total sales amount, in that order.  
   No other fields should be present in your result. Return your results sorted by 
   customer identifier and order date, each in ascending order.

Please keep in mind, your goal is not to answer the question presented at the top of
this assignment but instead is to generate an appropriate data set which can be 
delivered to an analytic tool (such as R or SAS) where that question would be answered.

Use the tables provided in AdventureWorksDW and limit your SQL to techniques demonstrated
in labs.*/
SELECT
   x.CustomerAlternateKey as [Customer ID],
   x.FullDateAlternateKey as [Order Date],
   y.FCP as [1st Clothing Order],
   CASE
   WHEN y.FCP <= x.FullDateAlternateKey THEN 1
      ELSE 0
      END as Flag,
   x.TS as [Total Sale]
FROM
   (SELECT
      a.SalesOrderNumber,
      d.CustomerAlternateKey,
      c.FullDateAlternateKey,
      SUM(a.SalesAmount) as TS
   FROM FactInternetSales a
   INNER JOIN DimProduct b
      ON a.ProductKey = b.ProductKey
   INNER JOIN DimDate c
      ON a.OrderDateKey = c.DateKey
   INNER JOIN DimCustomer d
      ON a.CustomerKey = d.CustomerKey
   GROUP BY 
      a.SalesOrderNumber,
      d.CustomerAlternateKey,
      c.FullDateAlternateKey
   ) x
LEFT JOIN 
   (SELECT
      d.CustomerAlternateKey,
      MIN(c.FullDateAlternateKey) as FCP
   FROM FactInternetSales a
   INNER JOIN DimProduct b
      ON a.ProductKey = b.ProductKey
   INNER JOIN DimDate c
      ON a.OrderDateKey = c.DateKey
   INNER JOIN DimCustomer d
      ON a.CustomerKey = d.CustomerKey
   WHERE b.EnglishProductCategoryName = 'Clothing'
   GROUP BY d.CustomerAlternateKey
   ) y
   ON x.CustomerAlternateKey = y.CustomerAlternateKey
ORDER BY 
   x.CustomerAlternateKey,
   x.FullDateAlternateKey;


/* What is the 2008 sales rank for the top 25 selling products of 2007? Present the 
product rank for both years and sort the results on the 2007 rank from best to
worst performing. HINT Products that sold in 2007 but that do not have sales in 
2008 should have a NULL rank in that year (2008).

NOTE The result set should consist of three fields, in this order: ProductAlternateKey, 
the 2007 Rank and the 2008 Rank.  Order your results on Product Alternate Key.

Use the tables provided in AdventureWorksDW and limit your SQL to techniques demonstrated
in labs.*/
SELECT * 
FROM
   (SELECT 
      x.ProductAlternateKey,
      x.Sales2007 as Rank2007,
      y.Sales2008 as Rank2008
   FROM
      (SELECT
         c.ProductAlternateKey,
         RANK() OVER (ORDER BY SUM(a.SalesAmount) DESC) as Sales2007
      FROM 
         (SELECT 
            ProductKey,
            OrderDateKey,
            SalesAmount
         FROM FactInternetSales
         UNION ALL
         SELECT 
            ProductKey,
            OrderDateKey,
            SalesAmount
         FROM FactResellerSales
         ) a
      LEFT JOIN DimDate b
         ON a.OrderDateKey = b.DateKey
      LEFT JOIN DimProduct c
         ON a.ProductKey = c.ProductKey
      WHERE b.CalendarYear = 2007
      GROUP BY c.ProductAlternateKey
      ) x
   LEFT JOIN
      (SELECT 
         c.ProductAlternateKey,
         RANK() OVER (ORDER BY SUM(a.SalesAmount) DESC) as Sales2008
      FROM 
         (SELECT 
            ProductKey,
            OrderDateKey,
            SalesAmount
         FROM FactInternetSales
         UNION ALL
         SELECT 
            ProductKey,
            OrderDateKey,
            SalesAmount
         FROM FactResellerSales
         ) a
      LEFT JOIN DimDate b
         ON a.OrderDateKey = b.DateKey
      LEFT JOIN DimProduct c
         ON a.ProductKey = c.ProductKey
      WHERE b.CalendarYear = 2008
      GROUP BY c.ProductAlternateKey
         ) y
   ON x.ProductAlternateKey = y.ProductAlternateKey
) m
WHERE Rank2007 <= 25
ORDER BY Rank2007;