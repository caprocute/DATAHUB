# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-31
Tính năng: TS-20-31 · Giải thể, hợp nhất tổ chức và đồng bộ khi sắp xếp ĐVHC

  @TC-20-144 @P1 @Dương
  Kịch bản: TC-20-144 Giải thể tổ chức có kế thừa, chuyển cha tổ chức con
    # Truy vết: FR-20-054 · UC-20-31 · API-20-149, 151 · BR-20-028 · EVT-20-13 · UI-20-15 · `PERM-20-org`
    Biết `U-T90-TA`; `SO-A` có 2 tổ chức con, 5 HTTT (PH-01), 12 người dùng (PH-12); `SO-B` `ACTIVE`; `mod-sim` trả số tham chiếu.
    Khi `POST T/organizations/SO-A:dissolve` với `effectiveTo`, `successorCode = SO-B`, `decisionDocNo`, `decisionDocDate`, `reason`, kèm `If-Match`
    Và `GET T/organizations/SO-A/history`
    Và kiểm hai tổ chức con
    Thì bước 1 `200`, `SO-A` `DISSOLVED`, `successor = SO-B`, danh sách con đã chuyển cha; EVT-20-13 `DISSOLVED` kèm `successorCode`; PH-01 tạo đề nghị đổi chủ quản chờ TA duyệt hàng loạt. Bước 2 có bản ghi lịch sử. Bước 3 cha mới là `SO-B`.

  @TC-20-145 @P1 @Âm
  Kịch bản: TC-20-145 Giải thể thiếu kế thừa, kế thừa sai, trạng thái cuối, PH lỗi
    # Truy vết: FR-20-054 · API-20-149 · ERR-20-049, ERR-20-048, ERR-20-006, ERR-20-062, ERR-20-005, ERR-00-428
    Biết `U-T90-TA`; `SO-A` còn 5 tham chiếu; `SO-C` `DISSOLVED`; `SO-D` ở `T91`.
    Khi `:dissolve` `SO-A` không có `successorCode`
    Và `:dissolve` với kế thừa chính nó; kế thừa `SO-C` (không `ACTIVE`); kế thừa `SO-D` của tenant khác
    Và `:dissolve` `SO-C` (đã giải thể)
    Và `:dissolve` khi PH-01 không trả lời số tham chiếu
    Và thiếu `If-Match`; `If-Match` cũ
    Thì bước 1 `409` `ERR-20-049`. Bước 2 `422` `ERR-20-048` cả ba trường hợp (kế thừa tenant khác nhận `404` hoặc `422` theo hợp đồng, không lộ tồn tại; ghi nhận ở bản chạy). Bước 3 `409` `ERR-20-006`. Bước 4 `503` `ERR-20-062`. Bước 5 `428` `ERR-00-428`, `412` `ERR-20-005`.

  @TC-20-146 @P1 @Dương
  Kịch bản: TC-20-146 Hợp nhất hai tổ chức vào tổ chức đích có sẵn và tổ chức đích mới
    # Truy vết: FR-20-054 · API-20-150, 151 · BR-20-028 · EVT-20-13 · UC-20-31
    Biết `U-T90-TA`; `SO-E`, `SO-F` `ACTIVE` có tham chiếu; đích `SO-EF` chưa có.
    Khi `POST T/organizations:merge` với `sourceCodes = [SO-E, SO-F]`, `targetCode = SO-EF`, tạo mới, `decisionDocNo`, `reason`
    Và hợp nhất `SO-G` vào `SO-B` có sẵn
    Thì bước 1 `200`, `SO-EF` `ACTIVE`, nguồn `MERGED` với `successor = SO-EF`, EVT-20-13 `MERGED`. Bước 2 tương tự với đích có sẵn. Tổ chức con chuyển cha sang đích.

  @TC-20-147 @P2 @Âm
  Kịch bản: TC-20-147 Hợp nhất sai: nguồn trùng đích, nguồn không hoạt động, thiếu văn bản
    # Truy vết: FR-20-054 · API-20-150 · ERR-20-004, ERR-20-048, ERR-20-006, ERR-20-002
    Biết `U-T90-TA`; `SO-E` `ACTIVE`; `SO-C` `DISSOLVED`.
    Khi hợp nhất với `targetCode` nằm trong `sourceCodes`
    Và hợp nhất nguồn `SO-C`
    Và hợp nhất thiếu `reason` hoặc `sourceCodes` rỗng
    Và hợp nhất nguồn `KHONG-CO`
    Thì bước 1 `422` `ERR-20-048`. Bước 2 `409` `ERR-20-006`. Bước 3 `400` `ERR-20-004`. Bước 4 `404` `ERR-20-002`. Không tổ chức nào đổi.

  @TC-20-148 @P2 @Dương @Âm
  Kịch bản: TC-20-148 Ngừng và hoạt động lại tổ chức
    # Truy vết: FR-20-054 · API-20-147, 148 · ERR-20-006, ERR-20-005, ERR-00-428 · EVT-20-13
    Biết `U-T90-TA`; `SO-H` `ACTIVE`; `SO-C` `DISSOLVED`.
    Khi `POST T/organizations/SO-H:deactivate` với `reason`, kèm `If-Match`
    Và `POST .../SO-H:reactivate`
    Và `:reactivate` `SO-C`; `:deactivate` `SO-H` đã `INACTIVE`
    Và thiếu `If-Match`; `If-Match` cũ
    Thì bước 1 `INACTIVE`, không cần kế thừa. Bước 2 về `ACTIVE`; mỗi lần phát EVT-20-13. Bước 3 `409` `ERR-20-006`. Bước 4 `428` `ERR-00-428`, `412` `ERR-20-005`.

  @TC-20-149 @P3 @Dương @Âm
  Kịch bản: TC-20-149 Xem lịch sử tổ chức, tổ chức tenant khác
    # Truy vết: FR-20-054 · API-20-151 · ERR-20-002 · UI-20-15
    Biết `U-T90-TA`, `U-T91-TA`; `SO-A` đã giải thể.
    Khi `U-T90-TA` `GET T/organizations/SO-A/history`
    Và `U-T91-TA` `GET T/organizations/SO-A/history`
    Thì bước 1 các bản ghi theo thời gian (cha, tên, trạng thái, kế thừa). Bước 2 `404` `ERR-20-002`.

  @TC-20-150 @P1 @Dương
  Kịch bản: TC-20-150 Sự kiện sắp xếp ĐVHC sinh đề xuất; TA áp và bỏ
    # Truy vết: FR-20-056 · UC-20-31 · API-20-157, 158 · BR-20-028 · EVT-20-13 · UI-20-14 · `PERM-20-org` · BR-20-029
    Biết `U-T90-TA`; `rdm-sim` phát EVT-07-10 gộp hai xã A, B thành xã C hiệu lực 2026-12-01; `T90` có tổ chức `UBND-A`, `UBND-B`; `T91` không có tổ chức liên quan.
    Khi `rdm-sim` phát EVT-07-10 (hai lần cùng `eventId`)
    Và `GET T/organization-sync-proposals?status=PENDING`
    Và `POST .../{p1}:decide` với `decision = APPLY`, sửa tên, mã tổ chức mới `UBND-C`
    Và `POST .../{p2}:decide` với `decision = DISMISS`, `reason`
    Thì bước 1 inbox lũy đẳng: chỉ một bộ đề xuất cho `T90`, không có đề xuất cho `T91`. Bước 2 hai đề xuất: tạo `UBND-C`, giải thể `UBND-A`, `UBND-B` kế thừa `UBND-C`. Bước 3 `200`, chạy như FR-20-054, EVT-20-13. Bước 4 `DISMISSED` có lý do.

  @TC-20-151 @P2 @Âm @Biên
  Kịch bản: TC-20-151 Áp đề xuất khi còn tham chiếu, đề xuất đã xử lý, tự áp dụng trước
    # Truy vết: FR-20-056 · API-20-158, 157 · ERR-20-049, ERR-20-006, ERR-20-004, ERR-20-002
    Biết `U-T90-TA`; đề xuất `p3` áp dụng làm giải thể tổ chức còn 4 tham chiếu mà kế thừa chưa hợp lệ; `p1` đã `APPLIED`; tỉnh đã tự giải thể `UBND-D` trước sự kiện.
    Khi `:decide` `p3` `APPLY` với kế thừa không hợp lệ
    Và `:decide` `p1` lần nữa
    Và `:decide` với `decision = XOA`; mã `p-khong-co`
    Và nhận sự kiện cho `UBND-D` đã tự giải thể
    Thì bước 1 `409` `ERR-20-049`. Bước 2 `409` `ERR-20-006`. Bước 3 `400` `ERR-20-004`, `404` `ERR-20-002`. Bước 4 đề xuất tự đánh dấu `ALREADY_APPLIED`.
