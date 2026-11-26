# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-17
Tính năng: TS-17-17 · Hỏi đáp tìm dịch vụ có trích dẫn, lọc theo quyền, phát trực tuyến và hủy

  @TC-17-054 @P1 @Dương
  Kịch bản: TC-17-054 Tìm dịch vụ bằng tiếng Việt có dấu và không dấu, trích dẫn tới màn đối tượng
    # Truy vết: FR-17-023, 025 · API-17-095, 099 · BR-17-034, 036, 037 · AC-17-09 · UI-17-01
    # Mục đích: Chứng minh truy hồi lai (vector và từ khóa không dấu, RRF) và trích dẫn đúng nguồn.
    Biết T90 bật; 40 API mẫu, trong đó `API-HGD` ("Tra cứu thông tin hộ gia đình", `INTERNAL`) và `TOPIC-HS` ("Hồ sơ y tế"); U-T90-IE có quyền đọc cả hai; LLM-MOCK.
    Khi IE `POST /search` với "api tra cứu hộ gia đình".
    Và IE `POST /search` với "tra cuu ho gia dinh" (không dấu).
    Và IE `POST /conversations/{id}/messages` "Có API nào tra cứu hộ gia đình không?".
    Và mở liên kết trong trích dẫn.
    Thì bước 1 và 2 `API-HGD` đứng đầu, điểm ≥ `17.rag.min-score` (0,55), tối đa 8 đoạn. Bước 3 `200`, `AnswerOutcome = ANSWERED`, mọi khẳng định có trích dẫn (đoạn, đối tượng, liên kết) và nhãn "Nội dung do AI tạo, cần kiểm tra lại". Bước 4 liên kết là route nội bộ tới màn chi tiết `API-HGD`.

  @TC-17-055 @P1 @Âm @Chất_lượng
  Kịch bản: TC-17-055 Câu hỏi ngoài phạm vi trả lời không tìm thấy, không bịa
    # Truy vết: FR-17-025, 023 · API-17-095 · BR-17-036 · NFR-17-013 · UI-17-01
    # Mục đích: Chứng minh BR-17-036 và AC-17-09: không có đoạn đạt ngưỡng thì không suy đoán.
    Biết T90; không có API về "đăng ký kết hôn"; LLM-MOCK được cài sẵn câu bịa nếu nhận được ngữ cảnh rỗng.
    Khi IE hỏi "API đăng ký kết hôn có không?".
    Và IE hỏi câu thông thường ngoài hệ thống "thời tiết hôm nay ở Hà Nội".
    Thì bước 1 `AnswerOutcome = NO_SOURCE`, câu trả lời "không tìm thấy" kèm gợi ý cách tìm, không có trích dẫn, không có tên API bịa. Bước 2 từ chối lịch sự ngoài phạm vi, `NO_SOURCE`.

  @TC-17-056 @P1 @Bảo_mật @Âm @Dương
  Kịch bản: TC-17-056 Chỉ trả đoạn người hỏi đọc được, kể cả khi đoạn có trong chỉ mục
    # Truy vết: FR-17-024 · API-17-095, 099 · BR-17-035 · NFR-17-008 · ERR-17-060
    # Mục đích: Chứng minh BR-17-035: lọc theo `acl` rồi xác minh bằng token của chính người hỏi.
    Biết T90; `API-NB` chỉ tổ chức `ORG-SYT` đọc được (acl), `API-HGD` mở cho mọi tổ chức; U-T90-IE-SYT (thuộc `ORG-SYT`), U-T90-IE-SGD (thuộc `ORG-SGD`); sau đó thu hồi quyền đọc `API-HGD` của U-T90-IE-SGD ở PH-02 trong khi đoạn còn ở chỉ mục.
    Khi IE-SYT hỏi về `API-NB`.
    Và IE-SGD hỏi về `API-NB`.
    Và IE-SGD hỏi về `API-HGD`; sau đó thu hồi quyền; hỏi lại.
    Và kiểm ngữ cảnh gửi mô hình (nhật ký prompt đã che) và trích dẫn ở bước 2, 3.
    Thì bước 1 có trích dẫn `API-NB`. Bước 2 `NO_SOURCE`, không có tên hay mô tả `API-NB` ở câu trả lời, trích dẫn hay ngữ cảnh gửi mô hình. Bước 3 lần đầu có `API-HGD`; lần sau không (đoạn "không xác minh được quyền" bị bỏ, kèm ERR-17-060 trong nhật ký nội bộ). Bước 4 0 đoạn ngoài quyền trong ngữ cảnh.

  @TC-17-057 @P2 @Dương @Âm @Hiệu_năng
  Kịch bản: TC-17-057 Phát trực tuyến SSE, hủy giữa chừng, đã hoàn tất thì không hủy được
    # Truy vết: FR-17-026, 023 · API-17-096, 097 · BR-17-038 · NFR-17-002, 003 · ERR-17-053
    # Mục đích: Chứng minh SSE, token đầu tiên ≤ 3 giây, hủy dừng gọi mô hình và token đã dùng vẫn tính.
    Biết T90; LLM-MOCK phát 40 token mỗi giây trong 20 giây; U-T90-IE.
    Khi IE `POST /conversations/{id}/messages:stream`, ghi thời gian token đầu.
    Và sau 3 giây gọi `POST /conversations/{id}/messages/{mid}:cancel`.
    Và gọi `:cancel` lần hai, và gọi `:cancel` cho câu trả lời đã hoàn tất.
    Và `GET /usage/me`.
    Thì bước 1 `Content-Type: text/event-stream`, token đầu ≤ 3 giây (p95 qua 20 phiên), phần phát ra đã qua bộ lọc đầu ra (đệm một câu). Bước 2 `200`, luồng dừng, `AnswerOutcome = CANCELLED`, LLM-MOCK ngừng nhận. Bước 3 `409` ERR-17-053. Bước 4 hạn mức đã trừ số token đã dùng.

  @TC-17-058 @P2 @Biên @Bảo_mật
  Kịch bản: TC-17-058 Độ dài hội thoại và hội thoại của người khác
    # Truy vết: FR-17-022, 023 · API-17-092, 095, 098 · BR-17-033 · ERR-17-050, ERR-17-001
    # Mục đích: Chứng minh giới hạn ngữ cảnh gần nhất, giới hạn lượt trong hội thoại và cô lập hội thoại theo người dùng.
    Biết T90 `17.context.max-messages = 20`; hội thoại `CV-1` của U-T90-IE đã 100 lượt; U-T90-VW.
    Khi IE gửi lượt thứ 101 ở `CV-1` (giới hạn lượt của hội thoại theo cấu hình).
    Và VW `GET /conversations/{CV-1}` và `GET /conversations/{CV-1}/messages`.
    Và IE gửi câu hỏi mới ở hội thoại 30 tin nhắn, đọc prompt đã che.
    Thì bước 1 `409` ERR-17-050. Bước 2 `404` ERR-17-001 (hội thoại thuộc đúng một người dùng). Bước 3 ngữ cảnh chỉ có 20 tin nhắn gần nhất.
