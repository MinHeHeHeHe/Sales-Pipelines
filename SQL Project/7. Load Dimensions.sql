use CRM_Analytics;
go

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