-- Step 5 of the exercise: create the table and trigger the mutations that
-- Debezium captures from the PostgreSQL write-ahead log.

CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- With the default REPLICA IDENTITY, the WAL only carries the primary key for
-- UPDATE/DELETE, so the "before" block of those events would contain just `id`.
-- FULL makes PostgreSQL log the whole old row, which is what Step 6 asks to
-- inspect.
ALTER TABLE products REPLICA IDENTITY FULL;

-- op = "c" (create)
INSERT INTO products (name, description, price) VALUES ('Wireless Mouse', 'Ergonomic 2.4G mouse', 25.99);
INSERT INTO products (name, description, price) VALUES ('Mechanical Keyboard', 'RGB mechanical keyboard', 89.99);

-- op = "u" (update)
UPDATE products SET price = 22.99 WHERE name = 'Wireless Mouse';

-- op = "d" (delete)
DELETE FROM products WHERE name = 'Mechanical Keyboard';

CREATE SCHEMA IF NOT EXISTS analytics;

CREATE TABLE IF NOT EXISTS analytics.products_enriched (
    id              INTEGER PRIMARY KEY,
    name            VARCHAR(255) NOT NULL,
    description     TEXT,
    price           NUMERIC(10,2) NOT NULL,
    price_with_vat  NUMERIC(10,2) NOT NULL,
    category        VARCHAR(50),
    created_at      TIMESTAMPTZ,
    -- metadatos de linaje CDC
    source_lsn      BIGINT NOT NULL,
    last_op         CHAR(1) NOT NULL,
    is_deleted      BOOLEAN NOT NULL DEFAULT FALSE,
    ingested_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
