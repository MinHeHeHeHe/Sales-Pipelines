-- PHASE 0 — Business Understanding (Hiểu data, xác định measure, dim, fact)

-- PHASE 1 — Database, Schema & ETL Metadata Setup
-- PHASE 1.1 — Tạo Database
create database CRM_Analytics;
go

use CRM_Analytics;
go

SELECT DB_NAME() AS CurrentDatabase; -- Kiểm tra database hiện tại


-- PHASE 1.2 — Tạo Schema
create SCHEMA raw;
go

create schema stg;
go

create schema dw;
go

create schema mart;
go

create schema etl;
go

-- 1.3. Tạo etl.LoadBatch
CREATE TABLE etl.LoadBatch
(
    LoadBatchID INT IDENTITY(1,1)
        PRIMARY KEY,

    SourceFileName NVARCHAR(255),

    LoadStartTime DATETIME2 NOT NULL
        DEFAULT SYSDATETIME(),

    LoadEndTime DATETIME2 NULL,

    RowsLoaded INT NULL,

    LoadStatus VARCHAR(20) NOT NULL
        DEFAULT 'Running'
);

-- 1.4. Data Quality log
CREATE TABLE etl.DataQualityIssue
(
    IssueID BIGINT IDENTITY(1,1)
        PRIMARY KEY,

    LoadBatchID INT,

    RawRecordID BIGINT,

    ColumnName VARCHAR(100),

    IssueType VARCHAR(100),

    IssueDescription NVARCHAR(500),

    DetectedAt DATETIME2
        DEFAULT SYSDATETIME()
);
-- PHASE 2 — Start Load Batch + Raw Data Ingestion
-- PHASE 2.1 — Tạo bảng RAW chính thức
CREATE TABLE raw.CRM_Pipeline
(
    RawRecordID BIGINT IDENTITY(1,1) PRIMARY KEY,

    Organization NVARCHAR(255),
    Country NVARCHAR(100),

    Lattitude NVARCHAR(50),
    Longitude NVARCHAR(50),

    Industry NVARCHAR(200),
    Organization_size NVARCHAR(100),

    Owner NVARCHAR(150),

    Lead_acquisition_date DATE,

    Product NVARCHAR(100),

    Status NVARCHAR(100),
    Status_sequence INT,

    Stage NVARCHAR(100),
    Stage_sequence INT,

    Deal_Value DECIMAL(18,2),

    Probability DECIMAL(5,2),

    Expected_close_date DATE,
    Actual_close_date DATE,

    LoadBatchID INT NOT NULL,

    LoadedAt DATETIME2 NOT NULL
        DEFAULT SYSDATETIME()
);

-- PHASE 2.2 — Tạo LoadBatch trước khi import
INSERT INTO etl.LoadBatch
(
    SourceFileName,
    LoadStatus
)
VALUES
(
    'CRM and Sales Pipelines.csv',
    'Running'
);

SELECT *
FROM etl.LoadBatch
ORDER BY LoadBatchID DESC;


DECLARE @LoadBatchID INT = SCOPE_IDENTITY();


-- PHASE 2.3 — Import Excel vào Landing table
SELECT *
FROM raw.CRM_Pipeline_Landing;


-- PHASE 2.4 — Landing → RAW
DECLARE @LoadBatchID INT = 3;
INSERT INTO raw.CRM_Pipeline
(
    Organization,
    Country,
    Lattitude,
    Longitude,
    Industry,
    Organization_size,
    Owner,
    Lead_acquisition_date,
    Product,
    Status,
    Status_sequence,
    Stage,
    Stage_sequence,
    Deal_Value,
    Probability,
    Expected_close_date,
    Actual_close_date,
    LoadBatchID
)

SELECT
    Organization,
    Country,
    Lattitude,
    Longitude,
    Industry,
    Organization_size,
    Owner,
    Lead_acquisition_date,
    Product,
    Status,
    Status_sequence,
    Stage,
    Stage_sequence,
    Deal_Value,
    Probability,
    Expected_close_date,
    Actual_close_date,

    @LoadBatchID

FROM raw.CRM_Pipeline_Landing;

-- PHASE 2.5 — Validate RAW load
-- Kiểm tra landing
SELECT COUNT(*) AS LandingRows
FROM raw.CRM_Pipeline_Landing;

-- Kiểm tra raw
SELECT COUNT(*) AS RawRows
FROM raw.CRM_Pipeline
WHERE LoadBatchID = 3;

-- Kiểm tra Meta data
SELECT TOP 10
    RawRecordID,
    Organization,
    LoadBatchID,
    LoadedAt
FROM raw.CRM_Pipeline;


-- PHASE 3 — Data Profiling
-- Row count
DECLARE @LoadBatchID INT = 3;

SELECT COUNT(*) AS TotalRows
FROM raw.CRM_Pipeline
WHERE LoadBatchID = @LoadBatchID; 

