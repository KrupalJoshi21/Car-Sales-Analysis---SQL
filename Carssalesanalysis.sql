CREATE DATABASE CarsSalesAnalysis; 
GO 
USE CarSalesAnalysis; 


SELECT COUNT(*) AS CustomerCount FROM Customers; 
SELECT COUNT(*) AS CarCount FROM Cars;
SELECT COUNT(*) AS SalesCount FROM Sales; 
SELECT TOP 5 * FROM Customers; 
SELECT TOP 5 * FROM Cars; 
SELECT TOP 5 * FROM Sales;



-- =============================================
-- STEP 2: CREATE TABLES
-- =============================================

-- Create Customers Table
CREATE TABLE Customers1 (
    Customer_ID VARCHAR(10) PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Gender VARCHAR(10),
    Age INT,
    Phone VARCHAR(50),
    Email VARCHAR(100),
    City VARCHAR(100)
);

-- Create Cars Table
CREATE TABLE Cars1 (
    Car_ID VARCHAR(10) PRIMARY KEY,
    Brand VARCHAR(50) NOT NULL,
    Model VARCHAR(50) NOT NULL,
    Year INT,
    Color VARCHAR(20),
    Engine_Type VARCHAR(20),
    Transmission VARCHAR(20),
    Price DECIMAL(10,2),
    Quantity_In_Stock INT,
    Status VARCHAR(20)
);

-- Create Sales Table
CREATE TABLE Sales1 (
    Sale_ID VARCHAR(10) PRIMARY KEY,
    Customer_ID VARCHAR(10) FOREIGN KEY REFERENCES Customers1(Customer_ID),
    Car_ID VARCHAR(10) FOREIGN KEY REFERENCES Cars1(Car_ID),
    Sale_Date DATE,
    Quantity INT,
    Sale_Price DECIMAL(10,2),
    Payment_Method VARCHAR(20),
    Salesperson VARCHAR(100)
);


-- =============================================
-- STEP 3: DATA QUALITY CHECKS
-- =============================================

-- Check for NULL values in critical columns
SELECT 
    'Customers' AS TableName,
    COUNT(*) AS TotalRows,
    COUNT(CASE WHEN Customer_ID IS NULL THEN 1 END) AS Null_CustomerID,
    COUNT(CASE WHEN Name IS NULL THEN 1 END) AS Null_Name,
    COUNT(CASE WHEN Email IS NULL THEN 1 END) AS Null_Email
FROM Customers
UNION ALL
SELECT 
    'Sales' AS TableName,
    COUNT(*) AS TotalRows,
    COUNT(CASE WHEN Sale_ID IS NULL THEN 1 END) AS Null_SaleID,
    COUNT(CASE WHEN Sale_Price IS NULL THEN 1 END) AS Null_SalePrice,
    COUNT(CASE WHEN Sale_Date IS NULL THEN 1 END) AS Null_SaleDate
FROM Sales
UNION ALL
SELECT 
    'Cars' AS TableName,
    COUNT(*) AS TotalRows,
    COUNT(CASE WHEN Car_ID IS NULL THEN 1 END) AS Null_CarID,
    COUNT(CASE WHEN Brand IS NULL THEN 1 END) AS Null_Brand,
    COUNT(CASE WHEN Price IS NULL THEN 1 END) AS Null_Price
FROM Cars;


-- =============================================
-- STEP 4: SALES PERFORMANCE ANALYSIS
-- =============================================

-- 1. Total Revenue and Sales Count by Year and Month
SELECT 
    YEAR(Sale_Date) AS SaleYear,
    MONTH(Sale_Date) AS SaleMonth,
    COUNT(DISTINCT Sale_ID) AS TotalSales,
    SUM(Sale_Price) AS TotalRevenue,
    AVG(Sale_Price) AS AverageSalePrice,
    SUM(Quantity) AS TotalUnitsSold
FROM Sales
GROUP BY YEAR(Sale_Date), MONTH(Sale_Date)
ORDER BY SaleYear, SaleMonth;

-- 2. Top 10 Best-Selling Car Models
SELECT TOP 10
    c.Brand,
    c.Model,
    COUNT(s.Sale_ID) AS NumberOfSales,
    SUM(s.Sale_Price) AS TotalRevenue,
    AVG(s.Sale_Price) AS AverageSalePrice
FROM Sales s
INNER JOIN Cars c ON s.Car_ID = c.Car_ID
GROUP BY c.Brand, c.Model
ORDER BY TotalRevenue DESC;

