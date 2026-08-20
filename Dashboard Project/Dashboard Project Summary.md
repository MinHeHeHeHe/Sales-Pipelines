# Dashboard Project Summary

**Dự Án:** Sales Pipeline Data Analysis  
**Ngành:** Data Analysis / Business Intelligence  
**Ngày Hoàn Thành:** 08/2026  
**Công Cụ Sử Dụng:** Excel, Power BI,

---

## 📋 Mục Lục
1. [Data Audit](#1-data-audit)
2. [Data Cleaning](#2-data-cleaning)
3. [Xác Định KPI](#3-xác-định-kpi)
4. [Exploratory Pivot Table](#4-exploratory-pivot-table)
5. [Data Model](#5-data-model)
6. [DAX & Calculations](#6-dax--calculations)
7. [Dashboard](#7-dashboard)
8. [Insight](#8-insight)
9. [Insight Validation](#9-insight-validation)
10. [Recommendation](#10-recommendation)
11. [Limitation](#11-limitation)
12. [Executive Summary](#12-executive-summary)

---

## 1. Data Audit

### 🎯 Mục Tiêu
Kiểm tra chất lượng, độ đầy đủ và độ tin cậy của dữ liệu nguồn.

### 📊 Nguồn Dữ Liệu
- **File dữ liệu thô:** CRM and Sales Pipelines.xlsx
- **File dữ liệu đã làm sạch / dùng cho phân tích:** Book1.xlsx
- **Bảng Dữ Liệu:** Fact_CRM_Pipeline (trên dữ liệu cleaned)
- **Số Lượng Hàng:** 3,003 rows
- **Các trường Chính:** 
  - Organization (Tên tổ chức)
  - Country (Quốc gia)
  - Industry (Ngành công nghiệp)
  - Owner (Người quản lý)
  - Lead acquisition date (Ngày tiếp nhận)
  - Product (Loại sản phẩm)
  - Status (Trạng thái)
  - Stage (Giai đoạn)
  - Deal Value ($) (Giá trị giao dịch)
  - Probability (%) (Xác suất thành công)

### Nội dung Audit
- Xem sheet "Data Audit" file book1.xlsx

### ✅ Kết Quả Audit
- ✓ Dữ liệu đầy đủ, không có null values đáng kể
- ✓ Độ tin cậy cao, các giá trị trong phạm vi hợp lý
- ✓ Không phát hiện duplicate records
- ✓ Định dạng dữ liệu consistent

*Dữ liệu thô được lấy từ file `CRM and Sales Pipelines.xlsx`, sau đó đã được làm sạch và lưu thành `Book1.xlsx` để làm file phân tích chính. Audit được thực hiện trên dữ liệu cleaned này.*

---

## 2. Data Cleaning

### 🎯 Mục Tiêu
Loại bỏ dữ liệu nhiễu, chuẩn hóa format, xử lý missing values từ dữ liệu thô trước khi đưa vào phân tích.

### 🔧 Quy Trình Xử Lý

1	Đổi tên cột Lattitude thành Latitude để trùng với Dictionary
2	Chuyển Deal Value sang Currency.
3	Chuyển Probability sang Decimal.
4	Loại bỏ khoảng trắng thừa trong Industry.
5	Kiểm tra các Organization trùng nhau.
6	"Tạo cột Weighted Deal Value
= Deal Value × Probability / 100"
7	"Tạo cột Close Variance Days
= Actual Close Date − Expected Close Date"
8	"Tạo cột Is Open Opportunity
= Status = ""Opportunity""
và Stage không thuộc ""Won"", ""Lost"""
9	"Tạo cột Close Status:
Close Variance Days < 0  → Early
Close Variance Days = 0  → On Time
Close Variance Days > 0  → Late"
10	Is Opportunity: Status = Opportunity
11	Is Ever Customer: Status = Customer hoặc Churned Customer
12	Is Current Customer: Status = Customer
13	Is Churned: Status = Churned Customer
14	Is Won: Stage = Won
15	Is Lost: Stage = Lost
16	Is Closed Opportunity: Stage là Won hoặc Lost


### ✅ Kết Quả
- Dữ liệu sạch, sẵn sàng cho phân tích
- 3,003 records được xác nhận hợp lệ
- Không có records bị loại bỏ

*Dữ liệu trong file `Book1.xlsx` là dữ liệu đã cleaned; dữ liệu thô ban đầu nằm ở `CRM and Sales Pipelines.xlsx`.*

---

## 3. Xác Định KPI

### 🎯 Mục Tiêu
Định nghĩa các chỉ số hiệu suất chính để đo lường hiệu quả kinh doanh.

### 📈 Các KPI Chính

| Nhóm KPI | KPI | Business Definition |
|----------|-----|---------------------|
| Pipeline | Total Leads | Count Organization |
| Pipeline | Total Opportunities | Sum Is Opportunity |
| Pipeline | Open Opportunities | Sum Is Open Opportunity |
| Pipeline | Ever Customers | Sum Is Ever Customer |
| Pipeline | Current Customers | Sum Is Current Customer |
| Pipeline | Lead Conversion Rate | Ever Customers / Total Leads |
| Pipeline | Retention Rate | Current Customers / Ever Customers |
| Pipeline | Churn Rate | Churned Customers / Ever Customers |
| Opportunity | Won Opportunities | Sum Is Won |
| Opportunity | Lost Opportunities | Sum Is Lost |
| Opportunity | Closed Opportunities | Won + Lost |
| Opportunity | Opportunity Win Rate | Won / Closed Opportunities |
| Opportunity | Opportunity Lost Rate | Lost / Closed Opportunities |
| Opportunity | Open Pipeline Value | Deal Value của open opportunity |
| Opportunity | Weighted Open Pipeline | Weighted Deal Value của Open Opportunity |
| Opportunity | Average Open Deal Size | Open Pipeline Value / Open Opportunities |
| Opportunity | Lost Opportunity Value | Deal Value của stage Lost |
| Forecast | Forecast Deal Value | Weighted Deal Value của Open Opportunity |
| Forecast | Forecast Deal Count | Số Open Opportunity theo Expected Close Month |
| Forecast | Average Forecast Probability | Average Probability của Open Opportunity |
| Forecast | Forecast Concentration | Tỷ trọng forecast theo Owner/Product/Country |
| Close Accuracy | Actual Closed Deals | Count Actual Close Date |
| Close Accuracy | Average Close Variance Days | Average Close Variance Days |
| Close Accuracy | Early Close Rate | Early / Actual Closed Deals |
| Close Accuracy | Late Close Rate | Late / Actual Closed Deals |
| Close Accuracy | On-time Before Rate | Early + On Time / Actual Closed Deals |

*Chi tiết KPI được ghi chú trong sheet "KPI Definition" của Book1.xlsx*

---

## 4. Exploratory Pivot Table

### 🎯 Mục Tiêu
Khám phá dữ liệu từ nhiều góc độ để phát hiện pattern, trend và anomaly.

### 🔍 Các Pivot Table Chính

#### Pivot 00 — Kiểm tra KPI tổng quan
#### Pivot 01 — Phân bố trạng thái Lead
- Lead hiện đang tập trung ở trạng thái nào?
- Có bao nhiêu Lead mới, Qualified, Opportunity và Customer?
- Giá trị hợp đồng tiềm năng tập trung ở trạng thái nào?

#### Pivot 02 — Sức khỏe Opportunity Pipeline
- Opportunity đang tập trung ở Stage nào?	
- Stage nào giữ nhiều giá trị hợp đồng nhất?	
- Giá trị Pipeline sau điều chỉnh xác suất là bao nhiêu?	
- Có quá nhiều Deal đang nằm ở giai đoạn đầu hay không?	

#### Pivot 03 — Phân tích phân khúc khách hàng

#### Pivot 04 — Hiệu suất Sales Agent

#### Pivot 05 — Forecast theo Expected Close Datee

#### Pivot 06 — Độ chính xác ngày đóng Deal

#### Pivot 07 — Lost Opportunity Analysis
- Phân khúc nào có Lost Rate cao?
- Lost Opportunity Value tập trung ở đâu?
- Có nhiều Deal Probability cao nhưng vẫn Lost không?

#### Pivot 08 — Churn Analysis
- Nhóm khách hàng nào có Churn Rate cao?
- Churn tập trung ở Product, Country hay Industry nào?
- Giá trị khách hàng đã Churn là bao nhiêu?

*Chi tiết Pivot Tables được tạo trong Book1.xlsx*

---

## 5. Data Model

### 🎯 Mục Tiêu
Xây dựng cấu trúc dữ liệu tối ưu để hỗ trợ phân tích và trực quan hóa trong Power BI.

### 📐 Kiến Trúc Star Schema

![Alt text]("/Data model.png")

---

## 6. DAX & Calculations
*Chi tiết DAX đã được tạo trong Power BI file (Sales Pipelines.pbix)*

---

## 7. Dashboard

### 🎯 Mục Tiêu
Trực quan hóa các KPI và insights thông qua interactive dashboard.

### 📊 Cấu Trúc Dashboard

#### **Trang 1: Overview**
![Alt text]("/Dashboard image/Overview.png")

#### **Trang 2: Pipeline Quality & Priority**
![Alt text]("/Dashboard image/Pipeline Quality & Priority.png")

#### **Trang 3: Sales Performance**
![Alt text]("/Dashboard image/Sales Performance.png")

#### **Trang 4: Customer Insights**
![Alt text]("/Dashboard image/Customer Insights.png")

*Dashboard được tạo chi tiết trong Power BI file (Sales Pipelines.pbix)*

---

## 8. Insight

*Chi tiết Insights được thuyết trình trong file PowerPoint (CRM & Sales Pipeline Insights and Recommendations.pptx)*

---

## 9. Insight Validation

### 🎯 Mục Tiêu
Xác thực tính chính xác của insights bằng cách so sánh giữa nhiều nguồn dữ liệu.

### ✅ Quy Trình Kiểm Chứng
- Sử dụng 2 nguồn dưới đây, so sánh các kpi và biểu đồ giữa 2 nguồn để tăng tính xác thực.
 **Validation Source 1: KPI vs Dashboard**

 **Validation Source 2: Pivot Table**


### 📊 Kết Quả Validation
- Dữ liệu consistent giữa Power BI, Pivot Tables

---

## 10. Recommendation

*Chi tiết Recommendation được thuyết trình trong file PowerPoint (CRM & Sales Pipeline Insights and Recommendations.pptx)*

---

## 11. Limitation

- Dataset là historical data nên không chứng minh causality
- Actual Close Date bị thiếu nhiều nên một số phân tích close-date bị hạn chế

*Chi tiết Limitation được thuyết trình trong file PowerPoint (CRM & Sales Pipeline Insights and Recommendations.pptx)*

---

## 12. Executive Summary

*Chi tiết Executive Summary được thuyết trình trong file PowerPoint (CRM & Sales Pipeline Insights and Recommendations.pptx)*

---


## 📌 Conclusion

Project này minh họa quy trình phân tích dữ liệu từ đầu đến cuối, từ dữ liệu thô cho đến các đề xuất kinh doanh. Phân tích Sales Pipeline đã xác định những cơ hội đáng kể để tăng trưởng doanh thu thông qua việc theo dõi tệp khách hàng, tập trung nguồn lực vào cơ hội cần thiết và điều chỉnh năng lực của đội ngũ bán hàng khi họ gặp khó khăn trong việc tiếp xúc với khách hàng.

---

**Document Version:** 1.0  
**Last Updated:** August 2026    
