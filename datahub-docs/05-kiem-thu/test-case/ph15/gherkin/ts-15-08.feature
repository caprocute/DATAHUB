# language: vi
# Sinh tự động từ D05-02-PH15 bằng ph15/tools/gen_gherkin.py; không sửa tay.
@PH-15 @TS-15-08
Tính năng: TS-15-08 · Duyệt bốn mắt, đăng và vòng đời trang

  @TC-15-049 @P1 @Dương
  Kịch bản: TC-15-049 Soạn, gửi duyệt, duyệt, đăng
    # Truy vết: FR-15-015, 017 · UC-15-07 · API-15-026, 027, 037 · UI-15-21, 22, 07 · EVT-15-08 · BR-15-012 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết U-T68-SV soạn, U-T68-CA duyệt; trang `bat-dau-nhanh` DRAFT.
    Khi SV `POST /content/pages/bat-dau-nhanh:submit`.
    Và CA `POST ...:approve`.
    Và U-T68-DEV-AN `GET /pages/bat-dau-nhanh`.
    Thì `IN_REVIEW` rồi `PUBLISHED`; đúng một EVT-15-08 `content.published`; KT: có; trang hiển thị trong ≤ 5 giây (bộ đệm vô hiệu); lịch sử có người soạn, người gửi, người duyệt.

  @TC-15-050 @P1 @Âm
  Kịch bản: TC-15-050 Không tự duyệt, kể cả người sửa gần nhất
    # Truy vết: FR-15-015 · UC-15-07 · API-15-027 · ERR-15-023 · BR-15-012 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết U-T68-SV gửi duyệt; U-T68-CA sửa 1 dòng của bản nháp rồi gửi lại; U-T68-TA.
    Khi SV tự `:approve`.
    Và CA soạn trang `dieu-khoan-moi`, tự gửi, tự `:approve`.
    Và với bản CA là người sửa gần nhất của SV: CA `:approve`.
    Và TA `:approve`.
    Thì bước 1…3 `403` ERR-15-023 "Người duyệt phải khác người soạn và người gửi duyệt."; trạng thái không đổi; bước 4 `200`.

  @TC-15-051 @P2 @Dương
  Kịch bản: TC-15-051 Từ chối có lý do, soạn lại
    # Truy vết: FR-15-015 · UC-15-07 · API-15-028 · ERR-15-003 · BR-15-012 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết trang IN_REVIEW của U-T68-SV; U-T68-CA.
    Khi `POST ...:reject` thiếu lý do.
    Và `POST ...:reject` {lý do}.
    Và SV sửa tiếp rồi gửi lại.
    Thì bước 1 `400` ERR-15-003 "Cần nêu lý do từ chối"; bước 2 phiên bản `REJECTED` giữ vĩnh viễn, trang về `DRAFT` có thể sửa; bước 3 tạo phiên bản mới `IN_REVIEW`.

  @TC-15-052 @P2 @Âm
  Kịch bản: TC-15-052 Thao tác sai trạng thái
    # Truy vết: FR-15-015, 016 · API-15-026, 027, 029 · ERR-15-022 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết trang DRAFT, trang IN_REVIEW, trang UNPUBLISHED.
    Khi `:approve` trang DRAFT.
    Và `:unpublish` trang không PUBLISHED.
    Và `PUT` nội dung của phiên bản IN_REVIEW.
    Thì `409` ERR-15-022 "Đối tượng đang {trạng thái} nên không thực hiện được thao tác này." cho từng bước; người soạn rút lại bản IN_REVIEW được (về `DRAFT`).

  @TC-15-053 @P3 @Dương
  Kịch bản: TC-15-053 Nhắc duyệt quá hạn
    # Truy vết: FR-15-015 · UC-15-07 · BR-15-012 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết `15.content.review-sla-days = 1`; trang IN_REVIEW; đồng hồ giả lập +25 giờ.
    Khi chạy tác vụ nhắc.
    Thì "Việc của tôi" của người có quyền duyệt hiện yêu cầu; TA nhận thông báo; trang vẫn IN_REVIEW.

  @TC-15-054 @P2 @Dương
  Kịch bản: TC-15-054 Phiên bản trang, so sánh, khôi phục
    # Truy vết: FR-15-016 · UC-15-07 · API-15-030, 031, 032, 142 · UI-15-22 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết trang `bat-dau-nhanh` có phiên bản 1 PUBLISHED (SUPERSEDED), 2 PUBLISHED, 3 REJECTED; U-T68-CA.
    Khi `GET /content/pages/bat-dau-nhanh/versions` và `/versions/1`.
    Và `GET /content/pages/bat-dau-nhanh/diff?tu=1&den=2` (API-15-142).
    Và `POST .../versions/1:restore`.
    Thì cả ba phiên bản còn đủ; so sánh đúng dòng thêm/xóa; khôi phục tạo phiên bản nháp mới từ bản 1 và phải duyệt lại, bản đang đăng không đổi.

  @TC-15-055 @P2 @Dương
  Kịch bản: TC-15-055 Gỡ đăng và gỡ điều khoản duy nhất
    # Truy vết: FR-15-016 · UC-15-07 · API-15-029, 035 · EVT-15-09 · ERR-15-022 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết trang `bat-dau-nhanh` PUBLISHED; trang TERMS đang hiệu lực, chưa có bản thay.
    Khi CA `:unpublish` `bat-dau-nhanh`; `GET /public/pages/bat-dau-nhanh`.
    Và CA `:unpublish` trang TERMS.
    Thì bước 1 `UNPUBLISHED`, EVT-15-09, trang `404` ở cổng; bước 2 `409` ERR-15-022 "Không thể gỡ điều khoản đang có hiệu lực".

  @TC-15-056 @P1 @Dương
  Kịch bản: TC-15-056 Hiển thị theo đối tượng và trạng thái
    # Truy vết: FR-15-017 · UC-15-09 · API-15-034, 035, 036, 037 · UI-15-07 · BR-15-005 · ERR-15-001 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết trang `PUBLIC`, `LOGGED_IN`, `TENANT`, và `DRAFT`; `15.public.enabled = true`; U-ANON, U-T68-DEV-AN, U-T68-OR.
    Khi mỗi vai gọi `GET /public/pages` hoặc `GET /pages`, rồi chi tiết từng trang.
    Và trang chưa có bản `en`; ảnh có URL ký đã hết hạn.
    Thì ẩn danh chỉ thấy `PUBLIC`; nhà phát triển thấy `PUBLIC`, `LOGGED_IN`; cán bộ thấy thêm `TENANT`; trang `DRAFT` hoặc ngoài đối tượng `404` ERR-15-001; thiếu `en` hiện `vi` kèm ghi chú; ảnh hết chữ ký được cấp lại khi tải lại trang, không hiện lỗi.
