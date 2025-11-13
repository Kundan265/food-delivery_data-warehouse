CREATE SCHEMA IF NOT EXISTS warehouse;

-- 1:
CREATE TABLE warehouse.dim_customer (
    customer_sk SERIAL PRIMARY KEY,
    customer_id VARCHAR(50) NOT NULL UNIQUE,
    gender VARCHAR(20),
    age_category VARCHAR(50),
    city VARCHAR(100),
    current_loyalty_points INT DEFAULT 0,
    churn_status VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
    end_date DATE DEFAULT '9999-12-31'::DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_dim_customer_id ON warehouse.dim_customer(customer_id);
CREATE INDEX idx_dim_customer_city ON warehouse.dim_customer(city);

-- 2:
CREATE TABLE warehouse.dim_restaurant (
    restaurant_sk SERIAL PRIMARY KEY,
    restaurant_name VARCHAR(100) NOT NULL UNIQUE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO warehouse.dim_restaurant (restaurant_name) 
VALUES ('McDonald''s'), ('KFC'), ('Pizza Hut'), ('Subway'), ('Burger King')
ON CONFLICT (restaurant_name) DO NOTHING;

-- 3:
CREATE TABLE warehouse.dim_product (
    product_sk SERIAL PRIMARY KEY,
    dish_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    restaurant_sk INT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (restaurant_sk) REFERENCES warehouse.dim_restaurant(restaurant_sk),
    UNIQUE(dish_name, restaurant_sk)
);

CREATE INDEX idx_dim_product_restaurant ON warehouse.dim_product(restaurant_sk);
CREATE INDEX idx_dim_product_category ON warehouse.dim_product(category);

-- 4:
CREATE TABLE warehouse.dim_date (
    date_sk INT PRIMARY KEY,
    calendar_date DATE NOT NULL UNIQUE,
    year INT NOT NULL,
    month INT NOT NULL,
    day INT NOT NULL,
    quarter INT NOT NULL,
    day_of_week INT,
    day_name VARCHAR(20),
    month_name VARCHAR(20),
    is_weekend BOOLEAN DEFAULT FALSE,
    is_holiday BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO warehouse.dim_date (date_sk, calendar_date, year, month, day, quarter, day_of_week, day_name, month_name, is_weekend)
SELECT 
    TO_CHAR(d, 'YYYYMMDD')::INT as date_sk,
    d,
    EXTRACT(YEAR FROM d)::INT,
    EXTRACT(MONTH FROM d)::INT,
    EXTRACT(DAY FROM d)::INT,
    EXTRACT(QUARTER FROM d)::INT,
    EXTRACT(DOW FROM d)::INT,
    TO_CHAR(d, 'Day'),
    TO_CHAR(d, 'Month'),
    EXTRACT(DOW FROM d) IN (0, 6)
FROM generate_series('2023-08-01'::DATE, '2025-12-31'::DATE, '1 day'::INTERVAL) as d
ON CONFLICT (date_sk) DO NOTHING;

-- 5
CREATE TABLE warehouse.dim_payment_method (
    payment_sk SERIAL PRIMARY KEY,
    payment_method VARCHAR(50) NOT NULL UNIQUE,
    payment_category VARCHAR(50),
    is_digital BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO warehouse.dim_payment_method (payment_method, payment_category, is_digital)
VALUES 
    ('Cash', 'Physical', FALSE),
    ('Card', 'Digital', TRUE),
    ('Wallet', 'Digital', TRUE)
ON CONFLICT (payment_method) DO NOTHING;

-- 6
CREATE TABLE warehouse.dim_delivery_status (
    delivery_sk SERIAL PRIMARY KEY,
    delivery_status VARCHAR(50) NOT NULL UNIQUE,
    status_code VARCHAR(10),
    is_delivered BOOLEAN,
    is_problem BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO warehouse.dim_delivery_status (delivery_status, status_code, is_delivered, is_problem)
VALUES 
    ('Delivered', 'DEL', TRUE, FALSE),
    ('Cancelled', 'CAN', FALSE, TRUE),
    ('Delayed', 'DEL', FALSE, TRUE)
ON CONFLICT (delivery_status) DO NOTHING;