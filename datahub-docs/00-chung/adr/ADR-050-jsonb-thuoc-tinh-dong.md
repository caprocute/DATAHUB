---
ma_tai_lieu: ADR-050
ten: Thuộc tính động của danh mục lưu bằng jsonb và kiểm tra bằng JSON Schema thay cho EAV
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, Trưởng nhóm PH-07, Nhóm CSDL, Hội đồng thẩm định
---

# ADR-050 · Thuộc tính động của danh mục lưu bằng jsonb và kiểm tra bằng JSON Schema thay cho EAV

## Bối cảnh

Mỗi danh mục dùng chung (PH-07) có tập thuộc tính riêng: danh mục đơn vị hành chính cần `level`, `unit_type`; danh mục thủ tục hành chính cần lĩnh vực, cơ quan thực hiện, thời hạn giải quyết; danh mục dân tộc chỉ cần tên gọi khác. Người quản lý danh mục phải tự khai báo thuộc tính có kiểu và ràng buộc (FR-07-005, FR-07-006) mà không cần đội phát triển sửa lược đồ CSDL. Quy mô mục tiêu là ít nhất 1.000 danh mục mỗi tenant, 200.000 bản ghi mỗi danh mục và 100 thuộc tính mỗi danh mục (NFR-07-011).

Hệ cũ Aita giải quyết bài toán này bằng mô hình thực thể–thuộc tính–giá trị (Entity–Attribute–Value, EAV): bảng `category_fields` định nghĩa thuộc tính, bảng `category_details` là bản ghi và bảng `category_details_value` lưu mỗi giá trị thành một dòng `varchar(2000)`. Kinh nghiệm vận hành Aita cho thấy ba vấn đề: một danh mục 10.000 bản ghi × 20 thuộc tính sinh 200.000 dòng giá trị nên đọc một bản ghi phải ghép nhiều dòng; mọi giá trị là chuỗi nên không có kiểm tra kiểu ở tầng dữ liệu; và việc sao chép một phiên bản (ADR-051) phải nhân bản cả ba bảng.

Thiết kế mới đồng thời phải hỗ trợ phiên bản ảnh chụp copy-on-write (ADR-051), truy vấn có cấu trúc trên thuộc tính đánh dấu `queryable` (ADR-054) và sinh JSON Schema để công bố qua API-07-048 cho bên khai thác.

## Các phương án

Bảng dưới đây so sánh bốn cách lưu giá trị thuộc tính động theo các tiêu chí: hiệu năng đọc một bản ghi, chi phí sao chép phiên bản, khả năng kiểm tra kiểu, khả năng truy vấn và độ phức tạp vận hành.

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. EAV như hệ cũ (bảng giá trị mỗi thuộc tính một dòng) | Linh hoạt tuyệt đối; quen thuộc với dữ liệu di trú từ Aita | Số dòng nhân theo số thuộc tính; đọc một bản ghi phải gộp (pivot); không kiểm tra kiểu; truy vấn nhiều điều kiện phải tự nối nhiều lần; copy-on-write tốn gấp nhiều lần |
| B. Bảng rộng sinh động (mỗi danh mục một bảng, DDL sinh khi khai báo thuộc tính) | Kiểu dữ liệu thật, chỉ mục thật, truy vấn nhanh nhất | DDL lúc chạy trái nguyên tắc migration có kiểm soát (Liquibase) và RLS phải tạo theo từng bảng; 1.000 danh mục × 34 tenant thành hàng chục nghìn bảng; đổi kiểu thuộc tính phải `ALTER TABLE` khóa bảng; phiên bản bất biến gần như không làm được |
| C. **Cột `attrs jsonb` trên `catalog_item`, định nghĩa ở `attribute_def`, kiểm tra bằng JSON Schema 2020-12 sinh từ định nghĩa** | Một bản ghi là một dòng; đọc một lần; copy-on-write bằng một câu `INSERT … SELECT`; JSON Schema dùng lại cho kiểm tra ở ứng dụng và công bố cho bên khai thác; chỉ mục biểu thức hoặc GIN `jsonb_path_ops` cho thuộc tính `queryable` | Kiểu dữ liệu chỉ được bảo đảm ở tầng ứng dụng; truy vấn phải ép kiểu biểu thức `(attrs->>'x')::numeric`; mỗi dòng mang lặp lại tên khóa (tăng dung lượng khoảng 10–20%) |
| D. Cột `hstore` | Gọn hơn jsonb với cặp khóa–giá trị phẳng | Chỉ chứa chuỗi, không có mảng, số, boolean; không có hệ sinh thái lược đồ; không hợp với giá trị `CATALOG_REF` nhiều mã hay `ENUM` nhiều lựa chọn |

