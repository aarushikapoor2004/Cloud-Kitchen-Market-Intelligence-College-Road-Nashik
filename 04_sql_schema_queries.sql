-- ============================================================
-- Cloud Kitchen Market Intelligence | College Road, Nashik
-- SQL Schema + Data + Queries
-- MySQL 8.0+
-- ============================================================

-- ============================================================
-- SECTION 1: SCHEMA
-- ============================================================

-- Fresh setup — drop and recreate the database
DROP DATABASE IF EXISTS cloud_kitchen_intelligence;
CREATE DATABASE cloud_kitchen_intelligence
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE cloud_kitchen_intelligence;

-- localities
-- Kept as a separate lookup table so the city/state info
-- isn't repeated in every restaurant row. Useful if the
-- project ever expands to other localities in Nashik.

CREATE TABLE localities (
    locality_id   TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
    locality_name VARCHAR(100)     NOT NULL,
    city          VARCHAR(100)     NOT NULL DEFAULT 'Nashik',
    state         VARCHAR(100)     NOT NULL DEFAULT 'Maharashtra',
    PRIMARY KEY (locality_id),
    UNIQUE KEY uq_locality_name (locality_name)
) ENGINE=InnoDB;

-- restaurants
-- Core table. Each row is one outlet.
-- delivery_time_min and delivery_time_max were split out
-- from strings like "30-35 min" so range queries don't
-- require string functions at runtime.

