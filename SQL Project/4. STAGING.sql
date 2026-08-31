use CRM_Analytics;
go

-- PHASE 4 — STAGING
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