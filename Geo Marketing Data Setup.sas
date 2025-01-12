
libname mylib '/home/u64110234';
PROC IMPORT DATAFILE="/home/u64110234/sales_q1.csv"
    OUT=mylib.sales
    DBMS=CSV
    REPLACE;
RUN;

PROC IMPORT DATAFILE="/home/u64110234/postcode.csv"
    OUT=mylib.postcodes
    DBMS=CSV
    REPLACE;
RUN;
PROC DATASETS library=mylib;
    delete full_postcodes;
quit;

/* Check the import */
PROC PRINT DATA=mylib.full_postcodes (OBS=10);
    TITLE 'First 10 Records from Full Postcodes';
RUN;

PROC IMPORT DATAFILE="/home/u64110234/Locations.csv"
    OUT=mylib.Locations
    DBMS=CSV
    REPLACE;
RUN;


PROC IMPORT DATAFILE="/home/u64110234/computers.csv"
    OUT=mylib.computers
    DBMS=CSV
    REPLACE;
RUN;

PROC CONTENTS DATA=mylib.sales;
TITLE 'Structure of Sales Data';
RUN;

PROC PRINT DATA=mylib.sales (OBS=5);
TITLE 'First 5 Sales Records';
RUN;

PROC CONTENTS DATA=mylib.Locations;
TITLE 'Structure of Store Locations';
RUN;

/* Let's look at a few records from each table */
PROC PRINT DATA=mylib.Locations (OBS=5);
TITLE 'First 5 Store Records';
RUN;

PROC PRINT DATA=mylib.postcodes (OBS=5);
TITLE 'First 5 Postcode Records';
RUN;

PROC PRINT DATA=mylib.computers (OBS=5);
TITLE 'First 5 Computer Configurations';
RUN;
/*renaming columns */

proc datasets library=mylib;
    modify Locations;
    rename 'OS X'n = OS_X 'OS Y'n = OS_Y;
quit;

proc datasets library=mylib;
    modify postcodes;
    rename 'OS X'n = OS_X 'OS Y'n = OS_Y;
quit;

/* Join sales with customer and store coordinates */

PROC  SQL;
CREATE TABLE mylib.sales_with_coords AS
SELECT 
s.*, pc.OS_X as customer_x,
pc.OS_Y as customer_y,
l.OS_X as store_x,
l.OS_Y as store_y
FROM mylib.sales s
LEFT JOIN mylib.postcodes pc
ON s.customer_Postcode = pc.PostCode
LEFT JOIN mylib.Locations l
ON s.store_Postcode=l.Postcode;
QUIT;

/* Let's verify our joined data */
PROC PRINT DATA=mylib.sales_with_coords (OBS=5);
TITLE 'First 5 Records with Coordinates';
RUN;

/* Check if we have any missing coordinates */
 PROC SQL;
 SELECT count(*) as total_records,
 SUM(CASE WHEN customer_x IS NULL OR customer_y is NULL THEN 1 ELSE 0 END) as missing_customer_coords,
 SUM (CASE WHEN store_x IS NULL OR store_y is NULL THEN 1 ELSE 0 END) as missing_store_coords
 FROM mylib.sales_with_coords;
 QUIT;

PROC SQL;
CREATE TABLE mylib.missing_postcodes AS
SELECT DISTINCT s.Customer_Postcode
FROM mylib.sales s LEFT JOIN mylib.postcodes p
ON s.customer_postcode = p.postcode
where p.os_x IS NULL
ORDER BY s.customer_postcode;
QUIT;

/* Print the first few missing postcodes */
PROC PRINT DATA=mylib.missing_postcodes (OBS=10);
    TITLE 'Sample of Customer Postcodes Missing Coordinates';
RUN;

/* Count how many unique postcodes are missing */
PROC SQL;
    SELECT COUNT(DISTINCT Customer_Postcode) as unique_missing_postcodes
    FROM mylib.missing_postcodes;
QUIT;

/* Create final dataset excluding records with missing coordinates */
PROC SQL;
CREATE TABLE mylib.sales_with_coords_clean AS
SELECT
s.*, pc.OS_X as customer_x,
pc.OS_Y as customer_y, l.OS_X as store_x, l.OS_Y as store_y,
/*Euclidean distance*/
SQRT((pc.OS_X - l.OS_X)**2 + (pc.OS_Y- l.OS_Y)**2) as distance
FROM mylib.sales s LEFT JOIN mylib.postcodes pc
ON s.customer_postcode = pc.postcode
left join mylib.Locations l 
ON s.store_postcode = l.postcode
WHERE pc.OS_X IS NOT NULL;
QUIT;
/* Analyze the distances */
PROC MEANS DATA=mylib.sales_with_coords_clean N MIN MEAN MEDIAN MAX;
    VAR distance;
    TITLE 'Customer Travel Distance Statistics';
RUN;

/* Create distance bands for analysis */
PROC SQL;
    CREATE TABLE mylib.distance_analysis AS
    SELECT 
        CASE 
            WHEN distance < 5000 THEN 'Under 5km'
            WHEN distance < 10000 THEN '5-10km'
            WHEN distance < 20000 THEN '10-20km'
            ELSE 'Over 20km'
        END as distance_band,
        COUNT(*) as number_of_customers,
        AVG(price) as avg_purchase_value
    FROM mylib.sales_with_coords_clean
    GROUP BY CALCULATED distance_band;
QUIT;



