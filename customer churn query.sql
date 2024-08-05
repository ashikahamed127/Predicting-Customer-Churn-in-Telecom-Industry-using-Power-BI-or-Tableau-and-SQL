CREATE SCHEMA customerchurn;
USE customerchurn;
CREATE TABLE customer_churn_new #Table creation using create table command
(Customer_ID VARCHAR(255),
Gender VARCHAR(255),
Age INT,
Married VARCHAR(255),
Number_of_Dependents INT,
City  VARCHAR(255),
Number_of_Referrals INT,
Tenure_in_Months INT,
Offer  VARCHAR(255),
Phone_Service  VARCHAR(255),
Avg_Monthly_Long_Distance_Charges DOUBLE,
Multiple_Lines  VARCHAR(255),
Internet_Service  VARCHAR(255),
Internet_Type  VARCHAR(255),
Online_Security  VARCHAR(255),
Online_Backup  VARCHAR(255),
Device_Protection_Plan  VARCHAR(255),
Premium_Tech_Support  VARCHAR(255),
Streaming_TV  VARCHAR(255),
Streaming_Movies  VARCHAR(255),
Streaming_Music  VARCHAR(255),
Unlimited_Data  VARCHAR(255),
Contract  VARCHAR(255),
Paperless_Billing  VARCHAR(255),
Payment_Method  VARCHAR(255),
Monthly_Charge DOUBLE,
Total_Charges DOUBLE,
Total_Refunds INT,
Total_Extra_Data_Charges INT,
Total_Long_Distance_Charges DOUBLE,
Total_Revenue DOUBLE,
Customer_Status  VARCHAR(255),
Churn_Category VARCHAR(255),
Churn_Reason  VARCHAR(255)
);
LOAD DATA INFILE'customer_churn new.csv' #Loading data by Infile command
INTO TABLE customer_churn_new
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;
SELECT * FROM customer_churn_new;
# Identification of customers with high total charges who have churned
SET @row_count = (SELECT COUNT(*) FROM customer_churn_new WHERE Customer_Status='Churned'); # Calculate the total number of churned customers
SET @row_num = 0; # Initialize a row number variable
CREATE TEMPORARY TABLE ordered_customers AS # Create a temporary table with ordered churned customers and row numbers
SELECT Customer_ID, Total_Charges, Customer_Status, (@row_num := @row_num + 1) AS rownumber
FROM customer_churn_new
WHERE Customer_Status = 'Churned'
ORDER BY Total_Charges;
SELECT Customer_ID, Total_Charges, Customer_Status # Filter the result to get customers with total charges greater than the 75th percentile
FROM ordered_customers
WHERE rownumber > 0.75 * @row_count;
#Calculation of the total charges distribution for churned and non-churned customers
SELECT # Basic Statistics for Total Charges
    Customer_Status,
    COUNT(*) AS Total_Customers,
    AVG(Total_Charges) AS Average_Total_Charges,
    MIN(Total_Charges) AS Minimum_Total_Charges,
    MAX(Total_Charges) AS Maximum_Total_Charges,
    STDDEV(Total_Charges) AS stddev_total_charges
FROM customer_churn_new
GROUP BY Customer_Status;
SELECT # Distribution by Charge Range
    Customer_Status,
    CASE 
        WHEN Total_Charges < 50 THEN '0-50'
        WHEN Total_Charges < 100 THEN '50-100'
        WHEN Total_Charges < 150 THEN '100-150'
        WHEN Total_Charges < 200 THEN '150-200'
        WHEN Total_Charges < 250 THEN '200-250'
        WHEN Total_Charges < 300 THEN '250-300'
        ELSE '300+'
    END AS Charge_Range,
    COUNT(*) AS Total_Customers_In_Range
FROM customer_churn_new
GROUP BY Customer_Status, Charge_Range
ORDER BY Customer_Status, Charge_Range;
# Identification of the average total charges for customers grouped by gender and marital status
SELECT 
    Gender,
    Married,
    AVG(Total_Charges) AS Average_Charges
