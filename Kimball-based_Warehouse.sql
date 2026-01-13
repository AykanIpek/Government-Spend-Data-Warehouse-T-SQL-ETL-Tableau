CREATE DATABASE DW_SPENDING
USE DW_SPENDING
GO

IF OBJECT_ID('Staging_all', 'U') IS NOT NULL 
BEGIN
    DROP TABLE Staging_all;
END
GO

-- Creating staging table
CREATE TABLE Staging_all(
Department NVARCHAR(max),
Entity NVARCHAR(max),
DateOfPayment NVARCHAR(max),
ExpenseType NVARCHAR(max),
ExpenseArea NVARCHAR(max),
Supplier NVARCHAR(max),
TransactionNumber NVARCHAR(max),
Amount NVARCHAR(max),
Description NVARCHAR(max),
SupplierPostCode NVARCHAR(max),
SupplierType NVARCHAR(max),
ContractNumber NVARCHAR(max),
ProjectCode NVARCHAR(max),
ExpenditureType NVARCHAR(max)

);
GO

-- Inserting csv data into Staging_all table 
BULK INSERT Staging_all
FROM "C:\Users\HÜSEYÝN ÝPEK\Desktop\Data Management\CourseWork2\Data\April_2015_published.csv"
WITH (
	FORMAT = 'CSV',
	FIELDQUOTE = '"',
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n',
	TABLOCK
);

-- Inserting csv data into Staging_all table 
BULK INSERT Staging_all
FROM "C:\Users\HÜSEYÝN ÝPEK\Desktop\Data Management\CourseWork2\Data\BIS_July_2015.csv"
WITH (	
	FORMAT = 'CSV',
	FIELDQUOTE = '"',
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n',
	TABLOCK
);

-- Inserting csv data into Staging_all table 
BULK INSERT Staging_all
FROM "C:\Users\HÜSEYÝN ÝPEK\Desktop\Data Management\CourseWork2\Data\BIS_June_2015.csv"
WITH (
	FORMAT = 'CSV',
	FIELDQUOTE = '"',
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n',
	TABLOCK
);

-- Inserting csv data into Staging_all table 
BULK INSERT Staging_all
FROM "C:\Users\HÜSEYÝN ÝPEK\Desktop\Data Management\CourseWork2\Data\May_2015_published.csv"
WITH (
	FORMAT = 'CSV',
	FIELDQUOTE = '"',
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n',
	TABLOCK
);
GO

-- Checking Staging_all table 
SELECT * FROM Staging_all;
SELECT COUNT(*) FROM Staging_all;
GO

-- Grouping and finding number of Personal Expense, Name Witheld supplier
SELECT Supplier, COUNT(*) AS AMOUNT
FROM Staging_all
GROUP BY Supplier
HAVING Supplier IN (
    SELECT Supplier
    FROM Staging_all
    WHERE Supplier = 'Personal Expense, Name Witheld'
);

-- Changing specific supplier name with student id
UPDATE Staging_all
SET Supplier = '4415663'
WHERE Supplier = 'Personal Expense, Name Witheld';

-- Grouping and finding number of 4415663 supplier
SELECT Supplier, COUNT(*) AS AMOUNT
FROM Staging_all
GROUP BY Supplier
HAVING Supplier IN (
    SELECT Supplier
    FROM Staging_all
    WHERE Supplier = '4415663'
);
GO

-- Examining ContractNumber attribute and null values
SELECT ContractNumber , COUNT(*) AS AMOUNT
FROM Staging_all
GROUP BY ContractNumber;

-- Examining ProjectCode attribute and null values
SELECT ProjectCode, COUNT(*) AS AMOUNT
FROM Staging_all
GROUP BY ProjectCode;

-- Examining ExpenditureType attribute and null values
SELECT ExpenditureType, COUNT(*) AS AMOUNT
FROM Staging_all
GROUP BY ExpenditureType;
GO



IF OBJECT_ID('Staging_Cleaned','U') IS NOT NULL
BEGIN 
	DROP TABLE Staging_Cleaned;
