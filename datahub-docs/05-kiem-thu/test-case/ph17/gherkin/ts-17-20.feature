# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-20
Tính năng: TS-17-20 · Xem trước, áp dụng gợi ý qua thẻ đề xuất và ghi nhận quyết định

  @TC-17-066 @P1 @Dương @Bảo_mật
  Kịch bản: TC-17-066 Xem trước, áp dụng vào bản nháp bằng token người dùng
    # Truy vết: FR-17-033, 035 · API-17-109, 110 · BR-17-047, 049 · EVT-17-18 · UI-17-02
    # Mục đích: Chứng minh AC-17-10: ghi chỉ xảy ra khi người dùng bấm "Áp dụng vào bản nháp" và bằng quyền của chính họ.
    Biết T90; gợi ý `SG-1` `PROPOSED` cho bản nháp luồng `LUONG-01` (ETag E1); U-T90-IE có quyền sửa bản nháp ở PH-04; ghi nhận qua WireMock PH-04.
    Khi IE `GET /suggestions/SG-1/preview`.
    Và trước khi bấm, kiểm số yêu cầu ghi tới PH-04.
    Và IE `POST /suggestions/SG-1:apply` kèm `If-Match`.
    Thì bước 1 hiển thị diff thay đổi sẽ ghi. Bước 2 0 yêu cầu ghi tới PH-04 (không ghi trước khi bấm). Bước 3 `200`, `SuggestionStatus = ACCEPTED`, PH-04 nhận đúng một yêu cầu `PUT` bản nháp mang token của IE (`sub` = IE, `act` = `dh-assist`), KT: có (suggestion-apply), EVT: `assist.suggestion.decided`; bản nháp ở trạng thái nháp, chưa kích hoạt.

  @TC-17-067 @P1 @Âm @Bảo_mật
  Kịch bản: TC-17-067 Thẻ hết hạn, bản nháp đã đổi, người dùng không có quyền sửa, gọi ghi trực tiếp
    # Truy vết: FR-17-033 · API-17-110, 109 · BR-17-047, 048 · ERR-17-056, 057, 070 · NFR-17-023
    # Mục đích: Chứng minh ERR-17-056, ERR-17-057 và trợ lý không có đường ghi riêng (ERR-17-070).
    Biết `SG-2` đã quá `17.suggestion.ttl-hours` (24); `SG-3` còn hạn nhưng bản nháp đổi sang E2; `SG-4` cho bản nháp mà U-T90-VW không có quyền sửa; U-T90-IE.
    Khi IE `:apply` `SG-2`.
    Và IE `:apply` `SG-3`.
    Và VW `:apply` `SG-4`.
    Và IE yêu cầu qua hội thoại "hãy lưu ánh xạ này vào luồng" (không bấm thẻ).
    Và kiểm số lần `dh-assist` gọi API ghi bằng danh tính riêng.
    Thì bước 1 `409` ERR-17-056, `EXPIRED`. Bước 2 `409` ERR-17-056, không ghi. Bước 3 `403` ERR-17-057, thân kèm phân hệ PH-04. Bước 4 `403` ERR-17-070, trợ lý chỉ trả thẻ đề xuất. Bước 5 0 lần ghi bằng danh tính máy của `dh-assist`.

  @TC-17-068 @P2 @Dương @Âm
  Kịch bản: TC-17-068 Ghi nhận chấp nhận, sửa, từ chối để đo chất lượng
    # Truy vết: FR-17-035 · API-17-111, 112, 107 · BR-17-049 · EVT-17-18
    # Mục đích: Chứng minh BR-17-049: ghi nhận phần khác biệt đã che và không dùng để huấn luyện.
    Biết ba gợi ý `SG-5`, `SG-6`, `SG-7` `PROPOSED`; U-T90-IE.
    Khi IE `POST /suggestions/SG-5:record-edit` kèm biểu thức đã sửa (chứa canary `DH-CANARY-sua`).
    Và IE `POST /suggestions/SG-6:reject`.
    Và IE `POST /suggestions/SG-7:apply`.
    Và IE `GET /suggestions`; quét bảng quyết định.
    Và IE `POST /suggestions/SG-8:record-edit` cho gợi ý đã `EXPIRED`.
    Thì bước 1 `EDITED`. Bước 2 `REJECTED`. Bước 3 `ACCEPTED`. Bước 4 danh sách đúng trạng thái; phần khác biệt đã che, canary không xuất hiện ở bản ghi; EVT: ba `assist.suggestion.decided`; số liệu tính vào tỷ lệ chấp nhận (FR-17-053). Bước 5 `409` ERR-17-056, không ghi nhận.
