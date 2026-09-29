CREATE DATABASE CASE_STUDY;

USE CASE_STUDY;

--QUESTION 1 START

SELECT 'NORTH AMERICA' AS REGION,SUM(NA_SALES) AS TOTAL_SALES
FROM video_game_sales
UNION ALL
SELECT 'EUROPE' AS REGION,SUM(EU_SALES) AS TOTAL_SALES
FROM video_game_sales
UNION ALL 
SELECT 'JAPAN' AS REGION,SUM(JP_SALES) AS TOTAL_SALES
FROM video_game_sales
UNION ALL 
SELECT 'OTHER REGION' AS REGION,SUM(OTHER_SALES) AS TOTAL_SALES
FROM video_game_sales;

--QUESTION 1 END

--QUESTION 2 START

WITH RANKED_NA_SALES AS (
SELECT GAME_NAME,NA_SALES,
ROW_NUMBER() OVER(ORDER BY NA_SALES DESC) AS NA_RANK
FROM video_game_sales
),
RANKED_EU_SALES AS(
SELECT GAME_NAME,EU_SALES, ROW_NUMBER() OVER(ORDER BY EU_SALES DESC) AS EU_RANK
FROM video_game_sales
),
RANKED_JP_SALES AS(
SELECT GAME_NAME,JP_SALES, ROW_NUMBER() OVER(ORDER BY JP_SALES DESC) AS JP_RANK
FROM video_game_sales
),
RANKED_OTHER_SALES AS(
SELECT GAME_NAME,OTHER_SALES, ROW_NUMBER() OVER(ORDER BY OTHER_SALES DESC) AS OTHER_RANK
FROM video_game_sales
)

SELECT 'NORTH AMERICA' AS REGION,
GAME_NAME AS TOP_GAME,
NA_SALES AS REGIONAL_SALES FROM RANKED_NA_SALES 
WHERE NA_RANK=1
UNION ALL
SELECT 'EUROPE' AS REGION,GAME_NAME AS TOP_GAME,
EU_SALES AS REGIONAL_SALES FROM RANKED_EU_SALES 
WHERE EU_RANK=1
UNION ALL
SELECT 'JAPAN' AS REGION,GAME_NAME AS TOP_GAME,
JP_SALES AS REGIONAL_SALES FROM RANKED_JP_SALES 
WHERE JP_RANK=1
UNION ALL 
SELECT 'OTHER REGION' AS REGION,GAME_NAME AS TOP_GAME,
OTHER_SALES AS REGIONAL_SALES FROM RANKED_OTHER_SALES 
WHERE OTHER_RANK=1
;

--QUESTION 2 END


--QUESTION 3 START

WITH GlobalTotal AS (
SELECT SUM(NA_Sales + EU_Sales + JP_Sales + Other_Sales) AS Grand_Total
FROM video_game_sales
),
RegionalTotals AS (
SELECT 'North America' AS Region, SUM(NA_Sales) AS Regional_Sales FROM video_game_sales
UNION ALL
SELECT 'Europe' AS Region, SUM(EU_Sales) AS Regional_Sales FROM video_game_sales
UNION ALL
SELECT 'Japan' AS Region, SUM(JP_Sales) AS Regional_Sales FROM video_game_sales
UNION ALL
SELECT 'Other Regions' AS Region, SUM(Other_Sales) AS Regional_Sales FROM video_game_sales
)

SELECT RT.Region,RT.Regional_Sales,
(CAST(RT.Regional_Sales AS FLOAT) / GT.Grand_Total) * 100 AS Percentage_Contribution
FROM RegionalTotals RT
CROSS JOIN  GlobalTotal GT
ORDER BY Percentage_Contribution DESC;

--QUESTION 3 END


--QUESTION 4 START

WITH RegionalAverages AS (
SELECT 'North America' AS Region, 
CAST(SUM(NA_Sales) AS FLOAT) / COUNT(*) AS Avg_Sales_Per_Game
FROM video_game_sales
 
UNION ALL

SELECT 'Europe' AS Region,
CAST(SUM(EU_Sales) AS FLOAT) / COUNT(*) AS Avg_Sales_Per_Game
FROM video_game_sales
    
UNION ALL

SELECT 'Japan' AS Region, 
CAST(SUM(JP_Sales) AS FLOAT) / COUNT(*) AS Avg_Sales_Per_Game
FROM video_game_sales
    
UNION ALL
    
SELECT 'Other Regions' AS Region, 
CAST(SUM(Other_Sales) AS FLOAT) / COUNT(*) AS Avg_Sales_Per_Game
FROM video_game_sales
)

SELECT TOP 1 Region,Avg_Sales_Per_Game
FROM RegionalAverages
ORDER BY Avg_Sales_Per_Game DESC;


--QUESTION 4 END


--QUESTION 5 START

