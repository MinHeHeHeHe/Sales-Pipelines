# CRM & Sales Pipeline Analytics Database Project

## Tổng Quan Dự Án

**Mục Tiêu:** Xây dựng một analytical database trong SQL Server để quản lý và phân tích dữ liệu CRM từ dữ liệu Excel để trả lời các câu hỏi kinh doanh về sales pipeline.

**Nguồn Dữ Liệu:** `CRM and Sales Pipelines.csv`

**Công Nghệ Sử Dụng:** SQL Server, Dimensional Modeling (Star Schema), ETL Pipeline

---

## Kiến Trúc Database

### Database: `CRM_Analytics`

#### **Schemas:**
1. **raw** - Chứa dữ liệu thô được import từ CSV, không chỉnh sửa
2. **stg** - Staging layer, dữ liệu được làm sạch, validate, tính toán các measure
3. **dw** - Data Warehouse layer, chứa dimensional model với Fact và Dimension tables
4. **mart** - Data Mart layer, chứa views và reports cho business users
5. **etl** - Chứa metadata và logs cho quá trình ETL

---

## Quy Trình ETL Chi Tiết (12 Phases)

### **PHASE 0: Business Understanding**
- Hiểu rõ dữ liệu source từ file CSV
- Xác định các measures (thước đo): dealValue, probability, weighting
- Xác định các dimensions (chiều): Organization, Owner, Product, Status, Stage, Date, Country, Industry
- Xác định các facts từ business logic

### **PHASE 1: Database, Schema & ETL Metadata Setup**
**Công việc:**
- Tạo database `CRM_Analytics`
- Tạo 5 schemas: raw, stg, dw, mart, etl
- Tạo ETL metadata tables:
  - `etl.LoadBatch` - Theo dõi quá trình load dữ liệu (LoadBatchID, SourceFileName, LoadStartTime, LoadEndTime, RowsLoaded, LoadStatus)
  - `etl.DataQualityIssue` - Ghi log các lỗi data quality

**Bảng Raw:**
- `raw.CRM_Pipeline` - Bảng chứa dữ liệu thô từ CSV với các cột:
  - Thông tin tổ chức: Organization, Country, Latitude, Longitude, Industry, Organization_size
  - Thông tin contact: Owner, Lead_acquisition_date
  - Thông tin deal: Product, Status, Status_sequence, Stage, Stage_sequence, Deal_Value, Probability
  - Timeline: Expected_close_date, Actual_close_date
  - Metadata: RawRecordID, LoadBatchID

### **PHASE 2: Start Load Batch + Raw Data Ingestion**
**Công việc:**
- Khởi tạo LoadBatch record trong `etl.LoadBatch`
- Tạo bảng landing table `raw.CRM_Pipeline_Landing` để import dữ liệu từ CSV
- Chuyển đổi dữ liệu từ Landing → Raw table
- Ghi lại thông tin: số rows loaded, thời gian load, status
- Validate row count từ Landing = Raw

### **PHASE 3: Data Profiling**
**Công việc:**
- Phân tích phân bổ dữ liệu bằng các queries chi tiết:
  - Row count: Số records tổng cộng
  - NULL profile: Kiểm tra các cột có NULL (Stage, Stage_sequence, Deal_Value, Probability, Actual_close_date)
  - Domain values: Kiểm tra min/max của Deal_Value, Probability
  - Categorical values: Unique values của Status, Stage, Product
  - Status & Sequence validation: Kiểm tra sự tương ứng giữa Status/StatusSequence và Stage/StageSequence
  - Duplicate analysis: Kiểm tra duplicate records theo Organization
- Kết quả profiling cung cấp insights về chất lượng dữ liệu

### **PHASE 4: STAGING (Data Transformation)**
**Công việc:**
Tạo bảng `stg.CRM_Pipeline` và transform dữ liệu:
- **String Trimming:** TRIM() cho tất cả các column text
- **Data Type Conversion:** 
  - Lattitude, Longitude: TRY_CAST thành DECIMAL(9,6)
  - Dates giữ nguyên định dạng DATE
- **Probability Normalization:** 
  - Raw: 0-100 → Staging: 0.0000-1.0000 (chia cho 100)
- **Calculated Fields:**
  - `WeightedDealValue = DealValue × Probability`
- **Status Sequence Mapping:**
  - Fix StatusSequence không đúng trong raw data
  - Ánh xạ: New(1) → Qualified(2) → Sales Accepted(3) → Opportunity(4) → Customer(5) → Churned Customer(6) → Disqualified(7)
