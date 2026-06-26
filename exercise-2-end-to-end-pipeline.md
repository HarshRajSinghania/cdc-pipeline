# Exercise 2: End-to-End Data Flow Pipeline

## 🏆 Project Objective
The goal of this project is to design, build, and deploy a fully functional, end-to-end data pipeline that ingests, processes, stores, and exposes a dataset (either batch or real-time).

*   **Core Flow**: Ingest data from a selected source, perform batch or real-time stream processing (cleaning/enrichment), and persist it to a structured storage layer.
*   **Data Exposure**: Build and expose a public REST or gRPC endpoint to retrieve the processed results.
*   **Deployment**: Deploy the entire stack using Docker containers or cloud services (AWS, Azure, GCP).

---

## ⚙️ Infrastructure & Setup

*   **Student Choice**: Select any ingestion tools (e.g., CDC/Debezium, Apache Kafka, Apache NiFi), processing engines (e.g., Apache Spark, Apache Flink, Node.js, Python), and storage layers (e.g., SQL/PostgreSQL, NoSQL/MongoDB, Lakehouse/Iceberg).
*   **Autonomy**: Choose between local orchestration (using `docker-compose`) or cloud-native infrastructure.
*   **Non-Functional Requirements (NFRs)**: Ensure network connectivity and access rules are correctly configured between layers (e.g., container networks, security groups).

---

## 📤 Project Deliverables

1.  **Deliverable 1: Architectural Diagram**
    *   An architectural diagram illustrating the components, data flows, and connections.
2.  **Deliverable 2: Code Repository**
    *   A clean codebase containing deployment configuration files (e.g., `Dockerfile`s, `docker-compose.yml`) and ingestion/processing scripts.
3.  **Deliverable 3: API Verification**
    *   A working API endpoint URL (or local `curl` command verification instructions) that returns the stored query results in JSON.

---
[⬅ Back to Module 2 README](./README.md)