-- Null profile
DECLARE @LoadBatchID INT = 3;
select 
	COUNT(*) AS TotalRows,
	sum(case when Stage is null
		then 1 else 0
	end) as MissingStage,
	sum(case when Stage_sequence is null
		then 1 else 0
	end) as MissingStage_sequence,
	sum(case when Deal_Value is null
		then 1 else 0
	end) as MissingDeal_Value,
	sum(case when Probability is null
		then 1 else 0
	end) as MissingProbability,
	sum(case when Actual_close_date is null
		then 1 else 0
	end) as MissingActual_close_date
from raw.CRM_Pipeline
where LoadBatchID = @LoadBatchID;


-- Kiểm tra domain
-- Cột Deal_value
select
	max(Deal_value) as MaxDealValue,
	min(Deal_value) as MinDealValue
from raw.CRM_Pipeline
where LoadBatchID = 3;

-- Cột Probability
select
	max(Probability) as MaxProbability,
	min(Probability) as MinProbability
from raw.CRM_Pipeline
where LoadBatchID = 3;



-- Kiểm tra categorical values
-- Cột Status
SELECT
    Status,
    COUNT(*) AS Records
FROM raw.CRM_Pipeline
where LoadBatchID = 3
GROUP BY Status
ORDER BY Records DESC;

-- Cột Stage (Lưu ý: theo dictionary của dataset thì cột Stage chỉ có giá trị khi cột Status = "Opportunity")
SELECT
    Stage,
    COUNT(*) as TotalRecords
FROM raw.CRM_Pipeline
where LoadBatchID = 3
GROUP BY Stage;

-- Có 2133 giá trị null trong cột "Stage", kiểm tra những giá trị này có cột Status = "Opportunity" hay không
select
	sum(case when Stage is null and Status != 'Opportunity'
		then 1 else 0
	end) as QualifiedNullStage
from raw.CRM_Pipeline
where LoadBatchID = 3;
-- Có 2133 giá trị null trong cột "Stage" nhưng tất cả đều có cột Status != "Opportunity", do đó không cần xử lý gì thêm cho cột Stage


-- Cột Product
SELECT
    Product,
    COUNT(*)
FROM raw.CRM_Pipeline
where LoadBatchID = 3
GROUP BY Product;


-- Kiểm tra các cột sequence có tương ứng với các cột categorical hay không
-- Cột Status_sequence
select
	Status,
	Status_sequence,
	count(*) as TotalRecords
from raw.CRM_Pipeline
where LoadBatchID = 3
group by Status, Status_sequence;
-- Kết quả cho thấy Status và Status_sequence không tương ứng với dictionary của dataset, cần xử lý lại cột Status_sequence

-- Cột Stage_sequence
select
	Stage,
	Stage_sequence,
	count(*) as TotalRecords
from raw.CRM_Pipeline
where LoadBatchID = 3
group by Stage, Stage_sequence;


-- Duplicate analysis (Mỗi Organization là 1 dòng, tương ứng 1 khách hàng)
select
	count(*) as TotalRecords,
	Organization
from raw.CRM_Pipeline
where LoadBatchID = 3
group by Organization
having count(*) > 1;


-- PHASE 4 — STAGING
/*
Staging là nơi chúng ta:
Trim strings
Fix column names
Convert datatype
Normalize Probability
Apply business-compatible transformation
Create derived fields
Flag invalid records
*/

CREATE TABLE stg.CRM_Pipeline
(
    RawRecordID BIGINT NOT NULL PRIMARY KEY,

    Organization NVARCHAR(255),
    Country NVARCHAR(100),

    Latitude DECIMAL(9,6),
    Longitude DECIMAL(9,6),

    Industry NVARCHAR(200),
    OrganizationSize NVARCHAR(100),
    Owner NVARCHAR(150),

    LeadAcquisitionDate DATE,

    Product NVARCHAR(100),

    Status NVARCHAR(100),
    StatusSequence INT,

    Stage NVARCHAR(100),
    StageSequence INT,

    DealValue DECIMAL(18,2),
    Probability DECIMAL(6,4),
    WeightedDealValue DECIMAL(18,2),

    ExpectedCloseDate DATE,
    ActualCloseDate DATE,

    LoadBatchID INT NOT NULL
);


-- Load Raw → Staging
DECLARE @LoadBatchID INT = 3;

INSERT INTO stg.CRM_Pipeline
(
    RawRecordID,
    Organization,
    Country,
    Latitude,
    Longitude,
    Industry,
    OrganizationSize,
    Owner,
    LeadAcquisitionDate,
    Product,
    Status,
    StatusSequence,
    Stage,
    StageSequence,
    DealValue,
    Probability,
    WeightedDealValue,
    ExpectedCloseDate,
    ActualCloseDate,
    LoadBatchID
)

SELECT
    RawRecordID,

    TRIM(Organization),
    TRIM(Country),

    TRY_CAST(Lattitude AS DECIMAL(9,6)),
    TRY_CAST(Longitude AS DECIMAL(9,6)),

    TRIM(Industry),
    TRIM(Organization_size),
    TRIM(Owner),

    Lead_acquisition_date,

    TRIM(Product),

    TRIM(Status),
    Status_sequence,

    TRIM(Stage),
    Stage_sequence,

    Deal_Value,

    Probability / 100.0,

    Deal_Value * Probability / 100.0,

    Expected_close_date,
    Actual_close_date,

    LoadBatchID

