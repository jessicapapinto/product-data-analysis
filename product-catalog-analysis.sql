/*
===============================================================================
                         PRODUCT DATA ANALYSIS
                          SQL Server Analysis
          Product Catalog | Data Quality & Business Analysis
===============================================================================

Database: ProductDataTraining
Purpose:  Explore the product catalog, data quality, inventory and channel
          publication data used in the Product Data Analysis project.

===============================================================================
*/


/*
===============================================================================
1. CATALOG EXPLORATION
===============================================================================
*/

-- Before assessing data quality, the catalog was explored to understand
-- its pricing structure, brand composition and channel coverage.
-- The analysis begins with broad catalog questions and then moves toward
-- product-level completeness and operational issues.

-- Products with a base price above 200

select p.*, b.BrandName, c.CategoryName
from Product.Products as p
left join Catalog.Brands b on b.BrandID = p.BrandID
left join Catalog.Categories c on c.CategoryID = p.CategoryID
where p.BasePrice > 200

-- Objective: identify products above the selected price threshold.
-- Critical observation: 200 is an analytical threshold rather than a
-- documented business rule. Products should also be compared within their
-- own categories before being considered unusually expensive.


-- Brands with an average product price above 435

select * from (
	select BrandName, avg(BasePrice) as avgPrice
	from Product.Products p
	left join Catalog.Brands b on b.BrandID = p.BrandID
	group by BrandName
) t1 
where avgPrice > 435

-- Objective: identify brands whose average BasePrice exceeds 435.
-- Critical observation: category average prices in this dataset are tightly
-- concentrated around 435. Small differences may therefore determine whether
-- a group appears above or below the threshold. The mean can also hide a wide
-- range of individual product prices.


--------------------------


-- Products available on Amazon but not on Walmart

select distinct p.ProductID
from Product.Products p
left join Commerce.ProductChannels pc on pc.ProductID = p.ProductID
left join Commerce.Channels c on c.ChannelID = pc.ChannelID
where c.ChannelName = 'Walmart'

select p.* 
from Product.Products p
left join Commerce.ProductChannels pc on pc.ProductID = p.ProductID
left join Commerce.Channels c on c.ChannelID = pc.ChannelID
where c.ChannelName = 'Amazon' AND p.ProductID NOT IN (
	
	select distinct p.ProductID
	from Product.Products p
	left join Commerce.ProductChannels pc on pc.ProductID = p.ProductID
	left join Commerce.Channels c on c.ChannelID = pc.ChannelID
	where c.ChannelName = 'Walmart'
)

-- Objective: identify products present on Amazon but absent from Walmart.
-- Business interpretation: a channel gap can indicate incomplete onboarding,
-- a deliberate assortment decision or a publication problem. The result
-- identifies the gap but does not establish which of these causes applies.


/*
===============================================================================
2. PRODUCT DATA COMPLETENESS
===============================================================================
*/

-- This section examines missing image and GTIN information. Both fields can
-- affect product identification, customer experience and channel publication.

-- produtos sem uma imagem primária

Select*
from product.productimages
where ImageURl is null

-- Objective: identify image records with a missing URL.
-- Critical observation: a NULL ImageURL confirms incomplete image information,
-- but does not by itself prove that the missing image is the primary image or
-- that the product has no other valid images.

Select*
From product.Products

Select productname, ImageURL
from product.Products as pp
Left join Product.ProductImages as ppi
on pp.ProductID =  ppi.ProductID
where ImageURl is null


-- produtos missing gtin

Select*
from Product.ProductVariants
where gtin is null

select distinct ProductId from Product.ProductVariants

-- Objective: identify variants with a missing GTIN and inspect the products
-- represented in the variants table.
-- Critical observation: the operational impact depends on whether GTIN is
-- mandatory for that product type and sales channel.


/*
===============================================================================
3. DATA QUALITY ANALYSIS
===============================================================================
*/

-- Product issues were connected to validation rules to understand which rule
-- generated each issue and how urgently it should be reviewed.

-- data quality issue by rule 

