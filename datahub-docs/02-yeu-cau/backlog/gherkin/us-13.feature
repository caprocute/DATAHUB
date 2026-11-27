# language: vi
# Sinh tự động từ D02-02/D02-03-PH13 bằng backlog/tools/sinh_backlog.py; không sửa tay.
@PH-13
Tính năng: PH-13 · Giám sát và kiểm toán

  # ---- EP-13-A · Thu thập dữ liệu quan sát

  @US-13-001 @FR-13-001 @M
  Kịch bản: US-13-001 dương · Thu thập chỉ số từ mọi thành phần
    Biết thành phần phơi điểm cuối chỉ số Prometheus (Micrometer ở DU Spring, `quarkus-micrometer` ở `dh-runtime`) trên cổng quản trị chỉ mở trong mesh, hoặc phát OTLP tới Collector; chứng thư mTLS của mesh còn hạn
    Khi chu kỳ scrape 15 giây (`13.metrics.scrape-interval-seconds`), hoặc thành phần đẩy OTLP (gRPC 4317, HTTP 4318)
    Thì người vận hành thấy số liệu mới nhất của mọi thành phần trên bảng điều khiển trong vòng 30 giây kể từ khi thành phần phát
    Và mọi mẫu trong Mimir có nhãn `tenant`
    Và sự kiện được phát: EVT-13-14 khi số chuỗi của tenant đạt 85% hạn mức

  @US-13-001 @FR-13-001 @M @âm
  Kịch bản: US-13-001 âm 1 · Collector quá tải
    Biết thành phần phơi điểm cuối chỉ số Prometheus (Micrometer ở DU Spring, `quarkus-micrometer` ở `dh-runtime`) trên cổng quản trị chỉ mở trong mesh, hoặc phát OTLP tới Collector; chứng thư mTLS của mesh còn hạn
    Khi collector quá tải
    Thì hệ thống từ chối với ERR-13-115
    Và người dùng thấy thông báo "Bộ thu thập quá tải"

  @US-13-001 @FR-13-001 @M @âm
  Kịch bản: US-13-001 âm 2 · Số chuỗi của tenant vượt hạn mức
    Biết thành phần phơi điểm cuối chỉ số Prometheus (Micrometer ở DU Spring, `quarkus-micrometer` ở `dh-runtime`) trên cổng quản trị chỉ mở trong mesh, hoặc phát OTLP tới Collector; chứng thư mTLS của mesh còn hạn
    Khi số chuỗi của tenant vượt hạn mức
    Thì hệ thống từ chối với ERR-13-114
    Và người dùng thấy thông báo "Nhãn {nhãn} không thuộc danh sách cho phép hoặc vượt hạn mức chuỗi; đã bỏ."

  @US-13-002 @FR-13-002 @M
  Kịch bản: US-13-002 dương · Thu thập log có cấu trúc
    Biết thành phần ghi log JSON ra stdout (Logback, Quarkus JSON) với các trường `ts`, `level`, `logger`, `message`, `trace_id`, `tenant_id`, `du`
    Khi thành phần ghi một dòng log; Collector đọc tệp log của container (`filelog`) hoặc nhận OTLP log
    Thì một yêu cầu qua nhiều thành phần có thể tra toàn bộ log bằng một `trace_id`
    Và log vận hành lưu 90 ngày, log an ninh 12 tháng (NFR-13-019)

  @US-13-002 @FR-13-002 @M @âm
  Kịch bản: US-13-002 âm 1 · Dòng không phải JSON
    Biết thành phần ghi log JSON ra stdout (Logback, Quarkus JSON) với các trường `ts`, `level`, `logger`, `message`, `trace_id`, `tenant_id`, `du`
    Khi dòng không phải JSON
    Thì vẫn nhận, không đánh nhãn, đếm theo DU; DU vi phạm quá 1% dòng trong 1 giờ thì phát cảnh báo `INFO` cho nhóm phát triển

  @US-13-002 @FR-13-002 @M @âm
  Kịch bản: US-13-002 âm 2 · Thiếu `tenant_id`
    Biết thành phần ghi log JSON ra stdout (Logback, Quarkus JSON) với các trường `ts`, `level`, `logger`, `message`, `trace_id`, `tenant_id`, `du`
    Khi thiếu `tenant_id`
    Thì hệ thống từ chối với ERR-13-113
    Và người dùng thấy thông báo "Dữ liệu quan sát thiếu nhãn tenant; đã gán không xác định."

  @US-13-003 @FR-13-003 @M
  Kịch bản: US-13-003 dương · Thu thập vết truy nguyên
    Biết APISIX sinh `traceparent` nếu bên gọi chưa có; mọi DU truyền `traceparent` qua HTTP và qua tiêu đề bản tin Kafka
    Khi thành phần kết thúc một span và đẩy OTLP
    Thì mỗi yêu cầu đi qua nền tảng có hành trình tra được bằng `trace_id` trong 14 ngày (trace được giữ)
    Và trace trong Tempo mang nhãn `tenant`; chỉ số theo chặng có trong Mimir

  @US-13-003 @FR-13-003 @M @âm
  Kịch bản: US-13-003 âm 1 · Trace thiếu span giữa chừng
    Biết APISIX sinh `traceparent` nếu bên gọi chưa có; mọi DU truyền `traceparent` qua HTTP và qua tiêu đề bản tin Kafka
    Khi trace thiếu span giữa chừng
    Thì hệ thống từ chối với ERR-13-117
    Và người dùng thấy thông báo "Trace chưa đủ span"

  @US-13-003 @FR-13-003 @M @âm
  Kịch bản: US-13-003 âm 2 · Trace quá 1.000 span
    Biết APISIX sinh `traceparent` nếu bên gọi chưa có; mọi DU truyền `traceparent` qua HTTP và qua tiêu đề bản tin Kafka
    Khi trace quá 1.000 span
    Thì hệ thống từ chối với ERR-13-116

  @US-13-004 @FR-13-004 @M
  Kịch bản: US-13-004 dương · Lấy mẫu trace theo đuôi
    Biết FR-13-003 đã đưa đủ span của trace tới cùng một bản sao gateway
    Khi hết thời gian chờ quyết định của một trace (mặc định 30 giây)
    Thì 100% trace lỗi, chậm bất thường hoặc chạm dữ liệu Nhạy cảm tra được; khoảng 10% trace thành công còn lại
    Và quyết định lấy mẫu ghi ở chỉ số, không ghi vào trace

  @US-13-004 @FR-13-004 @M @âm
  Kịch bản: US-13-004 âm 1 · Bộ đệm quyết định đầy (quá 500.000 trace chờ)
    Biết FR-13-003 đã đưa đủ span của trace tới cùng một bản sao gateway
    Khi bộ đệm quyết định đầy (quá 500.000 trace chờ)
    Thì hệ thống từ chối với ERR-13-115

  @US-13-004 @FR-13-004 @M @âm
  Kịch bản: US-13-004 âm 2 · Trace không có span gốc
    Biết FR-13-003 đã đưa đủ span của trace tới cùng một bản sao gateway
    Khi trace không có span gốc
    Thì hệ thống từ chối với ERR-13-117

  @US-13-005 @FR-13-005 @M
  Kịch bản: US-13-005 dương · Che dữ liệu Nhạy cảm và quét phát hiện lọt
    Biết thư viện log dùng chung của DU đã che theo chú thích `@Classified` (lớp 1); APISIX `http-logger` chỉ ghi siêu dữ liệu (lớp 3)
    Khi mỗi dòng log và mỗi span đi qua Collector; bộ quét chạy hằng ngày lúc 02:00
    Thì báo cáo quét hằng ngày; chỉ số `dh_obs_pii_findings_total`
    Và bản ghi phát hiện chỉ chứa dấu hiệu, không chứa giá trị gốc

  @US-13-005 @FR-13-005 @M @âm
  Kịch bản: US-13-005 âm 1 · Phát hiện mẫu Nhạy cảm trong log
    Biết thư viện log dùng chung của DU đã che theo chú thích `@Classified` (lớp 1); APISIX `http-logger` chỉ ghi siêu dữ liệu (lớp 3)
    Khi phát hiện mẫu Nhạy cảm trong log
    Thì cảnh báo kèm hướng dẫn thông báo cho nhóm phát triển và cho SO; nếu cùng DU tái phạm 3 ngày liên tiếp thì nâng thành `CRITICAL` và đề nghị bật `quarantine` (loại log DU đó khỏi kho tra cứu cho tới khi …
    Và người dùng thấy thông báo "Log của {du} chứa mẫu dữ liệu cá nhân: {mẫu}."

  @US-13-005 @FR-13-005 @M @âm
  Kịch bản: US-13-005 âm 2 · Bộ quét không chạy được (Loki lỗi)
    Biết thư viện log dùng chung của DU đã che theo chú thích `@Classified` (lớp 1); APISIX `http-logger` chỉ ghi siêu dữ liệu (lớp 3)
    Khi bộ quét không chạy được (Loki lỗi)
    Thì hệ thống từ chối với ERR-13-014

  @US-13-006 @FR-13-006 @M
  Kịch bản: US-13-006 dương · Thu siêu dữ liệu lượt gọi API
    Biết plugin `kafka-logger` của APISIX bật cho mọi route, cấu hình ghi trường theo danh sách cho phép; topic `{tenant}.obs.access.logged.v1` đã tạo (3 ngày lưu giữ)
    Khi APISIX hoàn tất một lượt gọi (thành công, lỗi, bị từ chối)
    Thì mọi lượt gọi API có một dòng siêu dữ liệu tra được trong 12 tháng
    Và bảng `access_log` không chứa thân bản tin, giá trị Nhạy cảm, hay tiêu đề xác thực

  @US-13-006 @FR-13-006 @M @âm
  Kịch bản: US-13-006 âm 1 · ClickHouse không ghi được
    Biết plugin `kafka-logger` của APISIX bật cho mọi route, cấu hình ghi trường theo danh sách cho phép; topic `{tenant}.obs.access.logged.v1` đã tạo (3 ngày lưu giữ)
    Khi ClickHouse không ghi được
    Thì hệ thống từ chối với ERR-13-118
    Và người dùng thấy thông báo "Kho lượt gọi API không ghi được; bản ghi đang chờ ở Kafka."

  @US-13-006 @FR-13-006 @M @âm
  Kịch bản: US-13-006 âm 2 · Kafka không nhận
    Biết plugin `kafka-logger` của APISIX bật cho mọi route, cấu hình ghi trường theo danh sách cho phép; topic `{tenant}.obs.access.logged.v1` đã tạo (3 ngày lưu giữ)
    Khi Kafka không nhận
    Thì APISIX bỏ bản ghi sau khi đệm tối đa 10.000 bản ghi và đếm `dh_obs_access_dropped_total`; không chặn lượt gọi (BR-13-015)

  @US-13-007 @FR-13-007 @M
  Kịch bản: US-13-007 dương · Thu chỉ số thành phần nền và hạ tầng
    Biết các bộ xuất chỉ số (kube-state-metrics, node-exporter, Strimzi, CNPG, các điểm cuối của APISIX, Keycloak, OPA, OpenBao, ClickHouse) do nhóm nền tảng triển khai
    Khi chu kỳ scrape 15 giây (`13.metrics.scrape-interval-seconds`); sự kiện nút thay đổi
    Thì người vận hành thấy CPU, bộ nhớ, đĩa, mạng của từng pod và nút; thấy broker Kafka, phân vùng thiếu bản sao, độ trễ nhân bản PostgreSQL
    Và có chỉ số hạ tầng trong Mimir theo danh mục

  @US-13-007 @FR-13-007 @M @âm
  Kịch bản: US-13-007 âm 1 · Nguồn không trả lời quá 3 chu kỳ
    Biết các bộ xuất chỉ số (kube-state-metrics, node-exporter, Strimzi, CNPG, các điểm cuối của APISIX, Keycloak, OPA, OpenBao, ClickHouse) do nhóm nền tảng triển khai
    Khi nguồn không trả lời quá 3 chu kỳ
    Thì hệ thống từ chối với ERR-13-124
    Và người dùng thấy thông báo "Chưa có dữ liệu"

  @US-13-007 @FR-13-007 @M @âm
  Kịch bản: US-13-007 âm 2 · Số chuỗi của nguồn quá lớn (thường do nhãn pod)
    Biết các bộ xuất chỉ số (kube-state-metrics, node-exporter, Strimzi, CNPG, các điểm cuối của APISIX, Keycloak, OPA, OpenBao, ClickHouse) do nhóm nền tảng triển khai
    Khi số chuỗi của nguồn quá lớn (thường do nhãn pod)
    Thì hệ thống từ chối với ERR-13-114

  @US-13-008 @FR-13-008 @M
  Kịch bản: US-13-008 dương · Kiểm tra tổng hợp mỗi phút
    Biết mỗi tenant có một client kiểm tra `dh-probe-{tenant}` (OAuth client credentials, scope chỉ-đọc) và ít nhất một API được đánh dấu "quan trọng" trong PH-02
    Khi chu kỳ theo từng định nghĩa kiểm tra (mặc định 60 giây)
    Thì chỉ số kiểm tra; nhãn trạng thái từng kiểm tra ở UI-13-01
    Và lượt gọi kiểm tra có cờ `synthetic` ở kho lượt gọi, loại khỏi thống kê nghiệp vụ
    Và sự kiện được phát: EVT-13-13 khi kiểm tra thất bại liên tiếp
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-13-008 @FR-13-008 @M @âm
  Kịch bản: US-13-008 âm 1 · Thất bại liên tiếp
    Biết mỗi tenant có một client kiểm tra `dh-probe-{tenant}` (OAuth client credentials, scope chỉ-đọc) và ít nhất một API được đánh dấu "quan trọng" trong PH-02
    Khi thất bại liên tiếp
    Thì hệ thống từ chối với ERR-13-124
    Và người dùng thấy thông báo "Kiểm tra tổng hợp {mã} thất bại {n} lần liên tiếp."

  @US-13-008 @FR-13-008 @M @âm
  Kịch bản: US-13-008 âm 2 · Không xin được token
    Biết mỗi tenant có một client kiểm tra `dh-probe-{tenant}` (OAuth client credentials, scope chỉ-đọc) và ít nhất một API được đánh dấu "quan trọng" trong PH-02
    Khi không xin được token
    Thì coi là thất bại kiểm tra và đồng thời phát cảnh báo cho PH-12

  @US-13-009 @FR-13-009 @M
  Kịch bản: US-13-009 dương · Cách ly dữ liệu quan sát theo tenant
    Biết tenant đã khởi tạo quan sát (FR-13-059); token có claim `tenant`
    Khi mỗi lần ghi dữ liệu quan sát và mỗi truy vấn
    Thì truy vấn chỉ trả dữ liệu của tenant hiện hành
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-13-009 @FR-13-009 @M @âm
  Kịch bản: US-13-009 âm 1 · Biểu thức chạm nhãn `tenant` khác hoặc dùng bộ chọn không giới hạn tenant sau khi ép
    Biết tenant đã khởi tạo quan sát (FR-13-059); token có claim `tenant`
    Khi biểu thức chạm nhãn `tenant` khác hoặc dùng bộ chọn không giới hạn tenant sau khi ép
    Thì hệ thống từ chối với ERR-13-044 (403)
    Và người dùng thấy thông báo "Truy vấn vượt phạm vi tenant hoặc tài khoản máy thiếu quyền."

  @US-13-009 @FR-13-009 @M @âm
  Kịch bản: US-13-009 âm 2 · Kiểm thử rò rỉ thành công
    Biết tenant đã khởi tạo quan sát (FR-13-059); token có claim `tenant`
    Khi kiểm thử rò rỉ thành công
    Thì hệ thống từ chối với ERR-13-044

  # ---- EP-13-B · Ghi vết kiểm toán

  @US-13-010 @FR-13-010 @M
  Kịch bản: US-13-010 dương · Tiếp nhận và xác thực bản ghi kiểm toán
    Biết chuỗi của tenant ở trạng thái `OPEN` (FR-13-059); topic `{tenant}.obs.audit.recorded.v1` đã tạo, lược đồ `audit-event.v1` đã đăng ký ở Apicurio; DU nguồn có KafkaUser được ghi topic của tenant
    Khi bộ chuyển outbox của DU phát bản ghi lên Kafka; hoặc DU gọi API dự phòng API-13-089
    Thì mọi bản ghi gửi tới đều được lưu ở bảng chuỗi hoặc kho cách ly; không bản ghi nào biến mất
    Và offset Kafka chưa được xác nhận cho tới khi FR-13-011 cam kết

  @US-13-010 @FR-13-010 @M @âm
  Kịch bản: US-13-010 âm 1 · Thiếu trường bắt buộc
    Biết chuỗi của tenant ở trạng thái `OPEN` (FR-13-059); topic `{tenant}.obs.audit.recorded.v1` đã tạo, lược đồ `audit-event.v1` đã đăng ký ở Apicurio; DU nguồn có KafkaUser được ghi topic của tenant
    Khi thiếu trường bắt buộc
    Thì hệ thống từ chối với ERR-13-101
    Và người dùng thấy thông báo "Bản ghi kiểm toán thiếu trường bắt buộc: {trường}."

  @US-13-010 @FR-13-010 @M @âm
  Kịch bản: US-13-010 âm 2 · DU không được phép ghi cho tenant
    Biết chuỗi của tenant ở trạng thái `OPEN` (FR-13-059); topic `{tenant}.obs.audit.recorded.v1` đã tạo, lược đồ `audit-event.v1` đã đăng ký ở Apicurio; DU nguồn có KafkaUser được ghi topic của tenant
    Khi DU không được phép ghi cho tenant
    Thì hệ thống từ chối với ERR-13-103
    Và người dùng thấy thông báo "DU {du} không được phép ghi kiểm toán cho tenant {tenant}."

  @US-13-011 @FR-13-011 @M
  Kịch bản: US-13-011 dương · Ghi chỉ-thêm và nối chuỗi băm theo tenant
    Biết bản ghi đã qua FR-13-010; bảng `audit_event` có phân vùng tháng hiện tại; trigger chặn `UPDATE`, `DELETE`, `TRUNCATE` đang bật
    Khi có lô bản ghi hợp lệ từ FR-13-010
    Thì bản ghi nằm trong chuỗi của tenant, số thứ tự liên tục, không sửa được mà không đứt chuỗi
    Và `head_seq`, `head_hash` của chuỗi bằng bản ghi mới nhất

  @US-13-011 @FR-13-011 @M @âm
  Kịch bản: US-13-011 âm 1 · Không ghi được (cơ sở dữ liệu lỗi, hết dung lượng)
    Biết bản ghi đã qua FR-13-010; bảng `audit_event` có phân vùng tháng hiện tại; trigger chặn `UPDATE`, `DELETE`, `TRUNCATE` đang bật
    Khi không ghi được (cơ sở dữ liệu lỗi, hết dung lượng)
    Thì hệ thống từ chối với ERR-13-106
    Và người dùng thấy thông báo "Không ghi được bản ghi vào bảng kiểm toán; sẽ thử lại."

  @US-13-011 @FR-13-011 @M @âm
  Kịch bản: US-13-011 âm 2 · Có lệnh `UPDATE`, `DELETE`, `TRUNCATE` vào bảng
    Biết bản ghi đã qua FR-13-010; bảng `audit_event` có phân vùng tháng hiện tại; trigger chặn `UPDATE`, `DELETE`, `TRUNCATE` đang bật
    Khi có lệnh `UPDATE`, `DELETE`, `TRUNCATE` vào bảng
    Thì trigger từ chối với mọi vai trò trừ `ph13_archive` (FR-13-018); việc thử được ghi vào `pgaudit` và phát UC-SEC-20 mức Cao

  @US-13-012 @FR-13-012 @M
  Kịch bản: US-13-012 dương · Neo băm ký hằng giờ
    Biết khóa ký `dh-audit-sign` có ở OpenBao transit (ECDSA P-256, không cho xuất); bucket WORM có Object Lock chế độ tuân thủ
    Khi đầu mỗi giờ, theo `13.audit.anchor-interval-minutes` (mặc định 60); mỗi tenant có bản ghi mới từ neo trước, hoặc ít nhất một neo mỗi 24 giờ
    Thì danh sách neo (API-13-080), chi tiết một neo kèm khóa công khai (API-13-081)
    Và neo nằm ở ba nơi: bảng, WORM, SIEM (nếu cấu hình)
    Và sự kiện được phát: EVT-13-06

  @US-13-012 @FR-13-012 @M @âm
  Kịch bản: US-13-012 âm 1 · OpenBao không ký được
    Biết khóa ký `dh-audit-sign` có ở OpenBao transit (ECDSA P-256, không cho xuất); bucket WORM có Object Lock chế độ tuân thủ
    Khi OpenBao không ký được
    Thì hệ thống từ chối với ERR-13-107
    Và người dùng thấy thông báo "Không ký được neo tại OpenBao; neo sẽ làm lại."

  @US-13-012 @FR-13-012 @M @âm
  Kịch bản: US-13-012 âm 2 · Không ghi được WORM
    Biết khóa ký `dh-audit-sign` có ở OpenBao transit (ECDSA P-256, không cho xuất); bucket WORM có Object Lock chế độ tuân thủ
    Khi không ghi được WORM
    Thì hệ thống từ chối với ERR-13-108

  @US-13-013 @FR-13-013 @M
  Kịch bản: US-13-013 dương · Sao lô sang kho WORM
    Biết bucket `dh-worm-audit` ở Ceph RGW có Object Lock chế độ tuân thủ, tiền tố `{tenant}/`; tài khoản ghi chỉ có `PutObject` (không `Delete`, không đổi thời hạn); hệ lưu trữ tách khỏi Garage
    Khi mỗi 5 phút (`13.audit.worm-batch-minutes`) cho mỗi tenant có bản ghi chưa sao
    Thì bản ghi nào cũng có bản trên WORM trong vòng 10 phút kể từ khi được ghi
    Và mỗi lô có `worm_verified_at`; không có bản ghi nào quá 10 phút chưa sao khi kho khả dụng

  @US-13-013 @FR-13-013 @M @âm
  Kịch bản: US-13-013 âm 1 · Kho WORM không nhận
    Biết bucket `dh-worm-audit` ở Ceph RGW có Object Lock chế độ tuân thủ, tiền tố `{tenant}/`; tài khoản ghi chỉ có `PutObject` (không `Delete`, không đổi thời hạn); hệ lưu trữ tách khỏi Garage
    Khi kho WORM không nhận
    Thì hệ thống từ chối với ERR-13-108
    Và người dùng thấy thông báo "Chưa sao được lô bản ghi sang kho WORM; sẽ thử lại."

  @US-13-013 @FR-13-013 @M @âm
  Kịch bản: US-13-013 âm 2 · `ETag` không khớp sau khi ghi
    Biết bucket `dh-worm-audit` ở Ceph RGW có Object Lock chế độ tuân thủ, tiền tố `{tenant}/`; tài khoản ghi chỉ có `PutObject` (không `Delete`, không đổi thời hạn); hệ lưu trữ tách khỏi Garage
    Khi `ETag` không khớp sau khi ghi
    Thì hệ thống từ chối với ERR-13-108

  @US-13-014 @FR-13-014 @M
  Kịch bản: US-13-014 dương · Kiểm tra toàn vẹn chuỗi
    Biết có ít nhất một neo hoặc chuỗi đang ở đoạn đầu (genesis); không có lượt kiểm tra khác của cùng tenant đang chạy
    Khi lịch `13.audit.verify-cron`; người dùng bấm "Kiểm tra toàn vẹn" ở UI-13-14; sau khi neo không khớp (FR-13-012)
    Thì hệ thống trả `202` với `verificationId`; kết quả ở `GET /verifications/{verificationId}`: `status`, `scope`, `checkedCount`, `firstBreakSeq`, `wormCheck`, `anchorsChecked`, `startedAt`, `finishedAt`
    Và lượt kiểm tra lưu 5 năm
    Và sự kiện được phát: EVT-13-07
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-13-014 @FR-13-014 @M @âm
  Kịch bản: US-13-014 âm 1 · Đang có lượt kiểm tra của tenant
    Biết có ít nhất một neo hoặc chuỗi đang ở đoạn đầu (genesis); không có lượt kiểm tra khác của cùng tenant đang chạy
    Khi đang có lượt kiểm tra của tenant
    Thì hệ thống từ chối với ERR-13-032 (409)
    Và người dùng thấy thông báo "Đang có lượt kiểm tra toàn vẹn của tenant này chạy."

  @US-13-014 @FR-13-014 @M @âm
  Kịch bản: US-13-014 âm 2 · Thiếu lý do ở `ON_DEMAND`
    Biết có ít nhất một neo hoặc chuỗi đang ở đoạn đầu (genesis); không có lượt kiểm tra khác của cùng tenant đang chạy
    Khi thiếu lý do ở `ON_DEMAND`
    Thì hệ thống từ chối với ERR-13-012 (422)

  @US-13-015 @FR-13-015 @M
  Kịch bản: US-13-015 dương · Xử lý đứt chuỗi và neo không khớp
    Biết FR-13-014 trả `FAILED`, hoặc FR-13-012 phát hiện neo lệch, hoặc `pgaudit` ghi nhận lệnh sửa bảng kiểm toán
    Khi một trong ba điều kiện trên
    Thì báo cáo toàn vẹn nêu `firstBreakSeq`, khoảng ảnh hưởng, loại lỗi, các hành động đã tự thực hiện
    Và chuỗi ở `SUSPECT`; chứng cứ bất biến đã thu; hồ sơ sự cố đã mở
    Và sự kiện được phát: EVT-13-05
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-13-015 @FR-13-015 @M @âm
  Kịch bản: US-13-015 âm 1 · Không thu được chứng cứ vì WORM lỗi
    Biết FR-13-014 trả `FAILED`, hoặc FR-13-012 phát hiện neo lệch, hoặc `pgaudit` ghi nhận lệnh sửa bảng kiểm toán
    Khi không thu được chứng cứ vì WORM lỗi
    Thì hệ thống từ chối với ERR-13-108
    Và người dùng thấy thông báo "Chưa sao được lô bản ghi sang kho WORM; sẽ thử lại."

  @US-13-015 @FR-13-015 @M @âm
  Kịch bản: US-13-015 âm 2 · Không gửi được thông báo qua kênh chính
    Biết FR-13-014 trả `FAILED`, hoặc FR-13-012 phát hiện neo lệch, hoặc `pgaudit` ghi nhận lệnh sửa bảng kiểm toán
    Khi không gửi được thông báo qua kênh chính
    Thì hệ thống từ chối với ERR-13-120

  @US-13-016 @FR-13-016 @M
  Kịch bản: US-13-016 dương · Chịu lỗi và đệm bản ghi khi PH-13 hoặc kho ngừng
    Biết DU dùng `dh-audit` với outbox trong cơ sở dữ liệu của DU; topic kiểm toán lưu giữ 7 ngày
    Khi một khâu của đường kiểm toán không nhận được
    Thì chỉ số backlog; `GET /chain-status` (API-13-087) trả `outboxPending`, `kafkaLag`, `wormLagSeconds`
    Và 0 bản ghi mất (NFR-13-011); chênh lệch đối chiếu bằng 0 sau hồi phục

  @US-13-016 @FR-13-016 @M @âm
  Kịch bản: US-13-016 âm 1 · Bản ghi đệm không gửi được quá 4 giờ
    Biết DU dùng `dh-audit` với outbox trong cơ sở dữ liệu của DU; topic kiểm toán lưu giữ 7 ngày
    Khi bản ghi đệm không gửi được quá 4 giờ
    Thì hệ thống từ chối với ERR-13-121

  @US-13-016 @FR-13-016 @M @âm
  Kịch bản: US-13-016 âm 2 · Không ghi được vào PostgreSQL
    Biết DU dùng `dh-audit` với outbox trong cơ sở dữ liệu của DU; topic kiểm toán lưu giữ 7 ngày
    Khi không ghi được vào PostgreSQL
    Thì hệ thống từ chối với ERR-13-106
    Và người dùng thấy thông báo "Không ghi được bản ghi vào bảng kiểm toán; sẽ thử lại."

  @US-13-017 @FR-13-017 @M
  Kịch bản: US-13-017 dương · Đối chiếu số bản ghi với bộ đếm của DU
    Biết mỗi DU xuất bộ đếm `dh_audit_emitted_total{du,tenant}` tăng khi ghi bản ghi vào outbox, và bộ đếm theo ngày `occurred_at`
    Khi hằng ngày lúc 01:00 cho ngày hôm trước; theo yêu cầu khi cần
    Thì hệ thống trả `GET /reconciliations`: danh sách theo ngày, DU, `emitted`, `received`, `diff`, `status`
    Và kết quả lưu 5 năm
    Và sự kiện được phát: EVT-13-09 khi `MISMATCH`

  @US-13-017 @FR-13-017 @M @âm
  Kịch bản: US-13-017 âm 1 · Lệch số
    Biết mỗi DU xuất bộ đếm `dh_audit_emitted_total{du,tenant}` tăng khi ghi bản ghi vào outbox, và bộ đếm theo ngày `occurred_at`
    Khi lệch số
    Thì hệ thống từ chối với ERR-13-111
    Và người dùng thấy thông báo "Số bản ghi kiểm toán của {du} lệch: phát {n}, nhận {m}."

  @US-13-017 @FR-13-017 @M @âm
  Kịch bản: US-13-017 âm 2 · Mimir không đọc được
    Biết mỗi DU xuất bộ đếm `dh_audit_emitted_total{du,tenant}` tăng khi ghi bản ghi vào outbox, và bộ đếm theo ngày `occurred_at`
    Khi Mimir không đọc được
    Thì hệ thống từ chối với ERR-13-014

  @US-13-018 @FR-13-018 @M
  Kịch bản: US-13-018 dương · Vòng đời lưu giữ và lưu trữ phân vùng
    Biết bảng `audit_event` phân vùng theo tháng của `recorded_at`; vai trò `ph13_archive` do OpenBao cấp động chỉ được tách và xóa phân vùng
    Khi ngày 1 mỗi tháng lúc 03:00; hằng ngày cho phần kiểm tra điều kiện lưu trữ
    Thì hệ thống trả `GET /partitions` (API-13-088): `month`, `status`, `recordCount`, `wormVerifiedAt`, `archivedAt`
    Và mọi phân vùng `ARCHIVED` có bản WORM đã xác minh
    Và sự kiện được phát: EVT-13-11
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-13-018 @FR-13-018 @M @âm
  Kịch bản: US-13-018 âm 1 · Phân vùng chưa xác minh đủ ở WORM
    Biết bảng `audit_event` phân vùng theo tháng của `recorded_at`; vai trò `ph13_archive` do OpenBao cấp động chỉ được tách và xóa phân vùng
    Khi phân vùng chưa xác minh đủ ở WORM
    Thì hệ thống từ chối với ERR-13-125
    Và người dùng thấy thông báo "Phân vùng {tháng} chưa lưu trữ được vì chưa xác minh đủ ở WORM."

  @US-13-018 @FR-13-018 @M @âm
  Kịch bản: US-13-018 âm 2 · Đặt thời hạn dưới 3 năm
    Biết bảng `audit_event` phân vùng theo tháng của `recorded_at`; vai trò `ph13_archive` do OpenBao cấp động chỉ được tách và xóa phân vùng
    Khi đặt thời hạn dưới 3 năm
    Thì hệ thống từ chối với ERR-13-040 (422)
    Và người dùng thấy thông báo "Tham số {khóa} ngoài miền cho phép; thời hạn lưu kiểm toán không được thấp hơn 3 năm."

  @US-13-019 @FR-13-019 @M
  Kịch bản: US-13-019 dương · Kiểm toán chính thao tác của PH-13
    Biết module `observability` và `audit` của `dh-platform` dùng `dh-audit`
    Khi một thao tác thuộc danh sách ở bảng "Thao tác của PH-13 phải ghi kiểm toán" dưới đây
    Thì mọi thao tác nhạy cảm ở PH-13 truy được tới người thực hiện, lý do, thời điểm
    Và bản ghi có trong chuỗi

  @US-13-019 @FR-13-019 @M @âm
  Kịch bản: US-13-019 âm 1 · Không ghi được outbox cho truy vấn kiểm toán
    Biết module `observability` và `audit` của `dh-platform` dùng `dh-audit`
    Khi không ghi được outbox cho truy vấn kiểm toán
    Thì hệ thống từ chối với ERR-13-014 (503)
    Và người dùng thấy thông báo "Dịch vụ {tên} tạm thời không khả dụng. Thử lại sau."

  @US-13-019 @FR-13-019 @M @âm
  Kịch bản: US-13-019 âm 2 · Bản ghi thiếu lý do ở thao tác bắt buộc lý do
    Biết module `observability` và `audit` của `dh-platform` dùng `dh-audit`
    Khi bản ghi thiếu lý do ở thao tác bắt buộc lý do
    Thì hệ thống từ chối với ERR-13-008, ERR-13-012 (400)

  # ---- EP-13-C · Tra cứu kiểm toán và bằng chứng

  @US-13-020 @FR-13-020 @M
  Kịch bản: US-13-020 dương · Tra cứu nhật ký kiểm toán
    Biết đã đăng nhập, chọn tenant (FR-00-004), có MFA hợp lệ (vai trò quản trị, FR-00-002); chuỗi của tenant tồn tại
    Khi người dùng mở "Giám sát và kiểm toán › Nhật ký kiểm toán" (UI-13-13) và bấm "Tra cứu"
    Thì hệ thống trả `200`: `items[]` (mỗi mục `id`, `seq`, `occurredAt`, `actor`, `action`, `objectType`, `objectId`, `outcome`, `reason`, `purpose`, `traceId`, `chainMarker`), `page`, `size`, `totalElements`, `integrity` (`status`, `lastVerifiedAt` …
    Và có bản ghi `AUDIT.QUERY` trong chuỗi; không thay đổi dữ liệu kiểm toán
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-13-020 @FR-13-020 @M @âm
  Kịch bản: US-13-020 âm 1 · Thiếu lý do
    Biết đã đăng nhập, chọn tenant (FR-00-004), có MFA hợp lệ (vai trò quản trị, FR-00-002); chuỗi của tenant tồn tại
    Khi thiếu lý do
    Thì hệ thống từ chối với ERR-13-012 (422)
    Và người dùng thấy thông báo "Cần nhập lý do truy vấn nhật ký kiểm toán (10 đến 500 ký tự)."

  @US-13-020 @FR-13-020 @M @âm
  Kịch bản: US-13-020 âm 2 · Phạm vi quá rộng
    Biết đã đăng nhập, chọn tenant (FR-00-004), có MFA hợp lệ (vai trò quản trị, FR-00-002); chuỗi của tenant tồn tại
    Khi phạm vi quá rộng
    Thì hệ thống từ chối với ERR-13-013 (422)
    Và người dùng thấy thông báo "Phạm vi truy vấn quá rộng ({n} bản ghi). Thu hẹp phạm vi hoặc chuyển sang xuất bằng chứng chạy nền."

  @US-13-021 @FR-13-021 @M
  Kịch bản: US-13-021 dương · Xem chi tiết bản ghi và xác minh băm
    Biết đã có một lượt tra cứu (FR-13-020) cho `queryId`; bản ghi nằm trong 12 tháng trực tuyến
    Khi người dùng bấm một dòng ở UI-13-13
    Thì hệ thống trả `200`: toàn bộ trường mục 4.7, `hashMatch`, `anchor` (`anchorId`, `anchoredAt`, `signatureValid`, `keyVersion`), `chainMarker`
    Và có bản ghi `AUDIT.RECORD.VIEW`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-13-021 @FR-13-021 @M @âm
  Kịch bản: US-13-021 âm 1 · Bản ghi đã lưu trữ (quá 12 tháng)
    Biết đã có một lượt tra cứu (FR-13-020) cho `queryId`; bản ghi nằm trong 12 tháng trực tuyến
    Khi bản ghi đã lưu trữ (quá 12 tháng)
    Thì hệ thống từ chối với ERR-13-029 (422)
    Và người dùng thấy thông báo "Khoảng thời gian này đã quá thời hạn lưu trực tuyến (12 tháng). Dùng xuất bằng chứng để lấy từ kho lưu trữ."

  @US-13-021 @FR-13-021 @M @âm
  Kịch bản: US-13-021 âm 2 · Không tìm thấy hoặc thuộc tenant khác
    Biết đã có một lượt tra cứu (FR-13-020) cho `queryId`; bản ghi nằm trong 12 tháng trực tuyến
    Khi không tìm thấy hoặc thuộc tenant khác
    Thì hệ thống từ chối với ERR-13-001 (404)

  @US-13-022 @FR-13-022 @M
  Kịch bản: US-13-022 dương · Lịch sử theo đối tượng cho tab "Lịch sử"
    Biết đối tượng có màn chi tiết (PTN-02) và bản ghi kiểm toán với `object_type`, `object_id` tương ứng
    Khi người dùng mở tab "Lịch sử" hoặc liên kết sâu `/{ma}/lich-su` ở màn của phân hệ chủ
    Thì hệ thống trả `200`: `items[]` (`id`, `occurredAt`, `actor`, `action`, `outcome`, `reason`, `hasDiff`), `archivedBefore`, `page`, `size`

  @US-13-022 @FR-13-022 @M @âm
  Kịch bản: US-13-022 âm 1 · PH-13 không phản hồi
    Biết đối tượng có màn chi tiết (PTN-02) và bản ghi kiểm toán với `object_type`, `object_id` tương ứng
    Khi PH-13 không phản hồi
    Thì hệ thống từ chối với ERR-13-014
    Và người dùng thấy thông báo "Chưa tải được lịch sử. Bấm Thử lại."

  @US-13-022 @FR-13-022 @M @âm
  Kịch bản: US-13-022 âm 2 · Đối tượng không thuộc tenant
    Biết đối tượng có màn chi tiết (PTN-02) và bản ghi kiểm toán với `object_type`, `object_id` tương ứng
    Khi đối tượng không thuộc tenant
    Thì hệ thống từ chối với ERR-13-001 (404)

  @US-13-023 @FR-13-023 @S
  Kịch bản: US-13-023 dương · Tra theo đối tượng bị tra cứu
    Biết bản ghi tra cứu dữ liệu nhạy cảm (PH-14, PH-09) đã ghi `object_key_hmac`; khóa HMAC `dh-{tenant}-audit-hmac` có ở OpenBao
    Khi người dùng chọn "Tra theo đối tượng" ở UI-13-13 và bấm "Tra"
    Thì hệ thống trả `200`: giống FR-13-020; trường `objectKeyHmac` ở mỗi mục dạng rút gọn
    Và có bản ghi `AUDIT.QUERY` (chỉ chứa băm)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-13-023 @FR-13-023 @S @âm
  Kịch bản: US-13-023 âm 1 · Định danh không đúng định dạng
    Biết bản ghi tra cứu dữ liệu nhạy cảm (PH-14, PH-09) đã ghi `object_key_hmac`; khóa HMAC `dh-{tenant}-audit-hmac` có ở OpenBao
    Khi định danh không đúng định dạng
    Thì hệ thống từ chối với ERR-13-031 (422)
    Và người dùng thấy thông báo "Số định danh không đúng định dạng."

  @US-13-024 @FR-13-024 @M
  Kịch bản: US-13-024 dương · Xuất bằng chứng kiểm toán ký số
    Biết đã chọn tenant; khóa ký bằng chứng có ở OpenBao; còn dung lượng ở bucket tạm
    Khi người dùng bấm "Xuất bằng chứng" ở UI-13-13 hoặc UI-13-14
    Thì hệ thống trả `202` với `exportId` và `Location`; `GET /exports/{exportId}` trả `status`, `recordCount`, `fileHash`, `expiresAt`; tải ở `GET /exports/{exportId}/download`
    Và siêu dữ liệu xuất lưu 5 năm, tệp xóa sau 7 ngày
    Và sự kiện được phát: EVT-13-08 khi `READY`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-13-024 @FR-13-024 @M @âm
  Kịch bản: US-13-024 âm 1 · Chưa xác thực lại
    Biết đã chọn tenant; khóa ký bằng chứng có ở OpenBao; còn dung lượng ở bucket tạm
    Khi chưa xác thực lại
    Thì hệ thống từ chối với ERR-13-028 (403)
    Và người dùng thấy thông báo "Cần xác thực lại để thực hiện thao tác này."

  @US-13-024 @FR-13-024 @M @âm
  Kịch bản: US-13-024 âm 2 · Có yêu cầu cùng phạm vi đang chạy
    Biết đã chọn tenant; khóa ký bằng chứng có ở OpenBao; còn dung lượng ở bucket tạm
    Khi có yêu cầu cùng phạm vi đang chạy
    Thì hệ thống từ chối với ERR-13-025 (409)
    Và người dùng thấy thông báo "Đã có yêu cầu xuất bằng chứng cùng phạm vi đang chạy."

  @US-13-025 @FR-13-025 @S
  Kịch bản: US-13-025 dương · Báo cáo truy cập liên tenant
    Biết bản ghi `AUDIT.CROSS_TENANT.OPEN` và các thao tác trong phiên đã được ghi ở chuỗi của tenant bị truy cập (FR-13-019)
    Khi một phiên liên tenant được mở, thông báo tới quản trị tỉnh; người dùng mở UI-13-16
    Thì hệ thống trả `200`: `sessions[]` (`sessionId`, `actor`, `homeTenant`, `openedAt`, `closedAt`, `reason`, `ticketRef`, `actionCount`)
    Và sự kiện được phát: EVT-13-12 khi mở phiên
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-13-025 @FR-13-025 @S @âm
  Kịch bản: US-13-025 âm 1 · Thao tác liên tenant không có phiên hợp lệ
    Biết bản ghi `AUDIT.CROSS_TENANT.OPEN` và các thao tác trong phiên đã được ghi ở chuỗi của tenant bị truy cập (FR-13-019)
    Khi thao tác liên tenant không có phiên hợp lệ
    Thì hệ thống từ chối với ERR-13-036 (403)
    Và người dùng thấy thông báo "Truy cập tenant khác cần phiên liên tenant có lý do còn hiệu lực."

  # ---- EP-13-D · Tra log, truy vết và liên kết

  @US-13-026 @FR-13-026 @M
  Kịch bản: US-13-026 dương · Tra log tập trung
    Biết đã chọn tenant; FR-13-002 đang đưa log vào Loki
    Khi người dùng mở "Giám sát › Tra log" (UI-13-07), nhập truy vấn và bấm "Chạy"; hoặc mở liên kết từ cảnh báo, trace
    Thì hệ thống trả `200`: `entries[]` (`id`, `ts`, `level`, `du`, `message`, `traceId`, `labels`), `histogram[]`, `nextCursor`

  @US-13-026 @FR-13-026 @M @âm
  Kịch bản: US-13-026 âm 1 · Khoảng quá dài
    Biết đã chọn tenant; FR-13-002 đang đưa log vào Loki
    Khi khoảng quá dài
    Thì hệ thống từ chối với ERR-13-005 (422)
    Và người dùng thấy thông báo "Khoảng thời gian tối đa cho loại dữ liệu này là 7 ngày mỗi lần tra. Hãy thu hẹp khoảng."

  @US-13-026 @FR-13-026 @M @âm
  Kịch bản: US-13-026 âm 2 · Cú pháp sai
    Biết đã chọn tenant; FR-13-002 đang đưa log vào Loki
    Khi cú pháp sai
    Thì hệ thống từ chối với ERR-13-006 (400)
    Và người dùng thấy thông báo "Cú pháp truy vấn chưa đúng ở vị trí {vị trí}: {gợi ý}."

  @US-13-027 @FR-13-027 @S
  Kịch bản: US-13-027 dương · Chi tiết dòng log, ngữ cảnh và theo dõi trực tiếp
    Biết đã có kết quả tra log hoặc trực tiếp
    Khi người dùng bấm một dòng; hoặc bật công tắc "Trực tiếp"
    Thì hệ thống trả `200` chi tiết; luồng `text/event-stream` cho trực tiếp

  @US-13-027 @FR-13-027 @S @âm
  Kịch bản: US-13-027 âm 1 · Dòng đã quá 90 ngày
    Biết đã có kết quả tra log hoặc trực tiếp
    Khi dòng đã quá 90 ngày
    Thì hệ thống từ chối với ERR-13-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy {loại đối tượng} {mã}. Đối tượng có thể đã bị xóa hoặc thuộc tenant khác."

  @US-13-028 @FR-13-028 @M
  Kịch bản: US-13-028 dương · Tìm trace và biểu đồ thác nước
    Biết trace được giữ theo FR-13-004 và còn trong 14 ngày
    Khi người dùng dán `trace_id` vào ô tìm ở UI-13-08; hoặc tìm theo điều kiện; hoặc mở từ thông báo lỗi, log, cảnh báo
    Thì hệ thống trả `200`: `summary` (`startedAt`, `durationMs`, `status`, `spanCount`, `caller`), `spans[]`, `timeBreakdown[]`, `remark`

  @US-13-028 @FR-13-028 @M @âm
  Kịch bản: US-13-028 âm 1 · Trace không tồn tại hoặc đã quá 14 ngày hoặc không nằm trong số được giữ
    Biết trace được giữ theo FR-13-004 và còn trong 14 ngày
    Khi trace không tồn tại hoặc đã quá 14 ngày hoặc không nằm trong số được giữ
    Thì hệ thống từ chối với ERR-13-030 (404)
    Và người dùng thấy thông báo "Không tìm thấy trace {traceId}. Trace chỉ giữ 14 ngày và chỉ giữ một phần trace thành công."

  @US-13-028 @FR-13-028 @M @âm
  Kịch bản: US-13-028 âm 2 · `traceId` sai định dạng
    Biết trace được giữ theo FR-13-004 và còn trong 14 ngày
    Khi `traceId` sai định dạng
    Thì hệ thống từ chối với ERR-13-003 (400)

  @US-13-029 @FR-13-029 @M
  Kịch bản: US-13-029 dương · Liên kết chỉ số, trace, log, kiểm toán bằng trace_id
    Biết mọi thành phần truyền `trace_id` (NFR-00-051)
    Khi người dùng bấm một liên kết `trace_id` ở thông báo lỗi, log, cảnh báo, bảng điều khiển; hoặc gọi API-13-024
    Thì hệ thống trả `200`: `traceId`, `trace` (`found`, `summaryRef`), `logs` (`count`, `searchLink`), `audit` (`exists`, `searchLink`; chỉ khi có quyền), `exemplars[]`, `remark`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-13-029 @FR-13-029 @M @âm
  Kịch bản: US-13-029 âm 1 · Không có dữ liệu ở cả ba nguồn
    Biết mọi thành phần truyền `trace_id` (NFR-00-051)
    Khi không có dữ liệu ở cả ba nguồn
    Thì hệ thống từ chối với ERR-13-030 (404)
    Và người dùng thấy thông báo "Không tìm thấy trace {traceId}. Trace chỉ giữ 14 ngày và chỉ giữ một phần trace thành công."

  @US-13-029 @FR-13-029 @M @âm
  Kịch bản: US-13-029 âm 2 · `traceId` sai định dạng
    Biết mọi thành phần truyền `trace_id` (NFR-00-051)
    Khi `traceId` sai định dạng
    Thì hệ thống từ chối với ERR-13-003 (400)

  @US-13-030 @FR-13-030 @M
  Kịch bản: US-13-030 dương · Tra nhật ký truy cập API
    Biết FR-13-006 đang ghi `access_log` ở ClickHouse
    Khi người dùng mở "Giám sát › Nhật ký truy cập API" (UI-13-09) hoặc mở từ bảng điều khiển theo API, theo HTTT
    Thì hệ thống trả `200`: `items[]` (`id`, `ts`, `systemCode`, `apiCode`, `method`, `pathTemplate`, `status`, `latencyMs`, `traceId`), `nextCursor`

  @US-13-030 @FR-13-030 @M @âm
  Kịch bản: US-13-030 âm 1 · Khoảng quá 31 ngày
    Biết FR-13-006 đang ghi `access_log` ở ClickHouse
    Khi khoảng quá 31 ngày
    Thì hệ thống từ chối với ERR-13-005 (422)

  @US-13-030 @FR-13-030 @M @âm
  Kịch bản: US-13-030 âm 2 · ClickHouse không khả dụng
    Biết FR-13-006 đang ghi `access_log` ở ClickHouse
    Khi ClickHouse không khả dụng
    Thì hệ thống từ chối với ERR-13-014, ERR-13-015 (503)

  # ---- EP-13-E · Bảng điều khiển

  @US-13-031 @FR-13-031 @M
  Kịch bản: US-13-031 dương · Bảng điều khiển tổng quan nền tảng
    Biết đã chọn tenant (FR-00-004); FR-13-001, 006, 007 đang thu dữ liệu
    Khi người dùng mở "Giám sát › Bảng giám sát" (UI-13-01), đổi khoảng thời gian hoặc bộ lọc
    Thì hệ thống trả `200`: `cards` (`rps`, `successRate`, `latencyP95Ms`, `openAlerts{critical,warning,info}`, `activeSystems`), `traffic[]`, `latency[]`, `components[]` (`code`, `status`, `reason`), `latestAlerts[]`, `monitoringHealth`

  @US-13-031 @FR-13-031 @M @âm
  Kịch bản: US-13-031 âm 1 · Thiếu dữ liệu cho một chỉ số
    Biết đã chọn tenant (FR-00-004); FR-13-001, 006, 007 đang thu dữ liệu
    Khi thiếu dữ liệu cho một chỉ số
    Thì hiện thông báo (BR-13-016)
    Và người dùng thấy thông báo "Chưa có dữ liệu"

  @US-13-031 @FR-13-031 @M @âm
  Kịch bản: US-13-031 âm 2 · Mimir hoặc ClickHouse không khả dụng
    Biết đã chọn tenant (FR-00-004); FR-13-001, 006, 007 đang thu dữ liệu
    Khi Mimir hoặc ClickHouse không khả dụng
    Thì hệ thống từ chối với ERR-13-014
    Và người dùng thấy thông báo "Dịch vụ {tên} tạm thời không khả dụng. Thử lại sau."

  @US-13-032 @FR-13-032 @M
  Kịch bản: US-13-032 dương · Bảng điều khiển đơn vị triển khai và tài nguyên
    Biết đơn vị triển khai `dh-runtime` được PH-04 tạo; FR-13-001, 007 thu chỉ số Micrometer và hạ tầng
    Khi người dùng mở tab "Đơn vị triển khai" ở UI-13-02 hoặc bấm một đơn vị
    Thì hệ thống trả `200`: danh sách `items[]` (`deploymentCode`, `image`, `replicasReady`, `replicasDesired`, `flowCount`, `routeCount`, `success`, `failure`, `avgMs`, `restarts`, `status`), `summary` (`active`, `total`); chi tiết kèm `pods[]` với CPU, bộ nhớ

  @US-13-032 @FR-13-032 @M @âm
  Kịch bản: US-13-032 âm 1 · Mã đơn vị không tồn tại hoặc thuộc tenant khác
    Biết đơn vị triển khai `dh-runtime` được PH-04 tạo; FR-13-001, 007 thu chỉ số Micrometer và hạ tầng
    Khi mã đơn vị không tồn tại hoặc thuộc tenant khác
    Thì hệ thống từ chối với ERR-13-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy đơn vị triển khai {mã}. Đối tượng có thể đã bị xóa hoặc thuộc tenant khác."

  @US-13-032 @FR-13-032 @M @âm
  Kịch bản: US-13-032 âm 2 · Mimir không khả dụng
    Biết đơn vị triển khai `dh-runtime` được PH-04 tạo; FR-13-001, 007 thu chỉ số Micrometer và hạ tầng
    Khi Mimir không khả dụng
    Thì hệ thống từ chối với ERR-13-014 (503)

  @US-13-033 @FR-13-033 @M
  Kịch bản: US-13-033 dương · Bảng điều khiển theo luồng và route
    Biết luồng đã phát hành ở PH-04; `dh-runtime` xuất chỉ số theo luồng, route (nhãn `flow`, `route`)
    Khi người dùng mở tab "Luồng" ở UI-13-02, bấm một luồng hoặc một route; hoặc mở từ chi tiết luồng ở PH-04
    Thì hệ thống trả `200`: `items[]` (`flowCode`, `state`, `throughput`, `errorRate`, `p50Ms`, `p95Ms`, `p99Ms`); chi tiết kèm `series[]`, `routes[]`

  @US-13-033 @FR-13-033 @M @âm
  Kịch bản: US-13-033 âm 1 · Luồng hoặc route không tồn tại
    Biết luồng đã phát hành ở PH-04; `dh-runtime` xuất chỉ số theo luồng, route (nhãn `flow`, `route`)
    Khi luồng hoặc route không tồn tại
    Thì hệ thống từ chối với ERR-13-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy luồng {mã}. Đối tượng có thể đã bị xóa hoặc thuộc tenant khác."

  @US-13-033 @FR-13-033 @M @âm
  Kịch bản: US-13-033 âm 2 · Chưa có chỉ số
    Biết luồng đã phát hành ở PH-04; `dh-runtime` xuất chỉ số theo luồng, route (nhãn `flow`, `route`)
    Khi chưa có chỉ số
    Thì hệ thống từ chối thao tác
    Và người dùng thấy thông báo "Chưa có dữ liệu"

  @US-13-034 @FR-13-034 @M
  Kịch bản: US-13-034 dương · Thống kê theo endpoint
    Biết route gắn nhãn endpoint (tên kết nối ở PH-05 hoặc host đích) trong chỉ số và trace
    Khi người dùng mở tab "Endpoint" ở UI-13-02
    Thì hệ thống trả `200`: `items[]` (`endpoint`, `direction`, `volume`, `errors`, `topError`, `lastMessageAt`, `lastTraceId`, `p95Ms`), `topApis[]`

  @US-13-034 @FR-13-034 @M @âm
  Kịch bản: US-13-034 âm 1 · ClickHouse hoặc Mimir không khả dụng
    Biết route gắn nhãn endpoint (tên kết nối ở PH-05 hoặc host đích) trong chỉ số và trace
    Khi ClickHouse hoặc Mimir không khả dụng
    Thì hệ thống từ chối với ERR-13-014 (503)

  @US-13-034 @FR-13-034 @M @âm
  Kịch bản: US-13-034 âm 2 · Tham số ngoài miền
    Biết route gắn nhãn endpoint (tên kết nối ở PH-05 hoặc host đích) trong chỉ số và trace
    Khi tham số ngoài miền
    Thì hệ thống từ chối với ERR-13-038 (400)
    Và người dùng thấy thông báo "Số dòng mỗi trang tối đa 200 hoặc tham số ngoài miền cho phép."

  @US-13-035 @FR-13-035 @M
  Kịch bản: US-13-035 dương · Bảng điều khiển theo API và theo HTTT
    Biết FR-13-006 đang ghi `access_log`; PH-02, PH-01 cung cấp danh mục API và HTTT
    Khi người dùng mở UI-13-03 hoặc bấm một API, một HTTT
    Thì hệ thống trả `200`: `items[]` (`apiCode`, `calls`, `errorRate`, `p95Ms`, `trend`); theo HTTT kèm `quotaUsedPercent`, `throttled`

  @US-13-035 @FR-13-035 @M @âm
  Kịch bản: US-13-035 âm 1 · API hoặc HTTT không tồn tại hoặc thuộc tenant khác
    Biết FR-13-006 đang ghi `access_log`; PH-02, PH-01 cung cấp danh mục API và HTTT
    Khi API hoặc HTTT không tồn tại hoặc thuộc tenant khác
    Thì hệ thống từ chối với ERR-13-001 (404)

  @US-13-035 @FR-13-035 @M @âm
  Kịch bản: US-13-035 âm 2 · ClickHouse không khả dụng
    Biết FR-13-006 đang ghi `access_log`; PH-02, PH-01 cung cấp danh mục API và HTTT
    Khi ClickHouse không khả dụng
    Thì hệ thống từ chối với ERR-13-014, ERR-13-015 (503)

  @US-13-036 @FR-13-036 @M
  Kịch bản: US-13-036 dương · Danh sách và chi tiết nút gateway
    Biết APISIX bật plugin `prometheus`; `dh-connect` xuất `dh_connect_config_revision` (phiên bản cấu hình đã đẩy xuống etcd)
    Khi người dùng mở tab "Gateway" ở UI-13-04 hoặc bấm một nút
    Thì hệ thống trả `200`: `items[]` (`nodeId`, `status`, `configRevision`, `latestRevision`, `lastSyncAt`, `connections`, `version`), chi tiết thêm `routesLoaded`, `lastSyncError`

  @US-13-036 @FR-13-036 @M @âm
  Kịch bản: US-13-036 âm 1 · Nút không tồn tại
    Biết APISIX bật plugin `prometheus`; `dh-connect` xuất `dh_connect_config_revision` (phiên bản cấu hình đã đẩy xuống etcd)
    Khi nút không tồn tại
    Thì hệ thống từ chối với ERR-13-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy nút gateway {mã}. Đối tượng có thể đã bị xóa hoặc thuộc tenant khác."

  @US-13-036 @FR-13-036 @M @âm
  Kịch bản: US-13-036 âm 2 · Mimir không khả dụng
    Biết APISIX bật plugin `prometheus`; `dh-connect` xuất `dh_connect_config_revision` (phiên bản cấu hình đã đẩy xuống etcd)
    Khi Mimir không khả dụng
    Thì hệ thống từ chối với ERR-13-014 (503)

  @US-13-037 @FR-13-037 @M
  Kịch bản: US-13-037 dương · Giám sát tài nguyên nút gateway
    Biết FR-13-007 thu chỉ số cAdvisor và APISIX
    Khi người dùng mở chi tiết nút ở UI-13-04
    Thì hệ thống trả `200`: `cpu[]`, `memory[]`, `connections[]`, `latency` (`p50Ms`, `p95Ms`, `p99Ms`, `sloMs`), `gateway5xx[]`

  @US-13-037 @FR-13-037 @M @âm
  Kịch bản: US-13-037 âm 1 · Mimir không khả dụng
    Biết FR-13-007 thu chỉ số cAdvisor và APISIX
    Khi Mimir không khả dụng
    Thì hệ thống từ chối với ERR-13-014 (503)

  @US-13-037 @FR-13-037 @M @âm
  Kịch bản: US-13-037 âm 2 · Khoảng không hợp lệ
    Biết FR-13-007 thu chỉ số cAdvisor và APISIX
    Khi khoảng không hợp lệ
    Thì hệ thống từ chối với ERR-13-004 (400)

  @US-13-038 @FR-13-038 @M
  Kịch bản: US-13-038 dương · Bảng điều khiển cụm Kafka
    Biết strimzi exporter hoạt động (FR-13-007)
    Khi người dùng mở tab "Kafka" ở UI-13-04; hoặc bấm liên kết từ bảng PH-10 (UI-10-01)
    Thì hệ thống trả `200`: `brokers[]` (`id`, `cpu`, `memory`, `diskUsed`, `bytesIn`, `bytesOut`), `cluster` (`underReplicated`, `underMinIsr`, `totalLag`, `topics`, `partitions`)

  @US-13-038 @FR-13-038 @M @âm
  Kịch bản: US-13-038 âm 1 · Không đủ quyền với chỉ số broker
    Biết strimzi exporter hoạt động (FR-13-007)
    Khi không đủ quyền với chỉ số broker
    Thì hệ thống từ chối với ERR-13-009 (403)

  @US-13-038 @FR-13-038 @M @âm
  Kịch bản: US-13-038 âm 2 · Mimir không khả dụng
    Biết strimzi exporter hoạt động (FR-13-007)
    Khi Mimir không khả dụng
    Thì hệ thống từ chối với ERR-13-014 (503)

  @US-13-039 @FR-13-039 @M
  Kịch bản: US-13-039 dương · Bảng điều khiển hoạt động nghiệp vụ
    Biết PH-01 cung cấp danh sách HTTT và tổ chức; FR-13-006 có số lượt gọi
    Khi người dùng mở UI-13-05
    Thì hệ thống trả `200`: `cards` (`totalCalls`, `connectedSystems`, `totalSystems`), `trend[]`, `byOrg[]`, `byService[]`, `notConnected[]`

  @US-13-039 @FR-13-039 @M @âm
  Kịch bản: US-13-039 âm 1 · PH-01 hoặc ClickHouse không khả dụng
    Biết PH-01 cung cấp danh sách HTTT và tổ chức; FR-13-006 có số lượt gọi
    Khi PH-01 hoặc ClickHouse không khả dụng
    Thì hệ thống từ chối với ERR-13-014 (503)
    Và người dùng thấy thông báo "Dịch vụ {tên} tạm thời không khả dụng. Thử lại sau."

  @US-13-039 @FR-13-039 @M @âm
  Kịch bản: US-13-039 âm 2 · Thiếu dữ liệu
    Biết PH-01 cung cấp danh sách HTTT và tổ chức; FR-13-006 có số lượt gọi
    Khi thiếu dữ liệu
    Thì hệ thống từ chối thao tác
    Và người dùng thấy thông báo "Chưa có dữ liệu"

  @US-13-040 @FR-13-040 @M
  Kịch bản: US-13-040 dương · Bảng điều khiển an ninh
    Biết log an ninh vào `{tenant}-security` (FR-13-002); luật phát hiện đang chạy (FR-13-051)
    Khi người dùng mở UI-13-06
    Thì hệ thống trả `200`: `auth` (`failed[]`, `succeeded[]`), `denied[]`, `waf[]`, `sensitiveViews[]`, `largeExports[]`, `crossTenantSessions`, `securityAlerts{open,byLevel}`, `piiScan`, `chain` (`status`, `lastVerifiedAt`, `lastAnchorAt`)

  @US-13-040 @FR-13-040 @M @âm
  Kịch bản: US-13-040 âm 1 · Thiếu quyền
    Biết log an ninh vào `{tenant}-security` (FR-13-002); luật phát hiện đang chạy (FR-13-051)
    Khi thiếu quyền
    Thì hệ thống từ chối với ERR-13-009 (403)

  @US-13-040 @FR-13-040 @M @âm
  Kịch bản: US-13-040 âm 2 · Loki hoặc PostgreSQL không khả dụng
    Biết log an ninh vào `{tenant}-security` (FR-13-002); luật phát hiện đang chạy (FR-13-051)
    Khi Loki hoặc PostgreSQL không khả dụng
    Thì hệ thống từ chối với ERR-13-014

  @US-13-041 @FR-13-041 @S
  Kịch bản: US-13-041 dương · Quản lý bộ dashboard theo tenant
    Biết Grafana đang chạy, có nguồn dữ liệu Mimir, Loki, Tempo, ClickHouse theo tổ chức; kho Git cấu hình có thư mục dashboard chuẩn
    Khi khởi tạo tenant; phát hành phiên bản dashboard mới; người dùng bấm "Đồng bộ lại" ở UI-13-17
    Thì hệ thống trả `202` cho đồng bộ; `GET /dashboard-sets` trả `items[]` (`setCode`, `version`, `syncedAt`, `status`, `grafanaOrg`)
    Và bộ chuẩn chỉ-đọc ở tổ chức Grafana của tenant
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-13-041 @FR-13-041 @S @âm
  Kịch bản: US-13-041 âm 1 · Bộ dashboard không hợp lệ
    Biết Grafana đang chạy, có nguồn dữ liệu Mimir, Loki, Tempo, ClickHouse theo tổ chức; kho Git cấu hình có thư mục dashboard chuẩn
    Khi bộ dashboard không hợp lệ
    Thì hệ thống từ chối với ERR-13-035 (422)
    Và người dùng thấy thông báo "Bộ dashboard không hợp lệ: {chi tiết}."

  # ---- EP-13-F · Cảnh báo

  @US-13-042 @FR-13-042 @M
  Kịch bản: US-13-042 dương · Quản lý luật cảnh báo kèm runbook, chạy thử
    Biết đã chọn tenant, tenant không tạm ngừng; hạn mức luật của tenant còn (mặc định 500)
    Khi người dùng bấm "+ Tạo luật" ở UI-13-11; hoặc sửa, tắt, bật, ngừng dùng, chạy thử một luật
    Thì hệ thống trả `201` với `Location` và `ETag` khi tạo; `200` khi sửa; chạy thử trả `200`: `fires`, `firingSeconds`, `periods[]`, `tooSensitive`
    Và luật `ACTIVE` ở Ruler; runbook gắn với luật
    Và sự kiện được phát: EVT-13-10 (tạo, sửa, tắt, ngừng dùng)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-13-042 @FR-13-042 @M @âm
  Kịch bản: US-13-042 âm 1 · Thiếu runbook hoặc runbook thiếu mục
    Biết đã chọn tenant, tenant không tạm ngừng; hạn mức luật của tenant còn (mặc định 500)
    Khi thiếu runbook hoặc runbook thiếu mục
    Thì hệ thống từ chối với ERR-13-017 (422)
    Và người dùng thấy thông báo "Luật cảnh báo phải có runbook đủ năm mục: ý nghĩa, kiểm tra đầu tiên, nguyên nhân thường gặp, cách xử lý, khi nào báo cấp trên."

  @US-13-042 @FR-13-042 @M @âm
  Kịch bản: US-13-042 âm 2 · Biểu thức sai
    Biết đã chọn tenant, tenant không tạm ngừng; hạn mức luật của tenant còn (mặc định 500)
    Khi biểu thức sai
    Thì hệ thống từ chối với ERR-13-018 (422)
    Và người dùng thấy thông báo "Biểu thức luật không hợp lệ: {chi tiết}."

  @US-13-043 @FR-13-043 @M
  Kịch bản: US-13-043 dương · Bộ luật cảnh báo chuẩn của nền tảng
    Biết kho Git luật chuẩn `dh-platform-rules` có tệp luật, runbook và đã qua kiểm tra CI (đủ runbook, biểu thức hợp lệ); Argo CD đồng bộ
    Khi PA hợp nhất thay đổi luật chuẩn vào nhánh chính; tenant mới được khởi tạo (FR-13-059)
    Thì hệ thống trả `GET /alert-rules?scope=PLATFORM`: danh sách luật chuẩn
    Và luật chuẩn ở Ruler khớp phiên bản Git
    Và sự kiện được phát: EVT-13-10 khi phiên bản luật chuẩn đổi
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-13-043 @FR-13-043 @M @âm
  Kịch bản: US-13-043 âm 1 · Tenant cố sửa hoặc tắt luật chuẩn
    Biết kho Git luật chuẩn `dh-platform-rules` có tệp luật, runbook và đã qua kiểm tra CI (đủ runbook, biểu thức hợp lệ); Argo CD đồng bộ
    Khi tenant cố sửa hoặc tắt luật chuẩn
    Thì hệ thống từ chối với ERR-13-019 (403)
    Và người dùng thấy thông báo "Luật chuẩn của nền tảng không sửa hoặc tắt được. Bạn có thể tạo luật riêng."

  @US-13-043 @FR-13-043 @M @âm
  Kịch bản: US-13-043 âm 2 · Ruler nạp luật lỗi
    Biết kho Git luật chuẩn `dh-platform-rules` có tệp luật, runbook và đã qua kiểm tra CI (đủ runbook, biểu thức hợp lệ); Argo CD đồng bộ
    Khi ruler nạp luật lỗi
    Thì hệ thống từ chối với ERR-13-119
    Và người dùng thấy thông báo "Luật {mã} đánh giá lỗi: {lý do}."

  @US-13-044 @FR-13-044 @M
  Kịch bản: US-13-044 dương · Đánh giá luật, chống nhấp nháy, sinh cảnh báo
    Biết luật `ACTIVE` đã nạp ở Ruler (FR-13-042, 043); Alertmanager ba bản sao chạy
    Khi chu kỳ đánh giá của từng luật (mặc định 30 giây, `13.alert.eval-interval-seconds`)
    Thì bản ghi cảnh báo `FIRING` ở API-13-030
    Và mỗi cảnh báo có `fingerprint` duy nhất, một bản ghi `alert`
    Và sự kiện được phát: EVT-13-01 khi `FIRING`; EVT-13-02 khi `RESOLVED`

  @US-13-044 @FR-13-044 @M @âm
  Kịch bản: US-13-044 âm 1 · Ruler không đánh giá được luật
    Biết luật `ACTIVE` đã nạp ở Ruler (FR-13-042, 043); Alertmanager ba bản sao chạy
    Khi ruler không đánh giá được luật
    Thì hệ thống từ chối với ERR-13-119
    Và người dùng thấy thông báo "Luật {mã} đánh giá lỗi: {lý do}."

  @US-13-044 @FR-13-044 @M @âm
  Kịch bản: US-13-044 âm 2 · Alertmanager không nhận
    Biết luật `ACTIVE` đã nạp ở Ruler (FR-13-042, 043); Alertmanager ba bản sao chạy
    Khi alertmanager không nhận
    Thì ruler thử lại; quá 2 phút thì luật `monitoring-down` của FR-13-049 phát cảnh báo qua kênh độc lập

  @US-13-045 @FR-13-045 @M
  Kịch bản: US-13-045 dương · Phân mức, gom nhóm, chống lặp
    Biết cảnh báo `FIRING` từ FR-13-044 có `group_key`
    Khi cảnh báo `FIRING` mới tới Alertmanager
    Thì nhóm cảnh báo ở `GET /alerts` (trường `groupKey`, `groupSize`)
    Và mỗi cảnh báo thuộc một nhóm

  @US-13-045 @FR-13-045 @M @âm
  Kịch bản: US-13-045 âm 1 · Alertmanager mất đồng bộ giữa các bản sao
    Biết cảnh báo `FIRING` từ FR-13-044 có `group_key`
    Khi alertmanager mất đồng bộ giữa các bản sao
    Thì cảnh báo có thể bị gửi trùng trong thời gian ngắn; luật `monitoring-down` (FR-13-049) theo dõi

  @US-13-045 @FR-13-045 @M @âm
  Kịch bản: US-13-045 âm 2 · Cảnh báo thiếu `group_key`
    Biết cảnh báo `FIRING` từ FR-13-044 có `group_key`
    Khi cảnh báo thiếu `group_key`
    Thì hệ thống từ chối với ERR-13-003

  @US-13-046 @FR-13-046 @M
  Kịch bản: US-13-046 dương · Gửi thông báo theo lịch trực và leo thang
    Biết có lịch trực và kênh thông báo cho nhóm nhận của luật (FR-13-048); PH-18 sẵn sàng gửi thư, SMS
    Khi nhóm cảnh báo mới tới `dh-platform` (FR-13-045); hết hạn bộ đếm leo thang
    Thì trạng thái lượt gửi ở chi tiết cảnh báo (`GET /alerts/{alertId}`: `notifications[]`)
    Và mỗi lượt gửi có kết quả ghi lại
    Và sự kiện được phát: EVT-13-01 khi gửi lần đầu; EVT-13-03 khi leo thang

  @US-13-046 @FR-13-046 @M @âm
  Kịch bản: US-13-046 âm 1 · Kênh chính lỗi
    Biết có lịch trực và kênh thông báo cho nhóm nhận của luật (FR-13-048); PH-18 sẵn sàng gửi thư, SMS
    Khi kênh chính lỗi
    Thì hệ thống từ chối với ERR-13-120
    Và người dùng thấy thông báo "Gửi thông báo qua kênh {kênh} thất bại: {lý do}."

  @US-13-046 @FR-13-046 @M @âm
  Kịch bản: US-13-046 âm 2 · Leo thang hết cấp mà chưa ai xác nhận
    Biết có lịch trực và kênh thông báo cho nhóm nhận của luật (FR-13-048); PH-18 sẵn sàng gửi thư, SMS
    Khi leo thang hết cấp mà chưa ai xác nhận
    Thì hệ thống từ chối với ERR-13-121
    Và người dùng thấy thông báo "Cảnh báo {id} đã leo thang hết cấp mà chưa ai xác nhận."

  @US-13-047 @FR-13-047 @M
  Kịch bản: US-13-047 dương · Xử lý cảnh báo: xác nhận, đã xử lý, tạm ẩn
    Biết có cảnh báo `FIRING` hoặc `ACKNOWLEDGED`
    Khi người dùng mở "Giám sát › Cảnh báo" (UI-13-10) và bấm một cảnh báo hoặc nhấn liên kết trong thông báo
    Thì hệ thống trả `200`: cảnh báo sau cập nhật (`status`, `ackBy`, `ackAt`, `resolvedAt`, `resolution`, `silenceUntil`), `ETag`
    Và trạng thái mới; Alertmanager đồng bộ silence; MTTA, MTTR cập nhật
    Và sự kiện được phát: EVT-13-02 khi đóng
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-13-047 @FR-13-047 @M @âm
  Kịch bản: US-13-047 âm 1 · Cảnh báo đã `RESOLVED` hoặc thao tác không áp dụng
    Biết có cảnh báo `FIRING` hoặc `ACKNOWLEDGED`
    Khi cảnh báo đã `RESOLVED` hoặc thao tác không áp dụng
    Thì hệ thống từ chối với ERR-13-020 (409)
    Và người dùng thấy thông báo "Cảnh báo đã ở trạng thái {trạng thái}, thao tác này không còn áp dụng."

  @US-13-047 @FR-13-047 @M @âm
  Kịch bản: US-13-047 âm 2 · Thiếu nguyên nhân, hành động khi đóng
    Biết có cảnh báo `FIRING` hoặc `ACKNOWLEDGED`
    Khi thiếu nguyên nhân, hành động khi đóng
    Thì hệ thống từ chối với ERR-13-022 (422)
    Và người dùng thấy thông báo "Cần ghi nguyên nhân và hành động đã thực hiện trước khi đánh dấu đã xử lý."

  @US-13-048 @FR-13-048 @M
  Kịch bản: US-13-048 dương · Quản lý lịch trực, nhóm nhận, kênh thông báo
    Biết có người dùng trong tenant được gán vào nhóm (PH-12); bí mật của kênh webhook lưu ở OpenBao
    Khi người dùng mở UI-13-12 và tạo hoặc sửa lịch trực, nhóm nhận, kênh
    Thì hệ thống trả `201` hoặc `200` kèm đối tượng; kiểm tra kênh trả `200`: `ok`, `detail`
    Và lịch, kênh có hiệu lực ngay cho cảnh báo mới
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-13-048 @FR-13-048 @M @âm
  Kịch bản: US-13-048 âm 1 · Lịch hở khoảng, chồng ca, hoặc nhóm Nghiêm trọng thiếu đường độc lập
    Biết có người dùng trong tenant được gán vào nhóm (PH-12); bí mật của kênh webhook lưu ở OpenBao
    Khi lịch hở khoảng, chồng ca, hoặc nhóm Nghiêm trọng thiếu đường độc lập
    Thì hệ thống từ chối với ERR-13-034 (422)
    Và người dùng thấy thông báo "Lịch trực chưa có người nhận ở mọi thời điểm, có ca chồng lấn, hoặc nhóm nhận mức Nghiêm trọng chưa có hai kênh độc lập."

  @US-13-048 @FR-13-048 @M @âm
  Kịch bản: US-13-048 âm 2 · Kiểm tra kênh thất bại
    Biết có người dùng trong tenant được gán vào nhóm (PH-12); bí mật của kênh webhook lưu ở OpenBao
    Khi kiểm tra kênh thất bại
    Thì hệ thống từ chối với ERR-13-033 (422)
    Và người dùng thấy thông báo "Kiểm tra kênh {mã} không thành công: {lý do}."

  @US-13-049 @FR-13-049 @M
  Kịch bản: US-13-049 dương · Giám sát chính hệ thống giám sát
    Biết có bộ nhận nhịp tim ngoài hạ tầng của site do nhóm nền tảng vận hành (không phụ thuộc Mimir, Alertmanager của site)
    Khi chu kỳ 1 phút; luật `Watchdog`
    Thì hệ thống trả `200`: `status`, `components[]` (`code`, `status`, `reason`, `since`)
    Và sự kiện được phát: EVT-13-14 khi kho vượt 85%

  @US-13-049 @FR-13-049 @M @âm
  Kịch bản: US-13-049 âm 1 · Mất nhịp tim
    Biết có bộ nhận nhịp tim ngoài hạ tầng của site do nhóm nền tảng vận hành (không phụ thuộc Mimir, Alertmanager của site)
    Khi mất nhịp tim
    Thì cảnh báo `CRITICAL` qua kênh độc lập; thông báo gửi PA, PO
    Và người dùng thấy thông báo "Hệ thống giám sát có thể đang ngừng, kiểm tra Ruler và Alertmanager."

  @US-13-049 @FR-13-049 @M @âm
  Kịch bản: US-13-049 âm 2 · Kho đạt 85%
    Biết có bộ nhận nhịp tim ngoài hạ tầng của site do nhóm nền tảng vận hành (không phụ thuộc Mimir, Alertmanager của site)
    Khi kho đạt 85%
    Thì hệ thống từ chối với ERR-13-123
    Và người dùng thấy thông báo "Kho {kho} đạt {x}% dung lượng."

  @US-13-050 @FR-13-050 @S
  Kịch bản: US-13-050 dương · Thống kê hiệu quả cảnh báo
    Biết có cảnh báo đã đóng trong khoảng; thao tác đóng ghi `outcome`
    Khi người dùng mở tab "Thống kê" ở UI-13-10
    Thì hệ thống trả `200`: `items[]` (`ruleCode`, `fires`, `escalations`, `mttaSeconds`, `mttrSeconds`, `falseRate`, `hint`)

  @US-13-050 @FR-13-050 @S @âm
  Kịch bản: US-13-050 âm 1 · Không có cảnh báo trong khoảng
    Biết có cảnh báo đã đóng trong khoảng; thao tác đóng ghi `outcome`
    Khi không có cảnh báo trong khoảng
    Thì hệ thống từ chối thao tác
    Và người dùng thấy thông báo "Chưa có dữ liệu"

  # ---- EP-13-G · Phát hiện bất thường an ninh

  @US-13-051 @FR-13-051 @M
  Kịch bản: US-13-051 dương · Nạp và tinh chỉnh bộ luật phát hiện UC-SEC
    Biết kho Git luật phát hiện `dh-platform-rules` có tệp 25 luật (mã, nguồn, ngưỡng mặc định, giới hạn nới, mức, người nhận); nguồn log tương ứng đã vào `{tenant}-security` hoặc Mimir
    Khi khởi tạo tenant (FR-13-059); phát hành phiên bản luật; SO mở UI-13-15 và sửa ngưỡng
    Thì hệ thống trả `200`: luật sau cập nhật (`ruleCode`, `threshold`, `enabled`, `defaultThreshold`, `limit`, `fires30d`, `falseRate30d`)
    Và ngưỡng mới có hiệu lực; thay đổi có trong lịch sử kiểm toán
    Và sự kiện được phát: EVT-13-10
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-13-051 @FR-13-051 @M @âm
  Kịch bản: US-13-051 âm 1 · Ngưỡng ngoài biên hoặc cố tắt luật không được tắt
    Biết kho Git luật phát hiện `dh-platform-rules` có tệp 25 luật (mã, nguồn, ngưỡng mặc định, giới hạn nới, mức, người nhận); nguồn log tương ứng đã vào `{tenant}-security` hoặc Mimir
    Khi ngưỡng ngoài biên hoặc cố tắt luật không được tắt
    Thì hệ thống từ chối với ERR-13-024 (422)
    Và người dùng thấy thông báo "Ngưỡng này vượt giới hạn nới cho phép ({giới hạn}) hoặc luật này không được tắt."

  @US-13-051 @FR-13-051 @M @âm
  Kịch bản: US-13-051 âm 2 · Thiếu lý do
    Biết kho Git luật phát hiện `dh-platform-rules` có tệp 25 luật (mã, nguồn, ngưỡng mặc định, giới hạn nới, mức, người nhận); nguồn log tương ứng đã vào `{tenant}-security` hoặc Mimir
    Khi thiếu lý do
    Thì hệ thống từ chối với ERR-13-008 (400)

  @US-13-052 @FR-13-052 @M
  Kịch bản: US-13-052 dương · Phát hiện bất thường từ bản ghi kiểm toán
    Biết bản ghi kiểm toán có `action`, `actor_id`, `object_key_hmac`, `after.rowCount` ở thao tác xuất, `occurred_at`; luật đang bật
    Khi chu kỳ 1 phút của bộ phát hiện
    Thì cảnh báo an ninh ở API-13-056
    Và mỗi cảnh báo có bằng chứng liên kết ngược tới bản ghi kiểm toán
    Và sự kiện được phát: EVT-13-04

  @US-13-052 @FR-13-052 @M @âm
  Kịch bản: US-13-052 âm 1 · Truy vấn phát hiện lỗi hoặc trễ quá 5 phút
    Biết bản ghi kiểm toán có `action`, `actor_id`, `object_key_hmac`, `after.rowCount` ở thao tác xuất, `occurred_at`; luật đang bật
    Khi truy vấn phát hiện lỗi hoặc trễ quá 5 phút
    Thì hệ thống từ chối với ERR-13-119
    Và người dùng thấy thông báo "Luật {mã} đánh giá lỗi: {lý do}."

  @US-13-052 @FR-13-052 @M @âm
  Kịch bản: US-13-052 âm 2 · Cơ sở dữ liệu không khả dụng
    Biết bản ghi kiểm toán có `action`, `actor_id`, `object_key_hmac`, `after.rowCount` ở thao tác xuất, `occurred_at`; luật đang bật
    Khi cơ sở dữ liệu không khả dụng
    Thì hệ thống từ chối với ERR-13-014

  @US-13-053 @FR-13-053 @M
  Kịch bản: US-13-053 dương · Xử lý cảnh báo an ninh, đề xuất tạm ngừng HTTT
    Biết có cảnh báo an ninh `NEW` hoặc `ACKNOWLEDGED`
    Khi người dùng mở UI-13-15 hoặc nhấn liên kết trong thông báo
    Thì hệ thống trả `200`: cảnh báo sau cập nhật (`status`, `assignee`, `verdict`, `verdictNote`, `proposedAction`, `incidentRef`)
    Và cảnh báo `CLOSED` có kết luận; đề xuất tạm ngừng ghi vết
    Và sự kiện được phát: EVT-13-04 khi đề xuất tạm ngừng
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-13-053 @FR-13-053 @M @âm
  Kịch bản: US-13-053 âm 1 · Đóng thiếu kết luận
    Biết có cảnh báo an ninh `NEW` hoặc `ACKNOWLEDGED`
    Khi đóng thiếu kết luận
    Thì hệ thống từ chối với ERR-13-023 (422)
    Và người dùng thấy thông báo "Chọn kết luận (sự cố thật, báo nhầm, chấp nhận rủi ro) trước khi đóng cảnh báo an ninh."

  @US-13-053 @FR-13-053 @M @âm
  Kịch bản: US-13-053 âm 2 · Cảnh báo đã đóng
    Biết có cảnh báo an ninh `NEW` hoặc `ACKNOWLEDGED`
    Khi cảnh báo đã đóng
    Thì hệ thống từ chối với ERR-13-020 (409)
    Và người dùng thấy thông báo "Cảnh báo đã ở trạng thái {trạng thái}, thao tác này không còn áp dụng."

  @US-13-054 @FR-13-054 @M
  Kịch bản: US-13-054 dương · Đẩy log và cảnh báo an ninh sang SIEM, SOC
    Biết mục tiêu SIEM đã khai báo; chứng thư TLS của đích tin cậy được; kênh mạng tới đích mở qua cổng thoát có kiểm soát (SEC-16)
    Khi mỗi sự kiện an ninh, cảnh báo, neo mới; hoặc người dùng khai báo, bấm "Kiểm tra kết nối"
    Thì hệ thống trả `201` hoặc `200` kèm mục tiêu; kiểm tra trả `200`: `ok`, `latencyMs`
    Và mục tiêu hoạt động; độ trễ đo được
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-13-054 @FR-13-054 @M @âm
  Kịch bản: US-13-054 âm 1 · Mục tiêu không hợp lệ hoặc không kết nối được
    Biết mục tiêu SIEM đã khai báo; chứng thư TLS của đích tin cậy được; kênh mạng tới đích mở qua cổng thoát có kiểm soát (SEC-16)
    Khi mục tiêu không hợp lệ hoặc không kết nối được
    Thì hệ thống từ chối với ERR-13-039 (422)
    Và người dùng thấy thông báo "Mục tiêu SIEM không hợp lệ hoặc không kết nối được: {lý do}."

  @US-13-054 @FR-13-054 @M @âm
  Kịch bản: US-13-054 âm 2 · SIEM không nhận khi đang chạy
    Biết mục tiêu SIEM đã khai báo; chứng thư TLS của đích tin cậy được; kênh mạng tới đích mở qua cổng thoát có kiểm soát (SEC-16)
    Khi SIEM không nhận khi đang chạy
    Thì hệ thống từ chối với ERR-13-122
    Và người dùng thấy thông báo "SIEM {mục tiêu} không nhận được dữ liệu."

  @US-13-055 @FR-13-055 @C
  Kịch bản: US-13-055 dương · Mẫu báo cáo sự cố và thông báo vi phạm DLCN
    Biết có cảnh báo an ninh `CLOSED` với kết luận `CONFIRMED_INCIDENT`, hoặc cảnh báo đang điều tra
    Khi SO bấm "Lập báo cáo" ở chi tiết cảnh báo (UI-13-15)
    Thì hệ thống trả `201`: báo cáo `DRAFT`; `GET /incident-reports/{reportId}` trả nội dung, `deadlineAt`, trạng thái
    Và báo cáo lưu 5 năm
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-13-055 @FR-13-055 @C @âm
  Kịch bản: US-13-055 âm 1 · Cảnh báo không có kết luận
    Biết có cảnh báo an ninh `CLOSED` với kết luận `CONFIRMED_INCIDENT`, hoặc cảnh báo đang điều tra
    Khi cảnh báo không có kết luận
    Thì vẫn lập bản nháp với dòng thông báo
    Và người dùng thấy thông báo "Chưa có kết luận"

  # ---- EP-13-H · Cung cấp dữ liệu cho phân hệ khác và vòng đời theo tenant

  @US-13-056 @FR-13-056 @M
  Kịch bản: US-13-056 dương · Cung cấp số liệu cho PH-16
    Biết FR-13-001, 006 đang thu dữ liệu; PH-16 đã được cấp scope
    Khi PH-16 gọi API theo lịch của PH-16
    Thì hệ thống trả `200`: `summary` (`transactions`, `successRate`, `latencyP95Ms`, `connectedSystems`, `apis`, `events`), `dataThrough`, `partial`

  @US-13-056 @FR-13-056 @M @âm
  Kịch bản: US-13-056 âm 1 · Thiếu scope hoặc truy vấn vượt tenant
    Biết FR-13-001, 006 đang thu dữ liệu; PH-16 đã được cấp scope
    Khi thiếu scope hoặc truy vấn vượt tenant
    Thì hệ thống từ chối với ERR-13-044 (403)
    Và người dùng thấy thông báo "Truy vấn vượt phạm vi tenant hoặc tài khoản máy thiếu quyền."

  @US-13-056 @FR-13-056 @M @âm
  Kịch bản: US-13-056 âm 2 · Biểu thức sai
    Biết FR-13-001, 006 đang thu dữ liệu; PH-16 đã được cấp scope
    Khi biểu thức sai
    Thì hệ thống từ chối với ERR-13-006, ERR-13-015 (400)

  @US-13-057 @FR-13-057 @M
  Kịch bản: US-13-057 dương · Cung cấp ngữ cảnh chẩn đoán cho PH-18
    Biết mục DLQ có `trace_id` và thời điểm lỗi
    Khi người xử lý mở một mục DLQ ở PH-18
    Thì hệ thống trả `200`: `trace` (`found`, `summary`), `logs[]`, `metrics[]`, `expired`

  @US-13-057 @FR-13-057 @M @âm
  Kịch bản: US-13-057 âm 1 · Không có dữ liệu ở cả ba nguồn
    Biết mục DLQ có `trace_id` và thời điểm lỗi
    Khi không có dữ liệu ở cả ba nguồn
    Thì hệ thống từ chối với ERR-13-030 (404)
    Và người dùng thấy thông báo "Không tìm thấy trace {traceId}. Trace chỉ giữ 14 ngày và chỉ giữ một phần trace thành công."

  @US-13-057 @FR-13-057 @M @âm
  Kịch bản: US-13-057 âm 2 · Thiếu scope
    Biết mục DLQ có `trace_id` và thời điểm lỗi
    Khi thiếu scope
    Thì hệ thống từ chối với ERR-13-044 (403)

  @US-13-058 @FR-13-058 @S
  Kịch bản: US-13-058 dương · Cung cấp sức khỏe thành phần cho phân hệ khác
    Biết FR-13-001, 007, 049 đang chạy
    Khi phân hệ gọi `GET /components`; giao diện mở UI-13-01
    Thì hệ thống trả `200`: `components[]` (`code`, `status`, `reason`, `since`)

  @US-13-058 @FR-13-058 @S @âm
  Kịch bản: US-13-058 âm 1 · Thiếu scope
    Biết FR-13-001, 007, 049 đang chạy
    Khi thiếu scope
    Thì hệ thống từ chối với ERR-13-044 (403)

  @US-13-059 @FR-13-059 @M
  Kịch bản: US-13-059 dương · Khởi tạo quan sát và chuỗi kiểm toán cho tenant mới
    Biết bản ghi tenant đã tạo và realm Keycloak, tiền tố Kafka đã có ở các bước trước của saga
    Khi PH-20 gọi `POST /api/platform/v1/tenants/{tenantCode}/observability:provision` kèm `Idempotency-Key`
    Thì hệ thống trả `200` hoặc `201`: `steps[]` (`name`, `status`), `genesisHash`, `grafanaOrg`
    Và chuỗi `OPEN`; mọi kho quan sát có cách ly cho tenant
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-13-059 @FR-13-059 @M @âm
  Kịch bản: US-13-059 âm 1 · Gọi lặp với tham số khác
    Biết bản ghi tenant đã tạo và realm Keycloak, tiền tố Kafka đã có ở các bước trước của saga
    Khi gọi lặp với tham số khác
    Thì hệ thống từ chối với ERR-13-042 (409)
    Và người dùng thấy thông báo "Tenant {tenant} đã có cấu hình quan sát."

  @US-13-059 @FR-13-059 @M @âm
  Kịch bản: US-13-059 âm 2 · Một bước phụ thuộc lỗi (OpenBao, Kafka, Grafana)
    Biết bản ghi tenant đã tạo và realm Keycloak, tiền tố Kafka đã có ở các bước trước của saga
    Khi một bước phụ thuộc lỗi (OpenBao, Kafka, Grafana)
    Thì hệ thống từ chối với ERR-13-014 (503)

  @US-13-060 @FR-13-060 @S
  Kịch bản: US-13-060 dương · Đóng chuỗi kiểm toán khi tenant ngừng hoặc sáp nhập
    Biết tenant đã sang trạng thái ngừng hoặc `DECOMMISSIONED` ở PH-20; sáp nhập có tenant đích
    Khi PH-20 gọi `POST /api/platform/v1/tenants/{tenantCode}/audit-chain:close` kèm lý do
    Thì hệ thống trả `200`: `status = CLOSED`, `finalAnchorId`, `closedAt`
    Và chuỗi `CLOSED`; neo cuối có chữ ký
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-13-060 @FR-13-060 @S @âm
  Kịch bản: US-13-060 âm 1 · Chuỗi đã đóng
    Biết tenant đã sang trạng thái ngừng hoặc `DECOMMISSIONED` ở PH-20; sáp nhập có tenant đích
    Khi chuỗi đã đóng
    Thì hệ thống từ chối với ERR-13-043 (409)
    Và người dùng thấy thông báo "Chuỗi kiểm toán của tenant đã đóng, không nhận thêm bản ghi."

  @US-13-061 @FR-13-061 @S
  Kịch bản: US-13-061 dương · Tham số và hạn mức quan sát theo tenant
    Biết tenant đã khởi tạo quan sát (FR-13-059)
    Khi người dùng mở "Cài đặt giám sát" (UI-13-17) và lưu
    Thì hệ thống trả `200`: `params`, `quota`, `version`, `ETag`
    Và tham số có hiệu lực; lịch sử thay đổi ghi vết
    Và sự kiện được phát: EVT-13-10
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-13-061 @FR-13-061 @S @âm
  Kịch bản: US-13-061 âm 1 · Tham số ngoài miền hoặc thời hạn dưới 3 năm
    Biết tenant đã khởi tạo quan sát (FR-13-059)
    Khi tham số ngoài miền hoặc thời hạn dưới 3 năm
    Thì hệ thống từ chối với ERR-13-040 (422)
    Và người dùng thấy thông báo "Tham số {khóa} ngoài miền cho phép; thời hạn lưu kiểm toán không được thấp hơn 3 năm."