FROM raw.CRM_Pipeline
WHERE LoadBatchID = @LoadBatchID;


-- Xử lý cột StatusSequence để đảm bảo rằng các giá trị của nó tương ứng với dictionary của dataset
ALTER TABLE stg.CRM_Pipeline
ADD StatusSequenceNew INT;

UPDATE stg.CRM_Pipeline
SET StatusSequenceNew = CASE Status
    WHEN 'New' THEN 1
    WHEN 'Qualified' THEN 2
    WHEN 'Sales Accepted' THEN 3
    WHEN 'Opportunity' THEN 4
    WHEN 'Customer' THEN 5
    WHEN 'Churned Customer' THEN 6
    WHEN 'Disqualified' THEN 7
END;

alter table stg.CRM_Pipeline
drop column StatusSequence;

EXEC sp_rename 'stg.CRM_Pipeline.StatusSequenceNew', 'StatusSequence', 'COLUMN';

-- Kiểm tra lại
select
	Status,
	StatusSequence,
	count(*) as TotalRecords
from stg.CRM_Pipeline
where LoadBatchID = 3
group by Status, StatusSequence
order by StatusSequence;

-- Phase 5 — Data Quality
DECLARE @LoadBatchID INT = 3;

SELECT *
FROM stg.CRM_Pipeline
WHERE LoadBatchID = @LoadBatchID
  AND (Probability < 0 OR Probability > 1);

SELECT *
FROM stg.CRM_Pipeline
WHERE LoadBatchID = @LoadBatchID
  AND DealValue < 0;

-- Nếu có lỗi xuất hiện:
INSERT INTO etl.DataQualityIssue
(
    LoadBatchID,
    RawRecordID,
    ColumnName,
    IssueType,
    IssueDescription
)

SELECT
    LoadBatchID,
    RawRecordID,
    'Probability',
    'OUT_OF_RANGE',
    'Probability must be between 0 and 1.'

FROM stg.CRM_Pipeline
WHERE LoadBatchID = @LoadBatchID
  AND (Probability < 0 OR Probability > 1);


-- Phase 6 — Dimensional Modeling
-- 6.1. Tạo DimOwner
CREATE TABLE dw.DimOwner
(
    OwnerKey INT IDENTITY(1,1) PRIMARY KEY,
    OwnerName NVARCHAR(150) NOT NULL,

    CONSTRAINT UQ_DimOwner_OwnerName
        UNIQUE (OwnerName)
);

-- 6.2. Tạo DimProduct
CREATE TABLE dw.DimProduct
(
    ProductKey INT IDENTITY(1,1) PRIMARY KEY,
    ProductName NVARCHAR(100) NOT NULL,

    CONSTRAINT UQ_DimProduct_ProductName
        UNIQUE (ProductName)
);

-- 6.3 . Tạo DimStatus
CREATE TABLE dw.DimStatus
(
    StatusKey INT IDENTITY(1,1) PRIMARY KEY,
    StatusName NVARCHAR(100) NOT NULL,
    StatusSequence INT NULL,

    CONSTRAINT UQ_DimStatus_StatusName
        UNIQUE (StatusName)
);

-- 6.4. Tạo DimStage
CREATE TABLE dw.DimStage
(
    StageKey INT IDENTITY(1,1) PRIMARY KEY,
    StageName NVARCHAR(100) NOT NULL,
    StageSequence INT NULL,

    CONSTRAINT UQ_DimStage_StageName
        UNIQUE (StageName)
);

-- 6.5. Tạo DimOrganization
CREATE TABLE dw.DimOrganization
(
    OrganizationKey INT IDENTITY(1,1) PRIMARY KEY,

    OrganizationName NVARCHAR(255) NOT NULL,

    Country NVARCHAR(100),
    Latitude DECIMAL(9,6),
    Longitude DECIMAL(9,6),

    Industry NVARCHAR(200),
    OrganizationSize NVARCHAR(100),

    CONSTRAINT UQ_DimOrganization_Name
        UNIQUE (OrganizationName)
);

-- 6.6. Tạo DimOrganization
CREATE TABLE dw.DimDate
(
    DateKey INT PRIMARY KEY,

    FullDate DATE NOT NULL UNIQUE,

    [Year] INT NOT NULL,
    [Quarter] INT NOT NULL,
    [Month] INT NOT NULL,
    MonthName NVARCHAR(20) NOT NULL,

    YearMonth CHAR(7) NOT NULL,

    [Day] INT NOT NULL,
    DayOfWeek INT NOT NULL,
    DayName NVARCHAR(20) NOT NULL
);

-- 6.7. Tạo Unknown Member
-- DimOwner
SET IDENTITY_INSERT dw.DimOwner ON;

INSERT INTO dw.DimOwner
(
    OwnerKey,
    OwnerName
)
VALUES
(
    0,
    'Unknown'
);

