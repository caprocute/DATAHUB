# language: vi
# Sinh tự động từ D05-02-PH11 bằng ph11/tools/gen_gherkin.py; không sửa tay.
@PH-11 @TS-11-20
Tính năng: TS-11-20 · Tra tiến độ hồ sơ cho Cổng DVC và phát sự kiện tiến độ

  @TC-11-112 @P1 @Dương
  Kịch bản: TC-11-112 Tra tiến độ hồ sơ
    # Truy vết: FR-11-055 · API-11-104 · BR-11-014, 015 · NFR-11-006 · bpm.progress.read
    Biết `HS-03` đang ở `capTheBHYT`; S-DVC; `11.progress.cacheSeconds = 30`.
    Khi S-DVC `GET /progress/HS-T90-2026-0003`
    Và lặp lại trong 30 giây, đọc số truy vấn CSDL
    Và đọc nhật ký truy cập
    Thì `200`; `steps` chỉ ba bước có `publicName` với `DONE`, `DONE`, `IN_PROGRESS`; `displayStatus`, `percentEstimate`, `dueAt`, `message`; `Cache-Control: max-age=30`; lần lặp không đọc CSDL; có dòng nhật ký (client, `businessKey`, thời điểm), không ghi nội dung.

  @TC-11-113 @P1 @Dương @Bảo @mật
  Kịch bản: TC-11-113 Tiến độ không lộ DLCN, ý định, lỗi kỹ thuật, tên cán bộ
    # Truy vết: FR-11-055 · API-11-104 · BR-11-014, 015 · NFR-11-021
    Biết phiên T96 với `F-DLCN`, có sự cố `TECHNICAL` ở `capTheBHYT` và một phiên đang `COMPENSATING`; từ điển cấm: `intentCode`, mã luồng PH-04, `errorCode`, `BHXH_TU_CHOI`, tên CB, `soDinhDanhMe`, canary.
    Khi S-DVC tra tiến độ các phiên
    Và quét toàn bộ JSON và tiêu đề bằng từ điển cấm
    Và tra phiên cha có phiên con
    Thì không có từ khóa cấm trong thân hay tiêu đề; lỗi kỹ thuật hiện thành câu thân thiện "Hồ sơ đang được xử lý"; phiên con gộp vào đúng vị trí bước gọi; Mồi sạch.

  @TC-11-114 @P1 @Âm @Bảo @mật
  Kịch bản: TC-11-114 Tiến độ không lộ tồn tại hồ sơ
    # Truy vết: FR-11-055 · API-11-104 · ERR-11-035 · ERR-00-403, 401
    Biết `HS-03` do S-DVC khởi tạo; S-DVC2; S-T91-DVC.
    Khi S-DVC tra `HS-KHONG-CO`
    Và S-DVC2 tra `HS-03`
    Và S-T91-DVC tra `HS-03`
    Và token thiếu scope `bpm.progress.read` tra `HS-03`
    Và không token
    Thì bước 1 đến 3 `404` ERR-11-035, ba thân giống nhau trừ `traceId`. Bước 4 `403` ERR-00-403. Bước 5 `401` ERR-00-401.

  @TC-11-115 @P1 @Dương
  Kịch bản: TC-11-115 Phát sự kiện tiến độ cùng giao dịch
    # Truy vết: FR-11-056 · EVT-11-03, 04, 05, 06, 07 · BR-11-014, 023, 030 · NFR-11-018
    Biết phiên `HS-26` chạy hết quy trình; lỗi chèn sau chuyển bước ở phiên `HS-27`.
    Khi chạy `HS-26` đến `COMPLETED`
    Và đọc `t90.bpm.instance.*` theo `businessKey`
    Và với `HS-27` gây lỗi trước commit
    Và đo độ trễ từ chuyển bước đến bản tin
    Thì có `instance.started`, các `instance.step.completed` theo thứ tự, `instance.completed` có `outcome`, `dueResult`; cùng partition `businessKey`; độ trễ p95 ≤ 10 giây; không có giá trị biến (Mồi sạch); `HS-27` không có bản tin nào. PH-11 không gửi thông báo cho công dân.

  @TC-11-116 @P1 @Âm @Chịu @lỗi
  Kịch bản: TC-11-116 Outbox tồn đọng khi Kafka ngừng
    # Truy vết: FR-11-056 · ERR-11-117 · EVT-11-04 · BR-11-023
    Biết T95; Kafka ngừng 15 phút trong khi 50 phiên chạy.
    Khi ngừng Kafka
    Và chạy bước các phiên
    Và đọc UI-11-19
    Và phục hồi Kafka, đối chiếu bản tin
    Thì bước nghiệp vụ vẫn hoàn thành; cảnh báo ERR-11-117 "Có {n} sự kiện chưa gửi quá {m} phút."; sau phục hồi đủ bản tin theo thứ tự từng `businessKey`, không trùng `id` CloudEvents.
