# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-40
Tính năng: TS-17-40 · Che DLCN, bí mật và không lộ dữ liệu ở nhật ký, vết, sự kiện

  @TC-17-140 @P1 @Bảo_mật
  Kịch bản: TC-17-140 Quét hằng ngày nhật ký hội thoại bằng mẫu DLCN và danh sách canary
    # Truy vết: NFR-17-017, 023 · FR-17-055, 034 · BR-17-073 · UI-17-15
    # Mục đích: Chứng minh NFR-17-017 và NFR-17-023.
    Biết T90; 100 canary `DH-CANARY-q-nnn` gieo vào dữ liệu thử của ánh xạ, log giải thích, câu hỏi, tài liệu; 2.000 lượt hội thoại hỗn hợp.
    Khi chạy lượt hỏi cho cả ba năng lực.
    Và chạy tác vụ quét hằng ngày trên bảng nhật ký và bản ghi prompt đã che.
    Thì 0 giá trị khớp mẫu DLCN rõ và 0 canary trong nhật ký, prompt đã che của năng lực ánh xạ; kết quả quét lưu làm bằng chứng.

  @TC-17-141 @P1 @Bảo_mật
  Kịch bản: TC-17-141 Không có bí mật nhà cung cấp trong CSDL, log, vết; gitleaks và quét log đạt 0
    # Truy vết: NFR-17-028 · FR-17-007, 013 · BR-17-011 · ERR-17-028
    # Mục đích: Chứng minh NFR-17-028 và BR-17-011.
    Biết mã nguồn `vn.datahub.assist`; bản chạy thử có `P-EXT-VN` dùng `secret_ref`; log 24 giờ.
    Khi chạy gitleaks trên mã và cấu hình.
    Và quét log ứng dụng, vết OTel, bảng `model_provider` tìm giá trị bí mật mẫu.
    Và kiểm lời gọi mô hình ngoài dùng TLS 1.3 qua APISIX.
    Thì 0 phát hiện ở cả ba nơi; chỉ có `secret_ref` dạng `openbao://kv/tenants/COMMON/assist/provider-x`; TLS 1.3 xác nhận bằng bắt gói ở egress.

  @TC-17-142 @P1 @Bảo_mật
  Kịch bản: TC-17-142 Sự kiện assist.* chỉ mang mã, trạng thái, số đếm, thời điểm
    # Truy vết: FR-17-013, 055 · BR-17-022 · EVT-17-01…28 · NFR-17-017
    # Mục đích: Chứng minh BR-17-022, BR-17-073: không nội dung hội thoại, đoạn tri thức hay giá trị dữ liệu ở Kafka.
    Biết T90; chạy ba năng lực với canary `DH-CANARY-evt`; `kcat` nghe `t90.assist.#`.
    Khi chạy luồng cấu hình, hội thoại, lọc vi phạm, phản hồi, xuất báo cáo.
    Và thu mọi bản tin `t90.assist.*.v1` và tìm canary, mẫu DLCN, đoạn tri thức.
    Và principal của T91 đăng ký `t90.assist.#`.
    Thì bước 2 0 canary, 0 mẫu DLCN, 0 nội dung; phong bì CloudEvents, khóa phân vùng `tenantId`. Bước 3 bị từ chối (ACL theo tiền tố).

  @TC-17-143 @P2 @Bảo_mật
  Kịch bản: TC-17-143 Tệp xuất và gói bằng chứng không có dữ liệu cá nhân
    # Truy vết: FR-17-057, 058 · BR-17-076, 077 · NFR-17-017 · API-17-176, 178
    # Mục đích: Chứng minh BR-17-076, 077 cho mọi tệp xuất.
    Biết gói bằng chứng, báo cáo sử dụng, tệp xuất hội thoại của người dùng; canary `DH-CANARY-xuat`.
    Khi tạo mọi loại tệp xuất sau khi chạy hội thoại có canary.
    Và quét từng tệp.
    Thì 0 canary, 0 mẫu DLCN; tệp xuất hội thoại có dòng chú về nội dung AI và chỉ của người yêu cầu.
