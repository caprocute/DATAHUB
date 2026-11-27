# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-41
Tính năng: TS-20-41 · Hiệu năng và dung lượng

  @TC-20-216 @P1 @Hiệu @năng
  Kịch bản: TC-20-216 Saga khởi tạo ≤ 60 phút p95 trên 34 tenant
    # Truy vết: NFR-00-057 · NFR-20-001 · NFR-20-005 · FR-20-008
    Biết PERF; 34 tenant `T01…T34` (`testTenant = true`, ngoài dải `T90…T99`, xem Phụ lục ĐN-TC-07); mẫu `tinh-chuan`; bản giả theo F-SAGA `OK` với trễ thực tế; 5 lần chạy song song tối đa.
    Khi khởi tạo tuần tự và song song 5 tenant, tổng 34 lần
    Và ghi thời gian từ `S01` đến `ACTIVE`
    Thì p95 ≤ 60 phút, không lần nào quá 60 phút do tranh chấp tài nguyên; nền tảng phục vụ ≥ 34 tenant, sức chứa cấu hình 40; thời gian khởi tạo đẩy được cho KPI-12.

  @TC-20-217 @P1 @Hiệu @năng
  Kịch bản: TC-20-217 Registry tenant p99 ≤ 50 ms ở ≥ 500 lượt mỗi giây
    # Truy vết: NFR-20-003 · NFR-20-017 · FR-20-065 · API-20-162, 163, 164
    Biết PERF; 34 tenant; `S-PH03`; tải k6 ở 500, 750 lượt/giây trong 10 phút.
    Khi gọi `GET I/tenants/{code}/enforcement` ở 500 lượt/giây
    Và Ở 750 lượt/giây; khi PH-20 DU mất một bản
    Thì p99 ≤ 50 ms ở 500 lượt/giây; không lỗi 5xx; khi mất một bản vẫn đạt; sẵn sàng registry ≥ 99,9 % theo đo cửa sổ.

  @TC-20-218 @P1 @Hiệu @năng
  Kịch bản: TC-20-218 Tạm ngừng có hiệu lực ở data plane ≤ 60 giây
    # Truy vết: NFR-20-004 · FR-20-038, 066 · ERR-20-001 · EVT-20-04
    Biết PERF; `T96` đang có tải; `S-PH03`, bộ lọc `dh-tenant-filter`.
    Khi `POST P/tenants/T96/lifecycle-requests` tạm ngừng; ghi thời điểm phát EVT-20-04
    Và gọi API data plane liên tục mỗi 1 giây
    Thì từ lúc tạm ngừng đến khi lượt ghi bị chặn `ERR-20-001` không quá 60 giây; lượt đọc vẫn qua.

  @TC-20-219 @P2 @Hiệu @năng
  Kịch bản: TC-20-219 Danh sách màn hình p95 ≤ 1,5 giây; SSE tiến độ ≤ 2 giây
    # Truy vết: NFR-20-006 · NFR-20-007 · API-20-001, 143, 087, 109 · UI-20-01, 14, 11, 18
    Biết PERF; 34 tenant; 5.000 tổ chức; 100 kế hoạch sáp nhập; 100 phiên bản.
    Khi tải 100 người dùng đồng thời gọi bốn danh sách
    Và theo dõi tiến độ saga qua SSE, đo trễ giữa đổi trạng thái và sự kiện
    Thì p95 ≤ 1,5 giây mỗi danh sách; trễ SSE ≤ 2 giây.

  @TC-20-220 @P2 @Hiệu @năng
  Kịch bản: TC-20-220 Thu sử dụng hằng giờ trễ ≤ 15 phút; cảnh báo ≤ 5 phút; lệch cấu hình ≤ 1 giờ; GitOps ≤ 5 phút
    # Truy vết: NFR-20-008 · NFR-20-009 · NFR-20-010 · NFR-20-011 · FR-20-028, 029, 022, 020
    Biết PERF; 34 tenant; `obs-sim` Mimir; `git-sim`, `argo-sim`; đồng hồ thật.
    Khi đo trễ từ giờ tròn đến ảnh chụp sử dụng; lưu 25 tháng
    Và đẩy sử dụng `T96` vượt 80 %; đo đến cảnh báo
    Và sửa lệch ở `argo-sim`; đo đến khi phát hiện
    Và ghi cấu hình; đo đến khi Argo CD áp
    Thì trễ sử dụng ≤ 15 phút; cảnh báo ≤ 5 phút; phát hiện lệch ≤ 1 giờ; áp cấu hình ≤ 5 phút; dữ liệu 25 tháng còn truy vấn được.

  @TC-20-221 @P2 @Hiệu @năng
  Kịch bản: TC-20-221 Xem trước nhập 5.000 dòng ≤ 30 giây; API đọc tổ chức p95 ≤ 100 ms
    # Truy vết: NFR-20-012 · NFR-20-013 · FR-20-055, 057 · API-20-153, 154, 169, 170, 171
    Biết PERF; F-ORG-IMP 5.000 dòng; `org-reader-sim`.
    Khi tải tệp 5.000 dòng, đo đến `PREVIEW_READY`
    Và tải 200 lượt mỗi giây vào API-20-169, 170, 171
    Thì xem trước ≤ 30 giây; p95 ≤ 100 ms ở API đọc tổ chức.

  @TC-20-222 @P2 @Hiệu @năng
  Kịch bản: TC-20-222 Kiểm đếm sáp nhập 100 %; cutover 0 lỗi, thêm trễ ≤ 10 ms; dừng sóng ≤ 5 phút
    # Truy vết: NFR-20-014 · NFR-20-015 · NFR-20-016 · FR-20-048, 051, 062
    Biết PERF; kế hoạch sáp nhập lớn (10 nghìn bản ghi mỗi phân hệ); `mod-sim`; sóng nâng cấp ba tenant.
    Khi chuyển dữ liệu, so kiểm đếm trừ `SKIP`
    Và cutover khi có 200 lượt gọi mỗi giây vào địa chỉ cũ
    Và đẩy tỷ lệ 5xx của sóng lên 3 %, đo đến khi dừng sóng
    Thì khớp 100 %; không lượt gọi lỗi do chuyển tiếp, thêm trễ p95 ≤ 10 ms; sóng dừng ≤ 5 phút.

  @TC-20-223 @P3 @Hiệu @năng
  Kịch bản: TC-20-223 Gói bàn giao 500 GB hoàn tất ≤ 24 giờ
    # Truy vết: NFR-20-023 · FR-20-041 · API-20-080, 082 · EVT-20-16
    Biết PERF; `T96` với dữ liệu giả 500 GB ở `s3-sim` (giả định Q20-02, xem Q20-43); `ops-sim`.
    Khi `POST P/tenants/T96/export-packages`; theo dõi đến `READY`
    Thì gói `READY` ≤ 24 giờ, EVT-20-16 phát một lần; số đo thật chốt ở hạ tầng tỉnh (Q20-43).
