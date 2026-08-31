use CRM_Analytics;
go

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