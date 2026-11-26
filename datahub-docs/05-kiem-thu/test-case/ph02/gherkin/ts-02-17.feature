# language: vi
# Sinh tự động từ D05-02-PH02 bằng ph02/tools/gen_gherkin.py; không sửa tay.
@PH-02 @TS-02-17
Tính năng: TS-02-17 · Cấp phạm vi truy cập và xem đăng ký

  @TC-02-056 @P1 @Dương @Âm @Bảo
  Kịch bản: TC-02-056 Cấp phạm vi sau duyệt, cấp lại khi lỗi, không có đường cấp tay
    # Truy vết: FR-02-048 · API-02-067, 068 · UC-02-25 · BR-02-025 · ERR-02-033, 011, 014 · GW: nạp consumer.
    Biết SUB-ACTIVE vừa duyệt; M-GW lỗi lần đầu; U-T68-TO.
    Khi `GET …/grant` sau khi duyệt khi M-GW lỗi; `:regrant` khi đã bật lại M-GW.
    Và tìm API sửa phạm vi tay (PATCH tùy ý vào `/subscriptions/{id}`, tạo scope không có đăng ký).
    Thì bước 1: lúc đầu "chưa cấp", sau `:regrant` `202` rồi cấp đủ ≤ 30 giây. Bước 2: không có operation nào, `405` hoặc `404`; scope chỉ hiện với đăng ký `ACTIVE`.

  @TC-02-057 @P1 @Dương @Âm @Bảo
  Kịch bản: TC-02-057 Xem đăng ký theo API và theo HTTT, cách ly theo tổ chức và tenant
    # Truy vết: FR-02-049, 050 · API-02-059, 060 · UI-02-02, 08 · UC-02-26 · BR-02-033 · ERR-02-001 · NFR-02-013.
    Biết SUB-ACTIVE; đăng ký của HTTT khác; A-T01 có đăng ký; U-T68-OR1, U-T68-SV1.
    Khi U-T68-OR1 `GET /subscriptions?systemCode=…` của mình và của HTTT khác.
    Và U-T68-SV1 `GET /subscriptions?apiCode=tc-dat-dai`.
    Và truy vấn `apiCode=tc-chi-t01`.
    Thì OR1 chỉ thấy đăng ký của HTTT mình; SV1 thấy mọi đăng ký của API mình; bước 3 404-ẩn.

  @TC-02-127 @P1 @Âm @Dương
  Kịch bản: TC-02-127 Trạng thái cấp phạm vi: tên phạm vi, cách ly, cấp lại sai trạng thái
    # Truy vết: FR-02-048 · API-02-067, 068 · UI-02-08 · UC-02-25 · BR-02-025 · ERR-02-001, 011, 014.
    Biết SUB-ACTIVE; đăng ký `SUSPENDED`; đăng ký của T01; U-T68-TO, U-T68-VW.
    Khi `GET /subscriptions/{SUB-ACTIVE}/grant`.
    Và `GET /subscriptions/{id của T01}/grant`.
    Và U-T68-TO `:regrant` cho đăng ký `SUSPENDED`; U-T68-VW `:regrant` cho SUB-ACTIVE.
    Thì bước 1: phạm vi `api:tc-dat-dai:goi-co-ban`, trạng thái đã cấp. Bước 2: `404` ERR-02-001. Bước 3: `409` ERR-02-011 và `403` ERR-02-014; không có đường nào cấp phạm vi bằng tay.

  @TC-02-128 @P2 @Âm
  Kịch bản: TC-02-128 Danh sách đăng ký: lọc sai, người xem ngoài HTTT
    # Truy vết: FR-02-049, 050 · API-02-059, 060 · UI-02-08 · UC-02-26 · BR-02-033 · ERR-02-003, 001.
    Biết 640 đăng ký mẫu ở T68 (rút gọn 50); U-T68-OR1, U-T68-SV2; đăng ký ở T01.
    Khi `GET /subscriptions` không có `apiCode` cũng không có `systemCode`.
    Và `GET /subscriptions?status=KHONG-CO`.
    Và U-T68-OR1 gọi `GET /subscriptions?systemCode={HTTT của Sở khác}`.
    Và `GET /subscriber-systems` bằng OR1.
    Thì bước 1, 2: `400` ERR-02-003. Bước 3: danh sách rỗng, không lộ đăng ký của HTTT mình không được xem. Bước 4: chỉ HTTT OR1 được xem.
