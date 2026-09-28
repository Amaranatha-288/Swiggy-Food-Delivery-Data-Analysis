SELECT * FROM Swiggy_Data
-- Data Validation & Cleaning 
--Null Check
SELECT
    SUM(CASE WHEN State IS NULL THEN 1 ELSE 0 END) AS null_state,
    SUM(CASE WHEN City IS NULL THEN 1 ELSE 0 END) AS null_state,
    SUM(CASE WHEN Order_Date IS NULL THEN 1 ELSE 0 END) AS null_order_date,
    SUM(CASE WHEN  Restaurant_Name IS NULL THEN 1 ELSE 0 END) AS null_state,
    SUM(CASE WHEN Location IS NULL THEN 1 ELSE 0 END) AS null_locatoin,
    SUM(CASE WHEN Category IS NULL THEN 1 ELSE 0 END) AS null_Category,
    SUM(CASE WHEN Dish_Name IS NULL THEN 1 ELSE 0 END) AS null_dish,
    SUM(CASE WHEN Price_INR IS NULL THEN 1 ELSE 0 END) AS null_price,
    SUM(CASE WHEN Rating IS NULL THEN 1 ELSE 0 END) AS null_rating,
    SUM(CASE WHEN Rating_Count IS NULL THEN 1 ELSE 0 END) AS null_rating_count
FROM Swiggy_data;

-- Blank or Empty Strigs
SELECT * 
FROM Swiggy_Data
WHERE 
State = '' OR City='' OR Restaurant_Name = '' OR Location='' OR Category = '' OR Dish_Name =''


--Duplicate Detection or Removel 
SELECT
State,City,order_date,Restaurant_Name,location,Category,Dish_Name,Price_INR,rating,Rating_Count,
COUNT(*) AS CNT
FROM Swiggy_Data
GROUP BY State,City,order_date,Restaurant_Name,location,Category,Dish_Name,Price_INR,rating,Rating_Count
Having COUNT(*) > 1

--Delete Duplication  or Removel duplicate
WITH CTE AS (
SELECT *,ROW_NUMBER() OVER(
PARTITION BY State,City,order_date,Restaurant_Name,location,Category,Dish_Name,Price_INR,rating,Rating_Count
ORDER BY (SELECT NULL)
) AS rn
FROM Swiggy_Data
)

DELETE FROM CTE WHERE rn>1



-- CREATING SCHEMA
-- DIMENSION TABLES
-- DATE TABLE
CREATE TABLE dim_date(
  date_id INT IDENTITY(1,1) PRIMARY KEY,
  Full_Date DATE,
  Year INT,
  MONTH INT,
  Month_Name VARCHAR(20),
  Quarter INT,
  Day INT,
  Week INT
  )
  DROP TABLE dim_date
--dim_location
CREATE TABLE dim_location (
    location_id INT IDENTITY(1,1) PRIMARY KEY,
    State VARCHAR(100),
    City VARCHAR(100),
    Location VARCHAR(200)
);

    
-- dim_restaurant
CREATE TABLE dim_restaurant (
    restaurant_id INT IDENTITY(1,1) PRIMARY KEY,
    Restaurant_Name VARCHAR(200)
);
-- dim_category
CREATE TABLE dim_category (
    category_id INT IDENTITY(1,1) PRIMARY KEY,
    Category_Name VARCHAR(200)
);

-- dim_dish
CREATE TABLE dim_dish(
   dish_id INT IDENTITY(1,1) PRIMARY KEY,
   Dish_Name VARCHAR(200)
);

