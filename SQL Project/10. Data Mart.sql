use CRM_Analytics;
go

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