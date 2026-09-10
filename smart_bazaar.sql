-- Total sales and average sales per item for each Item_Type
CREATE DATABASE smart_bazaar;
USE smart_bazaar;
SHOW TABLES;
DESCRIBE smart_bazaar;

-- DATA CLEANING / COLUMN RENAMING
ALTER TABLE smart_bazaar
RENAME COLUMN `Item Fat Content` TO Item_Fat_Content,
RENAME COLUMN `Item Identifier` TO Item_Identifier,
RENAME COLUMN `Item Type` TO Item_Type,
RENAME COLUMN `Outlet Establishment Year` TO Outlet_Establishment_Year,
RENAME COLUMN `Outlet Identifier` TO Outlet_Identifier,
RENAME COLUMN `Outlet Location Type` TO Outlet_Location_Type,
RENAME COLUMN `Outlet Size` TO Outlet_Size,
RENAME COLUMN `Outlet Type` TO Outlet_Type,
RENAME COLUMN `Item Visibility` TO Item_Visibility,
RENAME COLUMN `Item Weight` TO Item_Weight,
RENAME COLUMN `Total Sales` TO Total_Sales;

DESCRIBE smart_bazaar;

-- Total and average sales by Item Type
SELECT
    Item_Type,
    SUM(Total_Sales) AS total_sales,
    AVG(Total_Sales) AS avg_sales
FROM smart_bazaar
GROUP BY Item_Type
ORDER BY total_sales DESC;

-- Total item weight by Outlet Location Type
SELECT
    Outlet_Location_Type,
    SUM(Item_Weight) AS total_weight
FROM smart_bazaar
GROUP BY Outlet_Location_Type
ORDER BY total_weight DESC;

-- Minimum, maximum, and average sales by Outlet Type
SELECT 
    Outlet_Type,
    MIN(Total_Sales) AS min_sale,
    MAX(Total_Sales) AS max_sale,
    AVG(Total_Sales) AS avg_sale
FROM smart_bazaar
GROUP BY Outlet_Type
ORDER BY avg_sale DESC;

-- Top 5 outlets by total sales
SELECT
  Outlet_Identifier,      
  SUM(total_Sales) AS total_revenue
FROM smart_bazaar
GROUP BY Outlet_Identifier
ORDER BY total_revenue DESC
LIMIT 5;

-- Percentage contribution of each Item_Type to total sales
SELECT Item_Type,
  SUM(total_Sales) AS total_sales,
  ROUND(100.0 * SUM(total_Sales) / SUM(SUM(total_Sales)) OVER (), 2) AS pct_of_sale
FROM smart_bazaar
GROUP BY Item_Type
ORDER BY total_sales DESC;

-- Records where Item_Visibility > average visibility
SELECT *
FROM smart_bazaar
WHERE Item_Visibility > (SELECT AVG(Item_Visibility) FROM smart_bazaar);

-- Products available across multiple outlet types
select item_identifier , COUNT(DISTINCT Outlet_Type) AS outlet_type_count
from smart_bazaar 
group by item_identifier
HAVING COUNT(DISTINCT Outlet_Type) > 1
ORDER BY outlet_type_count DESC
LIMIT 10;

-- Rank products by sales within each Outlet Type
SELECT
    Outlet_Type,
    Item_Identifier,
    Item_Type,
    total_sales,
    RANK() OVER (
        PARTITION BY Outlet_Type
        ORDER BY total_sales DESC
    ) AS sales_rank
FROM (
    SELECT
        Outlet_Type,
        Item_Identifier,
        Item_Type,
        SUM(Total_Sales) AS total_sales
    FROM smart_bazaar
    GROUP BY
        Outlet_Type,
        Item_Identifier,
        Item_Type
) AS s
ORDER BY Outlet_Type, sales_rank;

-- Analyze sales and ratings by fat content and item type for outlets established in 2000
SELECT 
    Item_Fat_Content,
    Item_Type,
    ROUND(SUM(Total_Sales), 2) AS total_sales,
    ROUND(AVG(Total_Sales), 2) AS avg_sales,
    COUNT(*) AS record_count,
    ROUND(AVG(Rating), 2) AS avg_rating
FROM smart_bazaar
WHERE Outlet_Establishment_Year = 2000
GROUP BY Item_Fat_Content, Item_Type
ORDER BY total_sales DESC;

-- Item types with sales above the average item-type sales
WITH type_sales AS (
    SELECT
        Item_Type,
        SUM(Total_Sales) AS item_type_sales
    FROM smart_bazaar
    GROUP BY Item_Type
)
SELECT *
FROM type_sales
WHERE item_type_sales > (
    SELECT AVG(item_type_sales)
    FROM type_sales
)
ORDER BY item_type_sales DESC;

-- Item_Types that contribute > 10% of total sales
WITH type_sales AS (
    SELECT
        Item_Type,
        SUM(Total_Sales) AS sales,
        SUM(Total_Sales) * 100.0 
        / SUM(SUM(Total_Sales)) OVER () AS pct_of_total
    FROM smart_bazaar
    GROUP BY Item_Type
)
SELECT *
FROM type_sales
WHERE pct_of_total > 10
ORDER BY pct_of_total DESC;

-- Top 2 performing products within each outlet
WITH product_sales AS (
    SELECT
        Outlet_Identifier,
        Outlet_Size,
        Outlet_Type,
        Item_Identifier,
        Item_Type,
        Item_Fat_Content,
        SUM(Total_Sales) AS sales
    FROM smart_bazaar
    GROUP BY
        Outlet_Identifier,
        Outlet_Size,
        Outlet_Type,
        Item_Identifier,
        Item_Type,
        Item_Fat_Content
),
ranked_products AS (
    SELECT *,
        DENSE_RANK() OVER (
            PARTITION BY Outlet_Identifier
            ORDER BY sales DESC
        ) AS sale_rank
    FROM product_sales
)
SELECT *
FROM ranked_products
WHERE sale_rank <= 2
ORDER BY Outlet_Identifier, sale_rank;

-- Item types with the highest number of 5-star ratings
SELECT
    Item_Type,
    COUNT(*) AS five_star_count
FROM smart_bazaar
WHERE Rating = 5
GROUP BY Item_Type
ORDER BY five_star_count DESC;
