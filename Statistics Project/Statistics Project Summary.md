# Statistics Project Summary

**Dự án:** Sales Pipeline Statistical Validation  
**Ngành:** Data Analysis / Statistics / Sales Analytics  
**Năm:** 2026  
**Sản phẩm:** `Statistics Analysis.xlsx` (và dữ liệu nền từ CRM and Sales Pipelines.xlsx)  
**Mục tiêu chính:** kiểm tra tính hợp lý của cột Probability và đánh giá cột này có phản ánh đúng xác suất thực tế của các cơ hội Won/Lost hay không.

---

## 1. Bối cảnh và lý do thực hiện dự án

Khi xem dashboard kết quả tháng 4, biểu đồ `Conversion Rate by Probability Bucket` cho thấy một điểm bất thường: cột có xác suất cao nhất là `81-100%` lại có kết quả tốt nhất, nhưng các cột ở giữa như `41-60%`, `61-80%` lại cho kết quả không theo logic kinh doanh, thậm chí có xu hướng không đồng nhất hoặc không tăng theo xác suất.

Điều này đặt ra câu hỏi quan trọng:
- Nếu một cơ hội Won thì có xác suất trung bình cao hơn một cơ hội Lost không?
- Những cơ hội Won có thực sự đạt conversion rate tương ứng với mức Probability đã ghi hay không?

Vì vậy, dự án Statistics này được xây dựng để kiểm tra lại tính hợp lệ của pipeline probability bằng một flow 3 analysis rõ ràng, không chỉ dựa trên dashboard số liệu hiển thị.

---

---

## 2. Quy trình phân tích (3 analysis flow)

### Analysis 1 — Descriptive Analysis (kiểm tra sơ bộ)
**Mục đích:** kiểm tra dữ liệu theo cách đơn giản, nhằm phát hiện pattern, phân bố và anomaly trước khi đi vào kiểm định thống kê.

**Câu hỏi cần trả lời:**
- Các cơ hội phân bố như thế nào theo probability bucket?
- Có tồn tại bucket nào có kết quả “mâu thuẫn logic” không?
- Mức độ Won/Lost của từng bucket có hợp lý với xác suất gán hay không?

**Phương pháp:**
- Vẽ biểu đồ thể hiện số lượng cơ hội Won và Lost của từng mức Probability.

**Nhận xét :**
- Mean và Median của cơ hội Won và Lost gần bằng nhau, chưa có sự phân tách rõ ràng về mức Probability
- Boxplot còn hiểu hiện Outlier: 90%-100% nhưng vẫn Lost

**Kết luận :**
- Cần inferential statistics để xác định có đủ bằng chứng để cho rằng Won opportunities thực sự có Probability cao hơn Lost opportunities hay không.
- Hiện tại trường Probability chưa đáng tin cậy

*Chi tiết trong sheet Analysis 1 — Descriptive statistics (Statistics Analysis.xlsx)*
---

### Analysis 2 — Compare probability of Won vs Lost
**Mục đích:** kiểm tra xem một cơ hội Won thực sự có xác suất gán cao hơn một cơ hội Lost hay không.

**Câu hỏi cần trả lời:**
- Nếu một cơ hội kết thúc là Won, thì xác suất của nó có cao hơn đáng kể so với các cơ hội Lost hay không?

**Giả thuyết thống kê:**
- H0: Xác suất trung bình của Won và Lost là tương đương
- H1: Xác suất trung bình của Won lớn hơn Lost

**Phương pháp:**
- Tách dữ liệu thành 2 nhóm: `Won` và `Lost`
- So sánh giá trị median / mean / distribution của probability giữa 2 nhóm
- Nếu cần, dùng kiểm định thống kê phù hợp (one sided Mann-Whitney) để đánh giá sự khác biệt

**Nhận xét:**
Won mean probability = 43.86%
Lost mean probability= 42.30%
Difference = +1.56 pp

↓

Bằng chứng thống kê:

Mann–Whitney
p = 0.326 > 0.05

↓

Kết quả:

Rank-biserial ≈ 0.044
Probability of superiority ≈ 52.2%

↓

Độ biến thiên:

95% CI of mean difference
≈ [-5.6, +8.7] pp

↓

Conclusion

Dữ liệu lịch sử không cung cấp đủ bằng chứng cho thấy các cơ hội Won có probability cao hơn một cách có hệ thống so với các cơ hội Lost.


**Kết luận :**
- Trường Probability có khả năng hạn chế trong việc phân biệt các cơ hội Won và Lost trong tương lai nếu chỉ dựa vào data này.

*Chi tiết trong sheet Analysis 2 — Hypothesis Testing (Statistics Analysis.xlsx)*
---

### Analysis 3 — Validate conversion rate against probability
**Mục đích:** kiểm tra xem các cơ hội Won có thực sự đạt conversion rate tương ứng với probability đã quy định hay không.

**Câu hỏi cần trả lời:**
- Khi probability cao hơn, tỷ lệ thắng thực tế có tăng theo không?


**Phương pháp:**
- Tính Brier Score cho CRM Probability = 0,303
- Tính Brier Score của baseline (Overall Win Rate) = 0,244
- So sánh 2 Brier Scorew: điểm càng nhỏ càng tốt

**Kết luận:**
- Điều này cho thấy trường Probability hiện tại có thể không cung cấp sự đáng tin cậy phục vụ việc dự báo.
- Kết quả có thể không chính xác do các giá trị Probability  có mẫu nhỏ (80% và 100%)

*Chi tiết trong sheet Analysis 3 — Probability Calibration (Statistics Analysis.xlsx)*
---

## 3. Kết luận về ý nghĩa của dự án

Dự án Statistics này không nhằm tạo thêm dashboard mới, mà nhằm kiểm định một vấn đề cốt lõi trong sales forecasting: liệu `Probability` có thực sự là một tín hiệu đáng tin cậy hay chỉ là con số gán theo cảm tính / quy trình nội bộ không chuẩn hóa.

Nếu có bất thường ở Analysis 1, 2, 3 thì đó là bằng chứng rõ ràng cho thấy:
- Các Probability không phản ánh đúng conversion thực tế.
- Kiểm tra lại cách Probability đang được tạo.

*Chi tiết trong sheet Business Recommendation (Statistics Analysis.xlsx)*
---