Select* 
From DataQuality.ProductIssues

Select*
from DataQuality.ValidationRules

select * from Product.ProductAttributeValues

Select *
From DataQuality.ProductIssues as dpi
left join DataQuality.ValidationRules as dvr
on dpi.RuleID = dvr.RuleID

-- Result: the recorded issues are associated with High and Medium severity
-- rules. High-severity issues represent missing information considered more
-- important by the validation process.
-- Business interpretation: severity supports issue prioritization, but it does
-- not measure the time, cost or complexity required to resolve each problem.


-- categorias com mais open issues

select*
from DataQuality.ProductIssues
where IssueStatus like 'open'

Select*
from Catalog.Categories

Select* 
from product.Products

select CategoryName, count (IssueStatus) as issues_status
from product.Products as pp
left join DataQuality.ProductIssues as dpi on pp.ProductID = dpi.ProductID
left join Catalog.Categories as cc on cc.CategoryID = pp.CategoryID
group by CategoryName
order by issues_status desc

-- Objective: compare the volume of recorded issues across categories.
-- Critical observation: total issue count should be considered together with
-- category size. A category with more products may have more issues while
-- still having a lower issue rate per product.


/*
===============================================================================
4. INVENTORY ANALYSIS
===============================================================================
*/

-- Inventory was reviewed separately from product content because a complete
-- product can still be unavailable for sale when its stock reaches zero.

-- products with zero stock

select ProductName, Quantity 
from Commerce.Inventory as ci
left join Product.Products as pp
on ci.ProductID = pp.ProductID
where Quantity = 0

-- Objective: identify products that are currently unavailable in inventory.
-- Critical observation: zero stock is an availability issue and should not be
-- interpreted automatically as a product data quality problem.


-- valor total do stock

Select*
from Product.Products

Select* 
from  Commerce.Inventory

Select sum (Quantity * BasePrice) as stock_price_by_product
from Product.Products as pp
left join Commerce.Inventory as ci
on pp.ProductID = ci.ProductID

-- Objective: estimate total inventory value using Quantity multiplied by
-- BasePrice.
-- Critical observation: BasePrice may differ from acquisition cost, discounted
-- price or final selling price. The result is therefore an estimate rather
-- than an accounting valuation or measure of profit.


/*
===============================================================================
5. PRODUCT RANKING AND PRICE ANALYSIS
===============================================================================
*/

-- Window functions were used to compare products while preserving each
-- individual product record in the result.

-- raw number com o ranking the price dos producto (mostart nome da categoria)

Select* 
from Catalog.Categories

select*
from Product.Products

Select ROW_NUMBER() OVER (ORDER BY BasePrice DESC) as ranking, categoryname, baseprice, ProductName
from Product.Products as pp
left join Catalog.Categories as cc
on pp.CategoryID = cc.CategoryID

-- Interpretation: the global ranking identifies the highest-priced records
-- across the complete catalog. Comparisons may be limited because products
-- from unrelated categories can appear next to each other.

-- 

Select ROW_NUMBER() OVER (partition by categoryname ORDER BY BasePrice DESC) as ranking, categoryname, baseprice, ProductName
from Product.Products as pp
left join Catalog.Categories as cc
on pp.CategoryID = cc.CategoryID

-- Interpretation: partitioning by category creates a more relevant ranking by
-- comparing each product only with products in the same category.


-- % marca no catálogo

select*
from Catalog.Brands

select* 
from Product.Products

Select *, count (productid) 
from Product.Products as pp
left join Catalog.Brands as cb
on pp.BrandID = cb.BrandID
group by BrandName

-- Interpretation: brand share represents assortment volume only. It does not
-- measure revenue, sales performance, stock value or customer demand.
 
DECLARE @numberOfProduct int
Select @numberOfProduct = count (productid) from Product.Products

Select 
	count (productid) as sum_products, 
	BrandName,
	(count (productid)*1.0 / @numberOfProduct)*100 as percentagem
from Product.Products as pp
left join Catalog.Brands as cb
on pp.BrandID = cb.BrandID
group by BrandName