END
GO

-- Creating Staging_Cleaned table
SELECT 
	TRY_CAST(Department AS varchar(255)) AS Department,
	TRY_CAST(Entity AS varchar(255)) AS Entity,
	TRY_CAST(DateOfPayment AS DATE) AS DateOfPayment,
	TRY_CAST(ExpenseType AS varchar(255)) AS ExpenseType,
	TRY_CAST(ExpenseArea AS varchar(255)) AS ExpenseArea,
	TRY_CAST(Supplier AS varchar(255)) AS Supplier,
	TRY_CAST(TransactionNumber AS INT) AS TransactionNumber,
	TRY_CAST(Amount AS DECIMAL(10,2)) AS Amount,
	TRY_CAST(Description AS varchar(255)) AS Description,
	TRY_CAST(SupplierPostCode AS varchar(100)) AS SupplierPostCode,
	TRY_CAST(SupplierType AS varchar(100)) AS SupplierType
INTO Staging_Cleaned
FROM Staging_all;
GO

-- Checking Staging_Cleaned table
SELECT * FROM Staging_Cleaned;
SELECT COUNT(*) FROM Staging_Cleaned;
GO


IF OBJECT_ID('Suppliers_Invalid','U') IS NOT NULL
BEGIN
	DROP TABLE Suppliers_Invalid;
END
GO

-- Creating Suppliers_Invalid table
CREATE TABLE Suppliers_Invalid(
SupplierName nvarchar(255),
Entity nvarchar(255),
ExpenseArea nvarchar(255)
);
GO


-- Declaring xmlString variable
DECLARE @xmlString NVARCHAR(MAX);

-- Reading XML file
SELECT @xmlString = BulkColumn
FROM OPENROWSET(
        BULK 'C:\DAT_DATA\suppliers_invalid.xml',
        SINGLE_CLOB
     ) AS x;

-- Replacing the ampersand characters with &amp;
SET @xmlString = REPLACE(@xmlString, '&', '&amp;');

-- Converting xmlString to XML type
DECLARE @xml XML;
SET @xml = CAST(@xmlString AS XML);

-- Inserting data into table
INSERT INTO Suppliers_Invalid (SupplierName, Entity, ExpenseArea)
SELECT
    Supplier.value('@SupplierName', 'nvarchar(255)') AS SupplierName,
    Supplier.value('@Entity', 'nvarchar(255)') AS Entity,
    Supplier.value('@ExpenseArea', 'nvarchar(255)') AS ExpenseArea
FROM @xml.nodes('/Suppliers/Supplier') AS XTbl(Supplier);
GO

-- Checking Suppliers_Invalid table
SELECT * FROM Suppliers_Invalid;
SELECT COUNT(*) FROM Suppliers_Invalid;
GO


-- Checking the rows of Staging_Cleaned table
SELECT COUNT(*) FROM Staging_Cleaned;

-- Deleting values of Suppliers_Invalid table from Staging_Cleaned table
DELETE SC 
FROM Staging_Cleaned AS SC
WHERE EXISTS (
	SELECT 1
	FROM Suppliers_Invalid AS SI
	WHERE SI.SupplierName = SC.Supplier
	AND SI.Entity = SC.Entity
	AND SI.ExpenseArea = SC.ExpenseArea
);

-- Checking the rows of Staging_Cleaned table
SELECT COUNT(*) FROM Staging_Cleaned;
SELECT * FROM Staging_Cleaned;


-- Checking TransactionNumber attribute in Staging_Cleaned table
SELECT TransactionNumber, COUNT(*) AS NumberOfRows
FROM Staging_Cleaned
GROUP BY TransactionNumber;

-- Checking Department attribute in Staging_Cleaned table
SELECT Department, COUNT(*) AS NumberOfRows
FROM Staging_Cleaned
GROUP BY Department;

-- Checking Entity attribute in Staging_Cleaned table
SELECT Entity, COUNT(*) AS NumberOfRows
FROM Staging_Cleaned
GROUP BY Entity;
GO

-----------------------------------------------------------------------------------------------------------------------------------------------


