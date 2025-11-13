CREATE SCHEMA IF NOT EXISTS staging;

CREATE TABLE IF NOT EXISTS staging.stg_orders (
    customer_id VARCHAR(50),
    gender VARCHAR(20),
    age_category VARCHAR(50),
    city VARCHAR(100),
    order_id VARCHAR(50),
    order_date VARCHAR(20),
    restaurant_name VARCHAR(100),
    dish_name VARCHAR(100),
    category VARCHAR(50),
    quantity INT,
    price DECIMAL(10, 2),
    payment_method VARCHAR(50),
    order_frequency INT,
    last_order_date VARCHAR(20),
    loyalty_points INT,
    churned VARCHAR(20),
    rating INT,
    rating_date VARCHAR(20),
    delivery_status VARCHAR(50),
    loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    row_hash VARCHAR(32)  -- duplicate detector
);

CREATE INDEX idx_stg_customer_id ON staging.stg_orders(customer_id);
CREATE INDEX idx_stg_order_id ON staging.stg_orders(order_id);
CREATE INDEX idx_stg_restaurant ON staging.stg_orders(restaurant_name);


CREATE OR REPLACE VIEW staging.v_data_quality AS
SELECT 
    'Null customer_id' as issue_type,
    COUNT(*) as row_count
FROM staging.stg_orders
WHERE customer_id IS NULL
UNION ALL
SELECT 'Null order_id', COUNT(*)
FROM staging.stg_orders
WHERE order_id IS NULL
UNION ALL
SELECT 'Duplicate orders', COUNT(*) - COUNT(DISTINCT order_id)
FROM staging.stg_orders
UNION ALL
SELECT 'Invalid dates', COUNT(*)
FROM staging.stg_orders
WHERE order_date !~ '^\d{1,2}/\d{1,2}/\d{2,4}$';

-- LOADING INSTRUCTION: To do in PgAdmin or connecting to database in terminal
-- COPY staging.stg_orders (
--   customer_id, gender, age_category, city, order_id, order_date, 
--   restaurant_name, dish_name, category, quantity, price, payment_method, 
--   order_frequency, last_order_date, loyalty_points, churned, 
--   rating, rating_date, delivery_status
-- ) 
-- FROM '/Users/kundan/Documents/Projects/Food_order/Dataset.csv' DELIMITER ',' CSV HEADER;

-- SELECT * FROM staging.v_data_quality;
