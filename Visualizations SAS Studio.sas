/* 1. Customer Distance Distribution */

PROC SGPLOT DATA= mylib.sales_with_coords_clean;
HISTOGRAM distance/binwidth=1000;
DENSITY distance/ type = kernel;
XAXIS LABEL = 'Distance (meters)';
YAXIS LABEL = 'Frequence';
TITLE "Distribution of Customer Travel Distances";
RUN;

/* 2. Sales by Distance Band */
PROC SGPLOT DATA=mylib.distance_analysis;
    VBAR distance_band / response=number_of_sales 
                        datalabel
                        fillattrs=(color=lightblue);
    XAXIS LABEL="Distance Band";
    YAXIS LABEL="Number of Sales";
    TITLE "Sales Volume by Distance Band";
RUN;

/* 3. Store Performance Visualization */
PROC SGPLOT DATA=mylib.store_tiers;
    SCATTER x=avg_customer_distance y=total_revenue / 
            group=performance_tier
            markerattrs=(size=10)
            datalabel=Store_Postcode;
    XAXIS LABEL="Average Customer Distance (meters)";
    YAXIS LABEL="Total Revenue (£)";
    TITLE "Store Performance by Customer Distance";
RUN;

/* 4. Monthly Sales Trends */
PROC SGPLOT DATA=mylib.sales_with_coords_clean;
    VBAR month / response=price stat=sum
                 fillattrs=(color=lightgreen)
                 datalabel;
    XAXIS LABEL="Month";
    YAXIS LABEL="Total Sales (£)";
    TITLE "Monthly Sales Distribution";
RUN;

/* 5. Performance Tier Comparison */
PROC SGPLOT DATA=mylib.store_tiers;
    HBOX total_revenue / category=performance_tier;
    YAXIS LABEL="Total Revenue (£)";
    TITLE "Revenue Distribution by Store Performance Tier";
RUN;