-- Creating DimDepartment table
CREATE TABLE DimDepartment (
	DepartmentKey INT IDENTITY(1,1) PRIMARY KEY,
	Department varchar(255)
);


-- Creating DimEntity table
CREATE TABLE DimEntity(
	EntityKey INT IDENTITY(1,1) PRIMARY KEY,
	Entity varchar(255)
);


-- Creating DimDate table
CREATE TABLE DimDate(
	DateKey INT IDENTITY(1,1) PRIMARY KEY,
	FullDate DATE,
	Day INT,
	Month INT,
	Year INT
);


-- Creating DimSupplier table
CREATE TABLE DimSupplier(
	SupplierKey INT IDENTITY(1,1) PRIMARY KEY,
	Supplier varchar(255),
	SupplierType varchar(150),
	SupplierPostCode varchar(100),
);


-- Creating DimExpense table
CREATE TABLE DimExpense(
	ExpenseKey INT IDENTITY(1,1) PRIMARY KEY,
	ExpenseType varchar(255),
	ExpenseArea varchar(200),
	Description varchar(255)
);


-- Creating FactExpenditure table
CREATE TABLE FactExpenditure(
	FactID INT IDENTITY(1,1) PRIMARY KEY,
	DateKey INT NOT NULL REFERENCES DimDate(DateKey),
	DepartmentKey INT NOT NULL REFERENCES DimDepartment(DepartmentKey),
	EntityKey INT NOT NULL REFERENCES DimEntity(EntityKey),
	SupplierKey INT NOT NULL REFERENCES DimSupplier(SupplierKey),
	ExpenseKey INT NOT NULL REFERENCES DimExpense(ExpenseKey),
	
	TransactionNumber INT,
	Amount DECIMAL(10,2),
	Month INT
);
GO

--------------------------------------------------------------------------------------------------------------------------------------------------

-- Checking the rows of Staging_Cleaned table
SELECT * FROM Staging_Cleaned;

-- Grouping by TransactionNumber, Amount to find any duplicates
SELECT TransactionNumber,Amount,COUNT(*)
FROM Staging_Cleaned
GROUP BY TransactionNumber,Amount;

-- Grouping by TransactionNumber, Amount to find any duplicates that are more than one 
SELECT TransactionNumber,Amount,COUNT(*) AS DUPLICATES
FROM Staging_Cleaned
GROUP BY TransactionNumber,Amount
HAVING COUNT(*)>1;

-- Using subquery to examine and find any duplicates in all columns
SELECT * FROM Staging_Cleaned AS S1
JOIN (
	SELECT TransactionNumber,Amount,COUNT(*) AS DUPLICATES
	FROM Staging_Cleaned
	GROUP BY TransactionNumber,Amount
	HAVING COUNT(*)>1
) AS S2
ON S1.TransactionNumber = S2.TransactionNumber AND
S1.Amount = S2.Amount;


-- Using DateOfPayment,ExpenseType,TransactionNumber,Amount,Description attributes find all duplicates in all Staging_Cleaned table
SELECT S1.*,S2.DUPLICATES FROM Staging_Cleaned AS S1
JOIN (
	SELECT DateOfPayment,ExpenseType,TransactionNumber,Amount,Description,COUNT(*) AS DUPLICATES
	FROM Staging_Cleaned
	GROUP BY DateOfPayment,ExpenseType,TransactionNumber,Amount,Description
	HAVING COUNT(*) > 1
) AS S2
ON S1.TransactionNumber = S2.TransactionNumber AND
S1.Amount = S2.Amount AND S1.DateOfPayment = S2.DateOfPayment AND S1.ExpenseType = S2.ExpenseType AND
S1.Description = S2.Description;

