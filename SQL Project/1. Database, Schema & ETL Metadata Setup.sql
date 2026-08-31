-- PHASE 0 — Business Understanding (Hiểu data, xác định measure, dim, fact)

-- PHASE 1 — Database, Schema & ETL Metadata Setup
-- PHASE 1.1 — Tạo Database
create database CRM_Analytics;
go

use CRM_Analytics;
go

SELECT DB_NAME() AS CurrentDatabase; -- Kiểm tra database hiện tại


-- PHASE 1.2 — Tạo Schema
create SCHEMA raw;
go

create schema stg;
go

create schema dw;
go

create schema mart;
go

create schema etl;
go

-- 1.3. Tạo etl.LoadBatch
CREATE TABLE etl.LoadBatch
(
    LoadBatchID INT IDENTITY(1,1)
        PRIMARY KEY,

    SourceFileName NVARCHAR(255),

    LoadStartTime DATETIME2 NOT NULL
        DEFAULT SYSDATETIME(),

    LoadEndTime DATETIME2 NULL,

    RowsLoaded INT NULL,

    LoadStatus VARCHAR(20) NOT NULL
        DEFAULT 'Running'
);

-- 1.4. Data Quality log
CREATE TABLE etl.DataQualityIssue
(
    IssueID BIGINT IDENTITY(1,1)
        PRIMARY KEY,

    LoadBatchID INT,

    RawRecordID BIGINT,

    ColumnName VARCHAR(100),

    IssueType VARCHAR(100),

    IssueDescription NVARCHAR(500),

    DetectedAt DATETIME2
        DEFAULT SYSDATETIME()
);