- Load transform từ Raw → Staging

### **PHASE 5: Data Quality Checks**
**Công việc:**
Validate dữ liệu và ghi log các lỗi:
- **Value Range Checks:**
  - Probability phải 0 ≤ Probability ≤ 1
  - Deal_Value phải > 0
- **Ghi DataQualityIssue:** Các records không pass validation được flag vào `etl.DataQualityIssue` với:
  - IssueType: OUT_OF_RANGE
  - IssueDescription: Chi tiết lỗi

### **PHASE 6: Dimensional Modeling (Star Schema)**
**Công việc:**
Tạo dimension tables trong `dw` schema:

1. **DimOwner**
   - OwnerKey (PK, IDENTITY), OwnerName
   - Unique constraint trên OwnerName

2. **DimProduct**
   - ProductKey (PK, IDENTITY), ProductName
   - Unique constraint trên ProductName

3. **DimStatus**
   - StatusKey (PK, IDENTITY), StatusName, StatusSequence
   - Unique constraint trên StatusName

4. **DimStage**
   - StageKey (PK, IDENTITY), StageName, StageSequence
   - Unique constraint trên StageName

5. **DimOrganization**
   - OrganizationKey (PK, IDENTITY), OrganizationName, Country, Latitude, Longitude, Industry, OrganizationSize
   - Unique constraint trên OrganizationName

6. **DimDate**
   - DateKey (PK, INT format YYYYMMDD), FullDate, Year, Quarter, Month, MonthName, YearMonth, Day, DayOfWeek, DayName
   - Unique constraint trên FullDate

7. **Unknown Member Rows:**
   - Insert OwnerKey = 0, ProductKey = 0, StatusKey = 0, StageKey = 0/−1, OrganizationKey = 0 cho xử lý unknown values

### **PHASE 7: Load Dimensions**
**Công việc:**
- Load distinct values từ `stg.CRM_Pipeline` vào các dimension tables
- 7.1 **Load DimOwner:** Distinct Owner từ staging
- 7.2 **Load DimProduct:** Distinct Product từ staging
- 7.3 **Load DimStatus:** Distinct Status + StatusSequence từ staging
- 7.4 **Load DimStage:** Distinct Stage + StageSequence từ staging
- 7.5 **Load DimOrganization:** Distinct Organization + attributes (Country, Lat/Long, Industry, Size) từ staging
- 7.6 **Load DimDate:** Tạo calendar từ MIN(DateValue) đến MAX(DateValue) trong staging
  - DateValue bao gồm: LeadAcquisitionDate, ExpectedCloseDate, ActualCloseDate
- Sử dụng NOT EXISTS để tránh duplicate inserts
- Sử dụng SCD Type 1 (no versioning) cho các dimensions

### **PHASE 8: Create + Load Fact Table**
**Công việc:**

8.1 **Tạo Fact Table `dw.FactPipelineOpportunity`:**
- OpportunityKey (PK, BIGINT IDENTITY)
- Foreign Keys:
  - OrganizationKey → DimOrganization
  - OwnerKey → DimOwner
  - ProductKey → DimProduct
  - StatusKey → DimStatus
  - StageKey → DimStage
  - LeadAcquisitionDateKey → DimDate
  - ExpectedCloseDateKey → DimDate
  - ActualCloseDateKey → DimDate
- Facts:
  - DealValue, Probability, WeightedDealValue
  - OpportunityCount (DEFAULT 1)
  - SalesCycleDays (DATEDIFF nếu ActualCloseDate not NULL)
- Metadata: RawRecordID, LoadBatchID
- Constraints: UNIQUE(RawRecordID), FOREIGN KEYs

8.2 **Load Fact từ Staging:**
- Join stg.CRM_Pipeline với các dimensions để lấy surrogate keys
- COALESCE(DimensionKey, 0) để map unknown values
- Tính SalesCycleDays = DATEDIFF(DAY, LeadAcquisitionDate, ActualCloseDate) khi ActualCloseDate IS NOT NULL
- Load tất cả rows từ staging (nếu chưa exists trong fact)

### **PHASE 9: Reconciliation**
**Công việc:**
Đảm bảo data integrity trong toàn bộ pipeline:

9.1 **Row Count Reconciliation:**
   - Raw rows = Staging rows = Fact rows (không mất hoặc duplicate records)