-- Finding total row of duplicates in all Staging_Cleaned table
SELECT COUNT(*) AS DUPLICATES FROM Staging_Cleaned AS S1
JOIN (
	SELECT DateOfPayment,ExpenseType,TransactionNumber,Amount,Description,COUNT(*) AS DUPLICATES
	FROM Staging_Cleaned
	GROUP BY DateOfPayment,ExpenseType,TransactionNumber,Amount,Description
	HAVING COUNT(*) > 1
) AS S2
ON S1.TransactionNumber = S2.TransactionNumber AND
S1.Amount = S2.Amount AND S1.DateOfPayment = S2.DateOfPayment AND S1.ExpenseType = S2.ExpenseType AND
S1.Description = S2.Description;


-- Adding ID column for deleting process
ALTER TABLE Staging_Cleaned
ADD ID INT IDENTITY(1,1) PRIMARY KEY; 

SELECT * FROM Staging_Cleaned;

-- Deleting duplicates in Staging_Cleaned table
DELETE S1
FROM Staging_Cleaned S1
JOIN Staging_Cleaned S2
	ON S1.TransactionNumber = S2.TransactionNumber AND
	S1.Amount = S2.Amount AND 
	S1.DateOfPayment = S2.DateOfPayment AND 
	S1.ExpenseType = S2.ExpenseType AND 
	S1.Description = S2.Description AND
	S1.ID > S2.ID;


-- Checking the process by examining duplicate rows
SELECT COUNT(*) AS DUPLICATES FROM Staging_Cleaned AS S1
JOIN (
	SELECT DateOfPayment,ExpenseType,TransactionNumber,Amount,Description,COUNT(*) AS DUPLICATES
	FROM Staging_Cleaned
	GROUP BY DateOfPayment,ExpenseType,TransactionNumber,Amount,Description
	HAVING COUNT(*) > 1
) AS S2
ON S1.TransactionNumber = S2.TransactionNumber AND
S1.Amount = S2.Amount AND S1.DateOfPayment = S2.DateOfPayment AND S1.ExpenseType = S2.ExpenseType AND
S1.Description = S2.Description;
GO

-- Checking null values in the table
SELECT * FROM Staging_Cleaned
WHERE Department IS NULL OR Entity IS NULL OR DateOfPayment IS NULL OR ExpenseType IS NULL OR ExpenseArea IS NULL OR Supplier
IS NULL OR TransactionNumber IS NULL OR Amount IS NULL OR Description IS NULL OR SupplierPostCode IS NULL OR SupplierType IS NULL;

-- Finding total rows of the table
SELECT COUNT(*) AS TOTAL_ROW FROM Staging_Cleaned;

-- Deleting null values that do not contain any value in all columns
DELETE FROM Staging_Cleaned
WHERE Department IS NULL
  AND Entity IS NULL
  AND DateOfPayment IS NULL
  AND ExpenseType IS NULL
  AND ExpenseArea IS NULL
  AND Supplier IS NULL
  AND TransactionNumber IS NULL
  AND Amount IS NULL
  AND Description IS NULL
  AND SupplierPostCode IS NULL
  AND SupplierType IS NULL;
GO

-- Checking process by examining rows of the table
SELECT COUNT(*) AS TOTAL_ROW FROM Staging_Cleaned;

-- Dropping the constraint of primary key 
DECLARE @pkName NVARCHAR(200);
DECLARE @sql NVARCHAR(MAX);

-- Find PK
SELECT @pkName = name
FROM sys.key_constraints
WHERE parent_object_id = OBJECT_ID('Staging_Cleaned')
  AND type = 'PK';

-- Dynamic SQL is prepared correctly
SET @sql = N'ALTER TABLE Staging_Cleaned DROP CONSTRAINT ' + QUOTENAME(@pkName) + N';';

-- Execute the SQL
EXEC(@sql);


-- Dropping the primary key 
ALTER TABLE Staging_Cleaned DROP COLUMN ID;


-- Checking process by examining rows of the table
SELECT *  FROM Staging_Cleaned;

