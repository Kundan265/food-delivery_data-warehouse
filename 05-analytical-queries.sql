-- ===================================
-- ANALYTICAL QUERIES
-- Business Intelligence Queries
-- ===================================

-- ===== QUERY 1: Revenue Analysis by Restaurant and Month =====
SELECT 
    r.restaurant_name,
    d.year,
    d.month,
    d.month_name,
    COUNT(DISTINCT f.order_id) as total_orders,
    SUM(f.quantity) as total_items_sold,
    ROUND(SUM(f.order_total)::NUMERIC, 2) as total_revenue,
    ROUND(AVG(f.unit_price)::NUMERIC, 2) as avg_item_price,
    ROUND(AVG(f.rating)::NUMERIC, 2) as avg_customer_rating
FROM warehouse.fact_orders f
JOIN warehouse.dim_restaurant r ON f.restaurant_sk = r.restaurant_sk
JOIN warehouse.dim_date d ON f.date_sk = d.date_sk
GROUP BY r.restaurant_name, d.year, d.month, d.month_name
ORDER BY d.year DESC, d.month DESC, total_revenue DESC;

-- ===== QUERY 2: Customer Segmentation Analysis =====
SELECT 
    c.city,
    c.age_category,
    c.churn_status,
    COUNT(DISTINCT c.customer_sk) as num_customers,
    ROUND(AVG(c.current_loyalty_points)::NUMERIC, 2) as avg_loyalty_points,
    ROUND(SUM(f.order_total)::NUMERIC, 2) as total_spent,
    ROUND(AVG(f.order_total)::NUMERIC, 2) as avg_order_value,
    COUNT(f.order_id) as total_orders,
    ROUND(AVG(f.rating)::NUMERIC, 2) as avg_rating,
    ROUND((COUNT(f.order_id) * 100.0 / SUM(COUNT(f.order_id)) OVER ())::NUMERIC, 2) as pct_of_orders
FROM warehouse.dim_customer c
LEFT JOIN warehouse.fact_orders f ON c.customer_sk = f.customer_sk
GROUP BY c.city, c.age_category, c.churn_status
ORDER BY total_spent DESC NULLS LAST;

-- ===== QUERY 3: Top Products by Revenue =====
SELECT 
    r.restaurant_name,
    p.dish_name,
    p.category,
    COUNT(f.order_id) as times_ordered,
    SUM(f.quantity) as total_quantity,
    ROUND(SUM(f.order_total)::NUMERIC, 2) as total_revenue,
    ROUND(AVG(f.quantity)::NUMERIC, 2) as avg_qty_per_order,
    ROUND(AVG(f.rating)::NUMERIC, 2) as avg_rating,
    ROUND((COUNT(f.order_id) * 100.0 / SUM(COUNT(f.order_id)) OVER ())::NUMERIC, 2) as pct_of_orders
FROM warehouse.fact_orders f
JOIN warehouse.dim_product p ON f.product_sk = p.product_sk
JOIN warehouse.dim_restaurant r ON f.restaurant_sk = r.restaurant_sk
GROUP BY r.restaurant_name, p.dish_name, p.category
ORDER BY times_ordered DESC;

-- ===== QUERY 4: Payment Method Analysis =====
SELECT 
    pm.payment_method,
    pm.payment_category,
    COUNT(f.order_id) as num_transactions,
    ROUND(SUM(f.order_total)::NUMERIC, 2) as total_value,
    ROUND(AVG(f.order_total)::NUMERIC, 2) as avg_order_value,
    ROUND((COUNT(f.order_id) * 100.0 / SUM(COUNT(f.order_id)) OVER ())::NUMERIC, 2) as pct_usage,
    ROUND(AVG(f.rating)::NUMERIC, 2) as avg_rating
FROM warehouse.fact_orders f
JOIN warehouse.dim_payment_method pm ON f.payment_sk = pm.payment_sk
GROUP BY pm.payment_method, pm.payment_category
ORDER BY num_transactions DESC;

-- ===== QUERY 5: Delivery Status Impact Analysis =====
SELECT 
    ds.delivery_status,
    COUNT(f.order_id) as total_orders,
    ROUND(AVG(f.rating)::NUMERIC, 2) as avg_rating,
    ROUND((COUNT(f.order_id) * 100.0 / SUM(COUNT(f.order_id)) OVER ())::NUMERIC, 2) as pct_of_orders,
    COUNT(CASE WHEN f.rating >= 4 THEN 1 END) as high_ratings,
    COUNT(CASE WHEN f.rating <= 2 THEN 1 END) as low_ratings,
    ROUND((COUNT(CASE WHEN f.rating >= 4 THEN 1 END) * 100.0 / COUNT(f.order_id))::NUMERIC, 2) as pct_high_ratings
