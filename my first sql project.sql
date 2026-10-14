/* 
   INVENTORY MANAGEMENT SYSTEM  -  Beginner SQL Project (MySQL 8) 
    */

# creating the database

DROP DATABASE IF EXISTS inventory_db;
CREATE DATABASE inventory_db;
USE inventory_db;



#creating tables

/* categori table */
CREATE TABLE categories (
    category_id    INT AUTO_INCREMENT PRIMARY KEY,
    category_name  VARCHAR(50) NOT NULL UNIQUE
);

/* suppliers  table */
CREATE TABLE suppliers (
    supplier_id    INT AUTO_INCREMENT PRIMARY KEY,
    supplier_name  VARCHAR(100) NOT NULL,
    email          VARCHAR(100),
    phone          VARCHAR(15),
    city           VARCHAR(50)
);

/* products table */
CREATE TABLE products (
    product_id        INT AUTO_INCREMENT PRIMARY KEY,
    product_name      VARCHAR(100) NOT NULL,
    category_id       INT NOT NULL,
    supplier_id       INT NOT NULL,
    cost_price        DECIMAL(10,2) NOT NULL CHECK (cost_price >= 0),
    unit_price        DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
    quantity_in_stock INT NOT NULL DEFAULT 0 CHECK (quantity_in_stock >= 0),
    reorder_level     INT NOT NULL DEFAULT 10,
    created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(category_id),
    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id)
);


/* customers table */
CREATE TABLE customers (
    customer_id    INT AUTO_INCREMENT PRIMARY KEY,
    customer_name  VARCHAR(100) NOT NULL,
    email          VARCHAR(100),
    city           VARCHAR(50)
);

/* stock_in  table */
-- Stock coming IN (purchases from suppliers)
CREATE TABLE stock_in (
    stock_in_id    INT AUTO_INCREMENT PRIMARY KEY,
    product_id     INT NOT NULL,
    quantity       INT NOT NULL CHECK (quantity > 0),
    unit_cost      DECIMAL(10,2),
    received_date  DATE NOT NULL,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);


