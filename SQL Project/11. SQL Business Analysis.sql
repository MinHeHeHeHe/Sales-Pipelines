use CRM_Analytics;
go

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