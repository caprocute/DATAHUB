# 01 — Cơ sở pháp lý & Ma trận tuân thủ

> **Vai trò tài liệu**: nguồn sự thật duy nhất về yêu cầu pháp lý và ánh xạ điều khoản → thành phần kiến trúc. Các tài liệu khác chỉ tham chiếu về đây, không lặp lại nội dung.

---

## 1. Bộ văn bản chi phối

### 1.1. Tầng luật & nghị định

| Văn bản | Ngày / Hiệu lực | Nội dung chi phối thiết kế |
|---|---|---|
| **Luật Dữ liệu số 60/2024/QH15** | Thông qua 30/11/2024 — hiệu lực **01/7/2025** | Khung pháp lý cao nhất về dữ liệu số: xây dựng, phát triển, bảo vệ, quản trị, xử lý, sử dụng dữ liệu. Thiết lập Trung tâm Dữ liệu quốc gia. |
| **Nghị định 165/2025/NĐ-CP** | 30/6/2025 | Quy định chi tiết Luật Dữ liệu: truy cập & khai thác dữ liệu, hỗ trợ chủ quản dữ liệu kết nối chia sẻ, xác thực dữ liệu, công khai dữ liệu, **mã hóa/giải mã**, chuyển dữ liệu xuyên biên giới. |
| **Nghị định 47/2020/NĐ-CP** | 09/4/2020 — hiệu lực 25/5/2020 | **Văn bản xương sống của LGSP**: quản lý, kết nối và chia sẻ dữ liệu số của CQNN. |
| **Nghị định 85/2016/NĐ-CP** | 01/7/2016 | Bảo đảm an toàn hệ thống thông tin theo cấp độ — LGSP phải được phê duyệt hồ sơ cấp độ. |

### 1.2. Tầng thông tư & quyết định kỹ thuật

| Văn bản | Ngày | Nội dung chi phối thiết kế |
|---|---|---|
| **CV 631/THH-THHT** | 21/5/2020 | **Văn bản quan trọng nhất về chức năng LGSP** — Cục Tin học hóa (nay là Cục Chuyển đổi số quốc gia) ban hành yêu cầu chức năng, tính năng kỹ thuật Nền tảng chia sẻ, tích hợp dùng chung cấp bộ/tỉnh, phiên bản 1.0. |
| **QĐ 2568/QĐ-BTTTT** | 29/12/2023 | Khung Kiến trúc Chính phủ điện tử Việt Nam **phiên bản 3.0**, hướng tới Chính phủ số. Thay thế QĐ 2323/QĐ-BTTTT (v2.0). |
| **QĐ 1729/QĐ-BTTTT** | 09/10/2024 | Sửa đổi, bổ sung QĐ 2568 — bổ sung Trung tâm dữ liệu quốc gia, nền tảng định danh và xác thực điện tử. |
| **TT 13/2017/TT-BTTTT** | 23/6/2017 | Yêu cầu kỹ thuật về kết nối HTTT/CSDL với **cơ sở dữ liệu quốc gia** — áp dụng cho chiều LGSP ↔ NDXP/NGSP. |
| **TT 39/2017/TT-BTTTT** | 15/12/2017 — hiệu lực 01/7/2018 | Danh mục **tiêu chuẩn kỹ thuật** ứng dụng CNTT trong CQNN. Thay TT 22/2013. |

---

## 2. Trích yếu các yêu cầu bắt buộc

### 2.1. Từ Nghị định 47/2020/NĐ-CP

**Định nghĩa nền tảng** — kiến trúc phân cấp bắt buộc:

- **LGSP**: nền tảng tích hợp, chia sẻ dữ liệu cấp bộ/cấp tỉnh; chứa các dịch vụ dùng chung để chia sẻ dữ liệu giữa các HTTT của cơ quan, đơn vị **thuộc phạm vi một bộ/ngành/địa phương**; đóng vai trò **trung gian** kết nối HTTT nội bộ với các hệ thống bên ngoài.
- **NDXP/NGSP**: nền tảng cấp quốc gia, kết nối liên thông giữa các bộ/ngành/địa phương và tới CSDLQG.

**Nguyên tắc cốt lõi** (chi phối trực tiếp thiết kế):