CREATE TABLE restaurants (
    restaurant_id   SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    restaurant_name VARCHAR(150)      NOT NULL,
    rating          DECIMAL(2,1)      NULL
        CHECK (rating BETWEEN 1.0 AND 5.0),
    number_of_reviews INT UNSIGNED    NULL,
    cost_for_two    SMALLINT UNSIGNED NULL
        COMMENT 'INR; cost for two people',
    cuisines        VARCHAR(255)      NOT NULL
        COMMENT 'Raw comma-separated field from source; use restaurant_cuisines for normalised joins',
    locality_id     TINYINT UNSIGNED  NOT NULL,
    restaurant_type ENUM(
        'Cloud Kitchen',
        'Dine-In',
        'Unknown'
    ) NOT NULL DEFAULT 'Unknown',
    delivery_time_min TINYINT UNSIGNED NULL
        COMMENT 'Lower bound in minutes',
    delivery_time_max TINYINT UNSIGNED NULL
        COMMENT 'Upper bound in minutes',
    PRIMARY KEY (restaurant_id),
    UNIQUE KEY uq_restaurant_locality (restaurant_name, locality_id),
    KEY idx_rating          (rating),
    KEY idx_restaurant_type (restaurant_type),
    KEY idx_locality        (locality_id),
    CONSTRAINT fk_restaurant_locality
        FOREIGN KEY (locality_id)
        REFERENCES localities (locality_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='Master restaurant registry';

-- cuisines
-- Normalised list of cuisine tags.
-- Centralising names here means a typo fix in one place
-- propagates everywhere via the junction table.

CREATE TABLE cuisines (
    cuisine_id   SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    cuisine_name VARCHAR(100)      NOT NULL,
    PRIMARY KEY (cuisine_id),
    UNIQUE KEY uq_cuisine_name (cuisine_name)
) ENGINE=InnoDB;

-- restaurant_cuisines
-- Junction table for the many-to-many link between
-- restaurants and cuisines. A single restaurant like
-- "Domino's Pizza" maps to both Pizza and Italian here.

CREATE TABLE restaurant_cuisines (
    restaurant_id SMALLINT UNSIGNED NOT NULL,
    cuisine_id    SMALLINT UNSIGNED NOT NULL,
    PRIMARY KEY (restaurant_id, cuisine_id),
    CONSTRAINT fk_rc_restaurant
        FOREIGN KEY (restaurant_id)
        REFERENCES restaurants (restaurant_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_rc_cuisine
        FOREIGN KEY (cuisine_id)
        REFERENCES cuisines (cuisine_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Junction table: restaurant <-> cuisine (many-to-many)';

-- menu_categories
-- Lookup for category labels (Burgers, Pizzas, etc.).
-- Same idea as localities — avoids repeating strings
-- across hundreds of menu item rows.

CREATE TABLE menu_categories (
    category_id   TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
    category_name VARCHAR(100)     NOT NULL,
    PRIMARY KEY (category_id),
    UNIQUE KEY uq_category_name (category_name)
) ENGINE=InnoDB;

-- menu_items
-- Stores menu data for the 5 restaurants selected in
-- Part 3. Restaurants without menu data simply have no
-- child rows in this table.

CREATE TABLE menu_items (
    item_id       INT UNSIGNED      NOT NULL AUTO_INCREMENT,
    restaurant_id SMALLINT UNSIGNED NOT NULL,
    category_id   TINYINT UNSIGNED  NOT NULL,
    item_name     VARCHAR(150)      NOT NULL,
    price         SMALLINT UNSIGNED NOT NULL
        COMMENT 'INR per item/portion',
    is_bestseller TINYINT(1)        NOT NULL DEFAULT 0
        COMMENT '1 = bestseller, 0 = regular',
    PRIMARY KEY (item_id),
    KEY idx_mi_restaurant (restaurant_id),
    KEY idx_mi_price      (price),
    CONSTRAINT fk_mi_restaurant
        FOREIGN KEY (restaurant_id)
        REFERENCES restaurants (restaurant_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_mi_category
        FOREIGN KEY (category_id)
        REFERENCES menu_categories (category_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Menu items for selected restaurants';


-- ============================================================
-- SECTION 2: SEED DATA
-- ============================================================

INSERT INTO localities (locality_name) VALUES ('College Road');

INSERT INTO cuisines (cuisine_name) VALUES
    ('South Indian'), ('Sandwich'),    ('Sweets'),        ('Snacks'),
    ('Indian'),       ('Italian'),     ('Fast Food'),     ('Momos'),
    ('Rolls'),        ('Wraps'),       ('Street Food'),   ('Biryani'),
    ('Pizza'),        ('Continental'), ('Middle Eastern'),('Waffles'),
    ('Arabian'),      ('Bakery'),      ('Desserts'),      ('American'),
    ('Cakes'),        ('Beverages'),   ('North Indian'),  ('Pasta'),
    ('Finger Food'),  ('Asian'),       ('Maharashtrian'), ('Chinese');

INSERT INTO restaurants
    (restaurant_name, rating, number_of_reviews, cost_for_two,
     cuisines, locality_id, restaurant_type,
     delivery_time_min, delivery_time_max)
VALUES
    ('Anna Idli',                   4.6, 2100,  200,  'South Indian, Sandwich',    1, 'Cloud Kitchen', 30, 40),
    ('Madhur Sweets',               4.5, 3200,  250,  'Sweets, Snacks',            1, 'Cloud Kitchen', 30, 40),
    ('Tales & Spirits',             4.5,  717,  800,  'Indian, Italian',           1, 'Cloud Kitchen', 30, 35),
    ('King Momos Center',           4.3,  200, NULL,  'Fast Food, Momos',          1, 'Cloud Kitchen', NULL, NULL),
    ('M2H Shawarma Rolls & Wraps',  4.2, 2700,  300,  'Rolls, Wraps',              1, 'Cloud Kitchen', 30, 35),
    ('Viju''s Dabeli',              4.0,  200, NULL,  'Street Food',               1, 'Cloud Kitchen', NULL, NULL),
    ('Biryani Express Inn',         3.4,   36,  500,  'Biryani',                   1, 'Cloud Kitchen', NULL, NULL),
    ('Pizza Hut',                   4.3, 8400,  300,  'Pizza',                     1, 'Cloud Kitchen', 20, 25),
    ('Domo''s Cafe',                5.0, NULL,  500,  'Continental, Middle Eastern',1,'Dine-In',       NULL, NULL),
    ('Baker''s Emporium',           4.7,   50,  300,  'Continental, Italian',      1, 'Dine-In',       NULL, NULL),
    ('The Waffle Tree',             4.7,  103,  200,  'Fast Food, Waffles',        1, 'Dine-In',       NULL, NULL),
    ('Al Arabian Express',          4.6,16000,  500,  'Arabian',                   1, 'Dine-In',       30, 35),
    ('Sagar Sweet',                 4.6, 3300,  250,  'Sweets',                    1, 'Dine-In',       20, 25),
    ('Theobroma',                   4.6, 2900,  400,  'Bakery, Desserts',          1, 'Dine-In',       20, 25),
    ('Jaspers Indian Soulfood',     4.5, NULL,  400,  'Continental, American',     1, 'Dine-In',       NULL, NULL),
    ('Luscious Layers',             4.4,10000,  350,  'Desserts, Cakes',           1, 'Dine-In',       30, 35),
    ('McDonald''s',                 4.4, 2800,  400,  'Fast Food',                 1, 'Dine-In',       35, 40),
    ('Tamayo The Restro Cafe',      4.4, NULL,  600,  'Continental, Beverages',    1, 'Dine-In',       NULL, NULL),
    ('Caffeine Nova',               4.3,  176,  700,  'Beverages, Continental',    1, 'Dine-In',       NULL, NULL),
    ('Lariff Kitchen & Cocktails',  4.3, 1400, 1400,  'North Indian',              1, 'Dine-In',       NULL, NULL),
    ('The Lolo Cafe',               4.3,  162,  500,  'Italian, South Indian',     1, 'Dine-In',       NULL, NULL),
    ('Oven Story Pizza',            4.2, 9300,  400,  'Pizza, Pasta',              1, 'Dine-In',       35, 40),
    ('Renaissance Cafe',            4.2, 3000,  500,  'North Indian, South Indian',1, 'Dine-In',       NULL, NULL),
    ('Cafe Coffee Day',             4.1, 1000, 1000,  'Fast Food',                 1, 'Dine-In',       NULL, NULL),
    ('KFC',                         4.1, 9700,  400,  'Fast Food',                 1, 'Dine-In',       25, 30),
    ('Airbar',                      4.0, 1000, 1000,  'North Indian, South Indian',1, 'Dine-In',       NULL, NULL),
    ('Banjos The Food Chain',       4.0, NULL,  350,  'Fast Food, Finger Food',    1, 'Dine-In',       NULL, NULL),
    ('Hotel Wansh',                 4.0,  800, NULL,  'Middle Eastern',            1, 'Dine-In',       NULL, NULL),
    ('Junior''s Kitchen',           4.0,  700, NULL,  'Asian, Italian',            1, 'Dine-In',       NULL, NULL),
    ('Tushar Food Hub',             4.0, 9200,  300,  'Maharashtrian, Chinese',    1, 'Dine-In',       30, 35),
    ('Domino''s Pizza',             3.9, 9200,  700,  'Pizza, Italian',            1, 'Dine-In',       20, 25),
    ('The Woodfired Eatery',        3.9, NULL,  500,  'Fast Food',                 1, 'Dine-In',       NULL, NULL),
    ('Flavor Oasis',                3.8,  300, NULL,  'Chinese, North Indian',     1, 'Dine-In',       NULL, NULL),
    ('Lazeez Darbar',               3.7, NULL, NULL,  'North Indian, Middle Eastern',1,'Dine-In',      NULL, NULL),
    ('Amritsari Haveli',            3.2,  124, 1400,  'North Indian, Continental', 1, 'Dine-In',       NULL, NULL);

-- Populate junction table using FIND_IN_SET so IDs don't
-- need to be hardcoded. Handles multi-cuisine strings cleanly.
INSERT INTO restaurant_cuisines (restaurant_id, cuisine_id)
SELECT r.restaurant_id, c.cuisine_id
FROM   restaurants r
JOIN   cuisines c
       ON FIND_IN_SET(c.cuisine_name, REPLACE(r.cuisines, ', ', ',')) > 0;

INSERT INTO menu_categories (category_name) VALUES
    ('Burgers'),          ('Chicken Snacks'),   ('Rice & Bowls'),
    ('Combos'),           ('Beverages'),        ('Desserts'),
    ('McSavers'),         ('Wraps'),            ('Sides & Fries'),
    ('McCafé'),           ('Happy Meals'),      ('Pizzas'),
    ('Pastas'),           ('Sides'),            ('Signature Pizzas'),
    ('Classic Pizzas'),   ('Garlic Breads'),    ('Brownies & Cookies'),
    ('Cakes & Slices'),   ('Pastries'),         ('Breads & Croissants'),
    ('Hot Beverages'),    ('Cold Beverages');

-- KFC menu (10 items)
INSERT INTO menu_items (restaurant_id, category_id, item_name, price, is_bestseller) VALUES
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'KFC' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Burgers' LIMIT 1),
    'Zinger Burger', 249, 1
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'KFC' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Burgers' LIMIT 1),
    'Crunch Burger', 199, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'KFC' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Burgers' LIMIT 1),
    'Tower Burger', 349, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'KFC' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Chicken Snacks' LIMIT 1),
    'Hot & Crispy Chicken (2 pcs)', 299, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'KFC' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Chicken Snacks' LIMIT 1),
    'Popcorn Chicken (Regular)', 179, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'KFC' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Chicken Snacks' LIMIT 1),
    'Chicken Strips (3 pcs)', 249, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'KFC' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Rice & Bowls' LIMIT 1),
    'Chicken Rice Bowl', 249, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'KFC' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Combos' LIMIT 1),
    'Zinger Burger + Fries + Pepsi (M)', 429, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'KFC' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Beverages' LIMIT 1),
    'Pepsi (Large)', 89, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'KFC' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Desserts' LIMIT 1),
    'Chocolate Mousse Cake', 99, 0
),

-- McDonald's menu (10 items)
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'McDonald''s' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Burgers' LIMIT 1),
    'McAloo Tikki Burger', 49, 1
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'McDonald''s' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Burgers' LIMIT 1),
    'McSpicy Paneer Burger', 199, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'McDonald''s' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Burgers' LIMIT 1),
    'McSpicy Chicken Burger', 219, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'McDonald''s' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Burgers' LIMIT 1),
    'Big Mac (Chicken)', 249, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'McDonald''s' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'McSavers' LIMIT 1),
    'Small Fries', 49, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'McDonald''s' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Wraps' LIMIT 1),
    'Chicken Mexican McWrap', 219, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'McDonald''s' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Sides & Fries' LIMIT 1),
    'Medium Fries', 89, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'McDonald''s' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Sides & Fries' LIMIT 1),
    'Piri Piri Sprinkled Fries (M)', 129, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'McDonald''s' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'McCafé' LIMIT 1),
    'Cappuccino (Medium)', 179, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'McDonald''s' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Happy Meals' LIMIT 1),
    'McAloo Tikki Happy Meal', 199, 0
),

-- Pizza Hut menu (10 items)
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'Pizza Hut' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Pizzas' LIMIT 1),
    'Margherita (Medium)', 249, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'Pizza Hut' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Pizzas' LIMIT 1),
    'Chicken Tikka Pizza (Medium)', 449, 1
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'Pizza Hut' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Pizzas' LIMIT 1),
    'Veggie Paradise Pizza (Medium)', 379, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'Pizza Hut' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Pizzas' LIMIT 1),
    'Non-Veg Supreme Pizza (Large)', 699, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'Pizza Hut' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Pizzas' LIMIT 1),
    'Farmhouse Pizza (Medium)', 399, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'Pizza Hut' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Pastas' LIMIT 1),
    'Penne Arrabiata', 229, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'Pizza Hut' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Sides' LIMIT 1),
    'Garlic Breadsticks (4 pcs)', 149, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'Pizza Hut' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Sides' LIMIT 1),
    'Stuffed Garlic Bread', 229, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'Pizza Hut' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Beverages' LIMIT 1),
    'Pepsi (1.25 L)', 109, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'Pizza Hut' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Desserts' LIMIT 1),
    'Choco Lava Cake', 149, 0
),

-- Oven Story Pizza menu (10 items)
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'Oven Story Pizza' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Signature Pizzas' LIMIT 1),
    'Sausage Party Pizza (Medium)', 549, 1
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'Oven Story Pizza' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Signature Pizzas' LIMIT 1),
    'Spicy Margherita (Medium)', 399, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'Oven Story Pizza' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Signature Pizzas' LIMIT 1),
    'The Mexican Chicken (Medium)', 529, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'Oven Story Pizza' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Classic Pizzas' LIMIT 1),
    'Margherita (Medium)', 299, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'Oven Story Pizza' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Classic Pizzas' LIMIT 1),
    'Farmhouse Veggie (Medium)', 449, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'Oven Story Pizza' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Pastas' LIMIT 1),
    'Arrabbiata Penne', 249, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'Oven Story Pizza' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Pastas' LIMIT 1),
    'Creamy Mushroom Pasta', 279, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'Oven Story Pizza' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Garlic Breads' LIMIT 1),
    'Herb & Cheese Garlic Bread', 179, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'Oven Story Pizza' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Beverages' LIMIT 1),
    'Cold Coffee (Regular)', 129, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'Oven Story Pizza' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Combos' LIMIT 1),
    '2 Medium Pizzas + Garlic Bread Combo', 999, 0
),

-- Theobroma menu (10 items)
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'Theobroma' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Brownies & Cookies' LIMIT 1),
    'Chocolate Brownie (1 pc)', 99, 1
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'Theobroma' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Cakes & Slices' LIMIT 1),
    'Chocolate Truffle Cake Slice', 199, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'Theobroma' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Cakes & Slices' LIMIT 1),
    'Red Velvet Cake Slice', 219, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'Theobroma' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Cakes & Slices' LIMIT 1),
    'Blueberry Cheesecake Slice', 249, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'Theobroma' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Pastries' LIMIT 1),
    'Almond Croissant', 149, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'Theobroma' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Pastries' LIMIT 1),
    'Pain au Chocolat', 159, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'Theobroma' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Breads & Croissants' LIMIT 1),
    'Plain Croissant', 109, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'Theobroma' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Hot Beverages' LIMIT 1),
    'Café Latte (Regular)', 179, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'Theobroma' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Hot Beverages' LIMIT 1),
    'Hot Chocolate (Regular)', 189, 0
),
(
    (SELECT restaurant_id FROM restaurants WHERE restaurant_name = 'Theobroma' LIMIT 1),
    (SELECT category_id   FROM menu_categories WHERE category_name = 'Cold Beverages' LIMIT 1),
    'Iced Caramel Latte', 219, 0
);


-- ============================================================
-- SECTION 3: ANALYSIS QUERIES
-- ============================================================

-- Q1: Top 5 highest-rated restaurants
-- Ties broken by review count (higher = more reliable rating).
-- Restaurants with no reviews go to the bottom.

SELECT
    r.restaurant_name,
    r.rating
FROM restaurants r
ORDER BY
    r.rating DESC,
    (r.number_of_reviews IS NULL) ASC,
    r.number_of_reviews DESC
LIMIT 5;

-- Q2: Average cost-for-two by cuisine
-- Joins through the junction table so "Pizza, Italian"
-- contributes to both cuisine averages separately — not just
-- the first one in the string. NULLs excluded from the average.

SELECT
    c.cuisine_name                    AS cuisine,
    COUNT(DISTINCT rc.restaurant_id)  AS restaurant_count,
    ROUND(AVG(r.cost_for_two), 0)     AS avg_cost_for_two_inr
FROM cuisines c
JOIN restaurant_cuisines rc ON rc.cuisine_id    = c.cuisine_id
JOIN restaurants r          ON r.restaurant_id  = rc.restaurant_id
WHERE r.cost_for_two IS NOT NULL
GROUP BY c.cuisine_id, c.cuisine_name
ORDER BY avg_cost_for_two_inr DESC;

-- Q3: Restaurants with more than one cuisine tag
-- Uses the junction table count rather than string-splitting,
-- which is cleaner and index-friendly.

SELECT
    r.restaurant_name,
    r.restaurant_type,
    COUNT(rc.cuisine_id)  AS cuisine_count,
    GROUP_CONCAT(c.cuisine_name ORDER BY c.cuisine_name SEPARATOR ', ')
                          AS cuisines_list
FROM restaurants r
JOIN restaurant_cuisines rc ON rc.restaurant_id = r.restaurant_id
JOIN cuisines c             ON c.cuisine_id     = rc.cuisine_id
GROUP BY r.restaurant_id, r.restaurant_name, r.restaurant_type
HAVING COUNT(rc.cuisine_id) > 1
ORDER BY cuisine_count DESC, r.restaurant_name;

-- Q4: Highest-priced menu item
-- Subquery finds the global max; outer query pulls full context.
-- If two items share the max price, both rows come back —
-- no arbitrary filtering.

SELECT
    r.restaurant_name,
    mc.category_name AS category,
    mi.item_name,
    mi.price         AS price_inr
FROM menu_items mi
JOIN restaurants    r  ON r.restaurant_id = mi.restaurant_id
JOIN menu_categories mc ON mc.category_id = mi.category_id
WHERE mi.price = (SELECT MAX(price) FROM menu_items)
ORDER BY r.restaurant_name;

-- BONUS Q5: Marked bestseller per restaurant

SELECT
    r.restaurant_name,
    mc.category_name  AS category,
    mi.item_name      AS bestseller_item,
    mi.price          AS price_inr
FROM menu_items mi
JOIN restaurants     r  ON r.restaurant_id = mi.restaurant_id
JOIN menu_categories mc ON mc.category_id  = mi.category_id
WHERE mi.is_bestseller = 1
ORDER BY mi.price DESC;

-- BONUS Q6: Cloud kitchen vs Dine-In comparison
-- Segments key metrics by restaurant type for the
-- business analysis section of the report.

SELECT
    restaurant_type,
    COUNT(*)                         AS total_restaurants,
    ROUND(AVG(rating), 2)            AS avg_rating,
    ROUND(AVG(number_of_reviews), 0) AS avg_reviews,
    ROUND(AVG(cost_for_two), 0)      AS avg_cost_for_two,
    ROUND(AVG(delivery_time_min), 0) AS avg_delivery_min_minutes
FROM restaurants
GROUP BY restaurant_type
ORDER BY avg_rating DESC;