-- Assigning values to null values in the table
UPDATE Staging_Cleaned
SET
	Department = ISNULL(Department, 'Unknown'),
	Entity = ISNULL(Entity, 'Unknown'),
	DateOfPayment = ISNULL(DateOfPayment, '2015-01-01'),
	ExpenseType = ISNULL(ExpenseType, 'Unknown'),
	ExpenseArea = ISNULL(ExpenseArea, 'Unknown'),
	Supplier = ISNULL(Supplier, 'Unknown'),
	TransactionNumber = ISNULL(TransactionNumber, 0),
	Amount = ISNULL(Amount, 0),
	Description = ISNULL(Description, 'Unknown'),
	SupplierPostCode = ISNULL(SupplierPostCode, 'XXX XXX'),
	SupplierType = ISNULL(SupplierType, 'Unknown')
WHERE 
	Department IS NULL OR
	Entity IS NULL OR
	DateOfPayment IS NULL OR
	ExpenseType IS NULL OR
	ExpenseArea IS NULL OR
	Supplier IS NULL OR
	TransactionNumber IS NULL OR
	Amount IS NULL OR
	Description IS NULL OR
	SupplierPostCode IS NULL OR
	SupplierType IS NULL;
GO

-- Checking process by examining rows of the table
SELECT *  FROM Staging_Cleaned;

-- Checking any null values in the table
SELECT * FROM Staging_Cleaned
WHERE Department IS NULL OR Entity IS NULL OR DateOfPayment IS NULL OR ExpenseType IS NULL OR ExpenseArea IS NULL OR Supplier
IS NULL OR TransactionNumber IS NULL OR Amount IS NULL OR Description IS NULL OR SupplierPostCode IS NULL OR SupplierType IS NULL;
GO


-- Checking any misspellings in Department values by grouping
SELECT Department FROM Staging_Cleaned
GROUP BY Department;

-- Checking any misspellings in Entity values by grouping
SELECT Entity FROM Staging_Cleaned
GROUP BY Entity;

-- Checking any misspellings in SupplierType values by grouping
SELECT SupplierType FROM Staging_Cleaned
GROUP BY SupplierType;

-- Checking any misspellings in ExpenseType values by grouping
SELECT ExpenseType FROM Staging_Cleaned
GROUP BY ExpenseType;

-- Checking any misspellings in ExpenseArea values by grouping
SELECT ExpenseArea FROM Staging_Cleaned
GROUP BY ExpenseArea;

-- Checking any misspellings in Supplier values by grouping
SELECT Supplier FROM Staging_Cleaned
GROUP BY Supplier;

-- Checking any misspellings in Description values by grouping
SELECT Description FROM Staging_Cleaned
GROUP BY Description;
GO

----------------------------------------------------------------------------------------------------------------------------------------------------

SELECT * FROM Staging_Cleaned;

SELECT COUNT(*) AS TOTAL_ROWS FROM Staging_Cleaned;

SELECT DateOfPayment,COUNT(*) FROM Staging_Cleaned
GROUP BY DateOfPayment;

-- Adding new column into the table
ALTER TABLE Staging_Cleaned ADD DateOfPayment_Str VARCHAR(15);

-- Inserting data into DateOfPayment_Str column 
UPDATE Staging_Cleaned
SET DateOfPayment_Str = CONVERT(VARCHAR(10), DateOfPayment, 23); 

-- Updating data in DateOfPayment_Str column 
UPDATE Staging_Cleaned
SET DateOfPayment_Str = 
    SUBSTRING(DateOfPayment_Str, 1, 4) + '-' +  -- Year
    SUBSTRING(DateOfPayment_Str, 9, 2) + '-' +  -- Month 
    SUBSTRING(DateOfPayment_Str, 6, 2);         -- Day

-- Converting data from varchar(10) to date value type 
UPDATE Staging_Cleaned
SET DateOfPayment_Str = TRY_CAST(DateOfPayment_Str AS DATE);

SELECT * FROM Staging_Cleaned;

-- Changing column name
EXEC sp_rename 'dbo.Staging_Cleaned.DateOfPayment_Str', 'DateOfPayment_Corrected', 'COLUMN';


SELECT * FROM Staging_Cleaned;

-- Inserting data into DimDepartment table
INSERT INTO DimDepartment(Department)
SELECT DISTINCT Department 
FROM Staging_Cleaned
WHERE Department IS NOT NULL;

