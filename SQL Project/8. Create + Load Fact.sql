use CRM_Analytics;
go

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