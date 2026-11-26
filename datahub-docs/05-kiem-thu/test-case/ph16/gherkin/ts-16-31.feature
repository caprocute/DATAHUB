# language: vi
# Sinh tự động từ D05-02-PH16 bằng ph16/tools/gen_gherkin.py; không sửa tay.
@PH-16 @TS-16-31
Tính năng: TS-16-31 · Cô lập tenant: API, RLS, Kafka

  @TC-16-107 @P1 @Bảo @mật
  Kịch bản: TC-16-107 Rò rỉ chéo tenant qua API đọc, ghi và tài khoản máy
    # Truy vết: ERR-16-001, ERR-16-037 · API-16-001, 003, 021, 023, 031, 033, 043, 046, 048, 051, 064, 066, 077, 080, 088, 090, 094, 096, 112, 120, 129, 030, 101, 086 · BR-16-023 · FR-16-031, FR-16-043
    Biết T90 và T91 cùng mã chỉ tiêu, nguồn, kỳ, báo cáo `bc-thang-2026-10`, thành phần; U-T91-TA1, U-T91-TO1 (có đủ quyền ở T91).
    Khi với từng API đọc trong Truy vết, U-T91-TA1 gọi bằng mã tài nguyên mà chỉ T90 có (ví dụ `exportId`, `submissionId`, `manualId`, `runId`)
    Và gọi danh sách và so `totalElements` với số liệu của T91
    Và so sánh thân `404` giữa mã không tồn tại và mã thuộc T90
    Và thử `POST /reports/bc-thang-2026-10:approve` của T91 vào báo cáo cùng mã nhưng thuộc T90
    Và S-T91-PH01 (scope `kpi.ingest`, `arch.register`, `kpi.read` của T91) gọi `POST /ingest/observations` với `sourceCode` của T90, `POST /ingest/arch-components` với `componentCode` có ở T90, `GET /feed/indicator-values`
    Thì mọi lần gọi theo mã của T90 trả `404` ERR-16-001 (404-ẩn, thân giống mã không tồn tại trừ `traceId`) hoặc `403` ERR-16-037 cho phạm vi dữ liệu; danh sách chỉ chứa dữ liệu T91; thao tác ghi không có tác dụng ở T90; không bản ghi kiểm toán thành công ở T90. Bước 5: `403` ERR-16-037 hoặc `400` ERR-16-101, không quan sát nào vào T90; thành phần tạo ở T91 không ghi đè T90; `feed` chỉ trả số của T91.

  @TC-16-108 @P1 @Bảo @mật
  Kịch bản: TC-16-108 Cô lập ở CSDL bằng RLS
    # Truy vết: FR-16-055 · NFR-16-018 · BR-16-020 · ERR-16-037
    Biết bộ dữ liệu T90 và T91 ở schema `ph16_kpi`; vai trò dịch vụ có `app.tenant_id`; vai trò báo cáo liên tenant.
    Khi đặt `app.tenant_id = T91` rồi `SELECT` mọi bảng `ph16_kpi`
    Và đặt `T91` rồi `INSERT` và `UPDATE` dòng có `tenant_id = T90`
    Và không đặt `app.tenant_id`
    Và vai trò báo cáo liên tenant `SELECT` bảng giá trị và khung nhìn tổng hợp
    Và thử đọc các phân vùng bảng giá trị trực tiếp
    Thì bước 1 chỉ dòng T91 hoặc 0 dòng của T90. Bước 2 bị từ chối bởi chính sách RLS. Bước 3 không trả dòng nào. Bước 4 chỉ qua khung nhìn tổng hợp có ngoại lệ RLS, không đọc được bảng quan sát; đủ để so sánh ẩn danh. Bước 5 phân vùng cũng chịu RLS. Kịch bản chạy bằng tệp kiểm cô lập của D03-03-PH16.

  @TC-16-109 @P1 @Bảo @mật
  Kịch bản: TC-16-109 Cô lập ở Kafka và nội dung sự kiện
    # Truy vết: EVT-16-08, EVT-16-12 · NFR-16-018 · BR-16-021
    Biết client OAUTHBEARER của T91 và của T90; báo cáo của T90 được công bố; gói quốc gia của T96 đổi trạng thái.
    Khi client T91 đăng ký `t90.kpi.report.published.v1` và `t90.kpi.national-submission.state-changed.v1`
    Và client T90 đọc `t90.kpi.report.published.v1`
    Và kiểm nội dung bản tin
    Và bản tin EVT-16-05 chứa `completeness`, `flags`
    Thì bước 1 bị từ chối (ACL theo tiền tố tenant). Bước 2 nhận đúng một bản tin. Bước 3 chỉ có mã báo cáo, phiên bản, trạng thái, số tổng hợp; không có nội dung báo cáo, bằng chứng, `dimensions`. Bước 4 đúng lược đồ.
