# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-03
Tính năng: TS-18-03 · Đề nghị và duyệt bốn mắt tham số bảo mật ★

  @TC-18-010 @P1 @Dương
  Kịch bản: TC-18-010 Đề nghị đổi khóa ★ rồi SO duyệt, giá trị có hiệu lực sau duyệt
    # Truy vết: FR-18-004 · API-18-006, 008, 009, 010 · BR-18-004, 005, 046 · EVT-18-01, 02 · UI-18-09, 15
    # Mục đích: Chứng minh luồng bốn mắt chuẩn: đề nghị tạo `PENDING_APPROVAL`, việc duyệt hiện cho người có `PERM-18-approve` trừ người đề nghị, duyệt xong mới thành `ACTIVE`.
    Biết T90; U-T90-TA1 (đề nghị), U-T90-SO (`PERM-18-approve`); `18.dlq.replay.approval-threshold` ★ = 500.
    Khi TA1 `PUT /params/18.dlq.replay.approval-threshold` giá trị 200, lý do 30 ký tự.
    Và TA1 `GET /params/18.dlq.replay.approval-threshold`.
    Và SO mở `/ca-nhan/viec`, mở việc `ph18.approve-param`, xem giá trị trước và sau ở UI-18-09.
    Và SO `POST /param-change-requests/{requestId}:approve` kèm `If-Match`.
    Thì bước 1 `202`, đề nghị `PENDING_APPROVAL`, EVT-18-02 phát; KT: có (param-change-request). Bước 2 giá trị hiệu lực vẫn 500. Bước 3 việc chỉ hiện cho SO và TA2, không hiện cho TA1. Bước 4 `200`, phiên bản mới `ACTIVE`, phiên bản cũ `SUPERSEDED`, EVT-18-01 phát, việc đóng `DONE`; KT ghi trước khi giá trị có hiệu lực.

  @TC-18-011 @P1 @Âm @Bảo_mật
  Kịch bản: TC-18-011 Người đề nghị tự duyệt, đề nghị trùng, giá trị ngoài miền
    # Truy vết: FR-18-004 · API-18-006, 010 · BR-18-004 · ERR-18-005, 013, 018
    # Mục đích: Chứng minh LP-18-01: người đề nghị không duyệt được dù có `PERM-18-approve`, mỗi khóa chỉ một đề nghị chờ duyệt.
    Biết T90; U-T90-TA1 có cả `PERM-18-config` và `PERM-18-approve`; một đề nghị của TA1 đang `PENDING_APPROVAL` cho `18.dlq.reveal.ttl-minutes`.
    Khi TA1 `POST /param-change-requests/{requestId}:approve` cho đề nghị của mình.
    Và U-T90-TA2 gửi đề nghị thứ hai cho cùng khóa.
    Và TA2 gửi đề nghị cho `18.dlq.reveal.ttl-minutes` giá trị 90.
    Thì bước 1 `403` ERR-18-005, đề nghị vẫn `PENDING_APPROVAL`, nút "Duyệt" trên UI-18-09 bị khóa với TA1. Bước 2 `409` ERR-18-018 nêu tên người đề nghị. Bước 3 `422` ERR-18-013. KT: có cho lần duyệt bị từ chối.

  @TC-18-012 @P1 @Âm @Dương @Biên
  Kịch bản: TC-18-012 Khóa do phân hệ khác giữ duyệt, từ chối, rút và hết hạn đề nghị
    # Truy vết: FR-18-004 · API-18-006, 011, 012 · BR-18-004 · ERR-18-019
    # Mục đích: Chứng minh khóa có `approvalOwner` là PH-17 không đề nghị được ở PH-18, chỉ nhận giá trị đã duyệt từ danh tính PH-17 kèm `approvalRef`; đề nghị bị từ chối, rút hoặc quá `18.param.change-request-ttl-hours` không có hiệu lực.
    Biết T95 (đồng hồ giả); `17.external-model.enabled` ★ có `approvalOwner = PH-17`; S-PH17; U-T95-TA1, U-T95-SO.
    Khi U-T95-TA1 `PUT /params/17.external-model.enabled` giá trị `true`.
    Và S-PH17 ghi cùng khóa kèm `approvalRef` của đề nghị đã duyệt ở PH-17.
    Và TA1 đề nghị khóa ★ khác, SO `:reject` kèm lý do; TA1 đề nghị lại rồi `:withdraw`.
    Và TA1 đề nghị lần ba, tua đồng hồ thêm 73 giờ.
    Thì bước 1 `409` ERR-18-019, câu thông báo chỉ sang màn PH-17. Bước 2 `200`, phiên bản mới ghi `approvalRef`. Bước 3 đề nghị `REJECTED` rồi `CANCELLED`, giá trị không đổi. Bước 4 đề nghị chuyển `EXPIRED`, việc duyệt đóng `EXPIRED`, giá trị không đổi.

  @TC-18-013 @P1 @Âm @Chịu_lỗi
  Kịch bản: TC-18-013 PH-13 không ghi được kiểm toán thì từ chối duyệt khóa ★
    # Truy vết: FR-18-004 · API-18-010 · BR-18-046 · ERR-18-008
    # Mục đích: Chứng minh BR-18-046: thao tác bốn mắt không có hiệu lực khi kiểm toán chưa ghi được.
    Biết T94; WireMock PH-13 trả `503` cho API nhận kiểm toán; một đề nghị khóa ★ `PENDING_APPROVAL`.
    Khi U-T94-SO duyệt đề nghị.
    Và khôi phục PH-13 rồi SO duyệt lại.
    Thì bước 1 `503` ERR-18-008, giá trị không đổi, không có EVT-18-01. Bước 2 `200`, giá trị có hiệu lực, KT đủ.
