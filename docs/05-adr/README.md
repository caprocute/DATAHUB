# 05 — Quyết định kiến trúc (ADR)

> **Vai trò tài liệu**: nguồn sự thật duy nhất cho mọi lựa chọn công nghệ. Các tài liệu khác chỉ tham chiếu mã ADR, không lặp lại lý do.

**Cấu trúc mỗi ADR**: Bối cảnh → Phương án cân nhắc → Quyết định → Hệ quả (tích cực và tiêu cực).

| Mã | Quyết định | Trạng thái |
|---|---|---|
| [ADR-001](#adr-001) | Apache Camel làm lõi tích hợp | Đã chốt |
| [ADR-002](#adr-002) | Quarkus native làm runtime | Đã chốt |
| [ADR-003](#adr-003) | Apache APISIX làm API Gateway | Đã chốt |
| [ADR-004](#adr-004) | Keycloak + OPA cho định danh và ủy quyền | Đã chốt |
| [ADR-005](#adr-005) | Kafka + Apicurio + Debezium cho luồng bất đồng bộ | Đã chốt |
| [ADR-006](#adr-006) | Backstage làm Developer Portal | Đã chốt |
| [ADR-007](#adr-007) | OpenTelemetry + LGTM stack cho quan sát | Đã chốt |
| [ADR-008](#adr-008) | PostgreSQL + MinIO + Valkey cho lưu trữ | Đã chốt |
| [ADR-009](#adr-009) | Flowable cho BPM | Đã chốt |
| [ADR-010](#adr-010) | Argo CD + Kustomize cho GitOps | Đã chốt |
| [ADR-011](#adr-011) | Istio ambient mesh cho mTLS | Đã chốt |
| [ADR-012](#adr-012) | Vault/OpenBao cho quản lý bí mật | Đã chốt |
| [ADR-013](#adr-013) | Canonical Data Model làm trung gian chuyển đổi | Đã chốt |
| [ADR-014](#adr-014) | Tách Control Plane khỏi Data Plane | Đã chốt |

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

**Quyết định.** Dùng **Apache Camel 4.x** làm engine tích hợp duy nhất, kèm **Camel Karavan** làm trình thiết kế trực quan.

**Hệ quả tích cực:**
- Toàn bộ giao thức bắt buộc theo CV 631 có sẵn component — không phải viết mã kết nối (CMP-11, CMP-12).
- EIP chuẩn hóa cách giải quyết các bài toán tích hợp; đội mới vào dễ đọc hiểu.
- Route mô tả khai báo bằng YAML — cấu hình hơn lập trình (NT-02).
- Karavan hạ rào cản kỹ năng: cán bộ không chuyên Java vẫn thiết kế được luồng.

**Hệ quả tiêu cực:**
- Đội cần đào tạo về Camel DSL và tư duy EIP — đưa vào bước 16 của kế hoạch triển khai.
- Cần kỷ luật đặt tên và cấu trúc route, nếu không sẽ khó bảo trì khi số route tăng lên hàng trăm — giải quyết bằng template chuẩn ở bước 6.

---

## ADR-002
### Quarkus native làm runtime

**Bối cảnh.** Camel chạy được trên nhiều runtime: Spring Boot, Quarkus, Camel Main. Lựa chọn runtime ảnh hưởng trực tiếp tới thời gian khởi động, tiêu thụ bộ nhớ và khả năng mở rộng phản ứng trên K8s.

**Phương án cân nhắc:**

| Tiêu chí | Quarkus native | Quarkus JVM | Spring Boot |
|---|---|---|---|
| Thời gian khởi động | ~50ms | ~1s | ~5s |
| Bộ nhớ thường trú | ~50MB | ~150MB | ~300MB |
| Thời gian biên dịch | Chậm (native build) | Nhanh | Nhanh |
| Hệ sinh thái | Tốt | Tốt | Rất tốt |
| Gỡ lỗi | Khó hơn | Dễ | Dễ |

**Quyết định.** Dùng **Camel Quarkus biên dịch native (GraalVM)** cho môi trường PROD; dùng chế độ JVM cho môi trường DEV để rút ngắn vòng lặp phát triển.

**Hệ quả tích cực:**
- Khởi động dưới 50ms cho phép mở rộng phản ứng thực sự — pod mới phục vụ được gần như tức thì khi tải tăng đột ngột. Với hệ thống hành chính công có đỉnh tải theo giờ làm việc, đặc tính này chuyển hóa trực tiếp thành tiết kiệm tài nguyên.
- Bộ nhớ thấp cho phép chạy nhiều replica hơn trên cùng hạ tầng.
- Bề mặt tấn công nhỏ hơn (ảnh container tối giản, không có JVM đầy đủ).

**Hệ quả tiêu cực:**
- Biên dịch native chậm (vài phút) — chấp nhận được vì chỉ chạy trên CI, không ảnh hưởng vòng lặp phát triển cục bộ.
- Một số thư viện dùng reflection cần cấu hình bổ sung cho native. Giảm thiểu bằng cách chỉ dùng các Camel component đã được Quarkus hỗ trợ chính thức.
- Khác biệt giữa DEV (JVM) và PROD (native) có thể che giấu lỗi — bù lại bằng kiểm thử trên bản native ở môi trường TEST.

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

## Liên kết

- Kiến trúc tổng thể → [02-architecture](../02-architecture/README.md)
- Yêu cầu pháp lý → [01-legal](../01-legal/README.md)
- Kế hoạch triển khai → [04-deployment](../04-deployment/README.md)