-- Top 3 per categorie

select*
from Product.Products

select* 
from Catalog.Categories

Select*
from Commerce.Inventory

select top 3
	sum (Quantity) as products_quantity, CategoryName
from Product.Products as pp
left join Catalog.Categories as cc
on pp.CategoryID = cc.CategoryID
left join Commerce.Inventory as ci
on ci.ProductID = pp.ProductID
group by CategoryName
ORDER BY products_quantity DESC

-- Result:
-- Clothing: 203,580 units
-- Training: 203,556 units
-- Skincare: 202,582 units
-- Critical observation: these categories have the largest stock quantity,
-- not necessarily the highest inventory value or sales demand.


-- product price difference from category average

select*
from Product.Products

Select*
from Catalog.Categories

select productname, baseprice, CategoryName,
		AVG(BasePrice) OVER (PARTITION BY CategoryName) AS average_baseprice,
		baseprice - (AVG(BasePrice) OVER (PARTITION BY CategoryName)) as difference_price
from Product.Products as pp
left join Catalog.Categories as cc
on pp.CategoryID = cc.CategoryID


-- lag price comparison inside category 

-- Result: average category prices range only from approximately 434.82 to
-- 435.33.
-- Critical observation: the minimal difference between category averages is
-- consistent with the synthetic construction of the data. Distance from the
-- average can flag records for review but does not prove a pricing error.

select*
from Product.Products

select*
from Catalog.Categories

select productname, BasePrice, CategoryName,
	LAG (BasePrice) over (PARTITION BY CategoryName order by baseprice) AS previous_price
from Product.Products as pp
left join Catalog.Categories as cc
on pp.categoryid = cc.CategoryID
order by BasePrice asc, CategoryName

-- Objective: compare every product price with the preceding price within its
-- category. Large gaps may indicate outliers or missing price tiers.
-- Critical observation: LAG describes consecutive differences in the selected
-- order; it does not determine whether either price is commercially correct.


/*
===============================================================================
6. DATA QUALITY PRIORITIZATION
===============================================================================
*/

-- Severity and issue frequency were examined to identify products that may
-- require earlier operational review.

-- cte for data quality score

select*
from DataQuality.ProductIssues

select*
from DataQuality.ValidationRules

with cte as (
	select ProductID, Severity
	from DataQuality.ProductIssues as dp
	left join DataQuality.ValidationRules as dv
	on dp.RuleID = dv.RuleID
)

Select* 
From cte

-- Objective: prepare a temporary result containing each affected ProductID and
-- the severity of its validation issue.
-- Critical observation: the CTE organizes the data but does not independently
-- calculate a numerical data quality score.


-- 100 products with lowest score

select top 100
	dp.ProductID,
    COUNT(*) AS high_issues
from DataQuality.ProductIssues as dp
left join DataQuality.ValidationRules as dv
on dp.RuleID = dv.RuleID
where Severity = 'high'
group by dp.ProductID
order by high_issues

-- Result: 251 High-severity issue records were found. Most affected products
-- have one High issue, while ProductID 1591, 3182 and 4773 each have two.
-- Critical observation: many products are tied. A list limited to exactly 100
-- does not prove that products at the cut-off are worse than excluded products
-- with the same number of High issues.


-- products with issues in 2+ rule

select* 
from DataQuality.ProductIssues

select* 
from Product.Products

select ProductName, RuleID
from Product.Products as pp
left join DataQuality.ProductIssues dp
on pp.ProductID = dp.ProductID
where RuleID >= 2
order by RuleID

-- Critical observation: RuleID identifies the validation rule associated with
-- an issue. Its numeric value does not represent how many rules affect the
-- product, so repeated ProductID records must be considered when interpreting
-- products affected by multiple issues.


/*
===============================================================================
7. CHANNEL PUBLICATION ANALYSIS
===============================================================================
*/

-- Publication performance was assessed across Amazon, Walmart, Google
-- Shopping, Carrefour, Brand Website and Mobile App.

-- channel rejection rate. 

Select*
from Commerce.Channels