-- Inserting data into DimEntity table
INSERT INTO DimEntity(Entity)
SELECT DISTINCT Entity
FROM Staging_Cleaned
WHERE Entity IS NOT NULL;

-- Inserting data into DimDate table
INSERT INTO DimDate(FullDate,Day,Month,Year)
SELECT DISTINCT DateOfPayment_Corrected,DAY(DateOfPayment_Corrected),MONTH(DateOfPayment_Corrected),YEAR(DateOfPayment_Corrected)
FROM Staging_Cleaned
WHERE DateOfPayment IS NOT NULL;
SELECT * FROM DimDate;

-- Inserting data into DimSupplier table
INSERT INTO DimSupplier(Supplier,SupplierType,SupplierPostCode)
SELECT DISTINCT 
		Supplier,
		SupplierType,
		SupplierPostCode
FROM Staging_Cleaned
WHERE Supplier IS NOT NULL
	AND SupplierType IS NOT NULL
	AND SupplierPostCode IS NOT NULL;

-- Inserting data into DimExpense table
INSERT INTO DimExpense(ExpenseType,ExpenseArea,Description)
SELECT DISTINCT
		ExpenseType,
		ExpenseArea,
		Description
FROM Staging_Cleaned
WHERE ExpenseType IS NOT NULL AND
	ExpenseArea IS NOT NULL AND
	Description IS NOT NULL;


-- Inserting data into FactExpenditure table
INSERT INTO FactExpenditure (
	DateKey,
	DepartmentKey,
	EntityKey,
	SupplierKey,
	ExpenseKey,
	TransactionNumber,
	Amount,
	Month)
SELECT  
	DD.DateKey,
	DDEP.DepartmentKey,
	DE.EntityKey,
	DS.SupplierKey,
	DEX.ExpenseKey,
	S1.TransactionNumber,
	S1.Amount,
	MONTH(S1.DateOfPayment_Corrected) AS Month
FROM Staging_Cleaned S1
INNER JOIN DimDate AS DD
	ON DD.FullDate = S1.DateOfPayment_Corrected
INNER JOIN DimDepartment AS DDEP
	ON DDEP.Department = S1.Department
INNER JOIN DimEntity AS DE
	ON DE.Entity = S1.Entity
INNER JOIN DimSupplier AS DS
	ON DS.Supplier = S1.Supplier AND
		DS.SupplierType = S1.SupplierType AND
		DS.SupplierPostCode = S1.SupplierPostCode
INNER JOIN DimExpense AS DEX
	ON DEX.ExpenseType = S1.ExpenseType AND
		DEX.ExpenseArea = S1.ExpenseArea AND
		DEX.Description = S1.Description;
GO	

SELECT * FROM FactExpenditure;

-- Checking for data loss
SELECT COUNT(*) AS TOTAL_ROWS FROM Staging_Cleaned;
SELECT COUNT(*) AS TOTAL_ROWS FROM FactExpenditure;

SELECT * FROM DimDate;

------------------------------------------------------------------------------------------------------------------------------------------------------

-- Query 4.a
IF OBJECT_ID('dbo.Get_AboveAverage_Expenses', 'P') IS NOT NULL
    DROP PROCEDURE dbo.Get_AboveAverage_Expenses;
GO

CREATE PROCEDURE dbo.GetTop3SuppliersMonthlySpend
AS
BEGIN
    SET NOCOUNT ON;

    -- Calculates total spent and monthly spendings except month 1
    SELECT 
        D.Supplier,
        T.TOTAL_SPENT AS TOTAL_SPENT,
        SUM(CASE WHEN F.Month = 4 THEN F.Amount ELSE 0 END) AS APR,
        SUM(CASE WHEN F.Month = 5 THEN F.Amount ELSE 0 END) AS MAY,
        SUM(CASE WHEN F.Month = 6 THEN F.Amount ELSE 0 END) AS JUN,
        SUM(CASE WHEN F.Month = 7 THEN F.Amount ELSE 0 END) AS JUL
    FROM FactExpenditure AS F
    INNER JOIN DimSupplier AS D
        ON F.SupplierKey = D.SupplierKey
    INNER JOIN (
        SELECT TOP 3 
            D2.Supplier,             
            SUM(F2.Amount) AS TOTAL_SPENT
        FROM FactExpenditure F2
        INNER JOIN DimSupplier D2
            ON F2.SupplierKey = D2.SupplierKey
        WHERE F2.Month != 1
        GROUP BY D2.Supplier 
        ORDER BY SUM(F2.Amount) DESC
    ) AS T
        ON D.Supplier = T.Supplier 
    WHERE F.Month != 1
    GROUP BY D.Supplier, T.TOTAL_SPENT
    ORDER BY T.TOTAL_SPENT DESC;
