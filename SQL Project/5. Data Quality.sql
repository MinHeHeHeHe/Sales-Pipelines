use CRM_Analytics;
go

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