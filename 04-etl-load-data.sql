-- ===================================
-- ETL - POPULATE DIMENSIONS & FACTS
-- ===================================

-- Step 1: Populate dim_product with unique dish-restaurant combinations
INSERT INTO warehouse.dim_product (dish_name, category, restaurant_sk)
SELECT DISTINCT 
    s.dish_name,
    s.category,
    r.restaurant_sk
FROM staging.stg_orders s
JOIN warehouse.dim_restaurant r ON s.restaurant_name = r.restaurant_name
WHERE s.dish_name IS NOT NULL
ON CONFLICT (dish_name, restaurant_sk) DO NOTHING;

-- Step 2: Populate dim_customer (SCD Type 1 - slowly changing dimension)
INSERT INTO warehouse.dim_customer (
    customer_id, gender, age_category, city, 
    current_loyalty_points, churn_status, effective_date
)
SELECT DISTINCT 
    s.customer_id,
    s.gender,
    s.age_category,
    s.city,
    s.loyalty_points,
    s.churned,
    CURRENT_DATE
FROM staging.stg_orders s
ON CONFLICT (customer_id) DO UPDATE SET
    gender = EXCLUDED.gender,
    age_category = EXCLUDED.age_category,
    city = EXCLUDED.city,
    current_loyalty_points = EXCLUDED.current_loyalty_points,
    churn_status = EXCLUDED.churn_status,
    updated_at = CURRENT_TIMESTAMP;

-- Verify dimension loads
SELECT 'Customers' as entity, COUNT(*) as count FROM warehouse.dim_customer
UNION ALL
SELECT 'Restaurants', COUNT(*) FROM warehouse.dim_restaurant
UNION ALL
SELECT 'Products', COUNT(*) FROM warehouse.dim_product
UNION ALL
SELECT 'Dates', COUNT(*) FROM warehouse.dim_date
UNION ALL
SELECT 'Payments', COUNT(*) FROM warehouse.dim_payment_method
UNION ALL
SELECT 'Delivery Status', COUNT(*) FROM warehouse.dim_delivery_status;

-- Step 3: Populate fact_orders
INSERT INTO warehouse.fact_orders (
    order_id, customer_sk, restaurant_sk, product_sk, 
    date_sk, payment_sk, delivery_sk, 
    quantity, unit_price, order_total, 
    rating, order_frequency, loyalty_points_earned
)
SELECT 
    s.order_id,
    c.customer_sk,
    r.restaurant_sk,
    p.product_sk,
    TO_CHAR(TO_DATE(s.order_date, 'MM/DD/YY'), 'YYYYMMDD')::INT as date_sk,
    pm.payment_sk,
    ds.delivery_sk,
    s.quantity,
    s.price,
    ROUND((s.quantity * s.price)::NUMERIC, 2),
    s.rating,
    s.order_frequency,
    s.loyalty_points
FROM staging.stg_orders s
JOIN warehouse.dim_customer c ON s.customer_id = c.customer_id
JOIN warehouse.dim_restaurant r ON s.restaurant_name = r.restaurant_name
JOIN warehouse.dim_product p ON s.dish_name = p.dish_name 
    AND r.restaurant_sk = p.restaurant_sk
JOIN warehouse.dim_payment_method pm ON s.payment_method = pm.payment_method
JOIN warehouse.dim_delivery_status ds ON s.delivery_status = ds.delivery_status
WHERE s.order_id IS NOT NULL;

-- Verify fact table load
SELECT 
    COUNT(*) as total_orders,
    COUNT(DISTINCT customer_sk) as unique_customers,
    COUNT(DISTINCT restaurant_sk) as unique_restaurants,
    ROUND(SUM(order_total)::NUMERIC, 2) as total_revenue,
    ROUND(AVG(rating)::NUMERIC, 2) as avg_rating
FROM warehouse.fact_orders;

-- Data quality checks after load
SELECT 'Referential integrity - customers' as check_type,
    COUNT(*) as issues
FROM warehouse.fact_orders f
WHERE NOT EXISTS (
    SELECT 1 FROM warehouse.dim_customer c 
    WHERE f.customer_sk = c.customer_sk
)
UNION ALL
SELECT 'Referential integrity - dates', COUNT(*)
FROM warehouse.fact_orders f
WHERE NOT EXISTS (
    SELECT 1 FROM warehouse.dim_date d 
    WHERE f.date_sk = d.date_sk
)
UNION ALL
SELECT 'Missing order totals', COUNT(*)
FROM warehouse.fact_orders
WHERE order_total IS NULL OR order_total = 0
UNION ALL
SELECT 'Invalid ratings', COUNT(*)
FROM warehouse.fact_orders
WHERE rating < 1 OR rating > 5;
