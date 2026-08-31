use CRM_Analytics;
go

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