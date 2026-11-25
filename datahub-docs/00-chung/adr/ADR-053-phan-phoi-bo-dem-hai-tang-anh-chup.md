---
ma_tai_lieu: ADR-053
ten: Phân phối danh mục bằng bộ đệm hai tầng Caffeine và Valkey, kèm ảnh chụp trên Garage cho data plane
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, Trưởng nhóm PH-07, Trưởng nhóm PH-04, Nhóm hạ tầng, Hội đồng thẩm định
---

# ADR-053 · Phân phối danh mục bằng bộ đệm hai tầng Caffeine và Valkey, kèm ảnh chụp trên Garage cho data plane

## Bối cảnh

Tra cứu mã danh mục là thao tác dày đặc nhất của PH-07: gần như mọi bản tin đi qua trục tích hợp mang ít nhất một mã (đơn vị hành chính, loại giấy tờ, thủ tục). Yêu cầu là tra một mã p95 ≤ 20 ms tại gateway (NFR-07-001), thông lượng ≥ 5.000 lượt/giây mỗi tenant và ≥ 20.000 lượt/giây toàn cụm với ba bản sao `dh-data` (NFR-07-008), tỷ lệ trúng đệm ≥ 95% (NFR-07-009), và tra cứu tiếp tục ít nhất 24 giờ khi PostgreSQL ngừng (NFR-07-010). Bộ nhớ L1 mỗi pod ≤ 256 MB (NFR-07-012).

Có hai nhóm bên khai thác: ứng dụng HTTT và phân hệ control plane gọi API REST của `dh-data`; và các luồng Camel trong `dh-runtime` (data plane, ADR-002, ADR-013) cần làm giàu hoặc kiểm tra mã ngay trong luồng mà không được phụ thuộc vào control plane.

SRS cũ (docs/07-srs) hình dung một dịch vụ tra cứu riêng viết bằng Quarkus tách khỏi phần quản lý để tối ưu độ trễ.

## Các phương án

Bảng dưới đây so sánh bốn phương án phân phối dữ liệu danh mục tới bên khai thác.

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Dịch vụ tra cứu riêng viết bằng Quarkus (như SRS cũ) | Khởi động nhanh, bộ nhớ nhỏ, scale độc lập | Thêm một DU phải vận hành, giám sát, bảo mật; trùng lặp mô hình dữ liệu và logic hiệu lực theo thời điểm với `dh-data`; trái tiêu chí gom DU của D03-01 §4.2 khi chưa có bằng chứng tải lệch 3 lần |
| B. Nạp toàn bộ mọi danh mục vào bộ nhớ mỗi pod khi khởi động | Độ trễ thấp nhất, không phụ thuộc mạng | 34 tenant × 1.000 danh mục × hàng chục nghìn bản ghi vượt xa 256 MB; khởi động chậm; mỗi lần phát hành phải nạp lại ở mọi pod |
| C. CDN hoặc máy chủ tệp tĩnh phục vụ tệp danh mục | Rẻ, scale tốt cho tải về toàn bộ | Không hỗ trợ tra một mã, lô, truy vấn, theo thời điểm; không kiểm soát được quyền HTTT với danh mục RESTRICTED |
| D. **Bộ đệm hai tầng trong `dh-data` (Caffeine L1 trong pod + Valkey L2 dùng chung), khóa theo `version_id` bất biến, con trỏ phiên bản hiệu lực làm mới qua sự kiện; ảnh chụp JSON.gz và CSV trên Garage cho `dh-runtime` nạp vào bộ nhớ và cho tải về toàn bộ** | Không thêm DU; dùng lại hạ tầng đã có (Valkey, Garage); dữ liệu bất biến nên không có bài toán vô hiệu hóa; data plane độc lập control plane | Cần cơ chế làm mới con trỏ đúng lúc; cần giới hạn kích thước L1; độ trễ khi trượt cả hai tầng phụ thuộc PostgreSQL |

## Quyết định

Chọn **phương án D**.