-- CRETAE FACT TABLE
CREATE TABLE fact_swiggy_orders(
    order_id INT IDENTITY (1,1) PRIMARY KEY,

    date_id INT,
    Price_INR DECIMAL(10,2),
    Rating DECIMAL (4,2),
    Rating_Count INT,

    location_id INT,
    restaurant_id INT,
    category_id INT,
    dish_id INt,

   FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
   FOREIGN KEY (location_id) REFERENCES dim_location(location_id),
   FOREIGN KEY (restaurant_id) REFERENCES dim_restaurant(restaurant_id),
   FOREIGN KEY (category_id) REFERENCES dim_category(category_id),
   FOREIGN KEY (dish_id) REFERENCES dim_dish(dish_id)
   );

   --INSERT THE DATA TO THE ALL THE TABLES
   --dim_data
   INSERT INTO dim_date (Full_Date,Year,Month_Name,Quarter,Day,Week)
   SELECT DISTINCT 
        order_date,
        YEAR(Order_Date),
        DATENAME(MONTH,Order_Date),
        DATEPART(QUARTER,Order_Date),
        DAY(Order_Date),
        DATEPART(WEEK,Order_Date)
 FROM swiggy_data
 WHERE Order_Date IS NOT NULL; 
 
 SELECT * FROM dim_date

 -- dim_location
 INSERT INTO dim_location (State,City,Location)
 SELECT DISTINCT
        State,
        City,
        Location
FROM swiggy_data;


-- dim_restaurant
INSERT INTO dim_restaurant(Restaurant_Name)
SELECT DISTINCT
    Restaurant_Name
FROM Swiggy_Data;

-- dim_category
INSERT INTO dim_category(Category_Name)
SELECT DISTINCT
       Category
FROM swiggy_data;

--dim_dish
INSERT INTO dim_dish(Dish_Name)
SELECT DISTINCT
    Dish_Name
FROM swiggy_data;

-- Fact table

INSERT INTO fact_swiggy_orders
(
    date_id,
    Price_INR,
    Rating,
    Rating_Count,
    location_id,
    restaurant_id,
    category_id,
    dish_id
)
SELECT
    dd.date_id,
    s.Price_INR,
    s.Rating,
    s.Rating_Count,
    dl.location_id,
    dr.restaurant_id,
    dc.category_id,
    dsh.dish_id

FROM swiggy_data s

JOIN dim_date dd
    ON dd.Full_Date = s.Order_Date

JOIN dim_location dl
    ON dl.State = s.State
    AND dl.City = s.City
    AND dl.Location = s.Location

JOIN dim_restaurant dr
    ON dr.Restaurant_Name = s.Restaurant_Name

JOIN dim_category dc
    ON dc.Category_Name = s.Category

JOIN dim_dish dsh
    ON dsh.Dish_Name = s.Dish_Name;

-- data in all combine version

SELECT * FROM fact_swiggy_orders f
JOIN dim_date d
    ON f.date_id = d.date_id
JOIN dim_location l
    ON f.location_id = l.location_id
JOIN dim_restaurant r
    ON f.restaurant_id = r.restaurant_id
JOIN dim_category c
    ON f.category_id = c.category_id
JOIN dim_dish dl
    ON f.dish_id = dl.dish_id;


-- KPI's
-- Total Orders
SELECT COUNT(*) AS Total_Orders
FROM fact_swiggy_orders

-- Total Revenue (INR Million)
SELECT FORMAT(SUM(CONVERT(FLOAT ,price_INR))/1000000,'N2') + ' INR Million' AS Toatal_Revenue
FROM fact_swiggy_orders

--Average Dish Price
SELECT FORMAT(AVG(CONVERT(FLOAT ,price_INR)),'N2') + ' INR ' AS Toatal_Revenue
FROM fact_swiggy_orders

--Average Rating
SELECT
AVG(Rating) AS Avg_Raing
FROM fact_swiggy_orders

-- Deep-Dive Busines Analysis

-- Monthly Order Trends
SELECT 
d.Year,
d.month_name,
COUNT(*) AS Total_orders
FROM fact_swiggy_orders f
JOIN dim_date d
ON f.date_id = d.date_id
GROUP BY d.Year,
d.month_name 
ORDER BY COUNT(*)  DESC


-- Monthly Total_Revenue
SELECT 
d.Year,
d.month_name,
 FORMAT(SUM(CONVERT(FLOAT ,price_INR))/1000000,'N2')+ ' INR Million' AS Total_orders
FROM fact_swiggy_orders f
JOIN dim_date d
ON f.date_id = d.date_id
GROUP BY d.Year,
d.month_name 
ORDER BY Total_orders DESC