Select*
from Commerce.ProductChannels

select *
from Commerce.ProductChannels as cp
left join Commerce.Channels as cc
on cc.ChannelID = cp.ChannelID

select channelname, 
	count (*) as total_products_by_channel,
	SUM(CASE
            WHEN cp.PublicationStatus = 'rejected' THEN 1
            ELSE 0
        END
    ) AS rejected_products,
	(SUM (CASE
            WHEN cp.PublicationStatus = 'rejected' THEN 1
            ELSE 0
        END
    )*1.0/ count (*) * 100 ) as percentage_rejection
from Commerce.ProductChannels as cp
left join Commerce.Channels as cc
on cc.ChannelID = cp.ChannelID
group by channelname

-- Result: channel rejection rates range from approximately 5.25% to 5.27%.
-- Critical observation: the difference is minimal, so no channel stands out as
-- a substantially greater source of rejection. Rejection reasons would be
-- required to explain the affected product records.

select *
from Commerce.ProductChannels as cp
left join Commerce.Channels as cc
on cc.ChannelID = cp.ChannelID
where PublicationStatus = 'rejected'


-- publication rate by channel

Select *
from Commerce.Channels

Select*
from Commerce.ProductChannels

Select ChannelName,
	count (*) as total_product_by_channel,
	SUM(CASE
				WHEN cp.PublicationStatus = 'Published' THEN 1
				ELSE 0
			END) as published_products,
	(SUM(CASE
				WHEN cp.PublicationStatus = 'Published' THEN 1
				ELSE 0
			END)) *1.0 / count (*) *100 as percentage_published
from Commerce.Channels as cc
left join Commerce.ProductChannels as cp
on cc.ChannelID = cp.ChannelID
group by ChannelName

-- Result:
-- Mobile App:      82.3804%
-- Amazon:          82.3612%
-- Walmart:         82.3612%
-- Carrefour:       82.3612%
-- Brand Website:   82.3612%
-- Google Shopping: 82.3337%
-- Critical observation: publication performance is almost identical across
-- channels. This regularity is likely influenced by the synthetic dataset and
-- should not be treated as evidence of equal real-world performance.


-- brands below global amazon publication rate

select*
from Commerce.Channels

Select *
from Commerce.ProductChannels

Select*
From (
	Select ChannelName,
		count (*) as total_products,
		sum (case 
			when cp.publicationstatus = 'published' then 1
			else 0
			end) as publication_products,
		sum (case 
				when cp.publicationstatus = 'published' then 1
				else 0
				end) *1.0 / count(*) *100 as percentage_publiched
	from Commerce.ProductChannels as cp
	left join Commerce.Channels as cc
	on cp.ChannelID = cc.ChannelID
	group by ChannelName
) as t1
where percentage_publiched < 82.36

-- Objective: compare publication percentages with the selected Amazon
-- reference value of 82.36%.
-- Critical observation: using a rounded fixed threshold can affect borderline
-- results. The comparison identifies values below the benchmark but does not
-- explain the operational cause of the difference.


-- published products with missing required data.

Select* 
from Commerce.ProductChannels

Select*
from DataQuality.ProductIssues

Select ProductName, PublicationStatus, ruleid, IssueDetails
from Commerce.ProductChannels as cp
left join DataQuality.ProductIssues as dp
on cp.ProductID = dp.ProductID
left join Product.Products as pp
on pp.ProductID = dp.ProductID
where PublicationStatus = 'published' and RuleID >= 1

-- Business interpretation: Published status does not necessarily guarantee
-- complete underlying product information. These records may require
-- post-publication correction or review of validation enforcement.


-- cte for channel readiness

with cte_2 as (
	select productid, PublicationStatus
	from Commerce.ProductChannels
	where PublicationStatus != 'published'
)

select*
from cte_2

-- Interpretation: the result includes Draft, Pending and Rejected records.
-- These represent different workflow stages and should not be treated as one
-- single failure type: Draft is still in preparation, Pending awaits an outcome
-- and Rejected represents an unsuccessful publication attempt.


