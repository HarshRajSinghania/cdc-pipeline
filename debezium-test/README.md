# Exercise 1 — CDC with Debezium Server and PostgreSQL (solution)

Log-based Change Data Capture from PostgreSQL with a standalone Debezium Server,
no Kafka cluster involved.

```
PostgreSQL 15 (wal_level=logical)
        │  logical replication slot "debezium" (pgoutput)
        ▼
Debezium Server 2.5.4.Final
        │  Redis sink
        ▼
Redis 7 stream  tutorial.public.products
        │  export-events.py
        ▼
cdc-output/cdc_events.json   (one change event per line)
```

## Deviation from the statement: no `file` sink

The exercise asks for `debezium.sink.type=file` writing to
`/debezium/data/cdc_events.json`. **Debezium Server 2.5 does not ship a file
sink.** The sink modules available at `v2.5.0.Final` are `kafka`, `kinesis`,
`pubsub`, `pulsar`, `eventhubs`, `redis`, `http`, `nats-streaming`,
`nats-jetstream`, `pravega`, `rabbitmq`, `rocketmq`, `sqs` and `infinispan`.
Configuring `file` makes the server fail on startup.

Redis is used instead — still a single lightweight container, no Kafka — and
[`export-events.py`](./export-events.py) dumps the Redis stream to
`cdc-output/cdc_events.json` so that Step 6 of the exercise can be carried out
exactly as written.

## Files

| File | Purpose |
| --- | --- |
| [`docker-compose.yml`](./docker-compose.yml) | PostgreSQL + Redis + Debezium Server |
| [`debezium-conf/application.properties`](./debezium-conf/application.properties) | Source (PostgreSQL) and sink (Redis) connector configuration |
| [`sql/01-products-mutations.sql`](./sql/01-products-mutations.sql) | Step 5: table creation + INSERT / UPDATE / DELETE |
| [`export-events.py`](./export-events.py) | Dumps the Redis stream to `cdc-output/cdc_events.json` |
| `cdc-output/cdc_events.json` | Captured change events, one JSON document per line |
| `cdc-output/offsets.dat` | Debezium offset storage (last committed LSN) |

Two configuration details worth noting:

* `ALTER TABLE products REPLICA IDENTITY FULL` — with the default replica
  identity PostgreSQL only writes the primary key to the WAL for UPDATE/DELETE,
  so the `before` block would contain nothing but `id`. `FULL` logs the whole
  old row.
* `debezium.source.decimal.handling.mode=double` — otherwise `price` is emitted
  as a Kafka Connect `Decimal`, i.e. base64 bytes (`"Cic="` instead of `25.99`).

## How to run

```bash
docker compose up -d
docker compose ps

# wait until Debezium has created the replication slot
docker logs -f debezium_server

# Step 5: create the table and trigger the mutations
docker exec -i postgres_source psql -U postgres -d inventory_db -v ON_ERROR_STOP=1 < sql/01-products-mutations.sql

# Step 6: export and inspect the captured events
python export-events.py
```

Teardown: `docker compose down -v`.

## Step 6 — captured events

`XLEN tutorial.public.products` returns **4** events, one per mutation:

| `op` | Operation | `before` | `after` |
| --- | --- | --- | --- |
| `c` | CREATE | `null` | `id=1, Wireless Mouse, price=25.99` |
| `c` | CREATE | `null` | `id=2, Mechanical Keyboard, price=89.99` |
| `u` | UPDATE | `id=1, price=25.99` | `id=1, price=22.99` |
| `d` | DELETE | `id=2, price=89.99` | `null` |

The UPDATE event, as stored in `cdc-output/cdc_events.json`:

```json
{
  "before": { "id": 1, "name": "Wireless Mouse", "price": 25.99, "created_at": 1786981502839123 },
  "after":  { "id": 1, "name": "Wireless Mouse", "price": 22.99, "created_at": 1786981502839123 },
  "source": {
    "version": "2.5.4.Final", "connector": "postgresql", "name": "tutorial",
    "snapshot": "false", "db": "inventory_db", "schema": "public", "table": "products",
    "txId": 732, "lsn": 26596432
  },
  "op": "u",
  "ts_ms": 1786981503208
}
```

Observations:

* Each event carries a `schema` block plus a `payload` block; `payload` holds
  `before` / `after` / `source` / `op` / `ts_ms`.
* `before` is `null` for INSERTs and `after` is `null` for DELETEs — the state
  that did not exist at that point in time.
* `source.lsn` and `source.txId` tie the event to a WAL position and a
  PostgreSQL transaction; the same LSN is what ends up in `offsets.dat`, and it
  is how Debezium resumes without replaying events after a restart.
* `ts_ms` at the top level is when Debezium processed the event, while
  `source.ts_ms` is when the change was committed in the database. The gap
  between them is the CDC latency (~360 ms here, dominated by the connector
  poll interval).
* No `r` (snapshot read) events appear: the table was created after the
  connector started, so everything came through the streaming phase.
* `tombstones.on.delete=false` is set — otherwise each DELETE would be followed
  by a second record with an empty payload, which the Redis sink would store as
  a noise entry.

---
[⬅ Back to Module 2 README](../README.md)
