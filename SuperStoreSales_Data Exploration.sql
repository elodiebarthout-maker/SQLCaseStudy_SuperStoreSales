-- Q1 List the top 10 customers by total sales amount (show CustomerID, full name & total sales)

SELECT TOP 10 s.CustomerID,
	c.FirstName + ' ' + c.LastName AS CustomerName,
	SUM(s.Price) AS TotalSales
FROM Sales s
JOIN Customer c ON s.CustomerID = c.ID
GROUP BY s.CustomerID, c.FirstName, c.LastName
ORDER BY TotalSales DESC


-- Q2 Show total sales per month for year 2023, ordered by month

SELECT 
	MONTH(s.OrderDate) AS MonthIn2023,
	SUM(s.Price) AS TotalSales
FROM Sales s
WHERE YEAR(s.OrderDate) = '2023'
GROUP BY MONTH(s.OrderDate)
ORDER BY MONTH(s.OrderDate);


-- Q3 Find out which products have never been sold

SELECT p.ProductID, p.ProductName, p.Category
FROM Products p
LEFT JOIN Sales s ON p.ProductID = s.ProductID
WHERE s.ProductID IS NULL


-- Q4 Find how many new customers were acquired in 2022

SELECT COUNT(*) AS NewCustomers2022
FROM (
	SELECT s.CustomerID, MIN(s.OrderDate) AS FirstOrderDate
	FROM Sales s
	GROUP BY s.CustomerID
	HAVING YEAR(MIN(s.OrderDate)) = '2022'
) t


-- Q5 Calculate the profit margin (Profit/Sales) percentage for each category

SELECT p.Category,
	CAST(SUM(s.Profit) / SUM(s.Price) * 100 AS DECIMAL (10,2)) AS ProfitMarginPercentage
FROM Sales s
JOIN Products p ON s.ProductID = p.ProductID
GROUP BY p.Category


-- Q6 For each category, show date-wise sales & a running total of sales over time

WITH CTE_Sales AS (
	SELECT p.Category, s.OrderDate, 
		SUM(s.price) AS DailySales
	FROM Sales s
	JOIN Products p ON s.ProductID = p.ProductID
	GROUP BY p.Category, s.OrderDate
)
SELECT cte.Category, cte.OrderDate, cte.DailySales,
	SUM(cte.DailySales) OVER (PARTITION BY Category ORDER BY OrderDate 
	ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RunningTotal
FROM CTE_Sales cte


-- Q7 Get the most recent order (by OrderDate) for every customer

SELECT s.CustomerID, 
	c.FirstName + ' ' + c.LastName AS CustomerName,
	MAX(s.OrderDate) AS LastOrder
FROM Sales s
JOIN Customer c ON s.CustomerID = c.ID
GROUP BY s.CustomerID, c.FirstName, c.LastName


-- Q8 Classify customers based on their total sale. Show CustomerID, CustomerName, TotalSales:
--- Platinum - TotalSales >= 15,000
--- Gold - 10,000 to < 15,000
--- Silver - 5,000 to < 10,000
--- Bronze - < 5,000

WITH CTE_Sales AS (
	SELECT s.CustomerID, 
		c.FirstName + ' ' + c.LastName AS CustomerName,
		SUM(s.Price) AS TotalSales
	FROM Sales s
	JOIN Customer c ON s.CustomerID = c.ID
	GROUP BY s.CustomerID, c.FirstName, c.LastName
)
SELECT cte.CustomerID, cte.CustomerName, cte.TotalSales,
	CASE 
		WHEN cte.TotalSales < 5000 THEN 'Bronze'
		WHEN cte.TotalSales BETWEEN 5000 AND 10000 THEN 'Silver'
		WHEN cte.TotalSales BETWEEN 10000 AND 15000 THEN 'Gold'
		ELSE 'Platinum'
	END AS CustomerClass
FROM CTE_Sales cte
GROUP BY cte.CustomerID, cte.CustomerName, cte.TotalSales
ORDER BY cte.TotalSales DESC


-- Q9: For each category, find the product with the highest total sales. If ties exist, show all tied products.

WITH CTE_Sales AS (
	SELECT p.Category, p.ProductName,
		CAST(SUM(s.Price) AS DECIMAL(10,2)) AS TotalSales
	FROM Sales s
	JOIN Products p ON s.ProductID = p.ProductID
	GROUP BY p.Category, p.ProductName
),
CTE_Rk AS (
	SELECT cte.Category, cte.ProductName, cte.TotalSales,
		RANK() OVER(PARTITION BY Category ORDER BY TotalSales DESC) AS rk
	FROM CTE_Sales cte
)
SELECT Category, ProductName, TotalSales
FROM CTE_Rk
WHERE rk = 1;


-- Q10 Actual VS Target Sales by category & year

WITH CTE_TargetSales AS (
	SELECT Category,
		REPLACE(Year, '_Sales', '') AS SalesYear,
		TargetSales
	FROM (
				SELECT Category, Year, TargetSales
				FROM TargetSales ts
				UNPIVOT (
					TargetSales FOR Year IN (
					[2020_Sales],
					[2021_Sales],
					[2022_Sales],
					[2023_Sales]
					)
			) u
		) t
),
CTE_ActualSales AS (
	SELECT p.Category, YEAR(s.OrderDate) AS SalesYear,
		SUM(s.Price) AS ActualSales
	FROM Sales s
	JOIN Products p ON s.ProductID = p.ProductID
	GROUP BY p.Category, YEAR(s.OrderDate)
)
SELECT ts.Category, ts.SalesYear, ts.TargetSales, ac.ActualSales
FROM CTE_TargetSales ts
LEFT JOIN CTE_ActualSales ac ON ts.Category = ac.Category
	AND ts.SalesYear = ac.SalesYear

