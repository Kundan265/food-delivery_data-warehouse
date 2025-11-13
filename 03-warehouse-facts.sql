-- ===================================
-- WAREHOUSE LAYER - FACT TABLE
-- ===================================

-- ===== FACT TABLE: Orders =====
CREATE TABLE warehouse.fact_orders (
    order_sk SERIAL PRIMARY KEY,
    order_id VARCHAR(50) NOT NULL UNIQUE,
    customer_sk INT NOT NULL,
    restaurant_sk INT NOT NULL,
    product_sk INT NOT NULL,
    date_sk INT NOT NULL,
    payment_sk INT NOT NULL,
    delivery_sk INT NOT NULL,
    
    -- Measures (facts)
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    order_total DECIMAL(12, 2) NOT NULL,
    rating INT,
    order_frequency INT,
    loyalty_points_earned INT DEFAULT 0,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign keys
    FOREIGN KEY (customer_sk) REFERENCES warehouse.dim_customer(customer_sk),
    FOREIGN KEY (restaurant_sk) REFERENCES warehouse.dim_restaurant(restaurant_sk),
    FOREIGN KEY (product_sk) REFERENCES warehouse.dim_product(product_sk),
    FOREIGN KEY (date_sk) REFERENCES warehouse.dim_date(date_sk),
    FOREIGN KEY (payment_sk) REFERENCES warehouse.dim_payment_method(payment_sk),
    FOREIGN KEY (delivery_sk) REFERENCES warehouse.dim_delivery_status(delivery_sk)
);

-- Create indexes for performance
CREATE INDEX idx_fact_customer_sk ON warehouse.fact_orders(customer_sk);
CREATE INDEX idx_fact_restaurant_sk ON warehouse.fact_orders(restaurant_sk);
CREATE INDEX idx_fact_date_sk ON warehouse.fact_orders(date_sk);
CREATE INDEX idx_fact_product_sk ON warehouse.fact_orders(product_sk);
CREATE INDEX idx_fact_payment_sk ON warehouse.fact_orders(payment_sk);
CREATE INDEX idx_fact_delivery_sk ON warehouse.fact_orders(delivery_sk);
CREATE INDEX idx_fact_order_id ON warehouse.fact_orders(order_id);

-- Composite indexes for common queries
CREATE INDEX idx_fact_customer_date ON warehouse.fact_orders(customer_sk, date_sk);
CREATE INDEX idx_fact_restaurant_date ON warehouse.fact_orders(restaurant_sk, date_sk);