FROM warehouse.fact_orders f
JOIN warehouse.dim_delivery_status ds ON f.delivery_sk = ds.delivery_sk
GROUP BY ds.delivery_status
ORDER BY total_orders DESC;

-- ===== QUERY 6: Customer Lifetime Value (CLV) =====
SELECT 
    c.customer_id,
    c.city,
    c.age_category,
    COUNT(f.order_id) as total_orders,
    ROUND(SUM(f.order_total)::NUMERIC, 2) as total_spent,
    ROUND(AVG(f.order_total)::NUMERIC, 2) as avg_order_value,
    MIN(d.calendar_date) as first_order_date,
    MAX(d.calendar_date) as last_order_date,
    (MAX(d.calendar_date) - MIN(d.calendar_date)) as days_as_customer,
    ROUND(AVG(f.rating)::NUMERIC, 2) as avg_rating,
    c.current_loyalty_points,
    c.churn_status
FROM warehouse.dim_customer c
JOIN warehouse.fact_orders f ON c.customer_sk = f.customer_sk
JOIN warehouse.dim_date d ON f.date_sk = d.date_sk
GROUP BY c.customer_id, c.city, c.age_category, c.current_loyalty_points, c.churn_status
ORDER BY total_spent DESC;

-- ===== QUERY 7: Day of Week Analysis =====
SELECT 
    d.day_name,
    COUNT(f.order_id) as total_orders,
    ROUND(SUM(f.order_total)::NUMERIC, 2) as total_revenue,
    ROUND(AVG(f.order_total)::NUMERIC, 2) as avg_order_value,
    COUNT(DISTINCT c.customer_sk) as unique_customers,
    ROUND(AVG(f.rating)::NUMERIC, 2) as avg_rating,
    CASE WHEN d.is_weekend THEN 'Weekend' ELSE 'Weekday' END as day_type
FROM warehouse.fact_orders f
JOIN warehouse.dim_date d ON f.date_sk = d.date_sk
JOIN warehouse.dim_customer c ON f.customer_sk = c.customer_sk
GROUP BY d.day_name, d.is_weekend, d.day_of_week
ORDER BY d.day_of_week;

-- ===== QUERY 8: Churn Analysis =====
SELECT 
    c.churn_status,
    COUNT(DISTINCT c.customer_sk) as num_customers,
    COUNT(f.order_id) as total_orders,
    ROUND(SUM(f.order_total)::NUMERIC, 2) as total_revenue,
    ROUND(AVG(c.current_loyalty_points)::NUMERIC, 2) as avg_loyalty_points,
    ROUND(AVG(f.rating)::NUMERIC, 2) as avg_rating,
    COUNT(CASE WHEN f.rating <= 2 THEN 1 END) as low_ratings_count,
    ROUND((COUNT(CASE WHEN f.rating <= 2 THEN 1 END) * 100.0 / COUNT(f.order_id))::NUMERIC, 2) as pct_low_ratings
FROM warehouse.dim_customer c
LEFT JOIN warehouse.fact_orders f ON c.customer_sk = f.customer_sk
GROUP BY c.churn_status
ORDER BY num_customers DESC;

-- ===== QUERY 9: Top Cities by Revenue =====
SELECT 
    c.city,
    COUNT(DISTINCT c.customer_sk) as num_customers,
    COUNT(f.order_id) as total_orders,
    ROUND(SUM(f.order_total)::NUMERIC, 2) as total_revenue,
    ROUND(AVG(f.order_total)::NUMERIC, 2) as avg_order_value,
    ROUND(AVG(f.rating)::NUMERIC, 2) as avg_rating,
    ROUND((COUNT(f.order_id) * 100.0 / SUM(COUNT(f.order_id)) OVER ())::NUMERIC, 2) as pct_of_orders
FROM warehouse.dim_customer c
LEFT JOIN warehouse.fact_orders f ON c.customer_sk = f.customer_sk
GROUP BY c.city
ORDER BY total_revenue DESC;

-- ===== QUERY 10: Rating Distribution Analysis =====
SELECT 
    f.rating,
    COUNT(f.order_id) as num_orders,
    ROUND((COUNT(f.order_id) * 100.0 / SUM(COUNT(f.order_id)) OVER ())::NUMERIC, 2) as pct,
    COUNT(DISTINCT f.customer_sk) as unique_customers,
    ROUND(AVG(f.order_total)::NUMERIC, 2) as avg_order_value,
    COUNT(DISTINCT f.restaurant_sk) as restaurants_rated
FROM warehouse.fact_orders f
WHERE f.rating IS NOT NULL
GROUP BY f.rating
ORDER BY f.rating DESC;
