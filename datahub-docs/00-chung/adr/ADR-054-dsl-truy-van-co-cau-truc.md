---
ma_tai_lieu: ADR-054
ten: Truy vấn có cấu trúc trên danh mục bằng DSL lọc dạng JSON dịch sang SQL tham số hóa
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, Trưởng nhóm PH-07, Nhóm bảo mật, Hội đồng thẩm định
---

# ADR-054 · Truy vấn có cấu trúc trên danh mục bằng DSL lọc dạng JSON dịch sang SQL tham số hóa

## Bối cảnh

Hệ cũ Aita có chức năng "API truy vấn danh mục" (LGC-DMDC-016) cho phép HTTT lọc bản ghi theo giá trị thuộc tính. FR-07-032 yêu cầu API truy vấn có cấu trúc: lọc nhiều điều kiện, chọn trường, sắp xếp, phân trang, trên danh mục 100.000 bản ghi với p95 ≤ 500 ms và ngắt cứng 2 giây (NFR-07-004). BR-07-018 cấm chạy SQL tự do và chỉ cho lọc trên thuộc tính đánh dấu `queryable`. Thuộc tính lưu trong `attrs jsonb` (ADR-050) nên truy vấn phải ép kiểu theo `data_type`. Bên khai thác là lập trình viên HTTT với trình độ không đồng đều; cú pháp phải dễ sinh từ mã và dễ kiểm tra.

## Các phương án

Bảng dưới đây so sánh năm cú pháp truy vấn ứng viên.

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. SQL tự do hoặc mệnh đề `WHERE` truyền vào | Mạnh nhất | Nguy cơ chèn SQL; không kiểm soát được chi phí; lộ cấu trúc CSDL; vi phạm BR-07-018 |
| B. OData `$filter` | Chuẩn OASIS, có công cụ phía khách | Bộ phân tích cú pháp Java (Olingo) nặng, kéo theo mô hình EDM; tính năng thừa (`$expand`, hàm); khó giới hạn độ phức tạp |
| C. GraphQL | Chọn trường linh hoạt, có lược đồ | Thêm một kiểu API song song REST; lược đồ phải sinh động theo từng danh mục; khó áp giới hạn chi phí và bộ đệm HTTP; không thống nhất với quy ước API D03-01 §7.2 |
| D. RSQL/FIQL trong tham số truy vấn | Gọn, đọc được, có thư viện `rsql-parser` | Chuỗi trong URL khó mã hóa giá trị có dấu và dấu phẩy; khó mở rộng toán tử lồng; giới hạn độ dài URL với lệnh `in` 500 giá trị |
| E. **DSL lọc dạng JSON trong thân `POST …/items:query`: cây `and`/`or`/`not` với lá `{field, op, value}`, danh sách toán tử đóng, dịch sang SQL tham số hóa** | Dễ sinh từ mọi ngôn ngữ; kiểm tra bằng JSON Schema; giới hạn độ phức tạp dễ áp; không chuỗi SQL nào từ người dùng đi vào câu lệnh | Không phải chuẩn công nghiệp; bên khai thác phải học cú pháp riêng (giảm bằng tài liệu, trình thử UI-07-12 và SDK sinh từ OpenAPI) |

## Quyết định

Chọn **phương án E**. Thân yêu cầu theo khung PH-07 §8: `at`, `filter`, `select`, `sort`, `limit`, `cursor`, `includeDeprecated`. Toán tử đóng: `eq`, `ne`, `in`, `nin`, `lt`, `lte`, `gt`, `gte`, `between`, `contains`, `startsWith`, `isNull`, `isNotNull`. Trường hệ thống `code`, `name`, `parentCode`, `depth`, `status`, `sortOrder`, `validFrom`, `validTo`; thuộc tính động qua `attrs.{code}` và phải `queryable` (ERR-07-025).

Trình dịch phân tích JSON thành cây cú pháp trừu tượng (AST) bằng các `sealed interface` Java 21, kiểm tra giới hạn (≤ 20 điều kiện, lồng ≤ 3 cấp, `in` ≤ 500 giá trị, `limit` ≤ 1.000; vượt trả ERR-07-024), kiểm tra kiểu giá trị theo `data_type`, rồi sinh SQL chỉ từ danh sách mẫu cố định với tham số gắn (bind) qua `NamedParameterJdbcTemplate`. Tên trường không bao giờ được ghép vào chuỗi SQL; trường hệ thống ánh xạ qua bảng tra cố định sang tên cột, thuộc tính động sinh biểu thức `attrs->>:k` với khóa là tham số. `contains` dùng cột `name_search` (đã thường hóa, bỏ dấu) và hàm `unaccent` bất biến cho giá trị. Câu lệnh chạy trong giao dịch chỉ đọc có `SET LOCAL statement_timeout = '2s'`. Phân trang con trỏ mã hóa base64url của bộ (khóa sắp xếp, `code`) và băm của bộ lọc để chống dùng lại con trỏ với bộ lọc khác.

Đường lọc trong bộ nhớ: nếu phiên bản đã có trong L1 (ADR-053) và số bản ghi ≤ 20.000, trình thực thi đánh giá AST trực tiếp trên tập trong bộ nhớ thay vì chạy SQL, cho cùng kết quả (kiểm thử bằng bộ ca đối chứng hai đường).

## Hệ quả

Tích cực: loại trừ chèn SQL theo cấu trúc; chi phí truy vấn có trần; cú pháp dùng chung cho API, trình thử UI-07-12 và luồng Camel. Lược đồ JSON của DSL được công bố trong OpenAPI để bên khai thác sinh mã.

Tiêu cực: phải duy trì trình dịch riêng và bộ kiểm thử đối chứng; tính năng như nhóm, đếm theo nhóm, nối danh mục không được hỗ trợ (ghi nhận là ngoài phạm vi; nhu cầu phân tích dùng xuất dữ liệu). Thuộc tính `queryable` trên danh mục lớn cần chỉ mục biểu thức để đạt NFR-07-004.

## Trạng thái

Đề xuất.

## Truy vết

FR-07-032, FR-07-030; BR-07-018; NFR-07-004, NFR-07-014 (`rdm_query_rejected_total{reason}`); ERR-07-023, ERR-07-024, ERR-07-025; LGC-DMDC-016. Liên quan ADR-050, ADR-053. Thiết kế chi tiết: D03-02-PH07 §4.10.