FROM 
    customer_churn_new
GROUP BY   Gender,Married;
# Calculation of the average monthly charges for different age groups among churned customers
SELECT 
    CASE 
        WHEN Age BETWEEN 0 AND 20 THEN '0-20'
        WHEN Age BETWEEN 21 AND 30 THEN '21-30'
        WHEN Age BETWEEN 31 AND 40 THEN '31-40'
        WHEN Age BETWEEN 41 AND 50 THEN '41-50'
        WHEN Age BETWEEN 51 AND 60 THEN '51-60'
        WHEN Age BETWEEN 61 AND 70 THEN '61-70'
        WHEN Age BETWEEN 71 AND 80 THEN '71-80'
        ELSE '81-100'
    END AS Age_Group,
    AVG(Monthly_Charge) AS Average_Monthly_Charge
FROM 
    customer_churn_new
WHERE 
    Customer_Status = 'Churned'
GROUP BY 
    Age_Group
ORDER BY 
    Age_Group;
# Determination of the average age and total charges for customers with multiple lines and online backup
SELECT 
    AVG(Age) AS Average_age,
    SUM(Total_Charges) AS Total_charges
FROM 
    customer_churn_new
WHERE 
    Multiple_Lines = 'Yes'
    AND Online_Backup = 'Yes';
# Identification of the contract types with the highest churn rate among senior citizens (age 65 and over)
SELECT 
    Contract,
    COUNT(CASE WHEN Customer_Status = 'Churned' THEN 1 END) * 1.0 / COUNT(*) AS churn_rate #calculates the churn rate as the number of churned customers divided by the total number of customers for each contract type.
FROM 
    customer_churn_new
WHERE 
    age >= 65
GROUP BY 
    Contract
ORDER BY 
    churn_rate DESC;
# Calculation of the average monthly charges for customers who have multiple lines and streaming TV
SELECT
 AVG(Monthly_Charge) AS Average_Monthly_Charge
 FROM customer_churn_new
 WHERE Multiple_Lines = 'Yes'
 AND Streaming_TV = 'Yes';
# Identification of the customers who have churned and used the most online services
SELECT # Filter Churned Customers and Count Online Services
    Customer_ID,
    (CASE WHEN Online_Security = 'Yes' THEN 1 ELSE 0 END +
     CASE WHEN Online_Backup = 'Yes' THEN 1 ELSE 0 END +
     CASE WHEN Device_Protection_Plan = 'Yes' THEN 1 ELSE 0 END +
     CASE WHEN Premium_Tech_Support = 'Yes' THEN 1 ELSE 0 END +
     CASE WHEN Streaming_TV = 'Yes' THEN 1 ELSE 0 END +
     CASE WHEN Streaming_Movies = 'Yes' THEN 1 ELSE 0 END) AS Online_Services_Count
FROM 
    customer_churn_new
WHERE 
    Customer_Status = 'Churned';
SELECT # Identify the Maximum Number of Online Services Used
    MAX(Online_Services_Count) AS Max_Online_Services
FROM 
    (SELECT 
        Customer_ID,
        (CASE WHEN Online_Security = 'Yes' THEN 1 ELSE 0 END +
         CASE WHEN Online_Backup = 'Yes' THEN 1 ELSE 0 END +
         CASE WHEN Device_Protection_Plan = 'Yes' THEN 1 ELSE 0 END +
         CASE WHEN Premium_Tech_Support = 'Yes' THEN 1 ELSE 0 END +
         CASE WHEN Streaming_TV = 'Yes' THEN 1 ELSE 0 END +
         CASE WHEN Streaming_Movies = 'Yes' THEN 1 ELSE 0 END) AS Online_Services_Count
    FROM 
        customer_churn_new
    WHERE 
        Customer_Status = 'Churned') AS Subquery;
SELECT # Find Customers with the Maximum Online Services Count
    Customer_ID
