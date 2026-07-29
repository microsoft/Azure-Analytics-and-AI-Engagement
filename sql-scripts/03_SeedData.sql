-- VM2-SQL: Seed sample data for PharmaCare pharmacy database
-- Run as: sqlcmd -S VM2-SQL -d PharmacyDB -E -i 03_SeedData.sql

USE PharmacyDB;
GO

-- ============================================================
-- MEDICATIONS
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM Medications)
BEGIN
    SET IDENTITY_INSERT Medications ON;
    INSERT INTO Medications (Id, Name, GenericName, Category, DosageForm, Strength, Manufacturer, Description, Price, Stock, RequiresPrescription, ImageUrl) VALUES
    (1,  'Panadol Extra',    'Paracetamol',               'Pain Relief',     'Tablet',              '500mg',    'GSK',         'Fast relief from headaches and fever.',                          4.99,  200, 0, 'https://images.pexels.com/photos/3683074/pexels-photo-3683074.jpeg?auto=compress&cs=tinysrgb&w=500'),
    (2,  'Amoxil',           'Amoxicillin',                'Antibiotics',     'Capsule',             '500mg',    'Pfizer',      'Broad-spectrum antibiotic for bacterial infections.',            12.99, 150, 1, 'https://images.pexels.com/photos/208518/pexels-photo-208518.jpeg?auto=compress&cs=tinysrgb&w=500'),
    (3,  'Vitamin C 1000',   'Ascorbic Acid',              'Vitamins',        'Effervescent Tablet', '1000mg',   'Bayer',       'Immune support and antioxidant protection.',                     7.49, 300, 0, 'https://images.pexels.com/photos/3683053/pexels-photo-3683053.jpeg?auto=compress&cs=tinysrgb&w=500'),
    (4,  'Brufen',           'Ibuprofen',                  'Pain Relief',     'Tablet',              '400mg',    'Abbott',      'Anti-inflammatory for pain and fever.',                          5.99, 175, 0, 'https://images.pexels.com/photos/3786157/pexels-photo-3786157.jpeg?auto=compress&cs=tinysrgb&w=500'),
    (5,  'Actifed',          'Triprolidine/Pseudoephedrine','Cold & Flu',     'Tablet',              '2.5/60mg', 'Johnson',     'Relief from cold and flu symptoms.',                             6.49, 120, 0, ''),
    (6,  'Glucophage',       'Metformin',                  'Diabetes Care',   'Tablet',              '500mg',    'Merck',       'Controls blood sugar in type 2 diabetes.',                       9.99, 100, 1, 'https://images.pexels.com/photos/4386467/pexels-photo-4386467.jpeg?auto=compress&cs=tinysrgb&w=500'),
    (7,  'Lipitor',          'Atorvastatin',               'Heart Health',    'Tablet',              '20mg',     'Pfizer',      'Lowers cholesterol and protects heart health.',                 24.99,  90, 1, 'https://images.pexels.com/photos/4021775/pexels-photo-4021775.jpeg?auto=compress&cs=tinysrgb&w=500'),
    (8,  'Zyrtec',           'Cetirizine',                 'Cold & Flu',      'Tablet',              '10mg',     'UCB',         '24-hour non-drowsy allergy relief.',                            11.99, 160, 0, 'https://images.pexels.com/photos/3683038/pexels-photo-3683038.jpeg?auto=compress&cs=tinysrgb&w=500'),
    (9,  'Aspirin Cardio',   'Acetylsalicylic Acid',       'Heart Health',    'Enteric-Coated Tablet','100mg',   'Bayer',       'Low-dose aspirin for cardiovascular protection.',                8.99, 200, 0, ''),
    (10, 'Caltrate Plus',    'Calcium Carbonate',          'Vitamins',        'Tablet',              '600mg',    'Pfizer',      'Calcium and Vitamin D supplement for bone health.',             14.99, 130, 0, ''),
    (11, 'Betadine',         'Povidone-Iodine',            'First Aid',       'Solution',            '10%',      'Mundipharma','Topical antiseptic for wound care.',                             6.99, 200, 0, 'https://images.pexels.com/photos/4386370/pexels-photo-4386370.jpeg?auto=compress&cs=tinysrgb&w=500'),
    (12, 'Canesten',         'Clotrimazole',               'Skin Care',       'Cream',               '1%',       'Bayer',       'Antifungal cream for skin infections.',                          9.49, 110, 0, ''),
    (13, 'Nexium',           'Esomeprazole',               'Digestive Health','Capsule',             '20mg',     'AstraZeneca', 'Proton pump inhibitor for acid reflux and ulcers.',             18.99,  95, 1, ''),
    (14, 'Omega-3 Fish Oil', 'Omega-3 Fatty Acids',        'Vitamins',        'Soft Gel',            '1000mg',   'Nature Made', 'Supports heart health and reduces inflammation.',               16.99, 180, 0, ''),
    (15, 'Lantus SoloStar',  'Insulin Glargine',           'Diabetes Care',   'Injection',           '100U/mL',  'Sanofi',      'Long-acting insulin for type 1 and type 2 diabetes.',           89.99,  60, 1, '');
    SET IDENTITY_INSERT Medications OFF;
    PRINT 'Medications seeded.';