SET IDENTITY_INSERT dw.DimOwner OFF;

-- DimOrganization
SET IDENTITY_INSERT dw.DimOrganization ON;

INSERT INTO dw.DimOrganization
(
    OrganizationKey,
    OrganizationName
)
VALUES
(
    0,
    'Unknown'
);

SET IDENTITY_INSERT dw.DimOrganization OFF;

--DimProduct
SET IDENTITY_INSERT dw.DimProduct ON;

INSERT INTO dw.DimProduct
(
    ProductKey,
    ProductName
)
VALUES
(
    0,
    'Unknown'
);

SET IDENTITY_INSERT dw.DimProduct OFF;
--DimStatus
SET IDENTITY_INSERT dw.DimStatus ON;

INSERT INTO dw.DimStatus
(
    StatusKey,
    StatusName
)
VALUES
(
    0,
    'Unknown'
);

SET IDENTITY_INSERT dw.DimStatus OFF;

--DimStage
SET IDENTITY_INSERT dw.DimStage ON;

INSERT INTO dw.DimStage
(
    StageKey,
    StageName,
    StageSequence
)
VALUES
(0, 'Unknown', NULL),
(-1, 'Not Applicable', NULL);

SET IDENTITY_INSERT dw.DimStage OFF;


-- PHASE 7 — Load Dimensions
DECLARE @LoadBatchID INT = 3;
-- 7.1 Load Owner
INSERT INTO dw.DimOwner
(
    OwnerName
)
SELECT DISTINCT
    s.Owner
FROM stg.CRM_Pipeline s
WHERE
    s.LoadBatchID = @LoadBatchID
    AND s.Owner IS NOT NULL

    AND NOT EXISTS
    (
        SELECT 1
        FROM dw.DimOwner d
        WHERE d.OwnerName = s.Owner
    );

-- 7.2 Load Product
INSERT INTO dw.DimProduct
(
    ProductName
)
SELECT DISTINCT
    s.Product
FROM stg.CRM_Pipeline s
WHERE
    s.LoadBatchID = @LoadBatchID
    AND s.Product IS NOT NULL

    AND NOT EXISTS
    (
        SELECT 1
        FROM dw.DimProduct d
        WHERE d.ProductName = s.Product
    );

    -- 7.3 Load Status
    INSERT INTO dw.DimStatus
(
    StatusName,
    StatusSequence
)
SELECT
    s.Status,
    MAX(s.StatusSequence)
FROM stg.CRM_Pipeline s
WHERE
    s.LoadBatchID = @LoadBatchID
    AND s.Status IS NOT NULL

    AND NOT EXISTS
    (
        SELECT 1
        FROM dw.DimStatus d
        WHERE d.StatusName = s.Status
    )

GROUP BY s.Status;

-- 7.4 Load Stage
INSERT INTO dw.DimStage
(
    StageName,
    StageSequence
)
SELECT
    s.Stage,
    MAX(s.StageSequence)
FROM stg.CRM_Pipeline s
WHERE
    s.LoadBatchID = @LoadBatchID
    AND s.Stage IS NOT NULL

    AND NOT EXISTS
    (
        SELECT 1
        FROM dw.DimStage d
        WHERE d.StageName = s.Stage
    )

GROUP BY s.Stage;

-- 7.5 Load Organization
INSERT INTO dw.DimOrganization
(
    OrganizationName,
    Country,
    Latitude,
    Longitude,
    Industry,
    OrganizationSize
)

SELECT
    Organization,
    MAX(Country),
    MAX(Latitude),
    MAX(Longitude),
    MAX(Industry),
    MAX(OrganizationSize)

FROM stg.CRM_Pipeline s

WHERE
    s.LoadBatchID = @LoadBatchID
    AND s.Organization IS NOT NULL

    AND NOT EXISTS
    (
        SELECT 1
        FROM dw.DimOrganization d
        WHERE d.OrganizationName = s.Organization
    )

GROUP BY Organization;

--  7.6 Load DimDate
DECLARE @MinDate DATE;
DECLARE @MaxDate DATE;

SELECT
    @MinDate = MIN(DateValue),
    @MaxDate = MAX(DateValue)
FROM stg.CRM_Pipeline
CROSS APPLY
(
    VALUES
        (LeadAcquisitionDate),
        (ExpectedCloseDate),
        (ActualCloseDate)
) d(DateValue)
WHERE DateValue IS NOT NULL;

-- Tạo DimDate từ @MinDate đến @MaxDate
;WITH Dates AS
(
    SELECT @MinDate AS FullDate

    UNION ALL

    SELECT DATEADD(DAY, 1, FullDate)
    FROM Dates
    WHERE FullDate < @MaxDate
)

INSERT INTO dw.DimDate
(
    DateKey,
    FullDate,
    [Year],
    [Quarter],
    [Month],
    MonthName,
    YearMonth,
    [Day],
    DayOfWeek,
    DayName
)

