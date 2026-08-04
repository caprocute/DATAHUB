# 05 — Quyết định kiến trúc (ADR)

> **Vai trò tài liệu**: nguồn sự thật duy nhất cho mọi lựa chọn công nghệ. Các tài liệu khác chỉ tham chiếu mã ADR, không lặp lại lý do.

**Cấu trúc mỗi ADR**: Bối cảnh → Phương án cân nhắc → Quyết định → Hệ quả (tích cực và tiêu cực).

| Mã | Quyết định | Trạng thái |
|---|---|---|
| [ADR-001](#adr-001) | Apache Camel làm lõi tích hợp | Đã chốt |
| [ADR-002](#adr-002) | Camel Quarkus native cho Data Plane (PH-04) — phạm vi đã làm rõ | Đã chốt |
| [ADR-003](#adr-003) | Apache APISIX làm API Gateway | Đã chốt |
| [ADR-004](#adr-004) | Keycloak + OPA cho định danh và ủy quyền | Đã chốt |
| [ADR-005](#adr-005) | Kafka + Apicurio + Debezium cho luồng bất đồng bộ | Đã chốt |
| [ADR-006](#adr-006) | Backstage làm Developer Portal | Đã chốt |
| [ADR-007](#adr-007) | OpenTelemetry + LGTM stack cho quan sát | Đã chốt |
| [ADR-008](#adr-008) | PostgreSQL + MinIO + Valkey cho lưu trữ | ⚠ Phần MinIO **đã thay** bởi [ADR-020](#adr-020) |
| [ADR-009](#adr-009) | Flowable cho BPM | Đã chốt |
| [ADR-010](#adr-010) | Argo CD + Kustomize cho GitOps | Đã chốt |
| [ADR-011](#adr-011) | Istio ambient mesh cho mTLS | Đã chốt |
| [ADR-012](#adr-012) | Vault/OpenBao cho quản lý bí mật | Đã chốt |
| [ADR-013](#adr-013) | Canonical Data Model làm trung gian chuyển đổi | Đã chốt |
| [ADR-014](#adr-014) | Tách Control Plane khỏi Data Plane | Đã chốt |
| [ADR-015](#adr-015) | Kaoto làm mẫu tham chiếu cho thiết kế luồng và Camel YAML DSL | Đã chốt |
| [ADR-016](#adr-016) | Ant Design v6 làm bộ thành phần giao diện, tinh chỉnh theo phong cách shadcn | Đã chốt |
| [ADR-017](#adr-017) | XYFlow (React Flow) làm động cơ sơ đồ kéo thả trong console PH-04 | Đã chốt |
| [ADR-018](#adr-018) | Mô hình phát triển: DU hybrid, production-first (biên bắt buộc tách ngay) | Đã chốt |
| [ADR-019](#adr-019) | Spring Boot 4 + Spring Modulith cho DU ứng dụng; Camel giữ Quarkus (ADR-002) | Đã chốt |
| [ADR-020](#adr-020) | Chính sách vòng đời phiên bản; thay MinIO cho lưu trữ đối tượng; giữ Java 21 | Đã chốt |

---

## ADR-001
### Apache Camel làm lõi tích hợp

**Bối cảnh.** Cần một engine tích hợp đáp ứng yêu cầu của CV 631: hỗ trợ nhiều giao thức (HTTP/S, WebSocket, JMS, AMQP, MQTT, SMTP/POP/IMAP), nhiều định dạng (JSON, XML, SOAP), có khả năng định tuyến, chuyển đổi và mediation. Người dùng đã chỉ định Apache Camel làm lõi.

**Phương án cân nhắc:**

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| **Apache Camel** | 300+ component, 65+ EIP, ASF hậu thuẫn, tài liệu tốt | Đường cong học tập với DSL |
| Spring Integration | Quen thuộc với đội Java | Ít component hơn đáng kể |
| Apache NiFi | Giao diện trực quan mạnh | Nặng, thiên về luồng dữ liệu lớn hơn là API mediation |
| Tự phát triển | Kiểm soát hoàn toàn | Chi phí khổng lồ, tái phát minh bánh xe |

**Quyết định.** Dùng **Apache Camel 4.x** làm engine tích hợp duy nhất. Việc chọn trình thiết kế luồng trực quan đi kèm được tách thành quyết định riêng — xem [ADR-015](#adr-015).

**Hệ quả tích cực:**
- Toàn bộ giao thức bắt buộc theo CV 631 có sẵn component — không phải viết mã kết nối (CMP-11, CMP-12).
- EIP chuẩn hóa cách giải quyết các bài toán tích hợp; đội mới vào dễ đọc hiểu.
- Route mô tả khai báo bằng YAML — cấu hình hơn lập trình (NT-02). Đây cũng là điều kiện để một trình thiết kế đồ họa sinh và đọc lại được định nghĩa luồng.

**Hệ quả tiêu cực:**
- Đội cần đào tạo về Camel DSL và tư duy EIP — đưa vào bước 16 của kế hoạch triển khai.
- Cần kỷ luật đặt tên và cấu trúc route, nếu không sẽ khó bảo trì khi số route tăng lên hàng trăm — giải quyết bằng template chuẩn ở bước 6.

---

## ADR-002
### Camel Quarkus native cho Data Plane (PH-04)

**Bối cảnh.** Camel chạy được trên nhiều runtime: Spring Boot, Quarkus, Camel Main. Lựa chọn runtime ảnh hưởng trực tiếp tới thời gian khởi động, tiêu thụ bộ nhớ và khả năng mở rộng phản ứng trên K8s — **đặc biệt với hàng trăm route và scale theo miền**.

**Phạm vi (làm rõ 2026-08-03).** ADR này áp cho **runtime Camel / PH-04** (`lgsp-camel-<mien>`). Các DU ứng dụng (Control Plane, dữ liệu, BPM quản trị…) chọn runtime tại [ADR-019](#adr-019) — **không** bắt buộc Quarkus toàn bộ backend.

**Phương án cân nhắc (cho Camel):**

| Tiêu chí | Quarkus native | Quarkus JVM | Spring Boot + Camel |
|---|---|---|---|
| Thời gian khởi động | ~50ms | ~1s | ~5s |
| Bộ nhớ thường trú | ~50MB | ~150MB | ~300MB |
| Thời gian biên dịch | Chậm (native build) | Nhanh | Nhanh |
| Hệ sinh thái | Tốt | Tốt | Rất tốt |
| Gỡ lỗi | Khó hơn | Dễ | Dễ |

**Quyết định.** Dùng **Camel Quarkus biên dịch native (GraalVM)** cho môi trường PROD của các deployment PH-04; dùng chế độ JVM cho DEV để rút ngắn vòng lặp phát triển.

**Hệ quả tích cực:**
- Khởi động dưới 50ms cho phép mở rộng phản ứng thực sự — pod mới phục vụ được gần như tức thì khi tải tăng đột ngột. Với hệ thống hành chính công có đỉnh tải theo giờ làm việc, đặc tính này chuyển hóa trực tiếp thành tiết kiệm tài nguyên.
- Bộ nhớ thấp cho phép chạy nhiều replica hơn trên cùng hạ tầng.
- Bề mặt tấn công nhỏ hơn (ảnh container tối giản, không có JVM đầy đủ).

**Hệ quả tiêu cực:**
- Biên dịch native chậm (vài phút) — chấp nhận được vì chỉ chạy trên CI, không ảnh hưởng vòng lặp phát triển cục bộ.
- Một số thư viện dùng reflection cần cấu hình bổ sung cho native. Giảm thiểu bằng cách chỉ dùng các Camel component đã được Quarkus hỗ trợ chính thức.
- Khác biệt giữa DEV (JVM) và PROD (native) có thể che giấu lỗi — bù lại bằng kiểm thử trên bản native ở môi trường TEST.
- Đội phải nắm **hai** runtime Java (Camel Quarkus + Spring Boot DU — ADR-019); giảm thiểu bằng khuôn mẫu monorepo và CI chung.

---

## ADR-003
### Apache APISIX làm API Gateway

**Bối cảnh.** Cần API Gateway đáp ứng CV 631: quản lý vòng đời API, xác thực OAuth2, giới hạn tần suất, chống DDoS. Phải chịu được lưu lượng lớn và cho phép thay đổi cấu hình không gián đoạn.

**Phương án cân nhắc:**

| Phương án | Hiệu năng | Nạp nóng cấu hình | Hệ sinh thái plugin | Ghi chú |
|---|---|---|---|---|
| **Apache APISIX** | Rất cao (OpenResty/Nginx) | Có | Phong phú | ASF, thuần open-source |
| Kong OSS | Cao | Có | Phong phú | Nhiều tính năng quan trọng chỉ có ở bản Enterprise |
| Envoy Gateway | Cao | Có | Trung bình | Cấu hình phức tạp |
| Spring Cloud Gateway | Trung bình | Hạn chế | Ít | Tiêu thụ tài nguyên cao hơn |

**Quyết định.** Dùng **Apache APISIX** kèm **Coraza WAF** (tương thích ModSecurity, OWASP CRS).

**Hệ quả tích cực:**
- Hiệu năng cao nhờ nền OpenResty — độ trễ thêm vào chỉ vài mili giây.
- Nạp nóng cấu hình qua etcd: thêm route hay đổi hạn mức không cần khởi động lại, không gián đoạn dịch vụ (điều kiện cho 24/7 — CMP-15).
- Plugin sẵn có cho OIDC, OAuth2, JWT, rate-limit, WAF — phủ trọn CMP-05, CMP-19.
- Thuộc ASF, giấy phép Apache-2.0 thuần túy, không có mô hình open-core giữ tính năng cho bản trả phí.

**Hệ quả tiêu cực:**
- Plugin tùy chỉnh viết bằng Lua — kỹ năng ít phổ biến trong đội. Giảm thiểu bằng cách ưu tiên dùng plugin có sẵn, chỉ viết Lua khi thực sự cần.
- Phụ thuộc etcd cho lưu cấu hình — đã có sẵn trong cụm K8s, không phát sinh thành phần mới.

---

## ADR-004
### Keycloak + OPA cho định danh và ủy quyền

**Bối cảnh.** CV 631 yêu cầu SSO qua SAML2 và OpenID Connect, MFA, phân quyền theo chuẩn XACML 2.0/3.0. Cần đồng thời giải bài toán xác thực (anh là ai) và ủy quyền (anh được làm gì).

**Quyết định.** Tách hai trách nhiệm: **Keycloak** cho xác thực và quản lý danh tính; **Open Policy Agent** cho quyết định ủy quyền, kèm lớp chuyển đổi XACML để đáp ứng yêu cầu chuẩn.

**Vì sao tách.**

| Khía cạnh | Xác thực (Keycloak) | Ủy quyền (OPA) |
|---|---|---|
| Nhịp thay đổi | Hiếm | Thường xuyên theo nghiệp vụ |
| Hình thức | Cấu hình realm, client | Chính sách dạng mã (Rego) |
| Triển khai thay đổi | Cần cẩn trọng | Nạp nóng, không gián đoạn |

Nếu nhét toàn bộ logic phân quyền vào Keycloak, mỗi lần thay đổi quy tắc nghiệp vụ đều phải động vào hệ thống định danh — rủi ro cao và chậm. Tách ra cho phép thay chính sách truy cập hằng ngày mà không chạm vào danh tính.

**Hệ quả tích cực:**
- Keycloak phủ đủ OIDC, SAML2, OAuth2, MFA — đúng yêu cầu CMP-06, CMP-07.
- Keycloak làm cầu nối tới VNeID: thêm nguồn định danh mới không ứng dụng nào phải sửa mã (CMP-27).
- Chính sách OPA viết dạng mã, kiểm thử được, quản lý phiên bản trong Git.
- Chính sách tập trung bảo đảm quy tắc chặn dữ liệu mật (CMP-23) áp dụng đồng nhất, không phụ thuộc từng route có nhớ kiểm tra hay không.

**Hệ quả tiêu cực:**
- Thêm một lời gọi mạng cho mỗi lần kiểm quyền — giảm thiểu bằng cách chạy OPA dạng sidecar và cache quyết định; độ trễ thực tế dưới 10ms.
- Rego là ngôn ngữ mới với đội — cần đào tạo, nhưng phạm vi hẹp và có thể học nhanh.
- Yêu cầu XACML của CV 631 được đáp ứng qua lớp chuyển đổi thay vì PDP XACML thuần — cần thuyết minh rõ trong hồ sơ nghiệm thu tuân thủ.

---

## ADR-005
### Kafka + Apicurio + Debezium cho luồng bất đồng bộ

**Bối cảnh.** Không phải luồng nào cũng cần phản hồi ngay. Đồng bộ dữ liệu khối lượng lớn, thông báo thay đổi cần cơ chế bất đồng bộ để tách khớp nối giữa bên gửi và bên nhận. Đồng thời cần đưa các HTTT di sản không có API lên trục.

**Quyết định.** Dùng **Apache Kafka** (triển khai qua Strimzi Operator) làm xương sống sự kiện, **Apicurio Registry** quản lý schema, **Debezium** bắt thay đổi dữ liệu từ CSDL hệ thống cũ.

**Vì sao Kafka thay vì hàng đợi truyền thống (RabbitMQ/ActiveMQ):**

| Tiêu chí | Kafka | Hàng đợi truyền thống |
|---|---|---|
| Lưu giữ bản tin | Có, theo thời hạn cấu hình | Xóa sau khi tiêu thụ |
| Phát lại lịch sử | Có | Không |
| Nhiều bên tiêu thụ độc lập | Tự nhiên | Cần cấu hình phức tạp |
| Thông lượng | Rất cao | Cao |

Khả năng **phát lại** là yếu tố quyết định: khi một HTTT mới kết nạp cần dữ liệu lịch sử, hoặc khi cần khắc phục sự cố xử lý sai, Kafka cho phép đọc lại từ điểm bất kỳ.

**Vì sao Debezium là mảnh ghép không thể thiếu.** Thực tế mọi triển khai LGSP đều gặp các HTTT không có API, không còn nhà thầu bảo trì, không thể sửa. Debezium đọc nhật ký giao dịch của CSDL (WAL/binlog), phát hiện thay đổi mà **không chạm vào ứng dụng nguồn**, không thêm tải đáng kể. Đây thường là con đường khả thi duy nhất.

**Hệ quả tích cực:**
- Tách khớp nối theo thời gian: bên gửi không chờ bên nhận, hệ thống chịu được tải đột biến.
- Thêm bên tiêu thụ mới không ảnh hưởng bên phát — điều kiện để mở rộng diện kết nối (bước 18).
- Schema Registry chặn thay đổi phá vỡ tương thích ngay tại nguồn thay vì để lỗi lan xuống hạ nguồn.
- Debezium mở đường cho HTTT Nhóm 3 lên trục.

**Hệ quả tiêu cực:**
- Kafka là thành phần có trạng thái, cần chăm sóc vận hành (dung lượng, cân bằng phân vùng) — giảm thiểu bằng Strimzi Operator tự động hóa phần lớn.
- Giao nhận theo mô hình at-least-once nên bên tiêu thụ **bắt buộc** xử lý idempotent. Yêu cầu này phải ghi rõ trong tài liệu kết nạp HTTT thành viên.
- Thứ tự chỉ bảo đảm trong cùng phân vùng — buộc phải chọn khóa phân vùng theo định danh thực thể.

---

## ADR-006
### Backstage làm Developer Portal

**Bối cảnh.** NĐ 47 Điều 24 và 25 buộc chủ quản CSDL công bố dịch vụ chia sẻ kèm tài liệu kỹ thuật, và công khai thông tin dịch vụ. Cần một nơi tập trung để cán bộ kỹ thuật các đơn vị tra cứu dịch vụ nào đang có, dùng thế nào.

**Quyết định.** Dùng **Backstage** làm Developer Portal kết hợp Service Catalog, tích hợp hiển thị đặc tả OpenAPI.

**Hệ quả tích cực:**
- Đáp ứng trực tiếp CMP-02: mỗi dịch vụ có trang tài liệu tự sinh từ OpenAPI, luôn đồng bộ với thực tế.
- Cán bộ đơn vị thành viên tự tra cứu và tự thử API, giảm tải hỗ trợ thủ công.
- Kèm sổ tay kỹ thuật (TechDocs) đặt cạnh mã nguồn — tài liệu không bị lạc hậu.

**Hệ quả tiêu cực:**
- Backstage là ứng dụng Node.js cần tùy biến để dùng — chi phí thiết lập ban đầu. Bù lại bằng lợi ích lâu dài khi số dịch vụ tăng.
- Không phải công cụ chuyên về API Management — nên phần quản lý vòng đời API vẫn do API Manager tích hợp APISIX đảm nhiệm.

---

## ADR-007
### OpenTelemetry + LGTM stack cho quan sát

**Bối cảnh.** CV 631 yêu cầu giám sát, thống kê, báo cáo, phân tích hoạt động nghiệp vụ **thời gian thực** (CMP-10). Trên hệ thống phân tán, không có khả năng truy vết xuyên suốt thì việc chẩn đoán sự cố gần như bất khả thi.

**Quyết định.** Dùng **OpenTelemetry** làm chuẩn thu thập; **Prometheus** (metrics), **Loki** (logs), **Tempo** (traces), **Grafana** (trình bày).

**Vì sao OpenTelemetry.** Đây là chuẩn trung lập của CNCF. Ứng dụng phát telemetry theo chuẩn OTLP, không gắn với một nhà cung cấp cụ thể. Nếu sau này muốn đổi backend lưu trữ, chỉ đổi cấu hình Collector — **không sửa một dòng mã ứng dụng** (NT-09).

**Hệ quả tích cực:**
- traceId xuyên suốt từ gateway tới hệ thống đích, liên kết cả ba nguồn dữ liệu — khả năng chẩn đoán mạnh nhất có thể có trên hệ phân tán.
- Grafana hợp nhất ba nguồn trong một giao diện, chuyển từ metrics sang logs sang traces chỉ bằng một cú nhấp.
- Toàn bộ chuẩn mở, không khóa nhà cung cấp.

**Hệ quả tiêu cực:**
- Bốn thành phần cần vận hành — nhưng đều có Helm chart trưởng thành và tiêu thụ tài nguyên hợp lý.
- Lưu trữ trace tốn dung lượng nếu giữ toàn bộ — giải quyết bằng chiến lược lấy mẫu: giữ 100% trace lỗi và chậm bất thường, lấy mẫu 1–5% trace thành công.

---

## ADR-008
### PostgreSQL + MinIO + Valkey cho lưu trữ

> ⚠ **Phần MinIO đã bị thay thế bởi [ADR-020](#adr-020)** (2026-08-04): kho mã cộng đồng MinIO bị archive
> ngày 25/04/2026 — không còn bản vá. Phần PostgreSQL và Valkey **vẫn còn hiệu lực**.
> Lập luận WORM/CMP-28 bên dưới giữ nguyên giá trị và được ADR-020 kế thừa làm điều kiện bắt buộc.

**Bối cảnh.** Cần lưu trữ cho ba nhóm nhu cầu khác nhau: dữ liệu quan hệ có cấu trúc (dữ liệu chủ, danh mục, trạng thái quy trình), tệp lớn (đính kèm văn bản, nhật ký kiểm toán), và cache tốc độ cao.

**Quyết định:**

| Nhu cầu | Công nghệ | Lý do |
|---|---|---|
| Dữ liệu quan hệ | **PostgreSQL** qua **CloudNativePG** | Trưởng thành, HA tự động, sao lưu và khôi phục theo thời điểm |
| Tệp lớn, nhật ký kiểm toán | **MinIO** | Tương thích S3, hỗ trợ WORM cho nhật ký bất biến |
| Cache | **Valkey** | Nhánh cộng đồng của Redis dưới BSD-3 |

**Vì sao CloudNativePG.** Operator này đáp ứng trực tiếp CMP-17: sao lưu hằng ngày tự động cộng truyền WAL liên tục (cho phép khôi phục về bất kỳ thời điểm nào, RPO ≤ 15 phút), tự động đề bạt replica khi primary hỏng.

**Vì sao Valkey thay vì Redis.** Redis đổi sang giấy phép RSALv2/SSPL từ phiên bản 7.4 — không còn là open-source theo định nghĩa OSI. Valkey là nhánh do Linux Foundation bảo trợ, giữ giấy phép BSD-3, tương thích giao thức hoàn toàn. Lựa chọn này bảo đảm yêu cầu "toàn bộ công nghệ bổ sung phải open-source".

**Vì sao MinIO cho nhật ký kiểm toán.** Chế độ WORM (Write Once Read Many) khiến nhật ký không thể sửa hay xóa kể cả bởi quản trị viên hệ thống — điều kiện bắt buộc để nhật ký có giá trị chứng cứ theo CMP-28.

**Hệ quả tiêu cực:**
- MinIO dùng giấy phép AGPL-3.0. Chấp nhận được vì triển khai nội bộ, không phân phối phần mềm ra bên ngoài. Nếu tổ chức có chính sách nghiêm ngặt về AGPL, thay bằng SeaweedFS (Apache-2.0) hoặc Ceph RGW.

---

## ADR-009
### Flowable cho quản lý quy trình nghiệp vụ

**Bối cảnh.** CV 631 yêu cầu hỗ trợ BPMN 2.0 và WS-BPEL (CMP-09). Đồng thời có nhu cầu thực tế: các thủ tục hành chính liên thông kéo dài nhiều ngày, có tác vụ chờ cán bộ xử lý, cần lưu trạng thái bền vững.

**Phương án cân nhắc:**

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| **Flowable** | Nhẹ, nhúng được, Apache-2.0 thuần | Cộng đồng nhỏ hơn Camunda |
| Camunda 7 | Trưởng thành, tài liệu tốt | Đã ngừng phát triển bản community |
| Camunda 8 | Kiến trúc hiện đại | Zeebe engine không hoàn toàn open-source |
| jBPM | Tích hợp tốt hệ sinh thái Red Hat | Nặng, phụ thuộc nhiều |

**Quyết định.** Dùng **Flowable** cho quy trình nghiệp vụ dài hạn.

**Ranh giới với Camel — quy tắc quyết định:**

| Đặc điểm luồng | Dùng gì |
|---|---|
| Mili giây đến giây, không trạng thái | **Camel route** |
| Giờ đến tháng, có tác vụ người dùng, cần lưu trạng thái | **Flowable BPMN** |

Dùng sai công cụ gây hậu quả cụ thể: Camel cho quy trình dài sẽ mất trạng thái khi pod khởi động lại; BPMN cho mỗi lời gọi tra cứu tạo gánh nặng ghi CSDL không cần thiết. Nguyên tắc phân vai: **Flowable quyết định làm gì tiếp theo, Camel thực hiện bằng cách nào**.

**Hệ quả tích cực:**
- BPMN 2.0 đầy đủ, đáp ứng CMP-09.
- Quy trình mô tả bằng sơ đồ chuẩn — người làm nghiệp vụ đọc và góp ý được, không cần biết lập trình.
- Trạng thái lưu bền vững trong PostgreSQL, quy trình sống sót qua mọi sự cố hạ tầng.

**Hệ quả tiêu cực:**
- Thêm một thành phần có trạng thái cần vận hành.
- WS-BPEL không được Flowable hỗ trợ trực tiếp. Cần thuyết minh trong hồ sơ tuân thủ: BPMN 2.0 là chuẩn kế thừa và thay thế WS-BPEL trong thực tiễn công nghiệp; nếu cơ quan thẩm định yêu cầu nghiêm ngặt, bổ sung Apache ODE cho các quy trình BPEL cụ thể.

---

## ADR-010
### Argo CD + Kustomize cho GitOps

**Bối cảnh.** Cần cơ chế triển khai nhất quán qua bốn môi trường, có khả năng quay lui nhanh, có dấu vết kiểm toán mọi thay đổi hạ tầng.

**Quyết định.** Dùng **Argo CD** đồng bộ trạng thái từ Git, **Kustomize** quản lý khác biệt giữa các môi trường.

**Vì sao Kustomize thay vì Helm cho phần cấu hình môi trường.** Helm mạnh cho việc đóng gói phần mềm bên thứ ba (dùng Helm cài Keycloak, Kafka…), nhưng khi quản lý khác biệt giữa DEV/TEST/STAGING/PROD, cách tiếp cận lớp phủ (overlay) của Kustomize minh bạch hơn — nhìn thấy chính xác cái gì khác nhau giữa các môi trường mà không phải đọc qua nhiều lớp template lồng nhau.

**Hệ quả tích cực:**
- Git là nguồn sự thật duy nhất (NT-06): mọi thay đổi có người phê duyệt qua pull request, có lịch sử đầy đủ.
- Quay lui chỉ là revert commit — thao tác nhanh và an toàn trong sự cố.
- Argo CD tự phát hiện và sửa sai lệch: nếu ai đó sửa thủ công trên cụm, hệ thống tự đưa về trạng thái khai báo.

**Hệ quả tiêu cực:**
- Cấm `kubectl apply` thủ công lên PROD — cần kỷ luật đội và phân quyền chặt trên cụm.
- Trong sự cố khẩn cấp, quy trình qua Git chậm hơn sửa trực tiếp. Giải pháp: định nghĩa sẵn quy trình khẩn cấp có kiểm soát, cho phép can thiệp nhanh nhưng bắt buộc đồng bộ ngược về Git ngay sau đó.

---

## ADR-011
### Istio ambient mesh cho mTLS nội bộ

**Bối cảnh.** Nguyên tắc zero-trust (NT-04) đòi hỏi mã hóa và xác thực mọi kết nối, kể cả giữa hai pod trong cùng namespace. CV 631 yêu cầu TLS 1.2 trở lên (CMP-13).

**Phương án cân nhắc:**

| Phương án | Chi phí tài nguyên | Độ phức tạp | Ghi chú |
|---|---|---|---|
| **Istio ambient** | Thấp | Trung bình | Không cần sidecar mỗi pod |
| Istio sidecar | Cao | Trung bình | Mỗi pod thêm một container |
| Linkerd | Thấp | Thấp | Ít tính năng hơn |
| mTLS tự cài trong ứng dụng | Rất thấp | Cao | Rủi ro lập trình viên cài đặt sai |

**Quyết định.** Dùng **Istio ở chế độ ambient mesh**.

**Vì sao không để ứng dụng tự lo mTLS.** Đây là điểm quan trọng nhất: nếu mỗi ứng dụng tự cài đặt mTLS, chỉ cần một đội quên hoặc làm sai là có lỗ hổng. Đưa xuống tầng hạ tầng khiến bảo mật trở thành mặc định — **ứng dụng không cần viết một dòng mã bảo mật nào** mà vẫn được mã hóa và xác thực.

**Vì sao ambient thay vì sidecar.** Chế độ ambient dùng ztunnel cấp node thay vì sidecar cấp pod, giảm đáng kể tiêu thụ tài nguyên và loại bỏ vấn đề thứ tự khởi động giữa ứng dụng và sidecar — vấn đề gây nhiều sự cố khó chẩn đoán trong mô hình sidecar.

**Hệ quả tích cực:**
- mTLS tự động toàn cụm, chứng thư tự xoay vòng — đáp ứng CMP-13 mà không phụ thuộc kỷ luật lập trình viên.
- Có sẵn khả năng quan sát tầng mạng và điều khiển lưu lượng (canary, mirroring) khi cần.

**Hệ quả tiêu cực:**
- Istio làm tăng độ phức tạp vận hành và cần kỹ năng chuyên biệt để chẩn đoán khi có sự cố mạng — đưa vào chương trình đào tạo bước 16.
- Chế độ ambient mới hơn chế độ sidecar; cần theo dõi sát các phiên bản phát hành.

---

## ADR-012
### Vault / OpenBao cho quản lý bí mật

**Bối cảnh.** Hệ thống cần quản lý: mật khẩu CSDL, khóa API, và đặc biệt là **chứng thư số dùng ký bản tin gửi NDXP** — tài sản nhạy cảm bậc nhất. NĐ 165/2025 có quy định về mã hóa (CMP-24).

**Quyết định.** Dùng **HashiCorp Vault** kèm **External Secrets Operator**; nếu tổ chức yêu cầu giấy phép mở tuyệt đối thì dùng **OpenBao** (nhánh cộng đồng dưới MPL-2.0, tương thích API).

**Điểm thiết kế then chốt — ký số bên trong Vault.** Khóa riêng **không bao giờ rời khỏi Vault**. Ứng dụng gửi bản tin vào Vault để ký và nhận về bản tin đã ký. Hệ quả an ninh: kể cả khi pod ứng dụng bị chiếm quyền hoàn toàn, kẻ tấn công không lấy được khóa — chỉ có thể yêu cầu ký trong khoảng thời gian còn giữ được quyền, và mọi yêu cầu ký đều để lại dấu vết trong nhật ký Vault.

**Hệ quả tích cực:**
- Không có bí mật nào nằm trong mã nguồn hay ConfigMap — kiểm chứng được bằng quét tự động (tiêu chí ra của bước 5).
- Thông tin xác thực CSDL cấp động, thời hạn ngắn, tự xoay vòng — nếu rò rỉ thì cũng hết hạn nhanh.
- Mọi truy cập bí mật đều được ghi vết.

**Hệ quả tiêu cực:**
- Vault là thành phần trọng yếu: nếu Vault sập, ứng dụng không lấy được bí mật mới. Bù lại bằng triển khai HA 3 node và cache bí mật tại ứng dụng với thời hạn hợp lý.
- Quy trình unseal sau khi khởi động lại cần chuẩn bị kỹ — dùng auto-unseal với khóa quản lý riêng, và quy trình này phải có trong runbook.
- HashiCorp Vault từ v1.15 dùng giấy phép BUSL. Nếu ràng buộc giấy phép là yêu cầu cứng, chuyển sang OpenBao — tương thích API nên chi phí chuyển đổi thấp.

---

## ADR-013
### Canonical Data Model làm trung gian chuyển đổi

**Bối cảnh.** Các HTTT trong bộ/tỉnh dùng cấu trúc dữ liệu khác nhau cho cùng một thực thể nghiệp vụ. Cần chiến lược chuyển đổi bền vững khi số hệ thống tăng.

**Phương án cân nhắc:**

| Phương án | Số bộ chuyển đổi cần có (n hệ thống) | Với n=20 |
|---|---|---|
| Chuyển đổi trực tiếp từng cặp | n×(n-1) | 380 |
| **Qua mô hình chuẩn (CDM)** | 2n | 40 |

**Quyết định.** Mọi bản tin được chuẩn hóa về **Canonical Data Model** trước khi chuyển sang định dạng hệ thống đích. CDM đăng ký trong Apicurio Registry, kiểm tra tương thích khi thay đổi.

**Hệ quả tích cực:**
- Chi phí thêm một HTTT mới là hằng số (hai bộ chuyển đổi), không tăng theo số hệ thống đã có — điều kiện để mở rộng diện kết nối ở bước 18 mà không bùng nổ độ phức tạp.
- CDM là ngôn ngữ chung giữa các đơn vị, buộc thống nhất cách hiểu về thực thể nghiệp vụ.
- Kết hợp với dữ liệu chủ (MDM) và danh mục dùng chung (RDM) tạo thành lớp ngữ nghĩa nhất quán.

**Hệ quả tiêu cực:**
- Thiết kế CDM đòi hỏi đồng thuận giữa nhiều đơn vị — công việc tốn thời gian và mang tính chính trị nhiều hơn kỹ thuật. Đưa vào bước 2 và 9 của kế hoạch, cần vai trò điều phối của lãnh đạo.
- Thêm một lần chuyển đổi làm tăng độ trễ chút ít — không đáng kể so với ngân sách độ trễ tổng thể.
- CDM cần quản lý phiên bản chặt chẽ; thay đổi phá vỡ tương thích ảnh hưởng nhiều bên — Schema Registry chặn được rủi ro này.

---

## ADR-014
### Tách Control Plane khỏi Data Plane

**Bối cảnh.** CV 631 yêu cầu hệ thống hoạt động 24/7 liên tục (CMP-15). Cần bảo đảm hoạt động quản trị không gây gián đoạn luồng dữ liệu đang chạy.

**Quyết định.** Tách thành hai mặt phẳng có vòng đời triển khai độc lập:

| Mặt phẳng | Thành phần | Đặc điểm |
|---|---|---|
| **Control Plane** | API Manager, Service Catalog, Onboarding, Config Manager, Developer Portal | Có trạng thái, tần suất truy cập thấp |
| **Data Plane** | APISIX, Camel Runtime, Adapter | Stateless, tần suất truy cập rất cao |

**Hệ quả tích cực:**
- Sự cố hoặc bảo trì Control Plane **không làm gián đoạn** luồng dữ liệu. APISIX cache cấu hình tại chỗ nên vẫn phục vụ bình thường khi Control Plane offline.
- Hai mặt phẳng mở rộng theo nhịp khác nhau: Data Plane có thể chạy 20 replica trong khi Control Plane chỉ cần 2.
- Bề mặt tấn công của Data Plane nhỏ hơn vì không mang logic quản trị.

**Hệ quả tiêu cực:**
- Cần cơ chế đồng bộ cấu hình từ Control Plane xuống Data Plane, kèm xử lý tình huống mất đồng bộ. Giải quyết bằng etcd làm kho cấu hình chung và cơ chế theo dõi thay đổi (watch) của APISIX.
- Thay đổi cấu hình có độ trễ lan truyền vài giây — chấp nhận được, và đây là đánh đổi có chủ đích để lấy tính sẵn sàng.

---

## ADR-015
### Kaoto làm mẫu tham chiếu cho thiết kế luồng và Camel YAML DSL

**Bối cảnh.** Lõi tích hợp phải cho phép **tạo và quản lý luồng tích hợp bằng giao diện**, không bắt buộc viết Camel DSL bằng tay. Đây là điều kiện để cán bộ tích hợp không chuyên Java tự xây luồng, và để số luồng mở rộng theo diện kết nối ở bước 18 mà không phụ thuộc vào một nhóm nhỏ biết viết DSL.

Ràng buộc quan trọng: [ADR-010](#adr-010) đã chốt **Argo CD + Kustomize** là cơ chế triển khai duy nhất; [ADR-016](#adr-016) đã chốt Ant Design cho console quản trị; PH-04 tự quản lý vòng đời luồng (`FR-04-020…030`, `UI-04-01…09`). Do đó cần một **mô hình thiết kế** (catalog, YAML DSL, thao tác kéo thả kiểu [Kaoto](https://kaoto.io/)) gắn vào console LGSP — không phải một nền tảng thiết kế/triển khai riêng.

**Phương án cân nhắc:**

| Phương án | Phạm vi | Ưu điểm | Nhược điểm |
|---|---|---|---|
| **Kaoto làm mẫu tham chiếu** | Catalog Camel + UX kéo thả + YAML DSL | Sinh/đọc Camel YAML DSL chuẩn; catalog 300+ component, EIP, Kamelet; UX đã được cộng đồng Camel chấp nhận; giấy phép Apache-2.0 | Bản UI đầy đủ của Kaoto dùng PatternFly, lệch với [ADR-016](#adr-016) nếu nhúng nguyên khối |
| Nhúng nguyên Kaoto vào console | Trình thiết kế bên thứ ba | Ít mã tự viết | Xung đột thiết kế hệ thống (PatternFly ↔ Ant Design); khó gắn quy trình duyệt/GitOps của PH-04 |
| Camel Karavan | Nền tảng trọn gói | Có build/triển khai K8s | Xung đột [ADR-010](#adr-010); trùng PH-04 |
| Viết DSL thủ công | Không có công cụ | Không thêm phụ thuộc | Không đáp ứng yêu cầu tạo luồng bằng giao diện |

**Quyết định.** Lấy **Kaoto làm mẫu tham chiếu** cho năng lực thiết kế luồng: catalog thành phần Camel, thao tác kéo thả kiểu sơ đồ, và định dạng đầu ra **Camel YAML DSL**. Định nghĩa YAML được đẩy vào kho Git và triển khai bằng Argo CD ([ADR-010](#adr-010)). Động cơ vẽ sơ đồ trong console PH-04 được chọn riêng tại [ADR-017](#adr-017) — **không nhúng nguyên khối giao diện Kaoto**.

**Ranh giới trách nhiệm:**

| Việc | Do ai đảm nhiệm |
|---|---|
| Mẫu UX, catalog Camel, ngữ nghĩa YAML DSL | Kaoto (tham chiếu) |
| Sơ đồ kéo thả trong console, kiểm tra hợp lệ, sinh YAML | PH-04 trên XYFlow ([ADR-017](#adr-017), `FR-04-026…030`, `UI-04-07`) |
| Lưu bản nháp, phiên bản hóa, duyệt, nạp và điều khiển route | PH-04 |
| Triển khai định nghĩa đã duyệt ra môi trường | Argo CD ([ADR-010](#adr-010)) |
| Giám sát luồng đang chạy | PH-13 |

**Hệ quả tích cực:**
- Định nghĩa luồng vẫn là YAML nằm trong Git — một đường triển khai duy nhất.
- Không có công cụ thứ hai ghi thẳng vào cụm Kubernetes.
- Hạ rào cản kỹ năng; YAML viết tay và sơ đồ đồ họa sống chung được vì cùng một DSL.
- Console LGSP giữ đúng Ant Design ([ADR-016](#adr-016)) thay vì mang theo PatternFly của Kaoto.

**Hệ quả tiêu cực:**
- Phải tự dựng canvas và biểu mẫu thuộc tính trong PH-04 thay vì dùng sẵn UI Kaoto — chi phí phát triển cao hơn; giảm thiểu bằng cách tái sử dụng catalog/schema Camel mà Kaoto cũng dùng.
- Catalog gắn phiên bản Camel cụ thể; nâng cấp Camel phải đồng bộ catalog.
- Giao diện đồ họa dễ tạo luồng chạy được nhưng thiết kế kém — giảm thiểu bằng mẫu chuẩn và duyệt bắt buộc (`BR-04-016`).

---

## ADR-016
### Ant Design v6 làm bộ thành phần giao diện, tinh chỉnh theo phong cách shadcn

**Bối cảnh.** Nền tảng có nhiều console quản trị (PH-02, PH-04, PH-06, PH-07, PH-09, PH-13, PH-16, PH-17) và cổng dành cho lập trình viên (PH-15). Các màn hình này nặng về **bảng dữ liệu dày đặc, biểu mẫu nhiều trường, trạng thái vận hành theo thời gian thực** — đúng loại giao diện mà một bộ thành phần chín sẵn giải quyết tốt hơn là tự dựng.

Cán bộ vận hành trực ca theo dõi màn hình giám sát nhiều giờ liên tục, nên **chế độ tối là yêu cầu thực dụng**, không phải trang trí.

**Phương án cân nhắc:**

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| **Ant Design v6** | Bộ thành phần quản trị đầy đủ nhất trong hệ sinh thái React (Table với lọc/sắp xếp/phân trang, Form, DatePicker, Transfer, Tree); hệ token thiết kế mở, đổi được toàn bộ diện mạo mà không sửa CSS thành phần; v6 phát ra **CSS variables** nên chuyển chế độ sáng/tối không phải dựng lại cây style; sẵn tiếng Việt; MIT | Diện mạo mặc định đặc trưng, dễ bị nhận ra là "giao diện Ant"; một vài tổ hợp màu mặc định chưa đạt ngưỡng tương phản WCAG AA |
| shadcn/ui thuần | Diện mạo hiện đại, mã nguồn thuộc về dự án; sẵn chế độ tối | Không có Table cấp quản trị, DatePicker, Transfer, Tree — phải tự dựng hoặc ghép Radix, chi phí lớn với số màn hình của LGSP |
| MUI | Đầy đủ, cộng đồng lớn | Ngôn ngữ thị giác Material lệch với thẩm mỹ hệ thống hành chính; bảng dữ liệu mạnh nằm ở gói thương mại |
| Tự dựng thư viện | Khớp hoàn toàn | Không khả thi trong phạm vi dự án |

**Quyết định.** Dùng **Ant Design v6** làm bộ thành phần, và **áp phong cách shadcn bằng cách tinh chỉnh token** chứ không viết lại CSS thành phần. Cụ thể:

| Nhóm thuộc tính | Nguồn |
|---|---|
| Màu thương hiệu, màu trạng thái | Token Ant Design v6 (`colorPrimary`, `colorSuccess`, `colorWarning`, `colorError` và bảng sắc độ preset) |
| Thang màu trung tính, bo góc, viền, đổ bóng, vòng lấy nét, hình khối thành phần | Quy ước shadcn (thang xám zinc, viền mảnh, bóng rất nhẹ, ring 2px khi lấy nét) |
| Khoảng cách, cỡ chữ, chiều cao điều khiển | Thang Ant Design v6 |

Chế độ sáng/tối cài bằng thuộc tính `data-theme` trên thẻ gốc, ghi nhớ lựa chọn của người dùng và mặc định bám theo thiết lập hệ điều hành.

**Ngoại lệ có chủ đích về tương phản.** Một số màu mặc định của antd không đạt ngưỡng WCAG AA khi dùng làm chữ hoặc nền đặc. Dự án lùi sang **sắc độ khác trong chính bảng màu antd**, không tự pha màu mới:

| Vị trí | Mặc định antd | Đã đổi thành | Lý do |
|---|---|---|---|
| Nền đặc nút chính (chữ trắng) | `colorPrimary` — 4,1:1 | `colorPrimaryActive` (blue-7) — 6,2:1 | Dưới ngưỡng 4,5:1 cho chữ thường |
| Nền đặc nút xóa (chữ trắng) | `colorError` — 3,3:1 | red-7 (sáng) / red-4 (tối) — trên 5:1 | Dưới ngưỡng; sắc đỏ sẫm ở chế độ tối trùng với `destructive` của shadcn |
| Chữ trên nhãn trạng thái xanh, vàng | green-6, gold-6/7 — 2,8…3,4:1 | green-8, gold-9 | Dưới ngưỡng |
| Chấm chỉ dấu mang thông tin | green-6, gold-6 — 1,9…2,3:1 | green-7, gold-8 | Ngưỡng phần tử đồ họa là 3:1 |

**Hệ quả tích cực:**
- Giữ được bộ thành phần quản trị mạnh mà không mang theo diện mạo mặc định của antd.
- Lớp token là **hợp đồng duy nhất** giữa mockup và ứng dụng thật: mockup HTML tĩnh khai báo token bằng CSS variables, ứng dụng React nạp đúng các giá trị đó qua `ConfigProvider`, nên hai bên không lệch nhau.
- Chế độ tối không phải bảng màu thứ hai duy trì song song: bảng màu tối của antd đảo chiều sắc độ, nên phần lớn token dẫn xuất tự đúng chiều khi đổi bảng.
- Toàn bộ mockup đã đo tương phản tự động ở cả hai chế độ và không còn vi phạm ngưỡng WCAG AA.

**Hệ quả tiêu cực:**
- Nâng phiên bản antd có thể làm trôi giá trị token; phải đối chiếu lại bảng token khi nâng cấp. Giảm thiểu bằng cách trích token từ chính gói antd thay vì chép tay.
- Bốn ngoại lệ tương phản ở trên khiến diện mạo lệch nhẹ so với ảnh chụp trong tài liệu antd; cần nêu trong hướng dẫn cho lập trình viên để không ai "sửa lại cho giống antd".
- Phong cách shadcn áp bằng token chỉ đi được đến mức diện mạo; một vài hình khối thành phần (ví dụ Tabs dạng phân đoạn) vẫn là của antd. Đây là đánh đổi có chủ đích để không phải bảo trì CSS ghi đè.

**Hiện thực tham chiếu.** `mockup/css/app.css` (ba lớp token: gốc antd → trung tính shadcn → vai trò ngữ nghĩa) và `mockup/js/theme.js` (chuyển chế độ, chống nhấp nháy khi tải).

---

## ADR-017
### XYFlow (React Flow) làm động cơ sơ đồ kéo thả trong console PH-04

**Bối cảnh.** [ADR-015](#adr-015) đã chốt mô hình thiết kế luồng kiểu [Kaoto](https://kaoto.io/): kéo thả thành phần Camel trên sơ đồ, chỉnh thuộc tính, sinh Camel YAML DSL. [ADR-016](#adr-016) đã chốt Ant Design cho toàn bộ console. Cần chọn **thư viện vẽ đồ thị** để hiện thực `UI-04-07` bên trong console LGSP — không nhúng nguyên UI Kaoto (PatternFly Topology).

“XYFlow” là tên tổ chức/gói hiện tại của thư viện từng gọi là **React Flow**; gói npm chính thức là [`@xyflow/react`](https://reactflow.dev/).

**Phương án cân nhắc:**

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| **XYFlow (`@xyflow/react`)** | Kéo thả nút/cạnh sẵn; nút và cạnh tùy biến bằng React; MiniMap, Controls, Background; hỗ trợ sáng/tối; MIT; cộng đồng lớn; bản thân Kaoto cũng từng dùng React Flow và đang thử lại XYFlow thay Topology | Phải tự dựng nút theo EIP Camel, layout, sinh YAML |
| Nhúng UI Kaoto (PatternFly Topology) | UX gần bản playground Kaoto nhất | Xung đột Ant Design ([ADR-016](#adr-016)); khó gắn duyệt/GitOps PH-04 |
| PatternFly React Topology thuần | Cùng họ với Kaoto hiện tại | Cùng vấn đề thiết kế hệ thống |
| JointJS / GoJS | Canvas mạnh | GoJS thương mại; JointJS ít React-native hơn |
| SVG/Canvas tự viết | Kiểm soát tuyệt đối | Chi phí và rủi ro cao |

**Quyết định.** Dùng **XYFlow (`@xyflow/react`)** làm động cơ sơ đồ trong màn thiết kế luồng của PH-04. Catalog thành phần và ngữ nghĩa YAML bám [ADR-015](#adr-015). Giao diện xung quanh (palette, thuộc tính, thanh công cụ) dùng Ant Design ([ADR-016](#adr-016)).

**Mẫu tương tác UX.** Ngoài Kaoto (catalog/YAML), console học các điểm hay về **tương tác cấu hình** của [n8n](https://n8n.io/) — canvas trái→phải, thẻ node theo nhóm màu, panel một nút, expression editor, connection picker, pin data, highlight chạy thử — được chốt yêu cầu tại `FR-04-031…040` và `UI-04-07` / `UI-04-10` của [SRS PH-04](../07-srs/SRS-PH-04-integration-core.md). **Không** nhúng runtime n8n và **không** lưu secret trên node.

**Năng lực bắt buộc trên canvas:**

| Năng lực | Cách hiện thực |
|---|---|
| Kéo thành phần từ palette thả lên sơ đồ | HTML5 drag-and-drop → tạo nút tại toạ độ flow |
| Chèn chặng vào giữa hai chặng | Nút ＋ trên cạnh → menu chọn thành phần |
| Nối / đổi đường | `onConnect` / `onReconnect`; chặng thường một đường ra, EIP định tuyến được nhiều nhánh |
| Nhánh `choice` / điều kiện | Dữ liệu cạnh (`when` / `otherwise`); UI thân thiện FR-04-038 |
| Kéo dịch nút, phóng to thu nhỏ, minimap | Có sẵn của XYFlow |
| Tự sắp xếp | dagre (**trái → phải**, kiểu n8n) |
| Kiểm tra hợp lệ + YAML sống | `validate` + `emitRouteYaml` đồng bộ với sơ đồ |
| Panel cấu hình một nút | UI-04-10 + FR-04-031/032/037 |

**Hiện thực tham chiếu.** Nguồn: `mockup/designer-src/` (Vite + React + antd + `@xyflow/react`). Bản build một tệp: `mockup/pages/designer/index.html`. Chạy thử: `cd mockup/designer-src && npm run dev`.

**Hệ quả tích cực:**
- UX kéo thả cùng họ Kaoto (mô hình) + n8n (tương tác), nằm trong shell Ant Design của LGSP.
- YAML sinh ra vẫn là Camel YAML DSL — đường GitOps không đổi.
- Có thể mở rộng nút/cạnh tùy loại EIP mà không phụ thuộc lộ trình UI của Kaoto hay n8n.

**Hệ quả tiêu cực:**
- Phải bảo trì catalog subset và biểu mẫu thuộc tính; bản đầy đủ nạp catalog từ máy chủ theo phiên bản Camel đang chạy.
- Layout dagre đơn giản hơn layout chuyên biệt của Kaoto với nhóm lồng nhau sâu — chấp nhận ở mockup; sản phẩm có thể nâng lên ELK nếu cần.
- Attribution “React Flow” hiện trên canvas (gói miễn phí); bản Pro ẩn được nếu sau này mua giấy phép.

---

## ADR-018
### Mô hình phát triển: DU hybrid, production-first

| Mục | Nội dung |
|---|---|
| **Trạng thái** | Chấp nhận |
| **Ngày** | 2026-08-03 |
| **Bối cảnh** | Chốt tổ chức mã/deploy cho 18 PH hướng production và chuẩn hóa biên — không tối đa hóa số microservice, cũng không monolith một khối. |

**Các phương án**

| Phương án | Ưu | Nhược |
|---|---|---|
| A. Modular monolith một BE cho mọi PH | Đơn giản ngày 1 | Trái ADR-014 và scale Camel |
| B. Microservice 1 PH = 1 service ngay | Khớp chữ PR-04 | Nhân bản boilerplate; lệch chuẩn giữa service; không tự = chuẩn hóa |
| C. **Hybrid DU production-first** — tách ngay mọi biên đã cứng; gom PH cùng vòng đời vào DU modular | Chuẩn hóa đúng chỗ; khớp kiến trúc | Cần ArchUnit / Modulith + bản đồ PH↔DU |

**Quyết định.** Chọn **C**, với nguyên tắc **production-first**:

| Tách ngay từ đầu (bắt buộc) | Gom trong DU modular (chuẩn hóa logic) |
|---|---|
| COTS: APISIX, Keycloak, OPA, Kafka, Vault, LGTM, Backstage | `lgsp-control` (PH-01, 02, 16) |
| Control Plane ≠ Data Plane (ADR-014) | `lgsp-data` (PH-06…09) |
| Camel **theo miền** `lgsp-camel-<mien>` | `lgsp-process` (PH-11, 18), `lgsp-adapter-mgr` (PH-05, 14) |
| Console FE / Portal | Module PH trong DU: schema + `api/` riêng như microservice logic |

Chi tiết → [IP-01](../08-implementation/01-mo-hinh-phat-trien.md). Runtime DU ứng dụng → [ADR-019](#adr-019).

**Hệ quả:**
- Chuẩn hóa = biên cứng + khuôn mẫu giống nhau, không = 18 process custom ngày 1.
- SRS-19 không phải service riêng.
- Tách thêm PH → DU khi đủ tiêu chí IP-01 §4.3.

---

## ADR-019
### Spring Boot 4 + Spring Modulith cho DU ứng dụng

| Mục | Nội dung |
|---|---|
| **Trạng thái** | Chấp nhận |
| **Ngày** | 2026-08-03 |
| **Bối cảnh** | ADR-002 chọn Camel Quarkus cho Data Plane. DU ứng dụng (control/data/process…) cần module hóa chặt, hệ sinh thái CRUD/JPA/security quen thuộc — tham chiếu GiaPhaHub (Spring Boot 4 + Modulith). Hỏi: có được dùng Spring Boot 4 thay Quarkus cho các DU này không? |

**Phương án**

| Phương án | Ưu | Nhược |
|---|---|---|
| A. Quarkus cho mọi DU + Camel | Một runtime | Modulith/tooling kém “Spring-native”; lệch GiaPhaHub |
| B. Spring Boot 4 cho mọi thứ kể cả Camel | Một stack app | Mất lợi thế native scale của ADR-002 trên PH-04 |
| C. **Hai runtime có chủ đích** — Spring Boot 4 + Modulith cho DU ứng dụng; Camel Quarkus cho PH-04 | Đúng việc đúng tool; học được Modulith | Đội nắm hai stack (chấp nhận, phạm vi Camel hẹp) |

**Quyết định.** Chọn **C**.

| Lớp | Runtime |
|---|---|
| `lgsp-control`, `lgsp-data`, `lgsp-process`, `lgsp-adapter-mgr`, `lgsp-ai` (Java) | **Spring Boot 4.x** + **Spring Modulith 2.x** + Java 21 |
| `lgsp-camel-<mien>` (PH-04) | **Camel Quarkus native** (ADR-002) — không đổi |
| Console | React / Vite (ADR-016/017) |

**Hệ quả tích cực:**
- Ranh giới module cưỡng chế bằng Modulith verify / ArchUnit (học GiaPhaHub).
- Stack CRUD, Security, Liquibase/Flyway, test slice quen thuộc cho Control/Data Plane.
- Giữ scale & cold-start cho đường dữ liệu Camel.

**Hệ quả tiêu cực:**
- CI phải build hai kiểu artifact (Boot jar + Quarkus native).
- Không dùng Spring Cloud Gateway thay APISIX; không đưa logic tích hợp nặng vào Boot thay Camel.
- Thư viện dùng chung giữa Boot và Camel phải Java thuần / API ổn định — tránh kéo Quarkus API vào Boot và ngược lại.

---

## ADR-020
### Chính sách vòng đời phiên bản; thay MinIO cho lưu trữ đối tượng

| Mục | Nội dung |
|---|---|
| **Trạng thái** | Chấp nhận |
| **Ngày** | 2026-08-04 |
| **Thay thế một phần** | [ADR-008](#adr-008) (phần MinIO) |

**Bối cảnh.** Rà soát bảng phiên bản ghim của [IP-03](../08-implementation/03-stack-cong-nghe.md) ngày 2026-08-04 phát hiện ba vấn đề: (1) Camel ghim 4.20.x — **đã hết vòng đời 26/06/2026**; (2) MinIO chốt tại ADR-008 — kho mã cộng đồng **đã bị archive 25/04/2026**; (3) PostgreSQL ghim 16.x trong khi PG 18 đã GA. Nguyên nhân gốc không phải ba con số sai, mà là **thiếu chính sách vòng đời**: tài liệu ghim phiên bản nhưng không ràng buộc phải còn được hỗ trợ.

---

#### Phần A — Chính sách vòng đời phiên bản (áp cho mọi thành phần)

| # | Quy tắc |
|---|---|
| 1 | Chỉ ghim bản **còn trong vòng đời hỗ trợ** tại thời điểm khóa; ưu tiên dòng **LTS** |
| 2 | Với Apache Camel: **chỉ dùng dòng LTS** (4.18, 4.14…), không dùng bản giữa kỳ (4.19–4.21) — vòng đời chỉ vài tháng |
| 3 | Rà soát lại ngày EOL trước mỗi lần: mở pha lập trình · nâng cấp major · nộp hồ sơ cấp độ ATTT |
| 4 | Số phiên bản chỉ tồn tại ở **một nơi** — bảng ghim của IP-03; nơi khác tham chiếu, không lặp lại |
| 5 | Thành phần bị **archive / ngừng bảo trì** phải thay, kể cả khi giấy phép vẫn hợp lệ |

**Vì sao quy tắc 5 tách riêng khỏi tiêu chí giấy phép.** ADR-008 loại trừ MinIO theo trục AGPL và kết luận "chấp nhận được vì triển khai nội bộ". Kết luận đó vẫn đúng về giấy phép, nhưng bỏ sót trục quan trọng hơn: **ai còn vá lỗ hổng**. Một thành phần Apache-2.0 bị bỏ hoang rủi ro hơn một thành phần AGPL đang được bảo trì tích cực.

---

#### Phần B — Thay MinIO cho lưu trữ đối tượng

**Bối cảnh cụ thể.** Diễn biến MinIO: 06/2025 gỡ giao diện quản trị khỏi bản cộng đồng → 12/2025 chuyển sang chế độ bảo trì → **25/04/2026 archive kho mã, chỉ đọc**. Không còn release, không còn duyệt vá, không còn bản dựng chính thức.

**Phương án**

| Phương án | Ưu | Nhược |
|---|---|---|
| Giữ MinIO community | Không phải đổi | Không ai vá; tự gánh mọi lỗ hổng trên mã đóng băng |
| Mua MinIO AIStor thương mại | Có hỗ trợ | Trái yêu cầu open-source của dự án; ràng buộc nhà cung cấp |
| **Garage (AGPL-3.0)** | Đang bảo trì tích cực; thiết kế cho tự vận hành nhiều nút; S3-compatible | Cộng đồng nhỏ hơn; cần kiểm chứng WORM cho CMP-28 |
| **SeaweedFS (Apache-2.0)** | Giấy phép thoáng nhất; trưởng thành | Vận hành phức tạp hơn |
| **Ceph RGW** | Rất trưởng thành; đã phổ biến trong khu vực công | Nặng, tốn tài nguyên vận hành |

**Quyết định.** Bỏ MinIO. Ưu tiên **Garage**; nếu chính sách tổ chức cấm AGPL thì dùng **SeaweedFS**; nếu cụm đã có nền tảng Ceph thì dùng **Ceph RGW**.

**Điều kiện bắt buộc trước khi khóa lựa chọn.** Nhật ký kiểm toán cần **WORM** làm chứng cứ theo CMP-28 (xem [ADR-008](#adr-008)). Phải **kiểm chứng thực tế** khả năng object-lock / retention của bản được chọn trước khi đưa vào PROD — đây là điều kiện ra của WP-01, không phải giả định.

**Hệ quả tiêu cực:**
- Phát sinh việc kiểm chứng WORM + đo hiệu năng trên cụm đích (thuộc W0).
- Nếu chọn Garage: vẫn AGPL — chấp nhận được vì triển khai nội bộ, không phân phối (lập luận cũ của ADR-008 giữ nguyên).
- Tài liệu và runbook nhắc MinIO phải cập nhật.

**Quy ước đọc tài liệu cũ.** Khoảng 60 chỗ trong SRS và tài liệu luồng (PH-01, PH-04, PH-12, PH-13, PH-15, PH-18, SRS-00, 03-flows) viết trước ngày này còn nhắc tên **MinIO**. **Đọc là "lưu trữ đối tượng tương thích S3"** — mọi yêu cầu chức năng (S3 API, Object Lock/WORM, mã hóa lúc nghỉ, Claim Check) **giữ nguyên hiệu lực**, chỉ sản phẩm hiện thực thay đổi. Không mở đợt sửa hàng loạt: rủi ro chạm nhầm nội dung đặc tả lớn hơn lợi ích; đổi tên khi sửa các tài liệu đó vì lý do khác.

---

#### Phần C — Java 21 thay vì Java 25 LTS

**Bối cảnh.** Java 25 LTS phát hành 09/2025. Dự án ghim Java 21 — cần ghi rõ đây là lựa chọn có chủ đích.

**Quyết định.** Giữ **Java 21 LTS** cho lần khóa này.

| Lý do | Chi tiết |
|---|---|
| Camel 4.18 LTS | Dòng LTS đang dùng chưa lấy JDK 25 làm nền chính (hỗ trợ JDK 25 xuất hiện từ 4.20 — bản đã EOL) |
| GraalVM native | Chuỗi công cụ native cho Camel Quarkus ổn định nhất trên 21 (ADR-002) |
| Spring Boot 4 | Chỉ yêu cầu tối thiểu Java 17 — 21 nằm giữa vùng an toàn |
| Vòng đời | Java 21 được hỗ trợ tới ~2029, đủ dài cho chu kỳ đầu của LGSP |

**Điều kiện xét lại.** Nâng lên Java 25 khi dòng **Camel LTS kế tiếp** lấy JDK 25 làm nền và chuỗi native tương ứng ổn định. Ghi vào changelog ADR khi đổi.

**Hệ quả tiêu cực:** không dùng được tính năng ngôn ngữ mới của 22–25; chấp nhận vì đổi lại là chuỗi native ổn định.

---

## Liên kết

- Kiến trúc tổng thể → [02-architecture](../02-architecture/README.md)
- Yêu cầu pháp lý → [01-legal](../01-legal/README.md)
- Kế hoạch triển khai → [04-deployment](../04-deployment/README.md)
- Hướng dẫn lập trình → [08-implementation](../08-implementation/README.md)
- **Stack chốt theo tầng (production)** → [IP-03](../08-implementation/03-stack-cong-nghe.md)