/*
===============================================================================
8. CATALOG GAPS
===============================================================================
*/

-- The final comparison checks whether each catalog product has a related
-- record in the ProductIssues table.

-- EXISTIS / NOT EXISTS for catalog gaps

select*
from DataQuality.ProductIssues

select*
from Product.Products

select distinct productname, ruleid,
	case 
		when RuleID != 0 then 'EXISTIS' 
		else 'NOT EXISTS'
	end as 'EXISTIS / NOT EXISTS'
from Product.Products as pp
left join DataQuality.ProductIssues as dp
on pp.ProductID = dp.ProductID

-- Interpretation:
-- EXISTIS indicates that a RuleID was returned for the product.
-- NOT EXISTS indicates that no related issue record was returned.
-- Critical observation: no recorded issue does not prove that the product is
-- fully complete. It only confirms that no matching issue is present under the
-- current validation process.


/*
===============================================================================
9. DISCUSSION
===============================================================================
*/

-- 9.1 Data Quality Requires More Than One Indicator
-- Missing images, missing GTINs and recorded validation issues represent
-- different dimensions of product data quality. No single check provides a
-- complete view of catalog readiness. A product can have no recorded issue and
-- still contain incomplete information that is not covered by an active rule.

-- 9.2 Issue Severity Supports Operational Prioritization
-- High-severity issues provide a practical starting point for remediation.
-- However, issue count and severity should be combined with product status,
-- channel impact and commercial importance when deciding work priority.

-- 9.3 Publication Status and Data Quality Are Related but Not Equivalent
-- Published products can still have recorded data issues, while Draft and
-- Pending products are not necessarily incorrect. Publication status describes
-- a workflow outcome; data quality describes the condition of the information.

-- 9.4 Channel Performance Is Highly Uniform
-- Publication and rejection rates are almost identical across the six
-- channels. In a real business environment, different channel requirements
-- would often produce greater variation. The uniformity should therefore be
-- interpreted as a characteristic of the synthetic dataset.

-- 9.5 Counts Require Business Context
-- Categories with more products or stock can naturally generate larger totals.
-- Counts should be complemented by rates, such as issues per product or
-- rejected publications divided by total submissions, before comparing groups.

-- 9.6 Price Patterns Reflect Synthetic Data Generation
-- Category average prices are nearly identical. The price analysis remains
-- useful for demonstrating rankings, window functions and outlier review, but
-- the results should not be interpreted as realistic market pricing behavior.


/*
===============================================================================
10. LIMITATIONS
===============================================================================
*/

-- - The database is synthetic and does not represent a real organization.
-- - Some analytical thresholds, including BasePrice > 200 and 82.36%, are
--   selected reference values rather than documented business targets.
-- - PublicationStatus does not provide the reason for Draft, Pending or
--   Rejected records.
-- - Issue counts depend on the validation rules available in the database.
-- - The absence of a ProductIssues record does not guarantee complete data.
-- - Total stock value uses BasePrice and is not an accounting valuation.
-- - Counts by category or brand are influenced by group size.
-- - Highly uniform generated patterns limit real-world business conclusions.


/*
===============================================================================
11. CONCLUSIONS
===============================================================================
*/

-- This SQL exploration demonstrates how a relational product database can be
-- used to monitor catalog composition, completeness, inventory and channel
-- publication.

-- Key Takeaways:
-- 1. Product quality must be evaluated across several related tables rather
--    than through the core Products table alone.
-- 2. High-severity issues offer a useful starting point for prioritization,
--    although tied products require additional business criteria.
-- 3. Published status does not guarantee that a product has no recorded data
--    issue, showing the importance of post-publication monitoring.
-- 4. Channel publication and rejection rates are very similar in this dataset,
--    with no substantial channel-level performance difference.
-- 5. Product counts, stock quantities and average prices require context before
--    they can support operational or commercial decisions.
-- 6. The synthetic nature of the database makes the project suitable for SQL
--    practice and process analysis, but limits real-world inference.


/*
===============================================================================
END OF ANALYSIS
===============================================================================
*/

