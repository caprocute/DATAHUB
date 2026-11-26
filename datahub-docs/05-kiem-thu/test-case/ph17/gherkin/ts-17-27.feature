# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-27
Tính năng: TS-17-27 · Bộ lọc đầu ra và nhãn "Nội dung do AI tạo", không hành động ghi tự động

  @TC-17-087 @P1 @Dương @Bảo_mật
  Kịch bản: TC-17-087 Đầu ra có mẫu DLCN bị che, câu trả lời phát trực tuyến cũng được lọc
    # Truy vết: FR-17-046 · API-17-095, 096 · BR-17-060, 038 · NFR-17-009 · EVT-17-19
    # Mục đích: Chứng minh bộ lọc ra che số định danh, điện thoại, thư và hoạt động ở chế độ SSE.
    Biết LLM-MOCK trả "Liên hệ ông An, CCCD 001090000101, 0912345678, an.nguyen@example.test"; U-T90-IE.
    Khi IE gửi câu hỏi (trả đủ).
    Và IE gửi cùng câu hỏi bằng `:stream`.
    Thì bước 1 `200`, CCCD, điện thoại, thư bị che, EVT: `assist.guardrail.violation-detected`. Bước 2 phát hiện giữa chừng thì dừng, thay phần còn lại bằng thông báo chuẩn; không có byte DLCN nào được phát đi (đệm tối thiểu một câu).

  @TC-17-088 @P1 @Âm @Bảo_mật
  Kịch bản: TC-17-088 Đầu ra giống bí mật bị chặn và thay bằng thông báo chuẩn
    # Truy vết: FR-17-046 · API-17-095 · BR-17-060 · ERR-17-067 · EVT-17-19
    # Mục đích: Chứng minh chặn khóa riêng, mã `Bearer`, chuỗi kết nối.
    Biết LLM-MOCK trả lần lượt: khối khóa riêng PEM giả dạng đọc được "-----BEGIN PRIVATE KEY----- (mẫu thử)", "Authorization: Bearer mau-thu", chuỗi kết nối `postgres://user:matkhau-thu@host/db`.
    Khi IE gửi ba câu hỏi để LLM-MOCK trả ba đầu ra trên.
    Và đọc nhật ký hội thoại đã che.
    Thì mỗi lượt `422` ERR-17-067, `AnswerOutcome = BLOCKED_OUTPUT`, câu trả lời thay bằng thông báo chuẩn, EVT: `assist.guardrail.violation-detected`; nhật ký không có chuỗi bí mật.

  @TC-17-089 @P1 @Dương @Âm @Bảo_mật
  Kịch bản: TC-17-089 Liên kết ngoài danh sách trắng bị bỏ, chỉ giữ route nội bộ
    # Truy vết: FR-17-046, 025 · API-17-129, 130 · BR-17-037, 060 · UI-17-10
    # Mục đích: Chứng minh BR-17-037, 060 và quản lý danh sách trắng liên kết.
    Biết LLM-MOCK trả văn bản có liên kết `/tich-hop/luong/LUONG-01`, `https://doi-tuong.example.test/thu` và ảnh Markdown `![x](https://doi-tuong.example.test/p?d=du-lieu)`; U-T90-SO.
    Khi IE gửi câu hỏi.
    Và SO `PUT /guardrails/link-allowlist` thêm `/danh-muc/*`.
    Và lặp lại với LLM-MOCK trả liên kết `/danh-muc/DM-GIOITINH`.
    Thì bước 1 liên kết nội bộ giữ nguyên; liên kết ngoài và ảnh bị bỏ, 0 yêu cầu mạng tới `doi-tuong.example.test` từ trình duyệt, ghi vào nhật ký lọc. Bước 3 liên kết `/danh-muc/DM-GIOITINH` hiển thị, KT: có ở bước 2.

  @TC-17-090 @P1 @Dương @Bảo_mật
  Kịch bản: TC-17-090 Nhãn Nội dung do AI tạo ở mọi nơi hiển thị, sao chép, xuất; không có hành động ghi tự động
    # Truy vết: FR-17-048 · API-17-095, 096, 110 · BR-17-062 · ERR-17-070 · UI-17-01, UI-17-02
    # Mục đích: Chứng minh BR-17-062 và AC-17-10, 12.
    Biết U-T90-IE; trợ lý trả lời tìm dịch vụ, một thẻ ánh xạ và một danh sách kiểm; tệp xuất `.md` của hội thoại.
    Khi xem nhãn ở câu trả lời, thẻ đề xuất, danh sách kiểm, tóm tắt sự cố.
    Và sao chép câu trả lời, dán vào ô văn bản.
    Và xuất hội thoại ra tệp.
    Và gửi "đã áp dụng ánh xạ này vào luồng" và rà API ghi mà `dh-assist` đã gọi.
    Thì bước 1 nhãn "Nội dung do AI tạo, cần kiểm tra lại" ở mọi loại đầu ra. Bước 2 nhãn đi theo bản sao. Bước 3 tệp xuất có dòng chú. Bước 4 `403` ERR-17-070, 0 lời gọi ghi tự động; mọi ghi chỉ qua `:apply` của người dùng.