/* sales table */
-- Stock going OUT (sales to customers)
CREATE TABLE sales (
    sale_id        INT AUTO_INCREMENT PRIMARY KEY,
    product_id     INT NOT NULL,
    customer_id    INT NOT NULL,
    quantity       INT NOT NULL CHECK (quantity > 0),
    unit_price     DECIMAL(10,2),
    sale_date      DATE NOT NULL,
    FOREIGN KEY (product_id)  REFERENCES products(product_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);


/* 
TRIGGERS  (create BEFORE inserting data so stock updates itself)
   */
DELIMITER $$

-- 3a. When goods are received: fill cost if empty
CREATE TRIGGER trg_stock_in_before
BEFORE INSERT ON stock_in
FOR EACH ROW
BEGIN
    IF NEW.unit_cost IS NULL THEN
        SET NEW.unit_cost = (SELECT cost_price FROM products
                             WHERE product_id = NEW.product_id);
    END IF;
END$$

-- 3b. When goods are received: increase stock
CREATE TRIGGER trg_stock_in_after
AFTER INSERT ON stock_in
FOR EACH ROW
BEGIN
    UPDATE products
    
    SET quantity_in_stock = quantity_in_stock + NEW.quantity
    WHERE product_id = NEW.product_id;
    
END$$

-- 3c. Before a sale: block it if stock is not enough, and fill the price
CREATE TRIGGER trg_sales_before
BEFORE INSERT ON sales
FOR EACH ROW
BEGIN
    DECLARE available INT;

    SELECT quantity_in_stock INTO available
    FROM products WHERE product_id = NEW.product_id;

    IF available < NEW.quantity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Not enough stock for this sale!';
    END IF;

    IF NEW.unit_price IS NULL THEN
        SET NEW.unit_price = (SELECT unit_price FROM products
                              WHERE product_id = NEW.product_id);
    END IF;
END$$

-- 3d. After a sale: reduce stock
CREATE TRIGGER trg_sales_after
AFTER INSERT ON sales
FOR EACH ROW
BEGIN
    UPDATE products
    SET quantity_in_stock = quantity_in_stock - NEW.quantity
    WHERE product_id = NEW.product_id;
END$$

DELIMITER ;


/* 
    inserting sample data
    */

INSERT INTO categories (category_name) VALUES
('Electronics'), ('Furniture'), ('Stationery');

INSERT INTO suppliers (supplier_name, email, phone, city) VALUES
('TechNova Distributors', 'sales@technova.com',    '9876500001', 'Bengaluru'),
('Digital Hub',           'info@digitalhub.com',   '9876500002', 'Chennai'),
('Comfort Furnishings',   'orders@comfortfur.com', '9876500003', 'Madurai'),
('PaperWorld',            'contact@paperworld.com','9876500004', 'Sivakasi');

-- Products start with 0 stock; the stock_in triggers will fill the quantities
INSERT INTO products (product_name, category_id, supplier_id, cost_price, unit_price, reorder_level) VALUES
('Laptop 15 inch',        1, 1, 45000.00, 55000.00,  5),
('Wireless Mouse',        1, 1,   500.00,   800.00, 20),
('USB Keyboard',          1, 2,   800.00,  1200.00, 15),
('Office Chair',          2, 3,  5000.00,  7500.00,  5),
('Study Desk',            2, 3,  6500.00,  9500.00,  3),
('A4 Paper Ream',         3, 4,   250.00,   350.00, 50),
('Ballpoint Pen Box',     3, 4,    70.00,   120.00, 40),
('Notebook Pack',         3, 4,   150.00,   250.00, 30),
('Printer Ink Cartridge', 1, 2,  1000.00,  1500.00, 10),
('Whiteboard',            2, 3,  2200.00,  3200.00,  4);

INSERT INTO customers (customer_name, email, city) VALUES
('Arun Traders',       'arun@traders.com',   'Madurai'),
('Meena Stores',       'meena@stores.com',   'Chennai'),
('Kumar Enterprises',  'kumar@ent.com',      'Coimbatore'),
('Priya Offices',      'priya@offices.com',  'Madurai'),
('Ravi School',        'ravi@school.edu',    'Trichy');

-- Goods received (unit_cost left NULL -> trigger fills it from cost_price)
INSERT INTO stock_in (product_id, quantity, received_date) VALUES
(1,  10, '2026-08-01'),
(2,  60, '2026-08-01'),
(3,  40, '2026-08-02'),
(4,  12, '2026-08-03'),
(5,   6, '2026-08-03'),
(6, 200, '2026-08-05'),
(7, 150, '2026-08-05'),
(8, 100, '2026-08-06'),
(9,  25, '2026-08-07'),
(10,  8, '2026-08-07');

-- Sales (unit_price left NULL -> trigger fills it from products.unit_price)
INSERT INTO sales (product_id, customer_id, quantity, sale_date) VALUES
(1, 1,   3, '2026-09-02'),
(1, 2,   2, '2026-09-10'),
(1, 3,   2, '2026-09-20'),
(2, 1,  20, '2026-09-03'),
(2, 4,  25, '2026-09-15'),
(3, 2,  10, '2026-09-05'),
(4, 5,   4, '2026-09-08'),
(5, 5,   2, '2026-09-08'),
(6, 3, 100, '2026-09-12'),
(6, 4,  60, '2026-09-25'),
(7, 1,  50, '2026-09-14'),
(8, 2,  40, '2026-09-18'),
(9, 3,  10, '2026-09-22'),
(9, 1,   8, '2026-10-01'),
(10, 4,  3, '2026-10-05');


/* 
   BASIC QUERIES
	*/

-- Q1. See all products
SELECT * FROM products;

-- Q2. Products sorted by price (highest first)
SELECT product_name, unit_price
FROM products
ORDER BY unit_price DESC;

-- Q3. Top 3 most expensive products
SELECT product_name, unit_price
FROM products
ORDER BY unit_price DESC
LIMIT 3;

-- Q4. Products priced between 500 and 5000
SELECT product_name, unit_price
FROM products
WHERE unit_price BETWEEN 500 AND 5000;

-- Q5. Search products by name (contains "Pen" or "Paper")
SELECT product_name
FROM products
WHERE product_name LIKE '%Pen%' OR product_name LIKE '%Paper%';

-- Q6. Customers from Madurai
SELECT * FROM customers WHERE city = 'Madurai';


/* 
   AGGREGATES, GROUP BY, HAVING
 */

-- Q7. How many products per category?
SELECT c.category_name, COUNT(*) AS total_products
FROM products p
JOIN categories c ON p.category_id = c.category_id
GROUP BY c.category_name;

-- Q8. Total stock value (at cost) of the whole warehouse
SELECT SUM(quantity_in_stock * cost_price) AS total_inventory_value
FROM products;

-- Q9. Average, minimum and maximum selling price
SELECT AVG(unit_price) AS avg_price,
       MIN(unit_price) AS min_price,
       MAX(unit_price) AS max_price
FROM products;

-- Q10. Total revenue and units sold per product
SELECT p.product_name,
       SUM(s.quantity)               AS units_sold,
       SUM(s.quantity * s.unit_price) AS revenue
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY revenue DESC;

-- Q11. Customers who spent more than 50,000 (HAVING filters groups)
SELECT cu.customer_name,
       SUM(s.quantity * s.unit_price) AS total_spent
FROM sales s
JOIN customers cu ON s.customer_id = cu.customer_id
GROUP BY cu.customer_name
HAVING total_spent > 50000
ORDER BY total_spent DESC;




/* 
   JOINS AND SUBQUERIES
   */

-- Q13. Product list with category and supplier names (3-table JOIN)
SELECT p.product_id, p.product_name, c.category_name,
       s.supplier_name, p.quantity_in_stock
FROM products p
JOIN categories c ON p.category_id = c.category_id
JOIN suppliers  s ON p.supplier_id = s.supplier_id;

-- Q14. Products that have NEVER been sold (LEFT JOIN + IS NULL)
SELECT p.product_name
FROM products p
LEFT JOIN sales s ON p.product_id = s.product_id
WHERE s.sale_id IS NULL;
-- (Empty result is fine: every product has a sale in our sample data.)

-- Q15. Products priced above the average price (subquery)
SELECT product_name, unit_price
FROM products
WHERE unit_price > (SELECT AVG(unit_price) FROM products);

-- Q16. Best-selling product by units sold
SELECT p.product_name, SUM(s.quantity) AS units_sold
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY units_sold DESC
LIMIT 1;

-- Q17. Profit per product = (selling price - cost) x units sold
SELECT p.product_name,
       SUM(s.quantity * (s.unit_price - p.cost_price)) AS profit
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY profit DESC;


/* 
   VIEWS  (saved, reusable reports)
   */

-- View 1: products that need reordering
CREATE VIEW v_low_stock AS
SELECT p.product_id, p.product_name, p.quantity_in_stock, p.reorder_level,
       s.supplier_name, s.phone
FROM products p
JOIN suppliers s ON p.supplier_id = s.supplier_id
WHERE p.quantity_in_stock <= p.reorder_level;

-- View 2: full sales report
CREATE VIEW v_sales_report AS
SELECT s.sale_id, s.sale_date, cu.customer_name, p.product_name,
       s.quantity, s.unit_price,
       s.quantity * s.unit_price AS total_amount
FROM sales s
JOIN customers cu ON s.customer_id = cu.customer_id
JOIN products  p  ON s.product_id  = p.product_id;

-- View 3: inventory value per category
CREATE VIEW v_inventory_value AS
SELECT c.category_name,
       SUM(p.quantity_in_stock)               AS total_units,
       SUM(p.quantity_in_stock * p.cost_price) AS stock_value
FROM products p
JOIN categories c ON p.category_id = c.category_id
GROUP BY c.category_name;

-- Use the views like normal tables:
SELECT * FROM v_low_stock;            -- what should we reorder today?
SELECT * FROM v_sales_report ORDER BY sale_date DESC;
SELECT * FROM v_inventory_value;


/* 
	STORED PROCEDURE 
    */
DELIMITER $$

-- sell a product in one call:
CREATE PROCEDURE sp_sell_product(
    IN p_product_id  INT,
    IN p_customer_id INT,
    IN p_quantity    INT
)
BEGIN
    INSERT INTO sales (product_id, customer_id, quantity, sale_date)
    VALUES (p_product_id, p_customer_id, p_quantity, CURDATE());

    SELECT product_name, quantity_in_stock AS stock_left
    FROM products WHERE product_id = p_product_id;
END$$

DELIMITER ;

-- Sell 2 whiteboards to customer 5:
CALL sp_sell_product(10, 5, 2);


/* 
	RESTOCKING, UPDATE, DELETE, INDEXES
   */

-- Receive new stock of low items; triggers raise the quantity automatically
INSERT INTO stock_in (product_id, quantity, received_date) VALUES
(1, 10, CURDATE()),
(2, 40, CURDATE());

-- Check that low-stock list shrank
SELECT * FROM v_low_stock;

-- UPDATE: change a price
SET SQL_SAFE_UPDATES = 0;
UPDATE products SET unit_price = 850.00 WHERE product_name = 'Wireless Mouse';



-- UPDATE: raise reorder level of all Stationery by 10
UPDATE products
SET reorder_level = reorder_level + 10
WHERE category_id = (SELECT category_id FROM categories
                     WHERE category_name = 'Stationery');

-- DELETE: remove a customer who has no sales (safe example)
INSERT INTO customers (customer_name, city) VALUES ('Test Customer', 'Nowhere');
DELETE FROM customers WHERE customer_name = 'Test Customer';

-- INDEXES speed up searches / joins on frequently used columns
CREATE INDEX idx_products_name   ON products(product_name);
CREATE INDEX idx_sales_date      ON sales(sale_date);
CREATE INDEX idx_sales_product   ON sales(product_id);

-- Final check 
SELECT product_id, product_name, quantity_in_stock, reorder_level FROM products;