-- 3. Revenue by Payment Method
SELECT 
    Payment_Method,
    COUNT(Sale_ID) AS NumberOfTransactions,
    SUM(Sale_Price) AS TotalRevenue,
    AVG(Sale_Price) AS AverageSalePrice,
    CAST(COUNT(Sale_ID) * 100.0 / (SELECT COUNT(*) FROM Sales) AS DECIMAL(5,2)) AS PercentageOfSales
FROM Sales
GROUP BY Payment_Method
ORDER BY TotalRevenue DESC;

-- 4. Top 10 Performing Salespersons
SELECT TOP 10
    Salesperson,
    COUNT(Sale_ID) AS TotalSales,
    SUM(Sale_Price) AS TotalRevenue,
    AVG(Sale_Price) AS AverageSalePrice,
    MAX(Sale_Price) AS HighestSale
FROM Sales
GROUP BY Salesperson
ORDER BY TotalRevenue DESC;


-- =============================================
-- STEP 5: CUSTOMER ANALYSIS
-- =============================================

-- 1. Customer Demographics Analysis
SELECT 
    Gender,
    COUNT(DISTINCT Customer_ID) AS CustomerCount,
    AVG(Age) AS AverageAge,
    MIN(Age) AS MinAge,
    MAX(Age) AS MaxAge
FROM Customers
GROUP BY Gender;

-- 2. Top 10 Cities by Customer Count
SELECT TOP 10
    City,
    COUNT(Customer_ID) AS CustomerCount,
    CAST(COUNT(Customer_ID) * 100.0 / (SELECT COUNT(*) FROM Customers) AS DECIMAL(5,2)) AS PercentageOfTotal
FROM Customers
GROUP BY City
ORDER BY CustomerCount DESC;

-- 3. Customer Purchase Behavior
SELECT 
    c.Customer_ID,
    c.Name,
    c.City,
    COUNT(s.Sale_ID) AS NumberOfPurchases,
    SUM(s.Sale_Price) AS TotalSpending,
    AVG(s.Sale_Price) AS AveragePurchaseValue,
    MIN(s.Sale_Date) AS FirstPurchaseDate,
    MAX(s.Sale_Date) AS LastPurchaseDate
FROM Customers c
INNER JOIN Sales s ON c.Customer_ID = s.Customer_ID
GROUP BY c.Customer_ID, c.Name, c.City
HAVING COUNT(s.Sale_ID) > 1
ORDER BY TotalSpending DESC;

-- 4. Customer Segmentation by Total Spending
WITH CustomerSpending AS (
    SELECT 
        c.Customer_ID,
        c.Name,
        SUM(s.Sale_Price) AS TotalSpending
    FROM Customers c
    INNER JOIN Sales s ON c.Customer_ID = s.Customer_ID
    GROUP BY c.Customer_ID, c.Name
)
SELECT 
    CASE 
        WHEN TotalSpending >= 200000 THEN 'VIP'
        WHEN TotalSpending >= 100000 THEN 'High Value'
        WHEN TotalSpending >= 50000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS CustomerSegment,
    COUNT(Customer_ID) AS CustomerCount,
    AVG(TotalSpending) AS AverageSpending,
    SUM(TotalSpending) AS TotalRevenue
FROM CustomerSpending
GROUP BY 
    CASE 
        WHEN TotalSpending >= 200000 THEN 'VIP'
        WHEN TotalSpending >= 100000 THEN 'High Value'
        WHEN TotalSpending >= 50000 THEN 'Medium Value'
        ELSE 'Low Value'
    END
ORDER BY AverageSpending DESC;



-- =============================================
-- STEP 6: PRODUCT/INVENTORY ANALYSIS
-- =============================================

-- 1. Car Brand Performance
SELECT 
    c.Brand,
    COUNT(DISTINCT c.Car_ID) AS ModelCount,
    COUNT(s.Sale_ID) AS TotalSales,
    SUM(s.Sale_Price) AS TotalRevenue,
    AVG(s.Sale_Price) AS AverageSalePrice
FROM Cars c
LEFT JOIN Sales s ON c.Car_ID = s.Car_ID
GROUP BY c.Brand
ORDER BY TotalRevenue DESC;

