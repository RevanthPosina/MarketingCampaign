/* Get count of stores in each tier */
PROC FREQ DATA=mylib.store_tiers;
    TABLES performance_tier;
    TITLE 'Distribution of Store Performance Tiers';
RUN;

/* Get key statistics by tier with better formatting */
PROC TABULATE DATA=mylib.store_tiers FORMAT=COMMA10.2;
    CLASS performance_tier;
    VAR total_revenue unique_customers avg_customer_distance local_customer_percent;
    TABLE performance_tier,
          (total_revenue unique_customers avg_customer_distance local_customer_percent)*MEAN;
    TITLE 'Average Metrics by Store Performance Tier';
    FORMAT total_revenue POUND10.2;
RUN;



/* Get customer distance patterns by tier */
PROC SQL;
    CREATE TABLE mylib.tier_distance_patterns AS
    SELECT 
        t.performance_tier,
        CASE 
            WHEN s.distance < 5000 THEN '1. Under 5km'
            WHEN s.distance < 10000 THEN '2. 5-10km'
            WHEN s.distance < 15000 THEN '3. 10-15km'
            WHEN s.distance < 20000 THEN '4. 15-20km'
            ELSE '5. Over 20km'
        END as distance_band,
        COUNT(*) as num_transactions,
        SUM(s.price) as total_revenue,
        AVG(s.price) as avg_transaction_value
    FROM mylib.sales_with_coords_clean s
    JOIN mylib.store_tiers t ON s.Store_Postcode = t.Store_Postcode
    GROUP BY t.performance_tier, 
             CALCULATED distance_band
    ORDER BY t.performance_tier, 
             distance_band;
QUIT;

PROC PRINT DATA=mylib.tier_distance_patterns;
    TITLE 'Customer Distance Patterns by Store Tier';
    FORMAT total_revenue avg_transaction_value POUND10.2;
RUN;


/* Calculate percentage distributions within each tier */
PROC SQL;
    CREATE TABLE mylib.tier_patterns_pct AS
    SELECT 
        performance_tier,
        distance_band,
        num_transactions,
        total_revenue,
        avg_transaction_value,
        (num_transactions / SUM(num_transactions)) * 100 as pct_transactions,
        (total_revenue / SUM(total_revenue)) * 100 as pct_revenue
    FROM mylib.tier_distance_patterns
    GROUP BY performance_tier;
QUIT;

PROC PRINT DATA=mylib.tier_patterns_pct;
    TITLE 'Distance Analysis with Percentages by Store Tier';
    FORMAT total_revenue POUND10.2 
           avg_transaction_value POUND10.2
           pct_transactions pct_revenue 6.1;
RUN;

/* Summary by tier */
PROC MEANS DATA=mylib.store_tiers;
    CLASS performance_tier;
    VAR total_transactions unique_customers total_revenue avg_customer_distance local_customer_percent;
    TITLE 'Key Performance Metrics by Store Tier';
RUN;



/* Let's first look at our overall insights in a clear format */
PROC PRINT DATA=mylib.tier_patterns_pct;
    TITLE 'Final Distance and Revenue Patterns by Store Tier';
    FORMAT total_revenue POUND10.2 
           avg_transaction_value POUND10.2
           pct_transactions pct_revenue 6.1;
    BY performance_tier;
RUN;

/* Key metrics summary */
PROC MEANS DATA=mylib.store_tiers MAXDEC=2;
    CLASS performance_tier;
    VAR total_revenue local_customer_percent avg_customer_distance;
    TITLE 'Summary Performance Metrics by Tier';
RUN;

/* Get popular computer configurations by tier */
/* Check the distribution of configuration sales */
PROC SQL;
    CREATE TABLE mylib.config_counts AS
    SELECT 
        Configuration,
        COUNT(*) as sales_count
    FROM mylib.sales_with_coords_clean
    GROUP BY Configuration
    ORDER BY sales_count DESC;
QUIT;

/* Look at the distribution */
PROC PRINT DATA=mylib.config_counts (OBS=10);
    TITLE 'Top 10 Configuration Sales Counts';
RUN;

/* Now create popular configs with adjusted threshold */
PROC SQL;
    CREATE TABLE mylib.popular_configs AS
    SELECT 
        t.performance_tier,
        s.Configuration,
        COUNT(*) as sales_count,
        AVG(s.price) as avg_price
    FROM mylib.sales_with_coords_clean s
    JOIN mylib.store_tiers t 
        ON s.Store_Postcode = t.Store_Postcode
    GROUP BY t.performance_tier, s.Configuration
    HAVING sales_count >= 50  /* Lowered threshold to 50 */
    ORDER BY t.performance_tier, sales_count DESC;
QUIT;

PROC PRINT DATA=mylib.popular_configs;
    TITLE 'Popular Configurations by Store Performance (50+ Sales)';
    FORMAT avg_price POUND10.2;
RUN;

/* Let's also look at the actual computer specs for these configurations */
PROC SQL;
    CREATE TABLE mylib.popular_config_specs AS
    SELECT 
        p.*,
        c.screen_size,
        c.ram,
        c.processor_speed,
        c.SSD,
        c.HD_size
    FROM mylib.popular_configs p
    JOIN mylib.computers c
        ON p.Configuration = c.configuration
    ORDER BY performance_tier, sales_count DESC;
QUIT;

/* Print the results with specifications */
PROC PRINT DATA=mylib.popular_config_specs;
    TITLE 'Popular Configuration Specifications by Store Performance';
    FORMAT avg_price POUND10.2;
RUN;