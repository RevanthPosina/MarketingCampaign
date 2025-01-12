/* Analysis*/

/* First let's look at basic distance statistics */

PROC MEANS DATA = mylib.sales_with_coords_clean N MIN P25 MEDIAN P25 MAX MEAN STD MAXDEC=2;
VAR distance;
TITLE 'Customer Travel Distance Statistics (in OS Grind units)';
RUN;

/* Create distance bands and analyze purchasing patterns */
PROC SQL;
   CREATE TABLE mylib.distance_analysis AS
   SELECT 
       CASE 
           WHEN distance < 5000 THEN '1. Under 5km'
           WHEN distance < 10000 THEN '2. 5-10km'
           WHEN distance < 15000 THEN '3. 10-15km'
           WHEN distance < 20000 THEN '4. 15-20km'
           ELSE '5. Over 20km'
       END as distance_band,
       COUNT(*) as number_of_sales,
       COUNT(DISTINCT Customer_Postcode) as unique_customers,
       SUM(price) as total_revenue,
       AVG(price) as avg_purchase_value,
       MIN(price) as min_purchase,
       MAX(price) as max_purchase
   FROM mylib.sales_with_coords_clean
   GROUP BY CALCULATED distance_band
   ORDER BY distance_band;
QUIT;


/* Store Performance Analysis */
PROC SQL;
   CREATE TABLE mylib.store_performance AS
   SELECT 
       s.Store_Postcode,
       COUNT(*) as total_sales,
       COUNT(DISTINCT s.Customer_Postcode) as unique_customers,
       SUM(s.price) as total_revenue,
       AVG(s.price) as avg_sale_value,
       AVG(s.distance) as avg_customer_distance,
       MAX(s.distance) as max_customer_distance
   FROM mylib.sales_with_coords_clean s
   GROUP BY s.Store_Postcode
   ORDER BY total_revenue DESC;
QUIT;


PROC PRINT DATA=mylib.distance_analysis;
   TITLE 'Sales Analysis by Distance Bands';
RUN;

PROC PRINT DATA=mylib.store_performance;
   TITLE 'Store Performance Metrics';
RUN;


/*This analysis will give us:

Overall distance statistics to understand how far customers typically travel
Detailed breakdown of sales patterns by distance bands
Individual store performance metrics including:

Total sales and revenue
Number of unique customers
Average sale value
Average and maximum customer travel distances /*