FROM 
    (SELECT 
        Customer_ID,
        (CASE WHEN Online_Security = 'Yes' THEN 1 ELSE 0 END +
         CASE WHEN Online_Backup = 'Yes' THEN 1 ELSE 0 END +
         CASE WHEN Device_Protection_Plan= 'Yes' THEN 1 ELSE 0 END +
         CASE WHEN Premium_Tech_Support = 'Yes' THEN 1 ELSE 0 END +
         CASE WHEN Streaming_TV = 'Yes' THEN 1 ELSE 0 END +
         CASE WHEN Streaming_Movies = 'Yes' THEN 1 ELSE 0 END) AS Online_Services_Count
    FROM 
        customer_churn_new
    WHERE 
        Customer_Status = 'Churned') AS Subquery
WHERE 
    Online_Services_Count = (SELECT 
                                MAX(Online_Services_Count) 
                             FROM 
                                (SELECT 
                                    Customer_ID,
                                    (CASE WHEN Online_Security = 'Yes' THEN 1 ELSE 0 END +
                                     CASE WHEN Online_Backup = 'Yes' THEN 1 ELSE 0 END +
                                     CASE WHEN Device_Protection_Plan = 'Yes' THEN 1 ELSE 0 END +
                                     CASE WHEN Premium_Tech_Support = 'Yes' THEN 1 ELSE 0 END +
                                     CASE WHEN Streaming_TV = 'Yes' THEN 1 ELSE 0 END +
                                     CASE WHEN Streaming_Movies = 'Yes' THEN 1 ELSE 0 END) AS online_services_count
                                FROM 
                                    customer_churn_new
                                WHERE 
                                    Customer_Status = 'Churned') AS Max_Subquery);
# Identification of the gender distribution among customers who have churned and are on yearly contracts
SELECT 
    Gender,
    COUNT(*) AS Count
FROM 
    customer_churn_new
WHERE 
    Customer_Status = 'Churned'
    AND Contract = 'One_Year'
GROUP BY 
    Gender;
# Calculation of the average monthly charges and total charges for customers who have churned, grouped by contract type and internet service type
SELECT 
    Contract,
    Internet_Type,
    AVG(Monthly_Charge) AS Average_Monthly_Charge,
    SUM(Total_Charges) AS Total_Charges
FROM 
    customer_churn_new
WHERE 
    Customer_Status = 'Churned'
GROUP BY 
    Contract, Internet_Type;
#  To Find the customers who have churned and are not using online services, and their average total charges
SELECT 
    AVG(Total_Charges) AS Average_Total_Charges
FROM 
    customer_churn_new
WHERE 
    Customer_Status = 'Churned'
    AND Online_Security = 'No'
    AND Online_Backup = 'No'
    AND Device_Protection_Plan = 'No'
    AND Premium_Tech_Support = 'No'
    AND Streaming_TV = 'No'
    AND Streaming_Movies = 'No'
    AND Streaming_Music = 'No';
# Calculation of the average monthly charges and total charges for customers who have churned, grouped by the number of dependents
SELECT 
    Number_of_Dependents,
    AVG(Monthly_charge) AS Average_Monthly_Charge,
    SUM(Total_Charges) AS Total_Charges
FROM 
    customer_churn_new
WHERE 
    Customer_Status = 'Churned'
GROUP BY 
	Number_of_Dependents;
# Identification of the customers who have churned, and their contract duration in months (for monthly contracts)
SELECT 
    Customer_ID,
    Tenure_in_Months,
    Customer_Status
FROM 
    customer_churn_new
WHERE 
    Customer_Status = 'Churned'
    AND Contract = 'Month-to-Month';
# Determination of the average age and total charges for customers who have churned, grouped by internet service and phone service
SELECT 
    Internet_Service,
    Phone_Service,
    AVG(Age) AS Average_Age,
    AVG(Total_Charges) AS Average_Total_Charges
FROM 
    customer_churn_new
WHERE 
    Customer_Status = 'Churned'
    AND   Internet_Service = 'Yes'
    AND Phone_Service ='Yes'
GROUP BY 
	  Internet_Service,Phone_Service;







