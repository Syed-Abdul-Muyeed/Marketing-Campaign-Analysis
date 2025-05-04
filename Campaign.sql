-- ## SECTION 1: OVERVIEW OF THE DATA ## --

SELECT * FROM INFORMATION_SCHEMA.TABLES

SELECT * FROM city
SELECT * FROM customer
SELECT * FROM campaign
SELECT * FROM item
SELECT * FROM CouponMapping
SELECT * FROM CustomerTransactionData
-----------------------------------------------------------------------------------
-- Q1. Check the cardinality of following columns (Counts)

-- 1. Different type of paints provided by the company.
SELECT COUNT(DISTINCT Item_Category) AS Item_count FROM item

-- 2. Different Coupon Types that are offered
SELECT COUNT(DISTINCT couponType) AS coupon_types_count FROM couponmapping

-- 3. States where the company is currently delivering its products and services.
SELECT COUNT(DISTINCT state) AS State_count FROM city

-- 4. Different Order Types.
SELECT COUNT(DISTINCT ordertype) AS ordertype_count FROM CustomerTransactionData 

-- Q2. Identify total number of sales (transactions) happened by

-- 1. Yearly basis
SELECT YEAR(PurchaseDate) AS YEAR, COUNT(trans_id) Total_no_of_sales
FROM CustomerTransactionData
GROUP BY YEAR(PurchaseDate)

-- 2. Quarterly basis
SELECT DATEPART(QUARTER,PurchaseDate) AS QUARTER, COUNT(trans_id) Total_no_of_sales
FROM CustomerTransactionData
GROUP BY DATEPART(QUARTER,PurchaseDate)

-- 3. Yearly and Monthly basis
SELECT YEAR(PurchaseDate) Year, Month(PurchaseDate) Month, COUNT(trans_id) Total_no_of_sales
FROM CustomerTransactionData
GROUP BY YEAR(PurchaseDate),Month(PurchaseDate)

-----------------------------------------------------------------------------------
-- Q3. Identify the total purchase order by
-- 1. Product category
SELECT item_category, SUM(PurchasingAmt) Total_Sales FROM CustomerTransactionData c
JOIN item i
ON c.item_id = i.item_id
GROUP BY item_category

-- 2. Yearly and Quarterly basis
SELECT YEAR(PurchaseDate) Year, DATEPART(QUARTER,PurchaseDate) QUARTER, SUM(PurchasingAmt) Total_Sales
FROM CustomerTransactionData
GROUP BY  YEAR(PurchaseDate),DATEPART(QUARTER,PurchaseDate)

-- 3. Order Type
SELECT OrderType, ROUND(SUM(PurchasingAmt),0) Total_Sales
FROM CustomerTransactionData
GROUP BY OrderType

-- 4. City Tier
SELECT CityTier, ROUND(SUM(PurchasingAmt),0) Total_Sales FROM city ci
JOIN customer cu
ON ci.City_Id = cu.City_Id
JOIN CustomerTransactionData ct
ON cu.Customer_Id = ct.cust_id
GROUP BY CityTier

-- ## 2. Understanding lead conversions ## --

-- 1. Identify total no. of transactions with campaign coupon vs without campaign coupon.
SELECT 'Purchase_without_coupon' as 'Coupon_Status', 
    COUNT(Trans_Id) 'No_of_Trans' 
FROM CustomerTransactionData 
WHERE coupon_id IS NULL
UNION ALL
SELECT 'Purchase_with_coupon' as 'Coupon_Status', 
    COUNT(Trans_Id) 'No_of_Trans' 
FROM CustomerTransactionData 
WHERE coupon_id IS NOT NULL;

-- 2. identify the name of potential leads who have made a purchase but have not yet used a campaign coupon
SELECT C.Customer_Id,
    C.Name,
    COUNT(Trans_Id) AS NumberOfPurchase
FROM Customer C 
INNER JOIN CustomerTransactionData CT
ON C.Customer_Id = CT.Cust_Id 
WHERE coupon_id IS NULL
GROUP BY C.Customer_Id, C.Name ;

-- ## 3. Understanding customer engagement ## --

-- 1. Which customers have used the most coupons and what is the total price
SELECT TOP(1)
    C.Customer_Id, 
    C.Name,
    COUNT(coupon_id) AS 'No_of_Coupons',
    SUM(PurchasingAmt) AS 'Total_Price'
FROM Customer C
INNER JOIN CustomerTransactionData CT 
ON C.Customer_Id = CT.Cust_Id 
WHERE coupon_id IS NOT NULL
GROUP BY C.Customer_Id, C.Name
ORDER BY 3 DESC, 4 DESC;


-- 2. Name of customer in Which city have the highest number of transactions and what is the total 
SELECT TOP(1) Cust_Id, Name, 
    C.City_Id, CY.City_Name, 
    SUM(PurchasingAmt) 'Purchase_Amt'
FROM CustomerTransactionData CT 
INNER JOIN Customer C
ON C.Customer_Id = CT.Cust_Id
INNER JOIN City CY
ON CY.City_ID = C.City_ID
WHERE CY.City_Id = (SELECT City_ID FROM 
                    (SELECT TOP(1) City_Name, CY.City_ID,
                        COUNT(Trans_Id) AS 'Total_Trans',
                        ROUND(SUM(PurchasingAmt), 0) AS 'Total_Sales'
                    FROM CustomerTransactionData CT 
                    INNER JOIN Customer CS 
                    ON CT.Cust_Id = CS.Customer_Id
                    INNER JOIN City CY 
                    ON CY.City_Id = CS.City_Id 
                    GROUP BY City_Name, CY.City_ID
                    ORDER BY 3 DESC, 4 DESC) as temp)
GROUP BY Cust_Id, Name, C.City_Id, CY.City_Name
ORDER BY 5 DESC ;


-- ## 4. Automating the Task ## --

-- 1. Create view for top 10 Customers by Purchasing Amount

GO
CREATE VIEW vw_Top10CustomerPurchase AS
    (SELECT TOP(10) CT.Cust_Id, C.Name, 
        SUM(PurchasingAmt) AS 'Total_Sales' 
    FROM CustomerTransactionData CT 
    INNER JOIN Customer C 
    ON C.Customer_Id = CT.Cust_Id
    GROUP BY CT.Cust_Id, C.Name
    ORDER BY 3 DESC) ;
GO

select * from vw_Top10CustomerPurchase ;

-- 2. Top 5 Customers (from Household and Industrial Sector) Based on Purchase Amount 

GO
CREATE VIEW vw_Top5CustBySector AS 
(SELECT TOP(5) C.Name, Cust_Id, SUM(PurchasingAmt) AS 'Total_Sales', OrderType 
FROM CustomerTransactionData CT 
INNER JOIN Customer C 
ON C.Customer_Id = CT.Cust_Id
WHERE OrderType IN ('Household', 'Industrial')
GROUP by C.Name, Cust_Id, OrderType
ORDER BY 3 DESC) ;
GO

SELECT * from vw_Top5CustBySector;