SELECT
    CONVERT(
        INT,
        CONVERT(
            CHAR(8),
            FullDate,
            112
        )
    ),

    FullDate,

    YEAR(FullDate),

    DATEPART(QUARTER, FullDate),

    MONTH(FullDate),

    DATENAME(MONTH, FullDate),

    CONVERT(CHAR(7), FullDate, 126),

    DAY(FullDate),

    DATEPART(WEEKDAY, FullDate),

    DATENAME(WEEKDAY, FullDate)

FROM Dates d

WHERE NOT EXISTS
(
    SELECT 1
    FROM dw.DimDate dd
    WHERE dd.FullDate = d.FullDate
)

OPTION (MAXRECURSION 0);

-- kiểm tra
SELECT COUNT(*) FROM dw.DimOrganization;
select * from dw.DimOrganization;
SELECT COUNT(*) FROM dw.DimOwner;
select * from dw.DimOwner;
SELECT COUNT(*) FROM dw.DimProduct;
select * from dw.DimProduct;
SELECT COUNT(*) FROM dw.DimStatus;
select * from dw.DimStatus;
SELECT COUNT(*) FROM dw.DimStage;
SELECT COUNT(*) FROM dw.DimDate;

SELECT * FROM dw.DimStatus;
SELECT * FROM dw.DimStage;


-- PHASE 8 — Create + Load Fact
-- 8.1 Tạo Fact
CREATE TABLE dw.FactPipelineOpportunity
(
    OpportunityKey BIGINT IDENTITY(1,1)
        PRIMARY KEY,

    RawRecordID BIGINT NOT NULL,

    LoadBatchID INT NOT NULL,

    OrganizationKey INT NOT NULL,
    OwnerKey INT NOT NULL,
    ProductKey INT NOT NULL,
    StatusKey INT NOT NULL,
    StageKey INT NOT NULL,

    LeadAcquisitionDateKey INT NULL,
    ExpectedCloseDateKey INT NULL,
    ActualCloseDateKey INT NULL,

    DealValue DECIMAL(18,2),

    Probability DECIMAL(6,4),

    WeightedDealValue DECIMAL(18,2),

    OpportunityCount TINYINT NOT NULL
        DEFAULT 1,

    SalesCycleDays INT NULL,

    CONSTRAINT UQ_FactPipeline_RawRecord
        UNIQUE(RawRecordID),

    CONSTRAINT FK_Fact_Organization
        FOREIGN KEY (OrganizationKey)
        REFERENCES dw.DimOrganization(OrganizationKey),

    CONSTRAINT FK_Fact_Owner
        FOREIGN KEY (OwnerKey)
        REFERENCES dw.DimOwner(OwnerKey),

    CONSTRAINT FK_Fact_Product
        FOREIGN KEY (ProductKey)
        REFERENCES dw.DimProduct(ProductKey),

    CONSTRAINT FK_Fact_Status
        FOREIGN KEY (StatusKey)
        REFERENCES dw.DimStatus(StatusKey),

    CONSTRAINT FK_Fact_Stage
        FOREIGN KEY (StageKey)
        REFERENCES dw.DimStage(StageKey),

    CONSTRAINT FK_Fact_LeadDate
        FOREIGN KEY (LeadAcquisitionDateKey)
        REFERENCES dw.DimDate(DateKey),

    CONSTRAINT FK_Fact_ExpectedDate
        FOREIGN KEY (ExpectedCloseDateKey)
        REFERENCES dw.DimDate(DateKey),

    CONSTRAINT FK_Fact_ActualDate
        FOREIGN KEY (ActualCloseDateKey)
        REFERENCES dw.DimDate(DateKey)
);

-- 8.2 Load Fact
DECLARE @LoadBatchID INT = 3;

INSERT INTO dw.FactPipelineOpportunity
(
    RawRecordID,
    LoadBatchID,

    OrganizationKey,
    OwnerKey,
    ProductKey,
    StatusKey,
    StageKey,

    LeadAcquisitionDateKey,
    ExpectedCloseDateKey,
    ActualCloseDateKey,

    DealValue,
    Probability,
    WeightedDealValue,

    OpportunityCount,
    SalesCycleDays
)

SELECT
    s.RawRecordID,

    s.LoadBatchID,

    COALESCE(org.OrganizationKey, 0),

    COALESCE(ow.OwnerKey, 0),

    COALESCE(p.ProductKey, 0),

    COALESCE(st.StatusKey, 0),

    CASE
        WHEN s.Stage IS NULL
            THEN -1

        ELSE COALESCE(sg.StageKey, 0)
    END,

    ld.DateKey,

    ed.DateKey,

    ad.DateKey,

    s.DealValue,

    s.Probability,

    s.WeightedDealValue,

    1,

    CASE
        WHEN s.ActualCloseDate IS NOT NULL
        THEN DATEDIFF(
            DAY,
            s.LeadAcquisitionDate,
            s.ActualCloseDate
        )
    END

FROM stg.CRM_Pipeline s

LEFT JOIN dw.DimOrganization org
    ON s.Organization = org.OrganizationName

LEFT JOIN dw.DimOwner ow
    ON s.Owner = ow.OwnerName

LEFT JOIN dw.DimProduct p
    ON s.Product = p.ProductName

