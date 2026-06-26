# Exercise 1: Change Data Capture (CDC) with Debezium Server and PostgreSQL

## Objective
In this exercise, you will set up a standalone instance of **Debezium Server** to capture changes (CDC) from a PostgreSQL database in real-time. Instead of using a full Kafka cluster, Debezium Server will write the captured events directly into a local JSON file sink. This lightweight setup is perfect for understanding the mechanics of log-based CDC.

## Prerequisites
*   [Docker](https://www.docker.com/) and Docker Compose installed.
*   A terminal/command line interface.
*   A database client (or simply use `psql` inside the container).

---

## Step-by-Step Implementation

### Step 1: Set Up the Directory Structure
Create a directory on your machine for this exercise (e.g., `debezium-test`) and navigate into it:
```bash
mkdir debezium-test
cd debezium-test
```

### Step 2: Create the `docker-compose.yml`
Create a `docker-compose.yml` file in your directory and add the following configuration:

```yaml
version: '3.8'

services:
  # 1. The Source Database
  postgres:
    image: postgres:15-alpine
    container_name: postgres_source
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=inventory_db
    # CRITICAL: PostgreSQL must be configured with logical replication enabled for Debezium to work
    command: ["postgres", "-c", "wal_level=logical"]
    volumes:
      - pgdata:/var/lib/postgresql/data

  # 2. Debezium Server (Standalone, no Kafka required for this quick test)
  debezium:
    image: debezium/server:2.5
    container_name: debezium_server
    volumes:
      - ./debezium-conf:/debezium/conf
      - ./cdc-output:/debezium/data
    depends_on:
      - postgres

volumes:
  pgdata:
```

### Step 3: Create `application.properties`
Debezium Server requires a configuration file to define the source connector (PostgreSQL) and the sink connector (file output).

1. Create a directory named `debezium-conf` next to your `docker-compose.yml`:
   ```bash
   mkdir debezium-conf
   ```
2. Create a file named `application.properties` inside the `debezium-conf` folder and populate it with the following configuration:

```properties
# Sink configuration: Write to local files
debezium.sink.type=file
debezium.sink.file.filename=/debezium/data/cdc_events.json

# Source configuration: PostgreSQL Connector
debezium.source.connector.class=io.debezium.connector.postgresql.PostgresConnector
debezium.source.offset.storage.file.filename=/debezium/data/offsets.dat

# Database connection credentials
debezium.source.database.hostname=postgres
debezium.source.database.port=5432
debezium.source.database.user=postgres
debezium.source.database.password=postgres
debezium.source.database.dbname=inventory_db

# Prefix used to form the names of Kafka topics (or output stream names)
debezium.source.topic.prefix=tutorial
debezium.source.plugin.name=pgoutput
```

### Step 4: Start the Environment
Run Docker Compose in detached mode to start both PostgreSQL and Debezium Server:
```bash
docker-compose up -d
```
Verify that both containers are running:
```bash
docker-compose ps
```
*(Optional) You can inspect the Debezium Server logs to ensure it has successfully connected to PostgreSQL:*
```bash
docker logs -f debezium_server
```

### Step 5: Create a Table & Trigger Mutations
Now, connect to the PostgreSQL instance to create a table and execute some transactions.

1. **Connect to PostgreSQL using psql inside the container**:
   ```bash
   docker exec -it postgres_source psql -U postgres -d inventory_db
   ```
2. **Create a `products` table**:
   ```sql
   CREATE TABLE products (
       id SERIAL PRIMARY KEY,
       name VARCHAR(255) NOT NULL,
       description TEXT,
       price DECIMAL(10, 2) NOT NULL,
       created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
   );
   ```
3. **Insert a few records**:
   ```sql
   INSERT INTO products (name, description, price) VALUES ('Wireless Mouse', 'Ergonomic 2.4G mouse', 25.99);
   INSERT INTO products (name, description, price) VALUES ('Mechanical Keyboard', 'RGB mechanical keyboard', 89.99);
   ```
4. **Update a record**:
   ```sql
   UPDATE products SET price = 22.99 WHERE name = 'Wireless Mouse';
   ```
5. **Delete a record**:
   ```sql
   DELETE FROM products WHERE name = 'Mechanical Keyboard';
   ```
6. **Exit the psql console**:
   ```sql
   \q
   ```

### Step 6: Verify Captured Events
1. In your project directory, check that the `cdc-output` folder has been generated:
   ```bash
   ls -la cdc-output/
   ```
2. Open the file `cdc-output/cdc_events.json` to inspect the generated CDC records.
3. **Analyze the event structures**:
   *   Notice the structure of the JSON events. Debezium outputs complex schemas representing the change event.
   *   Look for the `"op"` field, which indicates the operation:
       *   `"c"` for **Create** (INSERTs)
       *   `"u"` for **Update** (UPDATEs)
       *   `"d"` for **Delete** (DELETEs)
   *   Examine the `"before"` and `"after"` blocks within the payload to see how the row states changed over time.

---
[⬅ Back to Module 2 README](./README.md)
