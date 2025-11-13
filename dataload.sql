COPY staging_raw.foapp_raw(
  customer_id, gender, age_category, city, order_id, order_date,
  restaurant_name, dish_name, category, quantity, price, payment_method,
  order_frequency, last_order_date, loyalty_points, churned,
  rating, rating_date, delivery_status
)
FROM '/Users/kundan/Documents/Projects/Food_order/Dataset.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');


