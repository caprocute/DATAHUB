# language: vi
# Sinh tự động từ D05-02-PH08 bằng ph08/tools/gen_gherkin.py; không sửa tay.
@PH-08 @TS-08-22
Tính năng: TS-08-22 · Từ chối, chuyển, leo thang phiếu và chuyển lỗi bản ghi vàng sang PH-06

  @TC-08-105 @P2 @Dương @Âm
  Kịch bản: TC-08-105 Từ chối, chuyển, hủy phiếu
    # Truy vết: FR-08-045 · API-08-092, 093, 096 · UI-08-15, 16 · EVT-08-08 · ERR-08-007, 006
    Biết phiếu `ASSIGNED` cho ORG-CA (đúng ra thuộc ORG-TC); DO1, DS1.
    Khi DO1 `POST /issues/{code}:reject` `{rejectType: WRONG_OWNER}` lý do 10 ký tự
    Và DO1 `:reject` lý do 30 ký tự
    Và DS1 `:transfer` sang ORG-TC
    Và DS1 `:cancel` một phiếu khác `OPEN` lý do đủ dài
    Và DS1 `:reject` phiếu `VERIFIED`
    Thì bước 1 `422` ERR-08-007. Bước 2 `REJECTED`, về DS. Bước 3 `ASSIGNED` cho ORG-TC. Bước 4 `CANCELLED`. Bước 5 `409` ERR-08-006. EVT: `issue.status-changed` mỗi lần đổi.

  @TC-08-106 @P2 @Dương
  Kịch bản: TC-08-106 Leo thang phiếu quá hạn
    # Truy vết: FR-08-045 · API-08-094 · BR-08-015 · EVT-08-08
    Biết phiếu `CRITICAL` quá hạn; `08.issue.escalate-after-overdue-days = 5`; `clock-sim`.
    Khi đẩy `clock-sim` qua hạn + 5 ngày làm việc, chạy job hằng ngày
    Và đẩy thêm 5 ngày
    Và DS1 `POST /issues/{code}:escalate` thủ công cho phiếu còn hạn
    Thì sau bước 1 `escalationLevel = 1`; sau bước 2 `escalationLevel = 2`; mỗi lần EVT-08-08 và thông báo PH-13. Bước 3 leo thang thủ công trước hạn khi lỗi `CRITICAL` ảnh hưởng liên thông.

  @TC-08-107 @P2 @Dương @Âm
  Kịch bản: TC-08-107 Chuyển lỗi bản ghi vàng sang hàng đợi PH-06
    # Truy vết: FR-08-046 · API-08-095 · BR-08-004 · ERR-08-105 · ERR-08-051
    Biết lỗi `UNIQUENESS` của `mdm-citizen`; lỗi của `src-hotich`; `mdm-sim` đã có mục mở cho một `goldenId`.
    Khi DS1 `POST /issues/{code}:send-to-steward` (lỗi MDM)
    Và cùng lệnh với lỗi `goldenId` đã có mục mở
    Và cùng lệnh với lỗi `src-hotich`
    Và tắt `mdm-sim`, lặp bước 1
    Thì bước 1 `200`, `stewardItemRef`, mục PH-06 lý do `DQ_FINDING`. Bước 2 gắn thêm lý do, không tạo trùng. Bước 3 `422` ERR-08-051. Bước 4 `503` ERR-08-105. PH-08 không sửa bản ghi vàng.