LEFT JOIN dw.DimStatus st
    ON s.Status = st.StatusName

LEFT JOIN dw.DimStage sg
    ON s.Stage = sg.StageName

LEFT JOIN dw.DimDate ld
    ON s.LeadAcquisitionDate = ld.FullDate

LEFT JOIN dw.DimDate ed
    ON s.ExpectedCloseDate = ed.FullDate

LEFT JOIN dw.DimDate ad
    ON s.ActualCloseDate = ad.FullDate

WHERE
    s.LoadBatchID = @LoadBatchID

    AND NOT EXISTS
    (
        SELECT 1
        FROM dw.FactPipelineOpportunity f
        WHERE f.RawRecordID = s.RawRecordID
    );


-- PHASE 9 — Reconciliation: Chứng minh DW không làm mất, duplicate hoặc biến đổi sai dữ liệu.
-- 9.1 Row count
DECLARE @LoadBatchID INT = 3;

SELECT
    (
        SELECT COUNT(*)
        FROM raw.CRM_Pipeline
        WHERE LoadBatchID = @LoadBatchID
    ) AS RawRows,

    (
        SELECT COUNT(*)
        FROM stg.CRM_Pipeline
        WHERE LoadBatchID = @LoadBatchID
    ) AS StagingRows,

    (
        SELECT COUNT(*)
        FROM dw.FactPipelineOpportunity
        WHERE LoadBatchID = @LoadBatchID
    ) AS FactRows;

-- 9.2 Deal Value reconciliation
SELECT
    (
        SELECT SUM(Deal_Value)
        FROM raw.CRM_Pipeline
        WHERE LoadBatchID = @LoadBatchID
    ) AS RawDealValue,

    (
        SELECT SUM(DealValue)
        FROM stg.CRM_Pipeline
        WHERE LoadBatchID = @LoadBatchID
    ) AS StagingDealValue,

    (
        SELECT SUM(DealValue)
        FROM dw.FactPipelineOpportunity
        WHERE LoadBatchID = @LoadBatchID
    ) AS FactDealValue;

-- 9.3 Weighted value
declare @LoadBatchID INT = 3;
SELECT
    SUM(WeightedDealValue)
FROM stg.CRM_Pipeline
WHERE LoadBatchID = @LoadBatchID;

SELECT
    SUM(WeightedDealValue)
FROM dw.FactPipelineOpportunity
WHERE LoadBatchID = @LoadBatchID;

-- 9.4 Unknown dimension mapping
SELECT
    SUM(
        CASE
            WHEN OrganizationKey = 0
            THEN 1 ELSE 0
        END
    ) AS UnknownOrganization,

    SUM(
        CASE
            WHEN OwnerKey = 0
            THEN 1 ELSE 0
        END
    ) AS UnknownOwner,

    SUM(
        CASE
            WHEN ProductKey = 0
            THEN 1 ELSE 0
        END
    ) AS UnknownProduct,

    SUM(
        CASE
            WHEN StatusKey = 0
            THEN 1 ELSE 0
        END
    ) AS UnknownStatus,

    SUM(
        CASE
            WHEN StageKey = 0
            THEN 1 ELSE 0
        END
    ) AS UnknownStage

FROM dw.FactPipelineOpportunity
WHERE LoadBatchID = 3;

-- 9.5 Duplicate Fact
select RawRecordID, count(*)
from dw.FactPipelineOpportunity
group by RawRecordID
having count(*) > 1

-- 9.6 Close LoadBatch
UPDATE etl.LoadBatch
SET
    LoadEndTime = SYSDATETIME(),

    RowsLoaded =
    (
        SELECT COUNT(*)
        FROM raw.CRM_Pipeline
        WHERE LoadBatchID = 3
    ),

    LoadStatus = 'Success'

WHERE LoadBatchID = 3;


-- PHASE 10 — Data Mart
-- 10.1 mart.vw_PipelineBase
CREATE VIEW mart.vw_PipelineBase
AS

SELECT
    f.OpportunityKey,
    f.RawRecordID,
    f.LoadBatchID,

    org.OrganizationName,
    org.Country,
    org.Industry,
    org.OrganizationSize,

    ow.OwnerName,

    p.ProductName,

    st.StatusName,
    st.StatusSequence,

    sg.StageName,
    sg.StageSequence,

    leadDate.FullDate AS LeadAcquisitionDate,

    expectedDate.FullDate AS ExpectedCloseDate,

    actualDate.FullDate AS ActualCloseDate,

    f.DealValue,
    f.Probability,
    f.WeightedDealValue,

    f.OpportunityCount,

    f.SalesCycleDays

FROM dw.FactPipelineOpportunity f

JOIN dw.DimOrganization org
    ON f.OrganizationKey = org.OrganizationKey

JOIN dw.DimOwner ow
    ON f.OwnerKey = ow.OwnerKey

JOIN dw.DimProduct p
    ON f.ProductKey = p.ProductKey

JOIN dw.DimStatus st
    ON f.StatusKey = st.StatusKey

