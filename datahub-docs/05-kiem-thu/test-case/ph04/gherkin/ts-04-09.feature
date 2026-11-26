# language: vi
# Sinh tự động từ D05-02-PH04 bằng ph04/tools/gen_gherkin.py; không sửa tay.
@PH-04 @TS-04-09
Tính năng: TS-04-09 · Trình ánh xạ dữ liệu

  @TC-04-054 @P1 @Dương
  Kịch bản: TC-04-054 Ánh xạ trường, hàm và chuyển mã
    # Truy vết: FR-04-020, 065 · API-04-033 · UI-04-07 · UC-04-06 · LGC-TOOL-008
    Biết lược đồ nguồn `hotich-yeucau-v1`, đích CDM `cdm-cong-dan-v1`; bảng chuyển mã PH-07 `GIOI_TINH` (giả lập).
    Khi trên UI-04-07, kéo `hoTen` → `ten.day_du`, `ngaySinh` → `ngay_sinh` với hàm "Định dạng ngày", `gioiTinh` → `gioi_tinh` với "Chuyển mã danh mục GIOI_TINH".
    Và gọi `POST /mappings:preview` với `sample` = MSG-OK có `gioiTinh = "1"`.
    Và chạy luồng mẫu dùng ánh xạ trên runtime (RT).
    Thì bước 2 trả `jq` có `dh_map("GIOI_TINH"; .gioiTinh)`, `output.gioi_tinh = "NAM"`, `targetValid = true`. Bước 3: runtime trả cùng kết quả với bước 2 (cùng phiên bản thư viện JQ, so sánh từng byte).

  @TC-04-055 @P1 @Âm
  Kịch bản: TC-04-055 Ánh xạ không hợp lệ
    # Truy vết: FR-04-020 · API-04-033 · ERR-04-038, 021
    Biết như ca trên.
    Khi xem trước với ánh xạ tới `ten.khong_co`.
    Và xem trước với hai trường suy ra lẫn nhau (vòng).
    Và xem trước với tài liệu mẫu 1,1 MiB.
    Thì bước 1, 2 trả `422` ERR-04-038, `findings[].args.target` chỉ trường. Bước 3 trả `413` ERR-04-021.

  @TC-04-056 @P3 @Biên
  Kịch bản: TC-04-056 Trường bắt buộc của đích chưa ánh xạ
    # Truy vết: FR-04-020, 084 · API-04-030
    Biết ánh xạ thiếu `so_dinh_danh` (bắt buộc ở đích).
    Khi `:validate` mức `SUBMIT` với `04.mapping.require-all-required = false`.
    Và bật tham số, kiểm lại.
    Thì bước 1: finding mức `WARN`. Bước 2: finding mức `ERROR`.
