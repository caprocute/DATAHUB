# language: vi
# Sinh tự động từ D05-02-PH03 bằng ph03/tools/gen_gherkin.py; không sửa tay.
@PH-03 @TS-03-07
Tính năng: TS-03-07 · Đăng ký sử dụng, phạm vi quyền, đường dẫn và ủy quyền OPA

  @TC-03-032 @P1 @Dương @Âm
  Kịch bản: TC-03-032 Kiểm tra đăng ký sử dụng và hiệu lực gói
    # Truy vết: FR-03-016 · API-03-012, 021 · UI-03-05 · ERR-03-111, 127 · BR-03-021, 022 · LGC-APIM-011; 016.
    Biết C-HTTT1 có đăng ký `r-ho-tich` hiệu lực; HTTT `HT-KHAC` chưa đăng ký; đăng ký thứ ba hết hạn hôm qua.
    Khi C-HTTT1 gọi `r-ho-tich`.
    Và client của `HT-KHAC` gọi `r-ho-tich`.
    Và client có đăng ký hết hiệu lực gọi `r-ho-tich`.
    Và PH-01 tạm ngừng HTTT của C-HTTT1; C-HTTT1 gọi lại.
    Thì bước 1 `200`. Bước 2, 3 `403` Lỗi GW 111 "HTTT chưa đăng ký sử dụng API này hoặc đăng ký đã hết hiệu lực." Bước 4 `403` Lỗi GW 127 ≤ 60 s. `GET /consumers/ht-ndxp` hiển thị đăng ký và trạng thái.

  @TC-03-033 @P1 @Dương @Âm
  Kịch bản: TC-03-033 Phạm vi quyền thô: thiếu scope bị chặn
    # Truy vết: FR-03-017 · API-03-002, 022 · UI-03-03 · ERR-03-107 · BR-03-008 · SEC-25, 26.
    Biết route `r-ho-tich` yêu cầu `ho-tich.read` cho GET và `ho-tich.write` cho POST; token C-HTTT1 chỉ có `ho-tich.read`.
    Khi GET bằng token đủ scope.
    Và POST bằng cùng token.
    Và token có cả hai scope POST.
    Thì bước 1 `200`. Bước 2 `403` Lỗi GW 107 "Thiếu phạm vi quyền {scope}. Xin cấp thêm phạm vi." Bước 3 `200`. Backend không nhận lượt ở bước 2.

  @TC-03-034 @P1 @Dương @Âm
  Kịch bản: TC-03-034 Danh sách cho phép và chặn đường dẫn
    # Truy vết: FR-03-020 · API-03-021, 022, 065 · UI-03-03, 13 · ERR-03-113, 005 · BR-03-014, 017 · LGC-APIM-014.
    Biết gói `GOI-STD` cho phép `/ho-tich/tra-cuu/`, chặn `/ho-tich/quan-tri/`; U-T68-TA.
    Khi C-HTTT1 gọi `/ho-tich/tra-cuu/1`.
    Và gọi `/ho-tich/quan-tri/xoa`; gọi `/ho-tich/../quan-tri/xoa` (đường dẫn chuẩn hóa).
    Và `GET /policy-templates` xem mẫu chặn đường dẫn.
    Và phát cấu hình có mẫu đường dẫn sai cú pháp (`/ho-tich/[`).
    Thì bước 1 `200`. Bước 2 cả hai `403` Lỗi GW 113 "Đường dẫn không nằm trong phạm vi gói của bạn." Bước 3 `200`. Bước 4 `422` ERR-03-005.

  @TC-03-035 @P1 @Dương @Âm
  Kịch bản: TC-03-035 OPA cho phép và từ chối kèm lý do
    # Truy vết: FR-03-019 · API-03-055 · UI-03-03 · ERR-03-112 · BR-03-008, 023 · NFR-03-002 · SEC-26 · LGC-BUS-041.
    Biết `SIM-OPA` cấu hình `allow-ho-tich` cho C-HTTT1, từ chối `C-OTHER` với lý do `purpose_not_allowed`.
    Khi C-HTTT1 gọi `r-ho-tich`.
    Và `C-OTHER` (cùng gói) gọi `r-ho-tich`.
    Và `GET /authorization-bindings`.
    Thì bước 1 `200`. Bước 2 `403` Lỗi GW 112 kèm lý do `purpose_not_allowed` (không lộ nội dung chính sách). Bước 3 `200`, `r-ho-tich` gắn `allow-ho-tich`; p99 hỏi OPA ≤ 2 ms (đo ở NFR-03-002).

  @TC-03-036 @P1 @Chịu @lỗi @Bảo
  Kịch bản: TC-03-036 OPA không phản hồi: gateway đóng, không cho qua
    # Truy vết: FR-03-019 · UI-03-03 · ERR-03-124 · BR-03-008 · SEC-26.
    Biết `SIM-OPA` chờ 5 giây hoặc ngắt; `r-ho-tich`.
    Khi ngắt OPA; C-HTTT1 gọi `r-ho-tich` liên tục 30 giây.
    Và bật OPA; gọi lại.
    Thì bước 1 mọi lượt `503` Lỗi GW 124 kèm `Retry-After` (không có lượt nào qua vì "OPA im lặng"), có cảnh báo mức Cao. Bước 2 `200` trở lại.