9.2 **Deal Value Reconciliation:**
   - SUM(DealValue) từ raw = stg = fact

9.3 **Weighted Value Verification:**
   - SUM(WeightedDealValue) từ stg = fact

9.4 **Unknown Dimension Mapping:**
   - Kiểm tra số lượng unknown values (Key = 0) trong các dimensions

9.5 **Duplicate Fact Detection:**
   - Kiểm tra có duplicate RawRecordID trong fact table

9.6 **Close LoadBatch:**
   - UPDATE etl.LoadBatch: LoadEndTime, RowsLoaded, LoadStatus = 'Success'

### **PHASE 10: Data Mart - Dimensional Views**
**Công việc:**
Tạo các views trong `mart` schema để serve business users:

10.1 **vw_PipelineBase** - Core view kết hợp tất cả dimensions với fact table
   - Joins: FactPipelineOpportunity LEFT/JOIN các DIM tables
   - Fields: OrganizationName, Country, Industry, OrganizationSize, OwnerName, ProductName, StatusName, StageName, Dates, Deal metrics

10.2 **vw_WonDeals** - View cho các deals đã thắng (StageName = 'Won')

10.3 **vw_OpenPipeline** - View cho các open opportunities (Stages: 'Opened', 'Initial contact', 'Nurturing', 'Proposal sent')

### **PHASE 11: SQL Business Analysis**
**Công việc:**

#### **Analysis 1: Pipeline Health**
```
Metrics:
- Total Opportunities: Số lượng cơ hội bán hàng
- Total Deal Value: Tổng giá trị của tất cả deals
- Total Weighted Deal Value: Sum(DealValue × Probability)
- Average Deal Value: Giá trị trung bình
- Average Probability: Xác suất thành công trung bình
```
**Insights:** DealValue trung bình ~$2,500 nhưng có giá trị cao bất thường (outliers). Probability trung bình < 50% cho thấy đa số khách hàng chưa chắc chắn → cần cải thiện chất lượng lead và skill sales.

#### **Analysis 2: Pipeline by Stage**
```
Metrics by Stage:
- Total Opportunities
- Total Deal Value
- Average Probability
- Total/Average Weighted Deal Value
```
**Insights:** 
- Deals tập trung ở giai đoạn giữa (Initial Contact, Nurturing, Proposal Sent)
- Mặc dù Lost deals ít hơn Won nhưng giá trị mất đi tương đương 1.5x Won value → cần phân tích nguyên nhân tại sao các deals lớn bị Lost

#### **Analysis 3: Owner Performance**
```
Metrics by Owner:
- Won Deals (count)
- Won Value (sum)
- Won Rate (Won Deals / Total Deals)
```
**Insights:**
- Variation lớn giữa các sales owners trong tỉ lệ thắng
- Một số owner có tỉ lệ thắng cao nhưng tổng value thấp (chỉ tập trung deal nhỏ)
- Phân bổ deals không đều → cần điều chỉnh lại phân bổ khách hàng hoặc training

#### **Analysis 4: Monthly Won Revenue + MoM (Month-over-Month)**
```
Metrics:
- Year, Month, TotalDealValue, TotalDeals, AverageDealValue
- MoM Change (tháng hiện tại - tháng trước)
- MoM % Change
```
**Insights:** Doanh thu biến động theo mùa hoặc campaign → cần phân tích yếu tố ảnh hưởng (campaign timing, market conditions, team changes)

#### **Analysis 5: Industry Performance**
```
Metrics by Industry:
- Total Deal Value, Total Deals, Average Deal Value
- Won Deals, Won Value
```
**Insights:**
- Transportation & Logistics, Banking & Finance dẫn đầu về doanh thu
- Recreation & Sports có average deal value cao nhất (high-value deals) mặc dù volume thấp → cơ hội tập trung
- Tỉ lệ thắng chung rất thấp (< 20%) → cần cải thiện strategy

#### **Analysis 6: Sales Cycle by Industry**
```
Metrics:
- Average Sales Cycle Days (từ Lead Acquisition đến Actual Close)
- Min/Max Sale Cycle
- Correlation với Deal Value
```
**Insights:** Xác định sales cycle trends, industries có cycle dài hoặc ngắn. Một số industries (Recreation & Sports, Energy & Utilities) có ít closed deals nên cần tăng volume để chắc chắn dữ liệu.

