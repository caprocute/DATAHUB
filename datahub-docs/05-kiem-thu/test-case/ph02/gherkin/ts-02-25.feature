# language: vi
# Sinh tự động từ D05-02-PH02 bằng ph02/tools/gen_gherkin.py; không sửa tay.
@PH-02 @TS-02-25
Tính năng: TS-02-25 · Cách ly tenant và không lộ bí mật xuyên suốt

  @TC-02-077 @P1 @Bảo @mật
  Kịch bản: TC-02-077 Rò rỉ chéo tenant cho toàn bộ API có tham số đường dẫn
    # Truy vết: NFR-02-013 · BR-02-033 · ERR-02-001, 014 · API-02-002, 005, 006, 007, 020, 026, 033, 044, 055, 056, 059, 063, 067, 072, 074, 078 · FR-02-002, 022, 044, 049.
    Biết đối tượng của T01 với mọi loại (API, phiên bản, gói, đăng ký, yêu cầu duyệt, bản ghi đồng bộ); U-T68-TA có quyền cao nhất ở T68.
    Khi sinh bộ lời gọi tự động cho mọi operation đọc và ghi có định danh đối tượng, dùng định danh của T01 bằng token T68.
    Và so sánh thân với thân của định danh không tồn tại.
    Và đọc trực tiếp bảng `ph02_catalog.*` bằng vai trò ứng dụng T68 không đặt `tenant_id`.
    Thì 100 % lời gọi trả 404-ẩn, thân giống nhau trừ `traceId`; truy vấn DB thiếu ngữ cảnh tenant không trả hàng nào (RLS).

  @TC-02-078 @P1 @Bảo @mật
  Kịch bản: TC-02-078 Mồi bí mật đi qua toàn bộ đường: đặc tả, ví dụ, ghi chú, di trú, URL nguồn
    # Truy vết: NFR-02-012 · FR-02-018, 011, 061, 014 · BR-02-015, 036 · ERR-02-008 · API-02-015, 021, 085.
    Biết mồi `DH-CANARY-all-{uuid}` đặt vào ví dụ đặc tả, ghi chú duyệt, lý do chuyển trạng thái, khóa của gói xuất APIM, tiêu đề của URL nguồn.
    Khi chạy vòng đời đầy đủ: nạp, kiểm tra, gửi duyệt, duyệt, công bố, đồng bộ quốc gia, di trú.
    Và quét phản hồi API, log 5 phút, vết OTel, bảng `ph02_catalog.*`, outbox, Kafka, danh mục cho máy, tệp báo cáo.
    Thì mồi trong ví dụ đặc tả bị chặn trước công bố; mồi trong khóa di trú không được nhập; không nơi nào chứa mồi ngoài bản ghi bị chặn (che một phần).

  @TC-02-079 @P1 @Âm @Bảo @mật
  Kịch bản: TC-02-079 Đọc ngoài quyền: vai trò sai ở mọi operation ghi
    # Truy vết: FR-02-014, 030, 035, 046, 051, 053 · API-02-014, 037, 045, 058, 061, 069 · ERR-02-014 · UI-02-02, 06, 08.
    Biết U-T68-VW, U-T68-AU, U-T68-OR1, U-T68-TO, U-T68-SV1, U-T68-CA theo ma trận FRS §3.2.
    Khi với mỗi cặp (vai trò, operation ghi), gọi theo bảng quyền sinh từ D02-08.
    Và Ở UI, mở UI-02-02, 06, 08 bằng U-T68-VW.
    Thì mọi cặp ngoài quyền 403-PQ; UI ẩn hoặc vô hiệu hóa nút thao tác tương ứng.

  @TC-02-144 @P1 @Biên @Âm
  Kịch bản: TC-02-144 Chống trùng lệnh: `Idempotency-Key` ở mọi `POST`
    # Truy vết: NFR-02-006 · API-02-014, 034, 042, 047, 058, 069 · ERR-02-042, 003, 014.
    Biết các lệnh `POST` tạo hoặc đổi trạng thái có `Idempotency-Key`; U-T68-SV1, U-T68-OR1, U-T68-TO.
    Khi với mỗi lệnh, gửi hai lần cùng khóa, cùng thân.
    Và gửi lần ba cùng khóa, khác thân.
    Và khóa 15 ký tự, 16 ký tự, 128 ký tự, 129 ký tự.
    Và cùng khóa nhưng người gọi khác.
    Thì bước 1: lần hai trả lại đúng phản hồi lần một, chỉ một thay đổi dữ liệu, một dòng kiểm toán. Bước 2: `422` ERR-02-042. Bước 3: 15 và 129 `400` ERR-02-003, 16 và 128 hợp lệ. Bước 4: không trả lại phản hồi của người khác (khóa tính theo `(tenant, người gọi, khóa)`).

  @TC-02-145 @P1 @Âm
  Kịch bản: TC-02-145 Khóa lạc quan: `If-Match` ở mọi lệnh sửa, xóa, đổi trạng thái
    # Truy vết: NFR-02-013 · API-02-008, 018, 025, 028, 035, 036, 047, 053, 057, 073, 089 · ERR-02-015.
    Biết đối tượng đại diện cho từng operation ở trạng thái cho phép; hai phiên cùng lấy `ETag` rồi một phiên đổi trước.
    Khi sinh bộ lời gọi từ OpenAPI cho mọi operation `PUT`, `PATCH`, `DELETE` và hành động đổi trạng thái.
    Và phiên thứ hai gửi với `ETag` cũ.
    Và gửi không có `If-Match`.
    Thì bước 2: `412` ERR-02-015, dữ liệu giữ bản của phiên đầu, không có dòng kiểm toán mới. Bước 3: bị từ chối, không đổi dữ liệu (mã lỗi đúng theo D03-04-PH02 §1).

  @TC-02-146 @P2 @Bảo @mật @Âm
  Kịch bản: TC-02-146 Định dạng lỗi `problem+json` thống nhất, không lộ chi tiết nội bộ
    # Truy vết: NFR-02-012, 013 · API-02-001, 014, 022, 042 · ERR-02-001, 003, 008, 014, 034.
    Biết một lời gọi gây ra từng lỗi trên; `Accept-Language: vi` và `en`.
    Khi gọi và lấy thân lỗi, tiêu đề `Content-Type`.
    Và kiểm tra từng trường: `type`, `title`, `status`, `code`, `traceId`, `errors[]`, `findings[]`.
    Và bật lỗi nội bộ (ném ngoại lệ ở IT) rồi gọi.
    Thì `application/problem+json`; `code` đúng `ERR-02-nnn`; `traceId` 32 ký tự hex khớp vết OTel; `title`, `detail` theo ngôn ngữ yêu cầu; không có dấu vết ngăn xếp, tên bảng, địa chỉ nội bộ, giá trị bí mật; lỗi 5xx chỉ nêu `traceId`.

  @TC-02-147 @P1 @Dương @Bảo @mật
  Kịch bản: TC-02-147 Kiểm toán mọi chuyển trạng thái có lý do, trước, sau
    # Truy vết: FR-02-034, 035, 036, 037, 038, 039, 040, 051 · BR-02-028 · API-02-042, 045, 047, 048, 050, 051, 052, 063 · ERR-02-041.
    Biết một đối tượng cho mỗi chuyển trạng thái của phiên bản, gói, đăng ký; U-T68-AU.
    Khi thực hiện từng chuyển trạng thái, không lý do rồi có lý do.
    Và U-T68-AU truy vấn kiểm toán.
    Và thử sửa hoặc xóa dòng kiểm toán bằng mọi vai trò.
    Thì không lý do `400` ERR-02-041 (trừ tạo mới); có lý do: mỗi lần đúng một dòng với người, thời điểm, giá trị trước và sau, `traceId`. Không có đường sửa, xóa kiểm toán; AU chỉ đọc.

  @TC-02-148 @P2 @Âm @Bảo @mật
  Kịch bản: TC-02-148 Tương thích hợp đồng `v1`: chặn thay đổi phá vỡ ở CI
    # Truy vết: NFR-02-018 · API-02-001…095.
    Biết openAPI `v1` đã phát hành; nhánh thử đổi tên trường, bỏ trường bắt buộc, thêm trường bắt buộc; nhánh thử thêm trường tùy chọn.
    Khi chạy oasdiff ở CI-5 cho từng nhánh.
    Và chạy kiểm tra hợp đồng Pact với PH-03, PH-04, PH-15.
    Thì ba nhánh phá vỡ bị chặn, nhánh thêm trường tùy chọn qua; Pact đạt ở nhánh qua.
