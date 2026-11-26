# language: vi
# Sinh tự động từ D05-02-PH04 bằng ph04/tools/gen_gherkin.py; không sửa tay.
@PH-04 @TS-04-19
Tính năng: TS-04-19 · Tình trạng runtime, điểm kết nối, giám sát, lịch sử

  @TC-04-118 @P1 @Dương
  Kịch bản: TC-04-118 Tình trạng runtime theo môi trường và bản sao
    # Truy vết: FR-04-051 · API-04-060 · UI-04-02 · LGC-BUS-014, 015, 017.
    Biết F-HT chạy ba môi trường; một route PROD đang tạm dừng.
    Khi gọi `GET /flows/tra-cuu-ho-tich/runtime`.
    Và dừng một bản sao PROD (xóa pod), gọi lại sau 70 giây.
    Thì bước 1: mỗi môi trường có `versionNo`, `syncStatus`, `healthStatus`, `readyReplicas`/`replicas`, `lastHeartbeatAt`; route tạm dừng có `pausedBy`, `pauseReason`. Bước 2: bản sao mất nhịp tim quá 60 giây không còn trong danh sách; `healthStatus = DEGRADED` tới khi pod mới sẵn sàng.

  @TC-04-119 @P2 @Âm
  Kịch bản: TC-04-119 Lỗi nạp luồng hiển thị cho người vận hành
    # Truy vết: FR-04-051 · API-04-060.
    Biết phát hành `tc-nap-loi` có tham chiếu kết nối mà PH-05 chưa cấp giá trị cho PROD (vượt qua kiểm tra do PH-05 đổi sau khi duyệt).
    Khi phát hành lên TEST; đọc runtime.
    Thì triển khai `FAILED`, `loadError` nêu "Không phân giải được {{conn:…}} ở TEST" (không lộ giá trị); các luồng khác trong cùng pod vẫn chạy (lỗi nạp một luồng không làm hỏng context).

  @TC-04-120 @P2 @Dương @Âm
  Kịch bản: TC-04-120 Điểm kết nối và số liệu theo điểm
    # Truy vết: FR-04-052 · API-04-062 · LGC-BUS-018.
    Biết F-HT PROD có lưu lượng giả lập 1 giờ.
    Khi gọi `GET .../endpoints?environment=PROD`.
    Và IE3 (không thuộc WS-HOTICH) gọi cùng API.
    Thì `items` có một điểm `IN` (`platform-http`, `httpPath`) và các điểm `OUT` (`http` qua CONN-HT, `kafka` topic kiểm toán); `uri` đã che tham số; `metrics` khớp Prometheus trong sai số 1%. Bước 2 trả 404-ẩn.

  @TC-04-121 @P2 @Dương @Âm
  Kịch bản: TC-04-121 Số liệu và lịch sử khi PH-13 không sẵn sàng
    # Truy vết: FR-04-053, 083 · API-04-063, 091 · ERR-04-047 · LGC-BUS-007, 033.
    Biết U-T68-AU, U-T68-VW.
    Khi AU gọi `GET .../metrics?environment=PROD&step=1m`.
    Và AU gọi `GET .../history?action=INT_DEPLOY`.
    Và VW gọi `GET .../history`.
    Và dừng PH-13, AU gọi lại bước 2.
    Thì bước 1: chuỗi `exchanges`, `failures`, `p95ms`, `dlq`, `dashboardUrl`. Bước 2: các lần triển khai có `before`, `after`. Bước 3: không có `before`, `after`. Bước 4 trả `503` ERR-04-047; các API khác của PH-04 vẫn trả bình thường.