JOIN dw.DimStage sg
    ON f.StageKey = sg.StageKey

LEFT JOIN dw.DimDate leadDate
    ON f.LeadAcquisitionDateKey =
       leadDate.DateKey

LEFT JOIN dw.DimDate expectedDate
    ON f.ExpectedCloseDateKey =
       expectedDate.DateKey

LEFT JOIN dw.DimDate actualDate
    ON f.ActualCloseDateKey =
       actualDate.DateKey;

SELECT *
FROM mart.vw_PipelineBase
where StageName = 'Won';

-- 10.2 Won Deals View
CREATE VIEW mart.vw_WonDeals
as 
select count(*) as WonDeals
from mart.vw_PipelineBase
where StageName = 'Won';

select WonDeals from mart.vw_WonDeals;

-- 10.3 Open Pipeline View
create view mart.vw_OpenPipeline
as
select *
from mart.vw_PipelineBase
where StageName in ('Opened',
                    'Initial contact',
                    'Nurturing',
                     'Proposal sent');

select * from mart.vw_OpenPipeline;

select * from mart.vw_PipelineBase
-- PHASE 11 — SQL Business Analysis
-- Analysis 1 — Pipeline Health
select 
    sum(OpportunityCount) as TotalOpportunities,
    sum(DealValue) as TotalDealValue,
    sum(WeightedDealValue) as TotalWeightedDealValue,
    avg(DealValue) as AverageDealValue,
    avg(Probability) as AverageProbability
from mart.vw_PipelineBase;
/*
Interpretation: 
- DealValue có giá trị trung bình xấp xỉ 2500$ trong khi tổng lại quá cao, có thể có nhiều deal giá trị cao thất thường.
- Probability có tỉ lệ thành công thấp (chưa tới 50%), đa số khách hàng chưa đủ chắc chắn.
Business implication: 
- Kiểm tra lại các deal có giá trị cao bất thường, xem xét loại bỏ outlier để có cái nhìn chính xác hơn.
- Cần có chiến lược tăng tỉ lệ thành công, ví dụ: cải thiện chất lượng lead, nâng cao kỹ năng sales, hoặc tập trung vào các khách hàng tiềm năng hơn.
*/

-- Analysis 2 — Pipeline by Stage
select
    StageName,
    StageSequence,
    count(*) as TotalOpportunities,
    sum(DealValue) as TotalDealValue,
    avg(Probability) as AverageProbability,
    sum(WeightedDealValue) as TotalWeightedDealValue,
    AVG(DealValue) AS AvgDealValue
from mart.vw_PipelineBase
group by Stagename, StageSequence
order by StageSequence;
/*
Interpretation:
- Các stage tập trung phân bố ở giai đoạn giữa (Initial contact, Nurturing, Proposal sent)
- Mặc dù số lượng Lost ít hơn Won nhưng số tiền bị mất lại nhiều hơn (tương đương 1.5 lần so với Won)
Business implication:
- Cần đẩy mạnh các giao đoạn cơ hội với khách hàng.
- Cần phân tích lý do tại sao các deal bị Lost, có thể cải thiện quy trình bán hàng hoặc chất lượng sản phẩm/dịch vụ.
*/

-- Analysis 3 — Owner Performance
select
    OwnerName,
    sum(case when StageName = 'Won'
        then 1 else 0
        end) as WonDeals,
    sum(case when StageName = 'Won'
        then DealValue else 0
        end) as WonValue,
    cast(
    sum(case when StageName = 'Won'
        then 1 else 0
        end) *1.0 / nullif(count(*), 0)
        as decimal(10,4)
        ) as WonRate
from mart.vw_PipelineBase
group by OwnerName
order by WonRate desc;
/*
Interpretation:
- Một số Owner có tỉ lệ thắng cao nhưng tổng giá trị Won lại thấp, điều này có thể do họ chỉ tập trung vào các deal nhỏ.
- Có sự phân bổ không đều giữa các Owner, chênh lệch số lượng deal quá nhiều.
Business implication:
- Cần phân tích kỹ hơn về chiến lược của từng Owner, có thể cần điều chỉnh phân bổ khách hàng hoặc hỗ trợ thêm cho các Owner có tỉ lệ thắng thấp.
*/

-- Analysis 4 — Monthly Won Revenue + MoM


with MonthlyRevenue as (
select 
    year(ActualCloseDate) as Year,
    month(ActualCloseDate) as Month,
    sum(DealValue) as TotalDealValue,
    count(RawRecordID) as TotalDeals,
    avg(DealValue) as AverageDealValue
from mart.vw_PipelineBase
where ActualCloseDate is not null
and StatusName = 'Customer'
group by year(ActualCloseDate), month(ActualCloseDate)
),

PreviousMonthRevenue as (
    select 
        Year,
        Month,
        TotalDealValue,
        TotalDeals,
        AverageDealValue,
        lag(TotalDealValue) over (order by Year, Month) as PreviousMonthDealValue
    from MonthlyRevenue
) 
select 
    Year,
    Month,
    TotalDealValue,
    TotalDeals,
    AverageDealValue,
    PreviousMonthDealValue,
    TotalDealValue - PreviousMonthDealValue as MoMChange,
    cast(
        ((TotalDealValue - PreviousMonthDealValue) * 1.0 / nullif(PreviousMonthDealValue, 0)) as decimal(10,4)
    ) as MoMPercentageChange