-- 2. Analysis by Engine Type
SELECT 
    c.Engine_Type,
    COUNT(DISTINCT s.Sale_ID) AS NumberOfSales,
    SUM(s.Sale_Price) AS TotalRevenue,
    AVG(s.Sale_Price) AS AverageSalePrice,
    AVG(c.Price) AS AverageListPrice
FROM Cars c
INNER JOIN Sales s ON c.Car_ID = s.Car_ID
GROUP BY c.Engine_Type
ORDER BY TotalRevenue DESC;

-- 3. Transmission Type Preference
SELECT 
    c.Transmission,
    COUNT(s.Sale_ID) AS SalesCount,
    SUM(s.Sale_Price) AS TotalRevenue,
    CAST(COUNT(s.Sale_ID) * 100.0 / (SELECT COUNT(*) FROM Sales) AS DECIMAL(5,2)) AS PercentageOfSales
FROM Cars c
INNER JOIN Sales s ON c.Car_ID = s.Car_ID
GROUP BY c.Transmission
ORDER BY SalesCount DESC;

-- 4. Inventory Status Overview
SELECT 
    Status,
    COUNT(Car_ID) AS CarCount,
    SUM(Quantity_In_Stock) AS TotalUnits,
    AVG(Price) AS AveragePrice,
    SUM(Price * Quantity_In_Stock) AS InventoryValue
FROM Cars
GROUP BY Status
ORDER BY CarCount DESC;

-- 5. Low Stock Alert (Cars with less than 5 units)
SELECT 
    Car_ID,
    Brand,
    Model,
    Year,
    Quantity_In_Stock,
    Price,
    Status
FROM Cars
WHERE Quantity_In_Stock < 5 AND Status = 'Available'
ORDER BY Quantity_In_Stock ASC;


-- =============================================
-- STEP 7: ADVANCED ANALYSIS WITH WINDOW FUNCTIONS
-- =============================================