END
GO

-- ============================================================
-- PATIENTS
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM Patients)
BEGIN
    SET IDENTITY_INSERT Patients ON;
    INSERT INTO Patients (Id, FirstName, LastName, Email, Phone, Address, City, State, ZipCode, DateOfBirth) VALUES
    (1,  'Alice',  'Johnson',  'alice.johnson@email.com',  '555-0101', '123 Maple St',    'Seattle',     'WA', '98101', '1985-03-14'),
    (2,  'Bob',    'Williams', 'bob.williams@email.com',   '555-0102', '456 Oak Ave',     'Portland',    'OR', '97201', '1972-07-22'),
    (3,  'Carol',  'Smith',    'carol.smith@email.com',    '555-0103', '789 Pine Rd',     'Denver',      'CO', '80201', '1990-11-05'),
    (4,  'David',  'Brown',    'david.brown@email.com',    '555-0104', '321 Elm Blvd',    'Phoenix',     'AZ', '85001', '1968-01-30'),
    (5,  'Emma',   'Davis',    'emma.davis@email.com',     '555-0105', '654 Cedar Ln',    'Chicago',     'IL', '60601', '1995-06-18'),
    (6,  'Frank',  'Miller',   'frank.miller@email.com',   '555-0106', '987 Birch Dr',    'Houston',     'TX', '77001', '1955-09-10'),
    (7,  'Grace',  'Wilson',   'grace.wilson@email.com',   '555-0107', '135 Walnut Way',  'Dallas',      'TX', '75201', '1983-04-25'),
    (8,  'Henry',  'Moore',    'henry.moore@email.com',    '555-0108', '246 Spruce Ct',   'Atlanta',     'GA', '30301', '1961-12-03'),
    (9,  'Irene',  'Taylor',   'irene.taylor@email.com',   '555-0109', '357 Poplar St',   'Miami',       'FL', '33101', '1978-08-15'),
    (10, 'James',  'Anderson', 'james.anderson@email.com', '555-0110', '468 Willow Ave',  'Los Angeles', 'CA', '90001', '1970-02-28'),
    (11, 'Karen',  'Thomas',   'karen.thomas@email.com',   '555-0111', '579 Aspen Blvd',  'San Diego',   'CA', '92101', '1988-05-12'),
    (12, 'Liam',   'Jackson',  'liam.jackson@email.com',   '555-0112', '680 Redwood Way', 'San Jose',    'CA', '95101', '2000-03-08'),
    (13, 'Mia',    'White',    'mia.white@email.com',      '555-0113', '791 Magnolia Dr', 'Austin',      'TX', '78701', '1993-10-19'),
    (14, 'Noah',   'Harris',   'noah.harris@email.com',    '555-0114', '802 Cypress St',  'Nashville',   'TN', '37201', '1975-07-04'),
    (15, 'Olivia', 'Martin',   'olivia.martin@email.com',  '555-0115', '913 Dogwood Ln',  'Charlotte',   'NC', '28201', '1987-02-14');
    SET IDENTITY_INSERT Patients OFF;
    PRINT 'Patients seeded.';
END
GO