END;
GO
 

EXEC dbo.GetTop3SuppliersMonthlySpend;







-- Query 4.b
IF OBJECT_ID('dbo.Get_AboveAverage_Expenses', 'P') IS NOT NULL
    DROP PROCEDURE dbo.Get_AboveAverage_Expenses;
GO

CREATE PROCEDURE dbo.Get_AboveAverage_Expenses
AS
BEGIN
    SET NOCOUNT ON;

    -- Computes every individual expense types for 2 months
    SELECT T1.ExpenseType, T1.Individual_2Month_Total
    FROM (
        SELECT 
            E.ExpenseType, 
            SUM(F1.Amount) AS Individual_2Month_Total
        FROM FactExpenditure AS F1
        INNER JOIN DimExpense AS E
            ON F1.ExpenseKey = E.ExpenseKey
        WHERE MONTH IN (4,5)
        GROUP BY E.ExpenseType
    ) AS T1
    CROSS JOIN
    (
        -- Computes global for all expense types for 2 months
        SELECT AVG(T.Individual_Total) AS Global_Avg_2Month_Spend
        FROM (
            SELECT SUM(F2.Amount) AS Individual_Total
            FROM FactExpenditure AS F2
            WHERE MONTH IN (4,5)
            GROUP BY F2.ExpenseKey
        ) AS T
    ) AS T2
    WHERE T1.Individual_2Month_Total > T2.Global_Avg_2Month_Spend
    ORDER BY T1.Individual_2Month_Total DESC
    FOR JSON PATH;
END;
GO

EXEC dbo.Get_AboveAverage_Expenses;







-- Query 4.c
IF OBJECT_ID('dbo.Get_MonthlyExpenseRanks', 'P') IS NOT NULL
    DROP PROCEDURE dbo.Get_MonthlyExpenseRanks;
GO

CREATE PROCEDURE dbo.Get_MonthlyExpenseRanks
AS
BEGIN
    SET NOCOUNT ON;

    -- Calculating total spending per ExpenseArea and per month (except month 1)
    WITH Monthly_Amounts AS (
        SELECT TOP 10
            E.ExpenseArea,
            SUM(CASE WHEN D.Month = 4 THEN F1.Amount ELSE 0 END) AS April,
            SUM(CASE WHEN D.Month = 5 THEN F1.Amount ELSE 0 END) AS May,
            SUM(CASE WHEN D.Month = 6 THEN F1.Amount ELSE 0 END) AS June,
            SUM(CASE WHEN D.Month = 7 THEN F1.Amount ELSE 0 END) AS July,
            SUM(F1.Amount) AS Total_Amount
        FROM FactExpenditure AS F1
        INNER JOIN DimExpense AS E
            ON F1.ExpenseKey = E.ExpenseKey
        INNER JOIN DimDate AS D
            ON F1.Datekey = D.Datekey
        WHERE D.Month IN (4,5,6,7)
        GROUP BY E.ExpenseArea
        ORDER BY Total_Amount DESC
    ),

    MonthlyRanks AS (
        SELECT 
            ExpenseArea,
            April,
            May,
            June,
            July,
            Total_Amount,

            -- Monthly ranks
            RANK() OVER (ORDER BY April DESC) AS Rank_April,
            RANK() OVER (ORDER BY May DESC) AS Rank_May,
            RANK() OVER (ORDER BY June DESC) AS Rank_June,
            RANK() OVER (ORDER BY July DESC) AS Rank_July,

            -- Calculating rank changes
            (RANK() OVER (ORDER BY April DESC) 
             - RANK() OVER (ORDER BY May DESC)) AS Move_April_May,

            (RANK() OVER (ORDER BY May DESC) 
             - RANK() OVER (ORDER BY June DESC)) AS Move_May_June,

            (RANK() OVER (ORDER BY June DESC) 
             - RANK() OVER (ORDER BY July DESC)) AS Move_June_July
        FROM Monthly_Amounts
    )
    -- Final output
    SELECT 
        ExpenseArea,
        April, Rank_April,
        May, Rank_May, Move_April_May,
        June, Rank_June, Move_May_June,
        July, Rank_July, Move_June_July,
        Total_Amount
    FROM MonthlyRanks
    ORDER BY Total_Amount ASC;
