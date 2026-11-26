# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-41
Tính năng: TS-17-41 · Đóng an toàn, chịu lỗi, egress và tắt từng phần

  @TC-17-144 @P1 @Chịu_lỗi @Âm
  Kịch bản: TC-17-144 PH-13 không ghi được kiểm toán thì thao tác quản trị bị từ chối
    # Truy vết: NFR-17-018 · FR-17-001, 003, 042, 049, 059 · BR-17-009 · ERR-17-010
    # Mục đích: Chứng minh NFR-17-018: 100 % thao tác quản trị có bản ghi PH-13 trước hiệu lực, không ghi được thì từ chối.
    Biết T94; PH-13 WireMock trả `503`; U-T94-TA1, U-T94-SO.
    Khi TA1 `PUT /settings/17.rag.top-k` giá trị 10.
    Và SO `PUT /tools/pt-log/enablement`.
    Và TA1 `POST /prompt-templates/{id}/versions`.
    Và PH-13 phục hồi, lặp lại bước 1.
    Thì bước 1 đến 3 `503` ERR-17-010, không đổi trạng thái. Bước 4 `200`, bản ghi kiểm toán có trước khi hiệu lực. Ngoại lệ của tắt khẩn cấp xem TC-17-016.

  @TC-17-145 @P1 @Chịu_lỗi
  Kịch bản: TC-17-145 Mất PH-09, Keycloak, mô hình, Kafka, PostgreSQL: lỗi đúng mã, không rò rỉ
    # Truy vết: NFR-17-015, 019 · FR-17-010, 012, 043 · ERR-17-009, 036, 064 · BR-17-026
    # Mục đích: Chứng minh trợ lý đóng an toàn và phục hồi khi từng phụ thuộc mất.
    Biết T94; Chaos Mesh: ngừng PH-09, ngừng Keycloak, ngừng mô hình nội bộ, ngắt Kafka, ngừng một nút PostgreSQL; 50 phiên hội thoại.
    Khi ngừng lần lượt từng phụ thuộc 3 phút.
    Và quan sát phản hồi người dùng, lập chỉ mục, công cụ.
    Và phục hồi và đo thời gian trở lại bình thường.
    Thì PH-09 ngừng: không lập chỉ mục mới, truy hồi vẫn chạy. Keycloak ngừng: `503` ERR-17-064 cho công cụ, tìm kiếm không công cụ vẫn chạy. Mô hình ngừng: `503` ERR-17-036. Kafka ngừng: tạo chỉ mục bị hoãn, hội thoại không ảnh hưởng. PostgreSQL mất nút: chuyển đổi dự phòng, không mất dữ liệu đã xác nhận. Không có trường hợp nào trả dữ liệu ngoài quyền.

  @TC-17-146 @P2 @Chịu_lỗi @Dương
  Kịch bản: TC-17-146 Tắt trợ lý không ảnh hưởng PH khác, đưa dh-assist về 0 bản sao, bật lại ≤ 5 phút
    # Truy vết: NFR-17-027, 015 · FR-17-001 · BR-17-079 · API-17-008
    # Mục đích: Chứng minh NFR-17-027, NFR-17-015: trợ lý là chức năng mức C, tắt được.
    Biết T90; PH-04 có luồng không dùng bước suy luận; `dh-assist` 2 bản sao.
    Khi TA1 `POST /policy:disable`; giảm `dh-assist` về 0 bản sao.
    Và chạy bộ kiểm khói PH-02, 04, 07, 10, 13 trong 10 phút.
    Và bật lại bằng đề nghị bốn mắt, tăng `dh-assist` lên 2; đo thời gian tới `status` sẵn sàng.
    Thì bước 2 0 lỗi do `dh-assist` ngừng ở PH khác (luồng PH-04 không dùng AI chạy bình thường; bước suy luận trả lỗi rõ ràng, luồng còn lại không hỏng). Bước 3 ≤ 5 phút tính từ lúc bật.

  @TC-17-147 @P1 @Bảo_mật
  Kịch bản: TC-17-147 Kết nối ra từ dh-assist chỉ tới đích khai báo (NFR-17-020)
    # Truy vết: NFR-17-020 · FR-17-003, 011 · BR-17-012 · ERR-17-039
    # Mục đích: Chứng minh 0 kết nối tới đích ngoài danh sách egress và cảnh báo ≤ 5 phút.
    Biết STAGING; Cilium và Istio egress; 20 đích thử, trong đó 18 ngoài danh sách.
    Khi từ pod `dh-assist` thử kết nối tới 20 đích.
    Và quan sát nhật ký Cilium và cảnh báo.
    Thì chỉ 2 đích trong danh sách (vLLM nội bộ, `api.nhacungcap.vn` khi tenant cho phép) kết nối được; 18 đích còn lại bị chặn; cảnh báo ≤ 5 phút.

  @TC-17-148 @P1 @Hiệu_năng @Chịu_lỗi
  Kịch bản: TC-17-148 Quá tải: hàng đợi mô hình tối đa 50, hạn mức DU, không làm sập phần còn lại
    # Truy vết: NFR-17-016, 015 · FR-17-012 · BR-17-021, 085 · ERR-17-037, 109
    # Mục đích: Chứng minh NFR-17-016: ≥ 200 lượt mỗi phút, quá hàng đợi thì `429` ERR-17-037.
    Biết PERF; hồ sơ tỉnh vừa; LLM-MOCK trả 100 ms; 300 người dùng; PH-04 gọi suy luận.
    Khi tăng tải tới 250 lượt mỗi phút trong 10 phút.
    Và tăng đột ngột 100 yêu cầu đồng thời.
    Thì bước 1 ≥ 200 lượt mỗi phút được phục vụ, p95 không vượt NFR-17-003. Bước 2 phần vượt hàng đợi 50 nhận `429` ERR-17-037; `dh-console` và PH khác vẫn trả lời bình thường.
