-- Reset legacy demo tables on each startup to keep the dataset deterministic
TRUNCATE TABLE orders, inventory, products, suppliers RESTART IDENTITY CASCADE;

-- Legacy supplier records
INSERT INTO suppliers (id, name, contact_email, phone) VALUES
(1, 'NorthMed Supplies', 'ops@northmed.local', '+1-555-1010'),
(2, 'PrimeRx Distributors', 'dispatch@primerx.local', '+1-555-2020'),
(3, 'HealthBridge Wholesale', 'support@healthbridge.local', '+1-555-3030'),
(4, 'Metro Pharma Logistics', 'orders@metropharma.local', '+1-555-4040');

-- Legacy products (15 records, intentionally small dataset)
INSERT INTO products (id, name, category, unit_price, sku, active, supplier_id) VALUES
(1, 'Panadol Extra', 'Pain Relief', 4.99, 'MED-0001', true, 1),
(2, 'Amoxil 500mg', 'Antibiotics', 12.99, 'MED-0002', true, 2),
(3, 'Vitamin C Effervescent', 'Vitamins', 7.49, 'MED-0003', true, 1),
(4, 'Brufen 400mg', 'Pain Relief', 5.99, 'MED-0004', true, 3),
(5, 'Actifed Syrup', 'Cold and Flu', 8.99, 'MED-0005', true, 2),
(6, 'Glucophage 500mg', 'Diabetes Care', 9.99, 'MED-0006', true, 4),
(7, 'Lipitor 20mg', 'Heart Health', 24.99, 'MED-0007', true, 4),
(8, 'Zyrtec 10mg', 'Allergy', 11.99, 'MED-0008', true, 3),
(9, 'Aspirin Cardio', 'Heart Health', 6.49, 'MED-0009', true, 2),
(10, 'Caltrate Plus', 'Vitamins', 13.99, 'MED-0010', true, 1),
(11, 'Betadine Antiseptic', 'First Aid', 6.99, 'MED-0011', true, 3),
(12, 'Canesten Cream', 'Skin Care', 9.49, 'MED-0012', true, 4),
(13, 'Nexium 20mg', 'Digestive Health', 18.99, 'MED-0013', true, 2),
(14, 'Omega 3 Fish Oil', 'Supplements', 19.99, 'MED-0014', true, 1),
(15, 'Lantus SoloStar', 'Diabetes Care', 89.99, 'MED-0015', true, 4);

-- Legacy inventory snapshot
INSERT INTO inventory (id, product_id, quantity_on_hand, reorder_level, last_updated) VALUES
(1, 1, 200, 40, CURRENT_TIMESTAMP),
(2, 2, 150, 35, CURRENT_TIMESTAMP),
(3, 3, 300, 50, CURRENT_TIMESTAMP),
(4, 4, 175, 40, CURRENT_TIMESTAMP),
(5, 5, 120, 30, CURRENT_TIMESTAMP),
(6, 6, 100, 25, CURRENT_TIMESTAMP),
(7, 7, 90, 20, CURRENT_TIMESTAMP),
(8, 8, 160, 35, CURRENT_TIMESTAMP),
(9, 9, 250, 45, CURRENT_TIMESTAMP),
(10, 10, 140, 35, CURRENT_TIMESTAMP),
(11, 11, 200, 40, CURRENT_TIMESTAMP),
(12, 12, 110, 25, CURRENT_TIMESTAMP),
(13, 13, 85, 20, CURRENT_TIMESTAMP),
(14, 14, 180, 35, CURRENT_TIMESTAMP),
(15, 15, 40, 10, CURRENT_TIMESTAMP);

-- Legacy order history
INSERT INTO orders (id, product_id, quantity, unit_price, total_price, status, customer_name, created_at) VALUES
(1, 1, 3, 4.99, 14.97, 'DELIVERED', 'Central Pharmacy', CURRENT_TIMESTAMP - INTERVAL '14 days'),
(2, 7, 1, 24.99, 24.99, 'DELIVERED', 'City Health Store', CURRENT_TIMESTAMP - INTERVAL '12 days'),
(3, 6, 2, 9.99, 19.98, 'DELIVERED', 'Neighborhood Clinic', CURRENT_TIMESTAMP - INTERVAL '10 days'),
(4, 3, 5, 7.49, 37.45, 'SHIPPED', 'Care Plus Retail', CURRENT_TIMESTAMP - INTERVAL '8 days'),
(5, 9, 4, 6.49, 25.96, 'SHIPPED', 'GoodCare Pharmacy', CURRENT_TIMESTAMP - INTERVAL '7 days'),
(6, 11, 2, 6.99, 13.98, 'CREATED', 'Metro Medical Shop', CURRENT_TIMESTAMP - INTERVAL '5 days'),
(7, 12, 1, 9.49, 9.49, 'CREATED', 'Family Drug House', CURRENT_TIMESTAMP - INTERVAL '4 days'),
(8, 4, 6, 5.99, 35.94, 'DELIVERED', 'Sunrise Pharmacy', CURRENT_TIMESTAMP - INTERVAL '3 days'),
(9, 14, 2, 19.99, 39.98, 'CREATED', 'Wellness Point', CURRENT_TIMESTAMP - INTERVAL '2 days'),
(10, 2, 3, 12.99, 38.97, 'SHIPPED', 'Community Med Center', CURRENT_TIMESTAMP - INTERVAL '1 day');
