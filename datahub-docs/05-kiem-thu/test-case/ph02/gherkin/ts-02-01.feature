# language: vi
# Sinh tự động từ D05-02-PH02 bằng ph02/tools/gen_gherkin.py; không sửa tay.
@PH-02 @TS-02-01
Tính năng: TS-02-01 · Tra cứu danh mục, chi tiết, tìm kiếm, mẫu gọi và tải đặc tả

  @TC-02-001 @P1 @Dương
  Kịch bản: TC-02-001 Danh sách API có lọc, sắp xếp và phân trang
    # Truy vết: FR-02-001 · API-02-001 · UI-02-01 · UC-02-01 · LGC-APIM-001.
    Biết U-T68-VW; 25 API ở T68 gồm A-DATDAI, A-DRAFT, A-DEPREC.
    Khi `GET /apis?page=1&size=10&status=PUBLISHED&sort=name:asc`.
    Và lọc thêm theo đơn vị, `dataClass=INTERNAL`; mở UI-02-01 và đổi `?trang=2&co=10`.
    Thì `200`, đúng trang và tổng, chỉ A-DATDAI khớp bộ lọc; thân có `ETag`; thẻ "Cần chú ý" ở UI-02-01 đếm đúng A-DEPREC.

  @TC-02-002 @P1 @Âm @Bảo @mật
  Kịch bản: TC-02-002 Người ngoài tổ chức không thấy phiên bản nháp
    # Truy vết: FR-02-001, 002, 003 · API-02-001, 002, 003 · BR-02-039 · ERR-02-001.
    Biết A-DRAFT của Sở TN&MT; U-T68-SV2, U-T68-OR1, U-T68-SV1.
    Khi U-T68-SV2 và U-T68-OR1 gọi `GET /apis`, `GET /apis/tc-nhap`, `GET /search/apis?q=tc-nhap`.
    Và U-T68-SV1 gọi lại ba lời gọi trên.
    Thì bước 1: danh sách và tìm kiếm không chứa `tc-nhap`, chi tiết là 404-ẩn. Bước 2: thấy đủ.

  @TC-02-003 @P2 @Dương
  Kịch bản: TC-02-003 Chi tiết API có đủ tab, SLA thực tế cạnh cam kết
    # Truy vết: FR-02-002 · API-02-002, 074, 075, 090, 091 · UI-02-02 · BR-02-013 · LGC-APIM-017.
    Biết A-DATDAI có SLA cam kết 99,5 % và kỳ thực tế chưa đủ dữ liệu.
    Khi `GET /apis/tc-dat-dai`, `GET /apis/tc-dat-dai/versions`, `GET /apis/tc-dat-dai/history`.
    Và mở UI-02-02, xem tab SLA.
    Thì đủ phiên bản, gói, lịch sử; tab SLA hiện "chưa đủ dữ liệu", không kết luận đạt hay không đạt.

  @TC-02-004 @P2 @Dương @Biên
  Kịch bản: TC-02-004 Tìm toàn văn tiếng Việt có dấu và không dấu
    # Truy vết: FR-02-003 · API-02-003 · UI-02-01 · NFR-02-002.
    Biết A-DATDAI có mô tả "Tra cứu thửa đất theo mã".
    Khi `GET /search/apis?q=thửa đất`, rồi `q=thua dat`.
    Và `GET /search/apis?q=` (rỗng) và `q` dài 300 ký tự.
    Thì bước 1 cả hai đều trả A-DATDAI. Bước 2: `400` ERR-02-003 cho `q` quá dài; `q` rỗng trả danh sách mặc định.

  @TC-02-005 @P1 @Dương @Âm
  Kịch bản: TC-02-005 Đường dẫn sử dụng, mẫu gọi và tải đặc tả đã công bố
    # Truy vết: FR-02-005, 006 · API-02-006, 007 · UI-02-02 · BR-02-001, 039 · ERR-02-001 · LGC-APIM-017.
    Biết A-DATDAI, A-DRAFT; U-T68-OR1.
    Khi `GET …/tc-dat-dai/versions/1.0.0/usage-guide` rồi `…/spec`.
    Và U-T68-OR1 gọi `…/tc-nhap/versions/1.0.0/spec`.
    Thì bước 1: có URL gateway ghép context-path `/{nhóm}/tc-dat-dai/v1`, mẫu `curl` theo kiểu xác thực của gói, tải được đặc tả đúng `Content-Type`. Bước 2: 404-ẩn.

  @TC-02-084 @P2 @Âm @Biên
  Kịch bản: TC-02-084 Đường dẫn sử dụng và đặc tả của phiên bản ngừng dùng, đã ngừng hẳn, không tồn tại
    # Truy vết: FR-02-005, 006 · API-02-006, 007 · UI-02-02 · UC-02-01 · BR-02-014, 039 · ERR-02-001 · LGC-APIM-017.
    Biết U-T68-OR1; A-DEPREC (`DEPRECATED`); `tc-cu` 0.9.0 ở `RETIRED` (seed thêm); A-DRAFT.
    Khi `GET …/tc-cu/versions/1.0.0/usage-guide` (phiên bản `DEPRECATED`).
    Và `GET …/tc-cu/versions/0.9.0/spec` (phiên bản `RETIRED`).
    Và `GET …/tc-cu/versions/9.9.9/spec`; sau đó `GET …/tc-nhap/versions/1.0.0/usage-guide` bằng U-T68-OR1.
    Thì bước 1: `200`, kèm cờ ngừng khuyến nghị, ngày hết hạn và liên kết phiên bản kế nhiệm 2.0.0. Bước 2: `200`, đặc tả vẫn tải được vì giữ vĩnh viễn (BR-02-014). Bước 3: `404` ERR-02-001 cho phiên bản không có; bản `DRAFT` với người ngoài tổ chức cũng `404`, cùng thân.

  @TC-02-085 @P2 @Âm @Biên
  Kịch bản: TC-02-085 Tham số lọc, sắp xếp, phân trang sai và ở biên
    # Truy vết: FR-02-001, 003 · API-02-001, 003 · UI-02-01 · UC-02-01 · ERR-02-003.
    Biết U-T68-VW; 25 API ở T68.
    Khi `GET /apis?size=100`, rồi `size=101`, `size=0`, `page=0`.
    Và `GET /apis?sort=truong-la:asc` và `status=KHONG-CO`.
    Và `GET /search/apis` không có `q`; rồi `q=` rỗng.
    Và `GET /apis?status=PUBLISHED,DEPRECATED` (tham số lặp phân tách dấu phẩy).
    Thì `size=100` trả `200`. Các giá trị còn lại trả `400` ERR-02-003 kèm `errors[]` nêu đúng trường (`size`, `page`, `sort`, `status`, `q`). Bước 4 trả đủ hai trạng thái, không trả `RETIRED`. UI-02-01 mở bằng đường dẫn sai tham số thì rơi về trang 1, cỡ 20, có thông báo.

  @TC-02-086 @P2 @Dương @Âm
  Kịch bản: TC-02-086 Danh sách phiên bản và lịch sử của API, cách ly tổ chức và tenant
    # Truy vết: FR-02-002 · API-02-090, 091 · UI-02-02 · UC-02-01 · BR-02-028, 033, 039 · ERR-02-001.
    Biết A-DATDAI đã qua vòng đời `DRAFT` → `PUBLISHED` → `SUSPENDED` → `PUBLISHED`; A-DRAFT; A-T01; U-T68-SV1, U-T68-VW, U-T68-SV2.
    Khi U-T68-SV1 gọi `GET …/tc-dat-dai/versions` và `GET …/tc-dat-dai/history`.
    Và U-T68-VW và U-T68-SV2 gọi `…/tc-nhap/versions` (có bản `DRAFT`).
    Và U-T68-SV1 gọi `GET /apis/tc-chi-t01/versions` và `…/history`.
    Và mở tab Phiên bản và tab Lịch sử ở UI-02-02.
    Thì bước 1: `200`, lịch sử đủ mọi chuyển trạng thái kèm lý do, người làm, giá trị trước và sau, đúng thứ tự thời gian. Bước 2: danh sách không có phiên bản `DRAFT` (`totalElements` = 0), không báo lỗi. Bước 3: `404` ERR-02-001 cùng thân với mã không tồn tại. Bước 4: hai tab hiện đúng dữ liệu của bước 1.