#### **Analysis 7: Top 3 Owner Each Industry**
```
Metrics by Industry & Owner:
- Industry
- OwnerName
- Won Revenue (sum DealValue cho STATUS = 'Customer')
- Revenue Rank (Dense Rank theo descending Won Revenue)
```
**Insights:** Một số Owner có doanh thu cao trong ngành nhưng không phải top 3 trong ngành khác → cho thấy sự phân bổ khách hàng và chiến lược bán hàng của từng Owner khác nhau → cần optimize lead distribution và training per industry.

#### **Analysis 8: Pipeline Prioritization**
```
Metrics:
- OrganizationName, OwnerName, StageName
- DealValue, Probability
- Deal Age Days (từ Lead Acquisition đến Today)
- Review Priority (High/Medium/Normal):
  - High: DealValue >= 1500 AND Probability >= 0.7
  - Medium: DealValue >= 1000
  - Normal: Còn lại
```
**Insights:** Xác định các deals cần ưu tiên theo giá trị và xác suất thành công, giúp team focus vào high-value opportunities.

---

## Dữ Liệu Source

**File:** `CRM and Sales Pipelines.csv`

**Các cột chính:**
- Organization, Country, Latitude, Longitude
- Industry, Organization_size
- Owner, Product, Status, Stage
- Lead_acquisition_date, Expected_close_date, Actual_close_date
- Deal_Value, Probability

---

## Key Metrics & Calculations

### Business Metrics:
1. **Weighted Deal Value** = Deal Value × Probability
   - Chuẩn hóa deal value dựa trên xác suất thành công
   - Dùng cho forecasting doanh thu

2. **Sales Cycle Days** = DATEDIFF(Lead Acquisition Date, Actual Close Date)
   - Đo độ dài của quá trình bán hàng
   - Dùng cho efficiency analysis

3. **Win Rate** = Won Deals / Total Deals
   - Xác suất thành công của team
   - Dùng để so sánh performance giữa các owner/stage/industry

---

## Quy Trình Data Flow

```
CSV File
   ↓
raw.CRM_Pipeline (Raw Data Layer)
   ↓
stg.CRM_Pipeline (Staging - Cleaning, Validation, Transformation)
   ↓
dw.Dimensions + dw.FactPipelineOpportunity (Data Warehouse - Star Schema)
   ↓
mart.vw_* Views (Data Mart - Business Friendly Views)
   ↓
Analytics & Reports (Business Insights)
```

---

## Loại Bỏ Outliers & Data Quality Checks

- **Deal Value Outliers:** Deals có giá trị quá cao so với average nên được kiểm tra manual
- **Invalid Dates:** Actual_close_date < Lead_acquisition_date
- **Invalid Probability:** > 1 hoặc < 0
- **Invalid Status Sequence:** Status sequence không tuân thứ tự

---

## Business Questions Được Trả Lời

Từ dữ liệu và dimensional model này, Sales Manager có thể trả lời:

1. **Pipeline Health:**
   - Tổng pipeline value? Weighted pipeline value là bao nhiêu?
   - Average deal size và success probability?

2. **Performance by Stage:**
   - Ở stage nào delay nhiều nhất?
   - Stage nào có win rate cao nhất/thấp nhất?
   - Mất bao nhiêu money ở Lost stage?

3. **Owner/Team Performance:**
   - Owner nào có win rate cao nhất?
   - Owner nào xử lý deal value lớn nhất?
   - Có chênh lệch công bằng trong phân bổ deals?

4. **Revenue Forecasting:**
   - Doanh thu dự kiến tháng/quý/năm tiếp theo (dựa weighted value)?
   - MoM growth trend?

5. **Industry & Market Analysis:**
   - Industry nào contributing nhiều nhất?
   - Industry nào có potential growth?
   - Sales cycle khác nhau giữa các industry?

6. **Strategic Insights:**
   - Vì sao Lost deals value cao hơn Won deals?
   - Cần cải thiện ở đâu: lead quality, sales skill, product, pricing?
   - Có pattern nào trong deals nào fail?

---

## Kết Luận

Dự án này xây dựng một comprehensive analytical database theo best practices của ETL & Data Warehouse:
- **Enterprise-grade architecture** với raw → stg → dw → mart layers
- **Data quality controls** từ raw data ingestion đến final reconciliation
- **Business-friendly views** để team dễ dàng access insights
- **6 deep analyses** để support strategic decision making

Kết quả là Sales Manager có thể dễ dàng theo dõi pipeline health, xác định bottlenecks, tối ưu team performance, và dự đoán doanh thu một cách chính xác.
