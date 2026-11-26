---
ma_tai_lieu: ADR-171
ten: Cổng mô hình qua APISIX ai-proxy, mô hình nội bộ mặc định, mô hình ngoài theo danh sách trắng và phiên bản đã duyệt
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, nhóm PH-17, nhóm PH-03, ATTT, Hội đồng thẩm định
---

# ADR-171 · Cổng mô hình qua APISIX ai-proxy

## Bối cảnh

D01-02 xác định PH-17 là cổng quản trị truy cập AI, không huấn luyện hay vận hành mô hình nền; mô hình do tỉnh hoặc cấp trên cung cấp. SEC-49 yêu cầu mặc định mô hình nội bộ, mô hình ngoài chỉ khi tenant bật riêng với nhà cung cấp lưu dữ liệu trong nước và không huấn luyện. SEC-16 chỉ cho egress tới đích khai báo. Cần một điểm duy nhất ghi vết, giới hạn tần suất, dự phòng và khóa nhà cung cấp mà mã nghiệp vụ không chạm tới.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Mỗi module gọi thẳng nhà cung cấp bằng khóa riêng | Đơn giản | Khóa nằm ở nhiều nơi, không có điểm kiểm soát egress, khó tắt khẩn và khó chứng minh dữ liệu không ra ngoài |
| B. Cổng mô hình viết riêng trong `dh-assist` giữ khóa nhà cung cấp | Toàn quyền điều khiển | `dh-assist` giữ bí mật và có đường ra Internet, trái SEC-16 và SEC-33 |
| C. **Mọi lời gọi qua tuyến egress của APISIX (plugin `ai-proxy` hoặc `ai-proxy-multi`), cấu hình do PH-03 đồng bộ từ GitOps; `dh-assist` chỉ có `ModelRouter` và `ModelGatewayClient`; bí mật nhà cung cấp APISIX đọc trực tiếp từ OpenBao; chỉ phiên bản mô hình `APPROVED` qua đánh giá, ca đỏ và bốn mắt mới được định tuyến** | Một điểm egress, bí mật không vào `dh-assist`, giới hạn và dự phòng ở cổng, kiểm toán đủ | Phụ thuộc tính năng `ai-proxy` của PH-03 (Q17-10); tuyến chưa đồng bộ thì mô hình chưa gọi được |

## Quyết định

Chọn **phương án C**. `dh-assist` là điểm duy nhất gọi mô hình (ArchUnit: chỉ `model.internal.gateway` được dùng client HTTP tới `ai-proxy`). Mô hình nội bộ (vLLM tương thích OpenAI API) là mặc định; mô hình ngoài chỉ dùng khi hội đủ: `17.model.external-allowed` bật bằng đề nghị bốn mắt, nhà cung cấp do PA khai báo, nằm trong danh sách trắng của tenant, có cam kết còn hiệu lực (hết hạn thì tự đình chỉ), mức dữ liệu không quá `INTERNAL`. Dự phòng chỉ sang phiên bản `APPROVED` cùng loại và cùng năng lực, không bao giờ từ nội bộ sang ngoài. Cầu dao Resilience4j mỗi tuyến, bulkhead 50 lời gọi, giới hạn tần suất theo (tuyến, tenant) ở APISIX. Vết lời gọi không chứa nội dung. Cấu hình tuyến phát bằng sự kiện EVT-17-08 và theo dõi sai lệch.

## Hệ quả

Tích cực: bằng chứng egress tập trung (SEC-16), tắt khẩn và đổi nhà cung cấp không đổi mã nghiệp vụ, bí mật ở một nơi. Tiêu cực: PH-17 phụ thuộc PH-03 cho từng thay đổi tuyến (p95 ≤ 60 giây); nếu `ai-proxy` thiếu tính năng cần tự viết plugin; phải duy trì sổ mô hình và quy trình duyệt cho cả mô hình nội bộ.

## Truy vết

FR-17-003, 007…014; BR-17-004, 011…024, 081; NFR-17-019, 020, 021, 022; SEC-16, SEC-33, SEC-49, THR-57; ADR-005, ADR-012, ADR-013; D03-02-PH17 §4.8, §4.9.
