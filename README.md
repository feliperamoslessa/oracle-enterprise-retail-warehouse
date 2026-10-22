# Enterprise Retail Data Warehouse

### Oracle Autonomous Database | SQL | PL/SQL | Data Engineering

An end-to-end data engineering portfolio project focused on designing and implementing an enterprise-style retail data warehouse using Oracle Autonomous Database on Oracle Cloud Infrastructure (OCI).

The project uses the Brazilian E-Commerce Public Dataset by Olist to explore data quality, dimensional modeling, ETL development, analytical SQL, and database performance optimization.

## Project Objectives

- Analyze and validate raw e-commerce datasets.
- Design a dimensional data warehouse with fact and dimension tables.
- Develop auditable ETL pipelines using Oracle SQL and PL/SQL.
- Implement data quality and reconciliation checks.
- Optimize analytical queries using indexing and execution plans.
- Deliver business insights through SQL analytics and reporting.

## Technology Stack

- **Database:** Oracle Autonomous Database (OCI)
- **SQL Development:** Oracle SQL Developer
- **Data Processing:** Python, Pandas
- **ETL:** SQL and PL/SQL
- **Modeling:** Star Schema / Dimensional Modeling
- **Version Control:** Git and GitHub

## Data Source

Brazilian E-Commerce Public Dataset by Olist

https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

The dataset contains anonymized Brazilian marketplace transactions, including orders, customers, products, payments, sellers, reviews, and geolocation data.

The original dataset is not redistributed in this repository.

## Architecture

Planned data flow:

`Olist CSVs → Data Profiling → Oracle Staging → PL/SQL ETL → Dimensional Data Warehouse → Analytics`

## Project Status

**In progress — Data Profiling completed.**

Completed:
- Oracle Autonomous Database environment configuration.
- Dedicated `RETAIL_DW` database user.
- Initial SQL and PL/SQL validation.
- Data profiling across nine Olist CSV files.
- Initial investigation of data quality exceptions.

Next steps:
- Design staging tables and ingestion processes.
- Implement batch control and data reconciliation.
- Develop dimensional models and ETL procedures.
- Benchmark SQL query performance.
- Document business insights and architecture decisions.

## Repository Structure

```text
oracle-enterprise-retail-warehouse/
├── data/
├── docs/
├── scripts/
├── sql/
│   ├── 01_setup/
│   ├── 02_staging/
│   ├── 03_dimensions/
│   ├── 04_facts/
│   ├── 05_etl/
│   ├── 06_analytics/
│   └── 07_performance/
├── tests/
├── requirements.txt
├── .gitignore
└── README.md
```

## Data Quality Findings

Initial profiling identified:

- 775 orders without associated order items.
- 1 delivered order without a payment record.
- 2 product categories without English translations.
- 4 order items with shipping deadlines in 2019 or later.
- Repeated geolocation records and non-unique review identifiers.

These findings will inform the ETL quality rules and dimensional modeling decisions.

## Development Approach

The project is being implemented incrementally, with version-controlled SQL scripts, reproducible data processing, documented architectural decisions, and validation at each stage.

## Author

[Felipe Ramos Lessa](https://github.com/feliperamoslessa)