WITH DominantRegion AS (
SELECT TOP 1 Region
FROM
(SELECT 'NA_Sales' AS Region, SUM(NA_Sales) AS TotalSales FROM video_game_sales
UNION ALL
SELECT 'EU_Sales' AS Region, SUM(EU_Sales) AS TotalSales FROM video_game_sales
UNION ALL
SELECT 'JP_Sales' AS Region, SUM(JP_Sales) AS TotalSales FROM video_game_sales
UNION ALL
SELECT 'Other_Sales' AS Region, SUM(Other_Sales) AS TotalSales FROM video_game_sales
) AS RegionalTotals
ORDER BY TotalSales DESC
),
MonthlySales AS (
SELECT YEAR(vg.[Publish_Year]) AS Sales_Year,MONTH(vg.[Publish_Year]) AS Sales_Month,
CASE dr.Region
WHEN 'NA_Sales' THEN vg.NA_Sales
WHEN 'EU_Sales' THEN vg.EU_Sales
WHEN 'JP_Sales' THEN vg.JP_Sales
WHEN 'Other_Sales' THEN vg.Other_Sales
END AS Dominant_Regional_Sales
FROM video_game_sales vg
CROSS JOIN DominantRegion dr
WHERE
CASE dr.Region
WHEN 'NA_Sales' THEN vg.NA_Sales
WHEN 'EU_Sales' THEN vg.EU_Sales
WHEN 'JP_Sales' THEN vg.JP_Sales
WHEN 'Other_Sales' THEN vg.Other_Sales
 END IS NOT NULL
),
AggregatedSales AS (
SELECT Sales_Year,Sales_Month,SUM(Dominant_Regional_Sales) AS Current_Monthly_Sales
FROM MonthlySales  
GROUP BY Sales_Year, Sales_Month
),
MoM_Growth AS (
SELECT Sales_Year,Sales_Month,Current_Monthly_Sales,LAG(Current_Monthly_Sales, 1, 0)OVER (ORDER BY Sales_Year ASC, Sales_Month ASC) AS Previous_Monthly_Sales
FROM AggregatedSales
)
SELECT Sales_Year,Sales_Month,Current_Monthly_Sales,Previous_Monthly_Sales,
CASE
WHEN Previous_Monthly_Sales = 0 THEN 0
ELSE ( (Current_Monthly_Sales - Previous_Monthly_Sales) / CAST(Previous_Monthly_Sales AS FLOAT) ) * 100
END AS MoM_Growth_Percentage
FROM MoM_Growth
ORDER BY Sales_Year, Sales_Month;


--QUESTION 5 END


--QUESTION 6 START

WITH SalesByYear AS (
SELECT [Publish_Year] AS Sales_Year,
SUM(NA_Sales) AS NA_Total,
SUM(EU_Sales) AS EU_Total,
SUM(JP_Sales) AS JP_Total,
SUM(Other_Sales) AS Other_Total
FROM video_game_sales
GROUP BY [Publish_Year]
HAVING [Publish_Year] IS NOT NULL
),
YoY_Change AS (
SELECT Sales_Year,
(NA_Total - LAG(NA_Total, 1) OVER (ORDER BY Sales_Year)) / NULLIF(LAG(NA_Total, 1) OVER (ORDER BY Sales_Year), 0) * 100 AS NA_YoY_Pct_Change,
(EU_Total - LAG(EU_Total, 1) OVER (ORDER BY Sales_Year)) / NULLIF(LAG(EU_Total, 1) OVER (ORDER BY Sales_Year), 0) * 100 AS EU_YoY_Pct_Change,
(JP_Total - LAG(JP_Total, 1) OVER (ORDER BY Sales_Year)) / NULLIF(LAG(JP_Total, 1) OVER (ORDER BY Sales_Year), 0) * 100 AS JP_YoY_Pct_Change,
(Other_Total - LAG(Other_Total, 1) OVER (ORDER BY Sales_Year)) / NULLIF(LAG(Other_Total, 1) OVER (ORDER BY Sales_Year), 0) * 100 AS Other_YoY_Pct_Change
FROM SalesByYear
),
Volatility AS (
SELECT 'North America' AS Region, AVG(ABS(NA_YoY_Pct_Change)) AS Avg_Abs_YoY_Change FROM YoY_Change WHERE NA_YoY_Pct_Change IS NOT NULL
UNION ALL
SELECT 'Europe' AS Region, AVG(ABS(EU_YoY_Pct_Change)) AS Avg_Abs_YoY_Change FROM YoY_Change WHERE EU_YoY_Pct_Change IS NOT NULL
UNION ALL
SELECT 'Japan' AS Region, AVG(ABS(JP_YoY_Pct_Change)) AS Avg_Abs_YoY_Change FROM YoY_Change WHERE JP_YoY_Pct_Change IS NOT NULL
UNION ALL
SELECT 'Other Regions' AS Region, AVG(ABS(Other_YoY_Pct_Change)) AS Avg_Abs_YoY_Change FROM YoY_Change WHERE Other_YoY_Pct_Change IS NOT NULL
)
SELECT TOP 1
Region,
Avg_Abs_YoY_Change AS Sales_Volatility_Score
FROM Volatility
ORDER BY Avg_Abs_YoY_Change DESC;


--QUESTION 6 END    