-- 1. Monthly Sales Trend with Running Total
WITH MonthlySales AS (
    SELECT 
        YEAR(Sale_Date) AS SaleYear,
        MONTH(Sale_Date) AS SaleMonth,
        SUM(Sale_Price) AS MonthlyRevenue
    FROM Sales
    GROUP BY YEAR(Sale_Date), MONTH(Sale_Date)
)
SELECT 
    SaleYear,
    SaleMonth,
    MonthlyRevenue,
    SUM(MonthlyRevenue) OVER (ORDER BY SaleYear, SaleMonth) AS RunningTotal,
    AVG(MonthlyRevenue) OVER (ORDER BY SaleYear, SaleMonth ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS ThreeMonthMovingAvg
FROM MonthlySales
ORDER BY SaleYear, SaleMonth;

-- 2. Ranking Salespersons by Quarter
WITH QuarterlySales AS (
    SELECT 
        Salesperson,
        YEAR(Sale_Date) AS SaleYear,
        DATEPART(QUARTER, Sale_Date) AS SaleQuarter,
        SUM(Sale_Price) AS QuarterlyRevenue
    FROM Sales
    GROUP BY Salesperson, YEAR(Sale_Date), DATEPART(QUARTER, Sale_Date)
)
SELECT 
    Salesperson,
    SaleYear,
    SaleQuarter,
    QuarterlyRevenue,
    RANK() OVER (PARTITION BY SaleYear, SaleQuarter ORDER BY QuarterlyRevenue DESC) AS SalesRank
FROM QuarterlySales
ORDER BY SaleYear, SaleQuarter, SalesRank;

-- 3. Customer Lifetime Value (CLV) Analysis
WITH CustomerMetrics AS (
    SELECT 
        c.Customer_ID,
        c.Name,
        c.City,
        COUNT(s.Sale_ID) AS TotalPurchases,
        SUM(s.Sale_Price) AS TotalRevenue,
        AVG(s.Sale_Price) AS AvgPurchaseValue,
        DATEDIFF(DAY, MIN(s.Sale_Date), MAX(s.Sale_Date)) AS CustomerLifespanDays
    FROM Customers c
    INNER JOIN Sales s ON c.Customer_ID = s.Customer_ID
    GROUP BY c.Customer_ID, c.Name, c.City
)
SELECT 
    Customer_ID,
    Name,
    City,
    TotalPurchases,
    TotalRevenue,
    AvgPurchaseValue,
    CustomerLifespanDays,
    NTILE(4) OVER (ORDER BY TotalRevenue DESC) AS RevenueQuartile
FROM CustomerMetrics
WHERE TotalPurchases > 1
ORDER BY TotalRevenue DESC;

-- 4. Year-over-Year Growth Analysis
WITH YearlySales AS (
    SELECT 
        YEAR(Sale_Date) AS SaleYear,
        SUM(Sale_Price) AS YearlyRevenue,
        COUNT(Sale_ID) AS TotalSales
    FROM Sales
    GROUP BY YEAR(Sale_Date)
)
SELECT 
    SaleYear,
    YearlyRevenue,
    TotalSales,
    LAG(YearlyRevenue) OVER (ORDER BY SaleYear) AS PreviousYearRevenue,
    CAST((YearlyRevenue - LAG(YearlyRevenue) OVER (ORDER BY SaleYear)) * 100.0 / 
         LAG(YearlyRevenue) OVER (ORDER BY SaleYear) AS DECIMAL(5,2)) AS YoYGrowthPercentage
FROM YearlySales
ORDER BY SaleYear;


-- =============================================
-- STEP 8: KEY BUSINESS INSIGHTS QUERIES
-- =============================================

-- 1. Most Profitable Car Models (Revenue vs List Price)
SELECT TOP 10
    c.Brand,
    c.Model,
    COUNT(s.Sale_ID) AS UnitsSold,
    AVG(c.Price) AS AvgListPrice,
    AVG(s.Sale_Price) AS AvgSalePrice,
    SUM(s.Sale_Price) AS TotalRevenue,
    CAST((AVG(s.Sale_Price) - AVG(c.Price)) * 100.0 / AVG(c.Price) AS DECIMAL(5,2)) AS PriceMarkupPercent
FROM Cars c
INNER JOIN Sales s ON c.Car_ID = s.Car_ID
GROUP BY c.Brand, c.Model
ORDER BY TotalRevenue DESC;

-- 2. Customer Retention Analysis
WITH CustomerPurchases AS (
    SELECT 
        Customer_ID,
        YEAR(Sale_Date) AS PurchaseYear,
        COUNT(Sale_ID) AS PurchaseCount
    FROM Sales
    GROUP BY Customer_ID, YEAR(Sale_Date)
)
SELECT 
    PurchaseYear,
    COUNT(DISTINCT Customer_ID) AS UniqueCustomers,
    SUM(PurchaseCount) AS TotalPurchases,
    CAST(SUM(PurchaseCount) * 1.0 / COUNT(DISTINCT Customer_ID) AS DECIMAL(5,2)) AS AvgPurchasesPerCustomer
FROM CustomerPurchases
GROUP BY PurchaseYear
ORDER BY PurchaseYear;

-- 3. Peak Sales Period Analysis
SELECT 
    DATENAME(MONTH, Sale_Date) AS MonthName,
    MONTH(Sale_Date) AS MonthNumber,
    COUNT(Sale_ID) AS TotalSales,
    SUM(Sale_Price) AS TotalRevenue,
    AVG(Sale_Price) AS AvgSalePrice
FROM Sales
GROUP BY DATENAME(MONTH, Sale_Date), MONTH(Sale_Date)
ORDER BY TotalRevenue DESC;

-- 4. Customer Age Group Analysis
SELECT 
    CASE 
        WHEN c.Age < 25 THEN '18-24'
        WHEN c.Age BETWEEN 25 AND 34 THEN '25-34'
        WHEN c.Age BETWEEN 35 AND 44 THEN '35-44'
        WHEN c.Age BETWEEN 45 AND 54 THEN '45-54'
        WHEN c.Age BETWEEN 55 AND 64 THEN '55-64'
        ELSE '65+'
    END AS AgeGroup,
    COUNT(DISTINCT c.Customer_ID) AS CustomerCount,
    COUNT(s.Sale_ID) AS TotalSales,
    SUM(s.Sale_Price) AS TotalRevenue,
    AVG(s.Sale_Price) AS AvgSalePrice
FROM Customers c
INNER JOIN Sales s ON c.Customer_ID = s.Customer_ID
GROUP BY 
    CASE 
        WHEN c.Age < 25 THEN '18-24'
        WHEN c.Age BETWEEN 25 AND 34 THEN '25-34'
        WHEN c.Age BETWEEN 35 AND 44 THEN '35-44'
        WHEN c.Age BETWEEN 45 AND 54 THEN '45-54'
        WHEN c.Age BETWEEN 55 AND 64 THEN '55-64'
        ELSE '65+'
    END
ORDER BY AgeGroup;