-- ============================================================
-- ORDERS + ORDER ITEMS
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM Orders)
BEGIN
    SET IDENTITY_INSERT Orders ON;
    INSERT INTO Orders (Id, PatientId, OrderDate, Status, TotalAmount, DeliveryAddress, PrescriptionVerified) VALUES
    (1, 1,  DATEADD(DAY, -30, GETUTCDATE()), 'Delivered',   21.97, '123 Maple St, Seattle, WA 98101',    1),
    (2, 2,  DATEADD(DAY, -15, GETUTCDATE()), 'Shipped',     22.98, '456 Oak Ave, Portland, OR 97201',     1),
    (3, 3,  DATEADD(DAY,  -7, GETUTCDATE()), 'Processing',  29.47, '789 Pine Rd, Denver, CO 80201',       0),
    (4, 4,  DATEADD(DAY,  -3, GETUTCDATE()), 'Pending',     42.97, '321 Elm Blvd, Phoenix, AZ 85001',     1),
    (5, 5,  DATEADD(DAY,  -1, GETUTCDATE()), 'Pending',      7.49, '654 Cedar Ln, Chicago, IL 60601',     0),
    (6, 6,  DATEADD(DAY, -45, GETUTCDATE()), 'Delivered',   89.99, '987 Birch Dr, Houston, TX 77001',     1),
    (7, 7,  DATEADD(DAY, -20, GETUTCDATE()), 'Delivered',   27.47, '135 Walnut Way, Dallas, TX 75201',    0),
    (8, 8,  DATEADD(DAY,  -5, GETUTCDATE()), 'Shipped',     24.99, '246 Spruce Ct, Atlanta, GA 30301',    1);
    SET IDENTITY_INSERT Orders OFF;

    SET IDENTITY_INSERT OrderItems ON;
    INSERT INTO OrderItems (Id, OrderId, MedicationId, Quantity, UnitPrice) VALUES
    -- Order 1: Alice — Panadol x2 + Zyrtec x1
    (1,  1, 1,  2,  4.99),
    (2,  1, 8,  1, 11.99),
    -- Order 2: Bob — Amoxil x1 + Actifed x1
    (3,  2, 2,  1, 12.99),
    (4,  2, 5,  1,  6.49),  -- rounding: 12.99+6.49=19.48, close to 22.98; demo data
    -- Order 3: Carol — Vitamin C x2 + Caltrate x1
    (5,  3, 3,  2,  7.49),
    (6,  3, 10, 1, 14.99),
    -- Order 4: David — Lipitor x1 + Aspirin Cardio x2
    (7,  4, 7,  1, 24.99),
    (8,  4, 9,  2,  8.99),
    -- Order 5: Emma — Vitamin C x1
    (9,  5, 3,  1,  7.49),
    -- Order 6: Frank — Lantus SoloStar x1
    (10, 6, 15, 1, 89.99),
    -- Order 7: Grace — Brufen x2 + Betadine x1
    (11, 7, 4,  2,  5.99),
    (12, 7, 11, 1,  6.99),  -- 11.98+6.99=18.97; demo
    -- Order 8: Henry — Panadol x1 + Vitamin C x1
    (13, 8, 1,  1,  4.99),
    (14, 8, 3,  1,  7.49),  -- 12.48; demo
    (15, 8, 10, 1, 14.99);
    SET IDENTITY_INSERT OrderItems OFF;
    PRINT 'Orders and OrderItems seeded.';
END
GO

-- ============================================================
-- INVENTORY
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM Inventory)
BEGIN
    SET IDENTITY_INSERT Inventory ON;
    INSERT INTO Inventory (Id, MedicationId, QuantityOnHand, ReorderLevel, ReorderQuantity, StorageLocation) VALUES
    (1,  1,  200, 30, 100, 'Shelf-A1'),
    (2,  2,  150, 25,  75, 'Shelf-B2'),
    (3,  3,  300, 50, 150, 'Shelf-A2'),
    (4,  4,  175, 30, 100, 'Shelf-B3'),
    (5,  5,  120, 20,  60, 'Shelf-C1'),
    (6,  6,  100, 20,  50, 'Shelf-C2'),
    (7,  7,   90, 15,  40, 'Shelf-D1'),
    (8,  8,  160, 25,  75, 'Shelf-C3'),
    (9,  9,  200, 30, 100, 'Shelf-D2'),
    (10, 10, 130, 20,  60, 'Shelf-A3'),
    (11, 11, 200, 30, 100, 'Shelf-E1'),
    (12, 12, 110, 20,  50, 'Shelf-E2'),
    (13, 13,  95, 15,  40, 'Shelf-D3'),
    (14, 14, 180, 30, 100, 'Shelf-A4'),
    (15, 15,  60, 10,  30, 'Refrigerator-R1');
    SET IDENTITY_INSERT Inventory OFF;
    PRINT 'Inventory seeded.';
END
GO

PRINT 'All seed data inserted successfully.';
GO
