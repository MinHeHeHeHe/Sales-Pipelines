use CRM_Analytics;
go

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