## Quyết định

Chọn **phương án C**. Định nghĩa thuộc tính lưu ở bảng `ph07_rdm.attribute_def` theo từng phiên bản (khóa `version_id`), gồm `code`, `data_type`, `required`, `unique_in_version`, `max_length`, `pattern`, `min_value`, `max_value`, `enum_values`, `ref_catalog_code`, `queryable`, `searchable` và các cột khác theo EN-07-04. Giá trị lưu ở cột `attrs jsonb` của `ph07_rdm.catalog_item`, khóa là `attribute_def.code`.

Module `rdm` sinh một JSON Schema 2020-12 cho mỗi phiên bản từ tập `attribute_def` (ánh xạ `STRING` → `{"type":"string","maxLength":…,"pattern":…}`, `INTEGER` → `{"type":"integer"}`, `DATE` → `{"type":"string","format":"date"}`, `ENUM` → `{"enum":[…]}`, `CATALOG_REF` → chuỗi kèm kiểm tra tham chiếu ngoài lược đồ). Lược đồ đã biên dịch được lưu đệm theo `schema_hash` của phiên bản; mọi thao tác ghi (thủ công, nhập tệp, nhập lô, đồng bộ) đều kiểm tra qua cùng một bộ kiểm tra dùng thư viện `com.networknt:json-schema-validator`. Các ràng buộc vượt quá khả năng của JSON Schema (duy nhất trong phiên bản, mã cha tồn tại, không vòng, độ sâu, tham chiếu danh mục khác) được kiểm tra bằng mã ứng dụng ở cùng bước.

Thuộc tính đánh dấu `queryable` được tạo chỉ mục biểu thức theo kiểu khi phiên bản được phát hành nếu danh mục vượt 5.000 bản ghi; ngoài ra dùng một chỉ mục GIN `jsonb_path_ops` chung cho phép toán `@>`. Chi tiết chỉ mục do D03-03-PH07 quy định.

CSDL vẫn giữ ràng buộc tối thiểu ở tầng dữ liệu: `CHECK (jsonb_typeof(attrs) = 'object')` và giới hạn kích thước `pg_column_size(attrs) <= 65536`. Cấm khai báo thuộc tính có mức phân loại Nhạy cảm (BR-07-025, ERR-07-036).

## Hệ quả

Tích cực: lược đồ CSDL của PH-07 cố định, chỉ một bộ changeset Liquibase cho mọi tenant và RLS áp dụng đồng nhất. Việc tạo bản nháp phiên bản mới chỉ là một câu `INSERT … SELECT` trên một bảng, đáp ứng NFR-07-007. JSON Schema công bố cho bên khai thác chính là lược đồ dùng để kiểm tra nên không có sai lệch giữa tài liệu và hành vi. Dữ liệu di trú từ EAV Aita được gộp (pivot) một lần thành đối tượng JSON.

Tiêu cực: đội phát triển phải bảo đảm mọi đường ghi đi qua bộ kiểm tra lược đồ; điều này được kiểm soát bằng việc chỉ lớp `ItemWriter` trong `internal/item` được phép ghi bảng `catalog_item` (luật ArchUnit). Truy vấn trên thuộc tính phải ép kiểu theo `data_type`; trình dịch DSL (ADR-054) đảm nhận việc này. Đổi kiểu thuộc tính trên dữ liệu đã có phải chạy kiểm tra chuyển đổi toàn bộ giá trị trước khi chấp nhận (BR-07-013, ERR-07-014).

Rủi ro: khóa jsonb lặp lại làm dung lượng tăng; với 200.000 bản ghi × 20 thuộc tính, ước tính khoảng 80–120 MB mỗi phiên bản trước nén TOAST, chấp nhận được. Nếu sau này một danh mục cần truy vấn phân tích nặng, có thể sinh khung nhìn vật chất (materialized view) dạng bảng rộng từ phiên bản đã phát hành mà không đổi mô hình lưu.

## Trạng thái

Đề xuất. Cần Hội đồng kiến trúc thông qua cùng ADR-051 vì hai quyết định phụ thuộc nhau.

## Truy vết

FR-07-005, FR-07-006, FR-07-013, FR-07-032, FR-07-033; BR-07-013, BR-07-018, BR-07-025; NFR-07-004, NFR-07-007, NFR-07-011; LGC-DMDC-004, LGC-DMDC-018. Liên quan ADR-003 (RLS), ADR-051 (phiên bản), ADR-054 (DSL truy vấn). Thiết kế chi tiết: D03-02-PH07 §4.1; CSDL: D03-03-PH07.