| Nguyên tắc | Hệ quả kiến trúc |
|---|---|
| Kết nối, chia sẻ dữ liệu giữa CQNN **không thu phí** | Không cần module billing; nhưng **bắt buộc** có đo đếm (metering) để phục vụ thống kê, báo cáo và quản trị dung lượng |
| **Không yêu cầu** người dân/doanh nghiệp cung cấp lại dữ liệu mà CQNN đã có | Bắt buộc có **dịch vụ tra cứu dữ liệu chủ** và cache/kho dữ liệu trung gian đủ nhanh |
| Chia sẻ **phải qua dịch vụ chia sẻ dữ liệu** (Điều 24) | **Cấm kết nối điểm-điểm** giữa các HTTT; mọi kết nối đi qua LGSP |
| Chủ quản CSDL phải **thiết lập và công bố** dịch vụ chia sẻ + tài liệu kỹ thuật | Bắt buộc có **API Portal / Service Catalog** với tài liệu OpenAPI |
| Công khai thông tin dịch vụ chia sẻ (Điều 25) | Registry dịch vụ phải public-readable trong phạm vi CQNN |
| Hệ thống quản lý dịch vụ chia sẻ dữ liệu tập trung do Bộ TTTT quản lý (Điều 26) | LGSP phải **đăng ký & đồng bộ** danh mục dịch vụ lên hệ thống trung ương |
| Dữ liệu chủ (master data) — thông tin cơ bản định danh thực thể nghiệp vụ cốt lõi | Bắt buộc có **phân hệ MDM** |
| Danh mục dữ liệu dùng chung — bảng mã phân loại dùng chung | Bắt buộc có **Reference Data Management** |
| Kiểm tra, đánh giá chất lượng dữ liệu **định kỳ hằng năm** | Bắt buộc có **Data Quality service** + báo cáo |
| Không áp dụng cho dữ liệu thuộc bí mật nhà nước | Phải có **phân loại mức độ mật** và chặn luồng tương ứng |

### 2.2. Từ CV 631/THH-THHT — Yêu cầu chức năng LGSP

**Các phân hệ bắt buộc:**

| # | Phân hệ | Yêu cầu |
|---|---|---|
| 1 | **Trục tích hợp (ESB)** | Kết nối hệ thống, định tuyến dữ liệu, xử lý và chuyển đổi bản tin (message transformation, routing, mediation) |
| 2 | **Quản lý API** | Thiết kế, công khai, bảo vệ API; quản lý vòng đời API từ tạo → triển khai; throttling/rate limiting; xác thực OAuth2 |
| 3 | **Quản lý bảo mật & định danh tập trung** | SSO qua **SAML2** và **OpenID Connect**; xác thực đa yếu tố (MFA); phân quyền theo vai trò (RBAC) theo chuẩn **XACML 2.0/3.0** |
| 4 | **Quản lý quy trình nghiệp vụ (BPM)** | Hỗ trợ chuẩn **BPMN 2.0**, **WS-BPEL** |
| 5 | **Giám sát** | Theo dõi hiệu năng, tình trạng hoạt động; quản lý, tìm kiếm, thống kê, báo cáo, phân tích nghiệp vụ **thời gian thực** |
| 6 | **Adapter/Connector** | Bộ điều hợp kết nối tới các dịch vụ; mọi yêu cầu ra/vào đều qua adapter |

**Yêu cầu kỹ thuật bắt buộc:**

- **Kiến trúc SOA**, thiết kế module hóa bảo đảm các thành phần độc lập.
- **Giao thức truyền tải**: HTTP, HTTPS, WebSocket, POP, IMAP, SMTP, JMS, AMQP, MQTT.
- **Định dạng dữ liệu**: JSON, XML, SOAP.
- **Bảo mật**: TLS v1.2 trở lên, HTTPS, OAuth2, SAML2, XACML.
- **Kiến trúc đa lớp**, hỗ trợ **cluster xử lý song song**.
- **Sẵn sàng IPv6**.

**Yêu cầu phi chức năng bắt buộc:**

| Chỉ tiêu | Ngưỡng quy định |
|---|---|
| Chế độ hoạt động | **24/7** liên tục |
| Thời gian phản hồi tối đa | **30 giây** |
| Sao lưu CSDL | **Hằng ngày**, có khả năng phục hồi khi sự cố |
| An toàn thông tin | Tối thiểu theo cấp độ tại NĐ 85/2016 |
| Chống tấn công | Có biện pháp giảm thiểu DDoS |

### 2.3. Từ QĐ 2568 + 1729 — Khung Kiến trúc CPĐT 3.0

Năm mô hình tham chiếu mà kiến trúc LGSP phải ánh xạ vào:

