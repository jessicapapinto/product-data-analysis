## Product Data Analysis
*SQL Server Analysis & Power BI Dashboard*

# Product Catalog | Data Quality & Business Analysis

# 1. Introduction

Product data plays an important role in how companies manage and distribute product information across brands, categories, suppliers and sales channels.
This project analyzes a synthetic product database designed to simulate a real-world Product Data environment.
The analysis uses SQL Server to explore the database, assess data quality, define relevant metrics and investigate patterns across the product catalog.
Power BI will then be used to visualize the main findings. 
The goal is to understand the state of the product catalog, identify data quality and publication issues, and transform product data into insights that can support operational and business decisions.

# 2. Business Context

Organizations managing large product catalogs need accurate, complete and consistent product information.
Product data can involve multiple dimensions, including product classification, brands, attributes, suppliers, inventory, pricing and publication across different channels.
Poor or incomplete product information can prevent products from being published successfully and create operational inefficiencies.
This project simulates the role of a Product Data Analyst responsible for exploring this data, monitoring its quality and identifying opportunities to improve the product information management process.

# 3. Dataset Description

The project uses `ProductDataTraining`, a synthetic Microsoft SQL Server database created for data analysis training and portfolio purposes.
The database simulates a product information environment containing interconnected data related to areas such as:
- Products
- Brands and categories
- Product attributes and variants
- Suppliers
- Inventory
- Sales channels
- Product images
- Product data issues
- Data validation rules

The database is organized into four main schemas:
| Schema | Description |
| Catalog | Brands, categories and other reference information |
| Product | Core product records, variants, attributes and images |
| Commerce | Inventory and product publication across sales channels |
| DataQuality | Validation rules and detected product data issues |
The database does not contain real company, customer, employee or proprietary data.

# 4. Analysis Objectives

The analysis focuses on understanding the product catalog and evaluating the quality and readiness of product information.
The main objectives are to:
1. Understand the structure and composition of the product catalog.
2. Assess the completeness and quality of product information.
3. Identify products with unresolved data issues.
4. Evaluate product readiness and publication status across channels.
5. Explore patterns across brands, categories and suppliers.
6. Identify areas where product data quality or operational processes could be improved.

# 5. SQL Analysis

# 5.1 Catalog Structure and Pricing

The catalog analysis examines how products are distributed across brands and categories and explores the main pricing patterns.
The analysis includes:
- Products and their associated brands and categories
- Average product price by brand
- Brand share of the total catalog
- Global product price ranking
- Product price ranking within each category
- Difference between each product price and its category average
- Comparison with the previous product price inside the same category

# 5.2 Product Data Completeness

Completeness checks are used to identify products that may not contain all the information required for publication or sale.
The analysis includes:
- Products without an image record
- Image records with a missing URL
- Product variants with a missing GTIN
- Products without related catalog records

# 5.3 Data Quality Issues

Detected product issues are connected to their validation rules to understand their volume, distribution and severity.
The analysis includes:
- Data quality issue volume by validation rule and severity
- Open issues by product category
- Products affected by two or more validation rules
- Products with the greatest number of high-severity issues
- Catalog products with and without recorded data quality issues

# 5.4 Inventory Analysis

Inventory data is analyzed to identify availability issues and estimate the value represented by the current stock.
The analysis includes:
- Products with zero stock
- Total estimated inventory value
- Categories with the highest total stock quantity

# 5.5 Channel Publication Analysis

Product publication records are analyzed to understand how successfully products are reaching different sales channels.
The analysis includes:
- Products available on Amazon but not on Walmart
- Publication rate by channel
- Rejection rate by channel
- Brands performing below the overall Amazon publication rate
- Published products with recorded data quality issues
- Products that have not yet reached `Published` status

# 6. SQL Techniques

The project demonstrates the use of:
`INNER JOIN` and `LEFT JOIN`
`WHERE`, `GROUP BY` and `HAVING`
Aggregations with `COUNT()`, `SUM()` and `AVG()`
Conditional aggregation with `CASE`
Subqueries and common table expressions (CTEs)
Window functions such as `ROW_NUMBER()`, `AVG() OVER()` and `LAG()`
`EXISTS` and `NOT EXISTS`
Variables, rankings and percentage calculations

# 7. Repository Structure

```text
.
├── README.md
├── dProductDataTraining.bak
├── product-catalog-analysis.sql
└── product-catalog-dashboard.pbix
```
`README.md` provides an overview of the project, business context, dataset, analysis objectives and methodology.
`dProductDataTraining.bak` contains a backup of the synthetic SQL Server database used in the project, allowing the analysis to be reproduced and the underlying data to be explored.
`product-catalog-analysis.sql` contains the SQL queries used to explore, validate and analyse the product data.
`product-catalog-dashboard.pbix` contains the interactive Power BI dashboard and its visual analysis.

# 8. Tools

Microsoft SQL Server — database management and analysis
Power BI — dashboard development and data visualization

# 9. Limitations

The database contains synthetic data and does not represent the performance of a real organization.
Publication status shows the workflow outcome but does not always explain the reason for a rejection or delay.
A recorded issue indicates a potential data quality problem that may require further investigation.
Base price is used to estimate inventory value and may not represent the final selling price.

# 10. Next Steps

- Add the database creation and population script to the repository
- Validate the final queries against the complete database schema
- Develop an interactive Power BI dashboard
- Document the main findings and operational recommendations