-- Quaterly Trend
SELECT 
d.Year,
d.quarter,
COUNT(*) AS Total_orders
FROM fact_swiggy_orders f
JOIN dim_date d
ON f.date_id = d.date_id
GROUP BY d.Year, 
d.quarter
ORDER BY COUNT(*)  DESC

-- Yearly Trend
SELECT 
d.Year,
COUNT(*) AS Total_orders
FROM fact_swiggy_orders f
JOIN dim_date d
ON f.date_id = d.date_id
GROUP BY d.Year
ORDER BY COUNT(*)  DESC

-- Orders by Day of Week (mon-Sun)
SELECT
    DATENAME(WEEKDAY, d.full_date) AS day_name,
    COUNT(*) AS total_orders
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY
    DATENAME(WEEKDAY, d.full_date),
    DATEPART(WEEKDAY, d.full_date)
ORDER BY
    DATEPART(WEEKDAY, d.full_date) DESC;

-- Loction Based Analysis

-- Top 10 cities by order volume
SELECT TOP 10
l.City,
COUNT(*) AS Total_Orders 
FROM fact_swiggy_orders f
JOIN dim_location l
ON l.location_id = f.location_id
GROUP BY l.City
ORDER BY COUNT(*) DESC

-- Revenue contribution by states
SELECT TOP 10
l.State,
SUM(f.price_INR) AS Total_Revenue
FROM fact_swiggy_orders f
JOIN dim_location l
ON l.location_id = f.location_id
GROUP BY l.State
ORDER BY SUM(f.price_INR) DESC

-- Food Perforemence

-- Top 10 restaurants by orders
SELECT TOP 10
r.restaurant_name,
COUNT(*) AS Total_Orders
FROM fact_swiggy_orders f
JOIN  dim_restaurant r
ON r.restaurant_id = f.restaurant_id
GROUP BY r.restaurant_name
ORDER BY COUNT(*) DESC

-- Top Category by Order Volume
SELECT
   c.Category_Name,
   COUNT(*) AS total_orders
FROM fact_swiggy_orders f
JOIN dim_category c 
ON f.category_id = c.category_id
GROUP BY c.Category_Name
ORDER BY total_orders DESC;

-- Most Orderd dish
SELECT TOP 10
d.Dish_Name,
COUNT(*) AS Order_Count
FROM fact_swiggy_orders f
JOIN dim_dish d
ON d.dish_id = f.dish_id
GROUP BY d.Dish_Name
ORDER BY  Order_Count  DESC

-- Cuisine Performance (Orders + Avg Rating)
SELECT
    c.Category_Name,
    COUNT(*) AS total_orders,
    AVG(f.rating) AS avg_rating
FROM fact_swiggy_orders f
JOIN dim_category c ON f.category_id = c.category_id
GROUP BY c.Category_Name
ORDER BY total_orders DESC;

-- Total Orders by Price Range
SELECT
    CASE
        WHEN CONVERT(FLOAT, price_inr) < 100 THEN 'Under 100'
        WHEN CONVERT(FLOAT, price_inr) BETWEEN 100 AND 199 THEN '100 - 199'
        WHEN CONVERT(FLOAT, price_inr) BETWEEN 200 AND 299 THEN '200 - 299'
        WHEN CONVERT(FLOAT, price_inr) BETWEEN 300 AND 499 THEN '300 - 499'
        ELSE '500+'
    END AS price_range,
    COUNT(*) AS total_orders
FROM fact_swiggy_orders
GROUP BY
    CASE
        WHEN CONVERT(FLOAT, price_inr) < 100 THEN 'Under 100'
        WHEN CONVERT(FLOAT, price_inr) BETWEEN 100 AND 199 THEN '100 - 199'
        WHEN CONVERT(FLOAT, price_inr) BETWEEN 200 AND 299 THEN '200 - 299'
        WHEN CONVERT(FLOAT, price_inr) BETWEEN 300 AND 499 THEN '300 - 499'
        ELSE '500+'
    END
ORDER BY total_orders DESC;


--Rating Count Disribution
SELECT TOP 10
   rating,
   COUNT(*) AS rating_count
FROM fact_swiggy_orders
GROUP BY rating
ORDER BY COUNT(*) DESC;