| Mô hình | Tên | Ánh xạ trong tài liệu này |
|---|---|---|
| **BRM** | Business Reference Model | [Luồng nghiệp vụ](../03-flows/README.md) |
| **DRM** | Data Reference Model | [Kiến trúc dữ liệu](../02-architecture/README.md#6-kiến-trúc-dữ-liệu) |
| **ARM** | Application Reference Model | [Kiến trúc ứng dụng](../02-architecture/README.md#4-kiến-trúc-ứng-dụng--phân-rã-thành-phần) |
| **TRM** | Technology Reference Model | [Kiến trúc hạ tầng](../02-architecture/README.md#7-kiến-trúc-hạ-tầng--triển-khai) |
| **SRM** | Security Reference Model | [Kiến trúc an toàn](../02-architecture/README.md#8-kiến-trúc-an-toàn-thông-tin) |

Hai bổ sung từ QĐ 1729 phải hiện diện trong thiết kế:
- **Nền tảng định danh và xác thực điện tử** (VNeID) — tích hợp bắt buộc.
- **Trung tâm dữ liệu quốc gia** — điểm kết nối mới bên cạnh NDXP.

---

## 3. Ma trận truy vết tuân thủ

> Bảng này ánh xạ **điều khoản pháp lý → thành phần kiến trúc → cơ chế kiểm chứng**. Đây là công cụ nghiệm thu.

| ID | Yêu cầu pháp lý | Nguồn | Thành phần đáp ứng | Cách kiểm chứng |
|---|---|---|---|---|
| **CMP-01** | Mọi chia sẻ dữ liệu phải qua dịch vụ chia sẻ | NĐ 47 Đ.24 | Integration Runtime (Camel) + API Gateway | Network policy chặn traffic điểm-điểm; audit log |
| **CMP-02** | Công bố dịch vụ + tài liệu kỹ thuật | NĐ 47 Đ.24, Đ.25 | Service Catalog / API Portal | Mỗi API có OpenAPI 3.1 đã publish |
| **CMP-03** | Đăng ký danh mục lên hệ thống trung ương | NĐ 47 Đ.26 | Catalog Sync Connector → Bộ TTTT | Job đồng bộ định kỳ, log kết quả |
| **CMP-04** | ESB: định tuyến, chuyển đổi, mediation | CV 631 | Apache Camel Integration Runtime | Test EIP: content-based routing, transform |
| **CMP-05** | Quản lý vòng đời API + throttling | CV 631 | APISIX + API Manager | Kiểm thử rate-limit, versioning API |
| **CMP-06** | SSO: SAML2 + OpenID Connect | CV 631 | Keycloak | Test đăng nhập cả 2 giao thức |
| **CMP-07** | MFA | CV 631 | Keycloak MFA (TOTP/WebAuthn) | Test luồng xác thực 2 bước |
| **CMP-08** | Phân quyền chuẩn XACML 2.0/3.0 | CV 631 | Open Policy Agent + XACML PDP adapter | Test policy decision (Permit/Deny) |
| **CMP-09** | BPM chuẩn BPMN 2.0 | CV 631 | Flowable / Camunda 8 | Deploy & chạy 1 quy trình BPMN 2.0 |
| **CMP-10** | Giám sát thời gian thực | CV 631 | OpenTelemetry + Prometheus + Grafana | Dashboard hiển thị metric < 15s độ trễ |
| **CMP-11** | Đa giao thức: HTTP/S, WS, JMS, AMQP, MQTT, SMTP/POP/IMAP | CV 631 | Camel components | Kiểm thử từng component |
| **CMP-12** | Định dạng JSON, XML, SOAP | CV 631 | Camel data formats | Test marshal/unmarshal 3 định dạng |
| **CMP-13** | TLS 1.2+ | CV 631 | Istio mTLS + APISIX TLS | Quét SSL Labs / testssl.sh |
| **CMP-14** | Sẵn sàng IPv6 | CV 631 | K8s dual-stack | Test truy cập qua IPv6 |
| **CMP-15** | Hoạt động 24/7 | CV 631 | HA multi-replica + PDB | Chaos test, đo uptime |
| **CMP-16** | Phản hồi ≤ 30s | CV 631 | Timeout policy + circuit breaker | Load test đo P99 |
| **CMP-17** | Sao lưu CSDL hằng ngày | CV 631 | CloudNativePG backup → MinIO | Kiểm thử khôi phục (restore drill) |
| **CMP-18** | An toàn theo cấp độ | NĐ 85/2016 | Toàn bộ SRM | Hồ sơ đề xuất cấp độ được phê duyệt |
| **CMP-19** | Chống DDoS | CV 631 | APISIX rate-limit + WAF (Coraza) | Kiểm thử tải bất thường |
| **CMP-20** | Quản lý dữ liệu chủ | NĐ 47 | MDM Service | Test golden record, khử trùng lặp |
| **CMP-21** | Danh mục dữ liệu dùng chung | NĐ 47 | Reference Data Service | Versioning bảng mã, API tra cứu |
| **CMP-22** | Đánh giá chất lượng dữ liệu định kỳ | NĐ 47 | Data Quality Service | Báo cáo chất lượng hằng năm |
| **CMP-23** | Không chia sẻ dữ liệu mật | NĐ 47 | Data Classification + Policy Engine | Test chặn luồng dữ liệu gắn nhãn mật |
| **CMP-24** | Mã hóa dữ liệu | NĐ 165/2025 | Vault + mã hóa at-rest/in-transit | Kiểm tra khóa, thuật toán |
| **CMP-25** | Kết nối CSDLQG theo chuẩn | TT 13/2017 | NDXP Adapter | Kiểm thử kết nối thực tế với NDXP |
| **CMP-26** | Tuân thủ danh mục tiêu chuẩn | TT 39/2017 | Toàn hệ thống | Đối chiếu danh mục tiêu chuẩn |
| **CMP-27** | Tích hợp định danh điện tử | QĐ 1729 | VNeID Adapter | Test xác thực qua VNeID |
| **CMP-28** | Ghi vết truy cập dữ liệu | Luật Dữ liệu 2024 | Audit Log (immutable) | Truy vết đầy đủ ai-truy cập-gì-khi nào |

---

## 4. Ranh giới phạm vi

**Trong phạm vi** (trục nội bộ — theo yêu cầu):
- Tích hợp các HTTT trong nội bộ một bộ/tỉnh.
- Cung cấp dịch vụ chia sẻ dữ liệu nội bộ.
- Đóng vai trò **điểm kết nối duy nhất** ra NDXP/NGSP và CSDLQG.

**Ngoài phạm vi**:
- Xây dựng NDXP/NGSP (thuộc trung ương).
- Xây dựng các CSDLQG.
- Nghiệp vụ chuyên ngành bên trong từng HTTT thành viên.

---

## 5. Nguồn tham chiếu

- [Nghị định 47/2020/NĐ-CP — Cổng TTĐT Chính phủ](https://vanban.chinhphu.vn/default.aspx?pageid=27160&docid=199754)
- [CV 631/THH-THHT — Caselaw](https://caselaw.vn/van-ban-phap-luat/358951-cong-van-so-631-thh-thht-ngay-21-05-2020-cua-cuc-tin-hoc-hoa-huong-dan-yeu-cau-ve-chuc-nang-tinh-nang-ky-thuat-cua-nen-tang-chia-se-tich-hop-dung-chung-cap-bo-cap-tinh-phien-ban-1-0)
- [QĐ 2568/QĐ-BTTTT — Khung Kiến trúc CPĐT 3.0](https://luatvietnam.vn/thong-tin/quyet-dinh-2568-qd-btttt-2023-khung-kien-truc-chinh-phu-dien-tu-viet-nam-phien-ban-30-287227-d1.html)
- [QĐ 1729/QĐ-BTTTT — Sửa đổi QĐ 2568](https://caselaw.vn/van-ban-phap-luat/507965-quyet-dinh-so-1729-qd-btttt-ngay-09-10-2024-cua-bo-truong-bo-thong-tin-va-truyen-thong-sua-doi-quyet-dinh-2568-qd-btttt-ve-khung-kien-truc-chinh-phu-dien-tu-viet-nam-phien-ban-3-0-huong-toi-chinh-phu-so)
- [TT 13/2017/TT-BTTTT](https://thuvienphapluat.vn/van-ban/Cong-nghe-thong-tin/Thong-tu-13-2017-TT-BTTTT-yeu-cau-ky-thuat-ket-noi-he-thong-thong-tin-co-so-du-lieu-quoc-gia-355458.aspx)
- [TT 39/2017/TT-BTTTT — Công báo Chính phủ](https://congbao.chinhphu.vn/van-ban/thong-tu-so-39-2017-tt-btttt-25437.htm)
- [Nghị định 165/2025/NĐ-CP hướng dẫn Luật Dữ liệu](https://antoanthongtin.vn/tin/chinh-phu-ban-hanh-quy-dinh-chi-tiet-mot-so-dieu-va-bien-phap-thi-hanh-luat-du-lieu)
