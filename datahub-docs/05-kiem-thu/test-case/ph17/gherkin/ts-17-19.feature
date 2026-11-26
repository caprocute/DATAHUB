# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-19
Tính năng: TS-17-19 · Gợi ý ánh xạ trường và mã danh mục kèm điểm tin cậy, chỉ dùng lược đồ và mẫu đã che

  @TC-17-062 @P1 @Dương @Chất_lượng
  Kịch bản: TC-17-062 Gợi ý ánh xạ trường nguồn sang đích có điểm tin cậy, lý do, biểu thức JQ hợp lệ
    # Truy vết: FR-17-030, 032 · API-17-104, 105, 108 · BR-17-044, 045 · UI-17-02
    # Mục đích: Chứng minh AC-17-10 phần gợi ý: điểm 0 đến 1, dưới 0,5 hiện "tin cậy thấp", biểu thức qua kiểm cú pháp.
    Biết T90 bật `MAPPING`; lược đồ nguồn 6 trường (`ho_ten`, `ngay_sinh`, `dia_chi`, `ma_xa`, `sdt`, `ghi_chu`) và đích 5 trường chuẩn; U-T90-IE; LLM-MOCK trả 6 gợi ý, trong đó 1 biểu thức sai cú pháp.
    Khi IE `POST /mapping-suggestions` với lược đồ nguồn và đích.
    Và `GET /suggestions/{id}` một gợi ý có điểm 0,42.
    Và IE `POST /mapping-suggestions:validate-expression` với một biểu thức JQ.
    Thì bước 1 `200`, mỗi gợi ý có `confidence` 0..1, lý do bằng lời, ứng viên thay thế; biểu thức sai cú pháp bị loại (không hiển thị); 5 gợi ý còn lại đã chạy thử trên mẫu tổng hợp. Bước 2 hiển thị "tin cậy thấp" cho điểm < 0,5, trạng thái `PROPOSED`. Bước 3 trả kết quả chạy thử trên mẫu tổng hợp sinh từ lược đồ, không dùng dữ liệu thật.

  @TC-17-063 @P1 @Dương @Bảo_mật @Âm
  Kịch bản: TC-17-063 Prompt ánh xạ không chứa giá trị dữ liệu thật, mẫu chưa che bị từ chối
    # Truy vết: FR-17-034, 030 · API-17-104 · BR-17-043, 055 · NFR-17-023 · ERR-17-059 · EVT-17-19
    # Mục đích: Chứng minh NFR-17-023: 0 giá trị canary trong prompt đã che; mẫu chưa che bị `422`.
    Biết T90 `17.mapping.sample-rows = 3`; lược đồ có trường mức `RESTRICTED` (`so_cccd`); 100 canary `DH-CANARY-m-nnn` gieo vào dữ liệu thử; mẫu có `0010 9000 0101` dạng rõ.
    Khi IE `POST /mapping-suggestions` kèm 3 dòng mẫu đã che.
    Và IE gửi lại kèm dòng mẫu có CCCD giả dạng rõ.
    Và IE gửi 8 dòng mẫu.
    Và quét nhật ký prompt đã che và bản ghi gọi mô hình của lượt bước 1.
    Thì bước 1 `200`. Bước 2 `422` ERR-17-059, EVT: `assist.guardrail.violation-detected`. Bước 3 chỉ 3 dòng đã che được đưa vào prompt (cắt theo tham số). Bước 4 prompt chỉ gồm tên trường, kiểu, mô tả, mức, ràng buộc và mẫu đã che; trường `so_cccd` không có mẫu; 0 canary.

  @TC-17-064 @P2 @Âm @Biên
  Kịch bản: TC-17-064 Thiếu lược đồ, biểu thức sai, không có mẫu
    # Truy vết: FR-17-030, 034 · API-17-104, 105 · BR-17-045 · ERR-17-054, 055
    # Mục đích: Chứng minh các từ chối ở API gợi ý và hành vi khi không có mẫu.
    Biết T90; U-T90-IE.
    Khi IE `POST /mapping-suggestions` với 0 trường nguồn.
    Và IE `POST /mapping-suggestions:validate-expression` với `.[ | ten`.
    Và IE `POST /mapping-suggestions` không có mẫu, chỉ lược đồ.
    Thì bước 1 `422` ERR-17-054. Bước 2 `422` ERR-17-055 nêu lý do cú pháp. Bước 3 `200` điểm tin cậy thấp hơn so với có mẫu, không lỗi.

  @TC-17-065 @P2 @Dương @Âm
  Kịch bản: TC-17-065 Gợi ý ánh xạ mã danh mục cục bộ sang danh mục chuẩn PH-07, không sinh mã mới
    # Truy vết: FR-17-031, 032 · API-17-106 · BR-17-046 · ERR-17-058 · UI-17-02
    # Mục đích: Chứng minh BR-17-046: chỉ chọn trong danh mục chuẩn đang `PUBLISHED`.
    Biết PH-07 WireMock có danh mục chuẩn `DM-GIOITINH` (3 mã) đang `PUBLISHED` và `DM-NGHE` đang `DRAFT`; mã cục bộ `NAM`, `NU`, `KHAC`, `X`; LLM-MOCK trả mã `GT-9` không có trong danh mục.
    Khi IE `POST /code-mapping-suggestions` với danh mục `DM-GIOITINH` và 4 mã cục bộ.
    Và IE gọi với danh mục `DM-NGHE`.
    Thì bước 1 `200`; mã `NAM`, `NU`, `KHAC` có gợi ý kèm điểm và lý do, mã `X` không gợi ý; mã `GT-9` do mô hình sinh bị loại (không hiển thị). Bước 2 `422` ERR-17-058.