Tầng L1 là Caffeine trong mỗi pod `dh-data`, giới hạn theo trọng số byte ước lượng (mặc định 200 MB, tối đa 256 MB), chính sách W-TinyLFU. Tầng L2 là Valkey dùng chung, khóa có tiền tố tenant theo D03-10 (`{tenant}:rdm:…`), giá trị nén. Mục đệm về dữ liệu bản ghi khóa theo `version_id` và `code` nên không bao giờ cũ; TTL chỉ để thu hồi bộ nhớ. Mục đệm "con trỏ" ánh xạ (tenant, mã danh mục, ngày) sang `version_id` có TTL ngắn (mặc định 60 giây) và được xóa chủ động khi nhận sự kiện EVT-07-05 qua kênh Valkey pub/sub `rdm:pointer-invalidate`. Chống dồn tải (cache stampede) bằng nạp gộp (`AsyncLoadingCache` của Caffeine gộp yêu cầu cùng khóa trong pod) và khóa ngắn `SET NX PX` trên Valkey cho việc nạp phiên bản từ PostgreSQL.

Khi phát hành một phiên bản, sau khi giao dịch commit, module sinh ảnh chụp `s3://dh-{tenant}-rdm/snapshots/{catalogCode}/{versionNo}.json.gz` (và `.csv.gz`), ghi `snapshot_uri` và tổng kiểm tra SHA-256 vào `catalog_version`. Tenant COMMON dùng bucket `dh-common-rdm`. `dh-runtime` nhận EVT-07-05, tải ảnh chụp bằng thông tin xác thực chỉ đọc của bucket, kiểm tra SHA-256 và nạp vào bộ nhớ của tiến trình Camel; khi khởi động, `dh-runtime` đọc tệp chỉ mục `s3://dh-{tenant}-rdm/snapshots/index.json` để biết phiên bản hiệu lực của các danh mục được luồng tham chiếu. Ảnh chụp cũng phục vụ API-07-049 (chuyển hướng 302 tới URL ký sẵn) và là nguồn dự phòng khi PostgreSQL ngừng: `dh-data` có thể nạp phiên bản vào L1 trực tiếp từ ảnh chụp nếu L2 trượt và CSDL không phản hồi.

Không tách dịch vụ tra cứu riêng ở MVP. Điều kiện xem xét lại: tải tra cứu vượt 3 lần tải phần còn lại của `dh-data` trong ba tháng liên tiếp (tiêu chí D03-01 §4.2); khi đó tách module `rdm` thành DU riêng không đổi hợp đồng API.

## Hệ quả

Tích cực: không thêm thành phần vận hành; độ trễ tra một mã khi trúng L1 dưới 1 ms trong ứng dụng, đủ dư cho ngân sách 20 ms tại gateway. Data plane không gọi control plane khi xử lý bản tin, đúng ADR-013. Khả năng tra cứu khi PostgreSQL ngừng được bảo đảm bằng L2 và ảnh chụp.

Tiêu cực: dữ liệu ở `dh-runtime` cập nhật theo sự kiện nên có độ trễ vài giây sau phát hành; điều này chấp nhận được vì phiên bản có ngày hiệu lực và thường phát hành trước ngày hiệu lực. Khi Valkey ngừng, mọi pod rơi về PostgreSQL; cơ chế ngắt mạch và giới hạn đồng thời nạp được mô tả ở D03-02-PH07 §4.9. Kích thước L1 phải được giám sát (`rdm_cache_hit_ratio{tier}`).

## Trạng thái

Đề xuất.

## Truy vết

FR-07-026, FR-07-027, FR-07-028, FR-07-034; NFR-07-001, NFR-07-008, NFR-07-009, NFR-07-010, NFR-07-012; ADR-002, ADR-008, ADR-013; D03-10 §4. Thay thế phương án "Lookup Service riêng" của SRS cũ. Thiết kế chi tiết: D03-02-PH07 §4.5, §4.9, §5.9.