from PreviousMonthRevenue;
   
 /*
 Interpretation:
 - Doanh thu hàng tháng giảm mạnh trong mức tăng trưởng mặc dù nhiều deal (tháng 5) có thể do trung bình deal thấp.
 Business implication:
 - Cần phân tích nguyên nhân của sự biến động này, có thể do yếu tố mùa vụ, chiến dịch marketing, hoặc các yếu tố bên ngoài khác.
 */

 -- Analysis 5 — Industry Performance
 select 
    Industry,
    sum(DealValue) as TotalDealValue,
    count(RawRecordID) as TotalDeals,
    avg(DealValue) as AverageDealValue,
    sum(case when StatusName = 'Customer'
        then 1 else 0
        end) as WonDeals,
    sum(case when StatusName = 'Customer'
        then DealValue else 0
        end) as WonValue
from mart.vw_PipelineBase
group by Industry
order by WonValue desc;

/*
Interpretation:
- Có sự chênh lệch lớn về doanh thu giữa các ngành, chiếm nhiều nhất là Transportation & Logistics,
Banking and Finance, doanh thu chủ yếu từ 2 ngày này.
- Mặc dù có giá trị thấp nhất nhưng Recreation & Sports lại có giá trị trung bình cao nhất, có thể là tiềm năng.
- Tỉ lệ thắng nhỏ so với tổng số deal ở tất cả các ngành.
Business implication:
- Nghiên cứu lại chiến lược marketing và bán hàng để nâng cao tỉ lệ thắng ở tất cả các ngành.
*/

-- Analysis 6 — Sales Cycle
SELECT
    Industry,

    COUNT(*) AS ClosedDeals,

    AVG(
        CAST(
            SalesCycleDays
            AS DECIMAL(10,2)
        )
    ) AS AvgSalesCycleDays

FROM mart.vw_PipelineBase

WHERE SalesCycleDays IS NOT NULL

GROUP BY Industry

ORDER BY AvgSalesCycleDays;

/*
Interpretation: số deal đóng giữa các ngành quá chênh lệch
                Recreation & Sports và Energy & Utilities quá ít deal để chắc chắn về ngày đóng deal
Business implication: gợi ý tìm kiếm khách hàng ở ngành để tăng tính chính xác của thống kê.     
*/

-- Analysis 7 — Top 3 Owner mỗi Industry
select * from mart.vw_OpenPipeline;

WITH OwnerIndustryRevenue AS
(
    SELECT
        Industry,
        OwnerName,

        SUM(DealValue) AS WonRevenue

    FROM mart.vw_PipelineBase
    where StatusName = 'Customer'
    GROUP BY
        Industry,
        OwnerName
),

RankedOwner AS
(
    SELECT
        Industry,
        OwnerName,
        WonRevenue,

        DENSE_RANK() OVER
        (
            PARTITION BY Industry
            ORDER BY WonRevenue DESC
        ) AS RevenueRank

    FROM OwnerIndustryRevenue
)

SELECT *
FROM RankedOwner

WHERE RevenueRank <= 3

ORDER BY
    Industry,
    RevenueRank;
/*
Interpretation: Một số Owner có doanh thu cao trong ngành nhưng lại không phải là top 3 trong ngành khác, điều này cho thấy sự phân bổ khách hàng và chiến lược bán hàng của từng Owner có thể khác nhau.
Business implication: Cần phân tích chiến lược của từng Owner trong từng ngành để tối ưu hóa doanh thu và phân bổ khách hàng hợp lý.
*/

-- Analysis 8 — Pipeline Prioritization
SELECT
    OrganizationName,
    OwnerName,
    StageName,
    DealValue,
    Probability,

    DATEDIFF(
        DAY,
        LeadAcquisitionDate,
        GETDATE()
    ) AS DealAgeDays,

    CASE

        WHEN DealValue >= 1500
             AND Probability >= 0.7
        THEN 'High Priority'

        WHEN DealValue >= 1000
        THEN 'Medium Priority'

        ELSE 'Normal'

    END AS ReviewPriority

FROM mart.vw_OpenPipeline

ORDER BY
    CASE

        WHEN DealValue >= 1500
             AND Probability >= 0.7
        THEN 1

        WHEN DealValue >= 1000
        THEN 2

        ELSE 3

    END,

    DealValue DESC;
/*
Interpretation: Các deal có giá trị cao và xác suất thành công
 cao được phân loại là ưu tiên cao, trong khi các deal có giá trị thấp hơn hoặc xác suất thành công thấp hơn được phân loại là ưu tiên trung bình hoặc bình thường.
Business implication: Cần tập trung nguồn lực và chiến lược bán hàng vào các deal ưu tiên cao để tối đa hóa doanh thu và hiệu quả kinh doanh.
*/