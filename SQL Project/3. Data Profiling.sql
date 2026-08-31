use CRM_Analytics;
go

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