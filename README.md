# Government-Spend-Data-Warehouse-T-SQL-ETL-Tableau
Designed and implemented a T-SQL based dimensional data warehouse for UK government expenditure, enabling advanced analytical queries and Tableau reporting for supplier and expense trend analysis

# Government Spend Data Warehouse & Analytics (T-SQL)

## Project Overview
This project designs and implements a prototype data warehouse for analyzing UK government expenditure data using Kimball’s Dimensional Modeling methodology. The solution covers end-to-end ETL, analytical querying with stored procedures, and business intelligence reporting.

## Data Source
- UK Government Spend over £25,000 dataset
- Department for Business, Innovation and Skills
- Period covered: April 2015 – March 2016
- Multiple monthly CSV files

## Data Warehouse Design
- Dimensional modeling using **Kimball methodology**
- Star schema implementation, including:
  - Fact table for invoice-level spend
  - Dimension tables for suppliers, expense types, expense areas, and time
- Time hierarchy designed to support month and period-based analysis

## ETL & Data Transformation (T-SQL)
- ETL implemented entirely using **T-SQL**
- Monthly datasets merged and cleansed
- Data quality handling:
  - Negative amounts retained as valid refunds
  - Invalid suppliers removed using XML-based filtering
  - Sensitive supplier names replaced with anonymized identifiers
- Transformations applied during load into star schema tables

## Analytical Queries & Stored Procedures
Four advanced analytical queries implemented as stored procedures:
1. Top three suppliers by total spend (overall and monthly)
2. Expense types exceeding the average two-month spend, exported as JSON
3. Monthly top 10 expense areas with ranking movement analysis
4. Custom time-based supplier analysis query, exported as CSV

## Business Intelligence Dashboard
- Dashboard built in **Power BI**
- Single consolidated view combining all analytical queries
- Visual storytelling focused on:
  - Supplier performance
  - Expense trends
  - Temporal spending patterns

## Technologies Used
- Microsoft SQL Server
- T-SQL (Stored Procedures, ETL, XML, JSON, CSV)
- Dimensional Modeling (Kimball)
- Tableau

## Key Outcomes
- Fully functional analytical data warehouse
- Complex T-SQL transformations and procedures
- Business-ready dashboard supporting decision-making

## Academic Context
This project was developed as part of the **CSI-7-DAT: Data Management** module coursework.