END;
GO


EXEC dbo.Get_MonthlyExpenseRanks;







-- Query 4.d
IF OBJECT_ID('dbo.Get_SupplierReliability', 'P') IS NOT NULL
    DROP PROCEDURE dbo.Get_SupplierReliability;
GO

CREATE PROCEDURE dbo.Get_SupplierReliability
AS
BEGIN
    SET NOCOUNT ON;

    -- Finding SupplierReliabilityScore of top 10 suppliers
    WITH SupplierSpending AS (
        -- Finding top 10 suppliers and their total and monthly spendings
        SELECT TOP 10
            S.Supplier,
            SUM(F.Amount) AS Total_Spending,
            SUM(CASE WHEN F.Month = 4 THEN F.Amount ELSE 0 END) AS April,
            SUM(CASE WHEN F.Month = 5 THEN F.Amount ELSE 0 END) AS May,
            SUM(CASE WHEN F.Month = 6 THEN F.Amount ELSE 0 END) AS June,
            SUM(CASE WHEN F.Month = 7 THEN F.Amount ELSE 0 END) AS July
        FROM FactExpenditure AS F
        INNER JOIN DimSupplier AS S
            ON F.SupplierKey = S.SupplierKey
        GROUP BY S.Supplier
        ORDER BY SUM(F.Amount) DESC
    ),

    SupplierReliabilityScore AS (
        -- SupplierReliabilityScore threshold is made from total 10 suppliers that spent the least 
        SELECT
            Supplier,
            Total_Spending,
            April, May, June, July,
            CASE
                WHEN Total_Spending > (
                    SELECT AVG(Total_Spending)
                    FROM (
                        SELECT TOP 10
                            SUM(F1.Amount) AS Total_Spending
                            FROM FactExpenditure F1
                            INNER JOIN DimSupplier S1
                                ON F1.SupplierKey = S1.SupplierKey
                            GROUP BY S1.SupplierKey
                            ORDER BY SUM(F1.Amount) ASC
                    ) AS Bottom10Suppliers
                ) THEN 'Standard Supplier'
                ELSE 'Low Reliability Score'
            END AS Supplier_Reliability_Score
        FROM SupplierSpending
    ),

    SupplierMonthlyChange AS (
        -- Changing monthly spending per supplier
        SELECT
            Supplier,
            Total_Spending,
            Supplier_Reliability_Score,
            April, May, June, July,
            CASE WHEN May > April THEN 'Up' ELSE 'Down' END AS April_May_Change,
            CASE WHEN June > May THEN 'Up' ELSE 'Down' END AS May_June_Change,
            CASE WHEN July > June THEN 'Up' ELSE 'Down' END AS June_July_Change
        FROM SupplierReliabilityScore
    )

    -- Final output
    SELECT 
        Supplier,
        Total_Spending,
        Supplier_Reliability_Score,
        April, May, April_May_Change,
        June, May_June_Change,
        July, June_July_Change
    FROM SupplierMonthlyChange
    ORDER BY Total_Spending DESC;

END;
GO


EXEC dbo.Get_SupplierReliability;

