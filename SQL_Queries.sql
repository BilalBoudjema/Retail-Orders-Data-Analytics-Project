-- Compter le nombre total de lignes dans la table des commandes
SELECT COUNT(*) AS total_orders FROM dbo.df_orders;

-- Afficher toutes les lignes de la table des commandes
SELECT * FROM dbo.df_orders;

-- Trouver les 10 produits générant le plus de revenus
SELECT TOP 10 
    product_id AS product_name,
    SUM(sale_price) AS total_sales
FROM dbo.df_orders 
GROUP BY product_id
ORDER BY total_sales DESC;

-- Trouver les 5 produits les plus vendus dans chaque région
WITH sales_cte AS (
    SELECT  
        region, 
        product_id,
        SUM(sale_price) AS total_sales
    FROM dbo.df_orders 
    GROUP BY region, product_id
)
SELECT * 
FROM (
    SELECT 
        *, 
        ROW_NUMBER() OVER (PARTITION BY region ORDER BY total_sales DESC) AS ranked_region_sales
    FROM sales_cte
) AS ranked_sales
WHERE ranked_region_sales <= 5;

-- Comparaison de la croissance des ventes mois par mois entre 2022 et 2023
WITH monthly_sales AS (
    SELECT 
        YEAR(order_date) AS order_year,
        MONTH(order_date) AS order_month,
        SUM(sale_price) AS total_sales
    FROM dbo.df_orders
    GROUP BY YEAR(order_date), MONTH(order_date)
)
SELECT 
    order_month,
    SUM(CASE WHEN order_year = 2022 THEN total_sales ELSE 0 END) AS sales_2022,
    SUM(CASE WHEN order_year = 2023 THEN total_sales ELSE 0 END) AS sales_2023
FROM monthly_sales 
GROUP BY order_month
ORDER BY order_month;

-- Identifier le mois ayant enregistré les ventes les plus élevées pour chaque catégorie
WITH category_sales AS (
    SELECT 
        category,
        FORMAT(order_date, 'yyyyMM') AS order_year_month,
        SUM(sale_price) AS total_sales 
    FROM dbo.df_orders
    GROUP BY category, FORMAT(order_date, 'yyyyMM')
)
SELECT * 
FROM (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY total_sales DESC) AS ranked_sales
    FROM category_sales
) AS ranked_category_sales
WHERE ranked_sales = 1;

-- Trouver les sous-catégories ayant connu la plus forte croissance en termes de profit entre 2022 et 2023
WITH subcategory_sales AS (
    SELECT 
        sub_category,
        YEAR(order_date) AS order_year,
        SUM(sale_price) AS total_sales
    FROM dbo.df_orders
    GROUP BY sub_category, YEAR(order_date)
),
comparison AS (
    SELECT 
        sub_category,
        SUM(CASE WHEN order_year = 2022 THEN total_sales ELSE 0 END) AS sales_2022,
        SUM(CASE WHEN order_year = 2023 THEN total_sales ELSE 0 END) AS sales_2023
    FROM subcategory_sales 
    GROUP BY sub_category
)
SELECT TOP 5 
    *, 
    (sales_2023 - sales_2022) AS growth,
    (sales_2023 - sales_2022) * 100.0 / NULLIF(sales_2022, 0) AS growth_percentage
FROM comparison
ORDER BY growth DESC;
