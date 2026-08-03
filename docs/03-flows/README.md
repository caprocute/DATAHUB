# 03 — Luồng nghiệp vụ chính của LGSP

> **Vai trò tài liệu**: mô tả các luồng nghiệp vụ cốt lõi kèm sơ đồ tuần tự và thuyết minh từng bước.
> Thành phần tham gia đã định nghĩa tại [02-architecture](../02-architecture/README.md#4-kiến-trúc-ứng-dụng--phân-rã-thành-phần).

## Danh mục luồng

| Mã | Luồng | Kiểu | Tần suất | Mức quan trọng |
|---|---|---|---|---|
| [F-01](#f-01--đăng-ký-và-kết-nạp-httt-thành-viên) | Đăng ký & kết nạp HTTT thành viên | Quản trị | Thấp | Cao |
| [F-02](#f-02--công-bố-và-đăng-ký-dịch-vụ-chia-sẻ-dữ-liệu) | Công bố & đăng ký dịch vụ chia sẻ dữ liệu | Quản trị | Trung bình | Cao |
| [F-03](#f-03--khai-thác-dữ-liệu-đồng-bộ-nội-bộ) | Khai thác dữ liệu đồng bộ (nội bộ) | Nghiệp vụ | Rất cao | Rất cao |
| [F-04](#f-04--khai-thác-dữ-liệu-từ-csdl-quốc-gia-qua-ndxp) | Khai thác dữ liệu từ CSDLQG qua NDXP | Nghiệp vụ | Cao | Rất cao |
| [F-05](#f-05--đồng-bộ-dữ-liệu-bất-đồng-bộ-theo-sự-kiện) | Đồng bộ dữ liệu bất đồng bộ theo sự kiện | Nghiệp vụ | Cao | Cao |
| [F-06](#f-06--liên-thông-văn-bản-điện-tử) | Liên thông văn bản điện tử | Nghiệp vụ | Cao | Cao |
| [F-07](#f-07--giải-quyết-thủ-tục-hành-chính-liên-thông) | Giải quyết TTHC liên thông đa cấp | Nghiệp vụ | Trung bình | Rất cao |
| [F-08](#f-08--xác-thực-người-dùng-qua-vneid-sso) | Xác thực người dùng qua VNeID / SSO | Nền tảng | Rất cao | Rất cao |
| [F-09](#f-09--quản-lý-dữ-liệu-chủ-và-đối-sánh-thực-thể) | Quản lý dữ liệu chủ & đối sánh thực thể | Dữ liệu | Trung bình | Cao |
| [F-10](#f-10--xử-lý-lỗi-và-phát-lại-bản-tin) | Xử lý lỗi & phát lại bản tin | Vận hành | Theo sự cố | Cao |
| [F-11](#f-11--đánh-giá-chất-lượng-dữ-liệu-định-kỳ) | Đánh giá chất lượng dữ liệu định kỳ | Tuân thủ | Định kỳ | Trung bình |
| [F-12](#f-12--giám-sát-và-cảnh-báo-vận-hành) | Giám sát & cảnh báo vận hành | Vận hành | Liên tục | Cao |

---

## F-01 — Đăng ký và kết nạp HTTT thành viên

**Mục đích.** Kết nạp một hệ thống thông tin của sở/ngành vào trục LGSP, cấp danh tính và quyền truy cập.

**Tác nhân.** Cán bộ kỹ thuật đơn vị thành viên, Quản trị viên LGSP, hệ thống Onboarding, Keycloak, Service Catalog.

```mermaid
sequenceDiagram
    autonumber
    actor DEV as Cán bộ kỹ thuật<br/>đơn vị thành viên
    participant PORTAL as API Developer Portal
    participant ONB as Onboarding Service
    actor ADMIN as Quản trị viên LGSP
    participant KC as Keycloak
    participant VAULT as Vault
    participant CAT as Service Catalog
    participant GW as APISIX Gateway

    DEV->>PORTAL: Nộp hồ sơ đăng ký HTTT<br/>(thông tin đơn vị, mục đích, dữ liệu cần)
    PORTAL->>ONB: Tạo yêu cầu kết nạp
    ONB->>ONB: Kiểm tra tính hợp lệ hồ sơ<br/>(đơn vị có thẩm quyền?)
    ONB->>ADMIN: Chuyển hồ sơ chờ phê duyệt

    ADMIN->>ADMIN: Thẩm định:<br/>· Căn cứ pháp lý khai thác<br/>· Phạm vi dữ liệu đề nghị<br/>· Mức độ mật của dữ liệu

    alt Từ chối
        ADMIN-->>ONB: Từ chối + nêu lý do
        ONB-->>DEV: Thông báo từ chối
    else Phê duyệt
        ADMIN->>ONB: Phê duyệt + phạm vi quyền (scope)
        ONB->>KC: Tạo client OAuth2<br/>(client_id, scope, vai trò)
        KC-->>ONB: Trả client_id
        ONB->>VAULT: Sinh & lưu client_secret,<br/>chứng thư mTLS
        VAULT-->>ONB: Trả tham chiếu bí mật
        ONB->>GW: Cấu hình định tuyến + hạn mức<br/>cho client mới
        ONB->>CAT: Ghi nhận HTTT vào danh mục
        ONB-->>DEV: Trả thông tin kết nối<br/>(qua kênh an toàn, dùng một lần)
        DEV->>GW: Kiểm thử kết nối (health check)
        GW-->>DEV: Xác nhận kết nối thành công
    end
```

### Thuyết minh F-01

| Bước | Điểm cần lưu ý |
|---|---|
| 3 | Kiểm tra tự động: đơn vị phải tồn tại trong danh mục đơn vị hành chính (RDM) và người nộp phải có vai trò hợp lệ |
| 5 | **Khâu then chốt** — thẩm định của con người không thể tự động hóa. Quản trị viên đối chiếu căn cứ pháp lý: đơn vị này có quyền khai thác dữ liệu này theo văn bản nào? Đây là chốt chặn thực thi CMP-23 (không chia sẻ dữ liệu vượt thẩm quyền) |
| 8 | Nguyên tắc đặc quyền tối thiểu: scope cấp đúng phạm vi được duyệt, không cấp rộng "cho tiện" |
| 10 | Bí mật sinh ra và lưu tại Vault, **không bao giờ** lưu ở CSDL ứng dụng hay gửi qua email thường |
| 13 | Trả thông tin qua liên kết dùng một lần, hết hạn sau 24 giờ |

**Kết quả.** HTTT thành viên có danh tính OAuth2 riêng, chứng thư mTLS, phạm vi quyền xác định và hạn mức tần suất — đủ điều kiện gọi dịch vụ trên trục.

**Xử lý ngoại lệ.** Hồ sơ bị từ chối phải nêu rõ lý do và điều khoản pháp lý viện dẫn để đơn vị bổ sung. Nếu quá 15 ngày không có phản hồi phê duyệt, hệ thống tự động nhắc quản trị viên.

---

## F-02 — Công bố và đăng ký dịch vụ chia sẻ dữ liệu

**Mục đích.** Chủ quản CSDL công bố dịch vụ chia sẻ dữ liệu của mình lên trục và đồng bộ danh mục lên hệ thống trung ương của Bộ TTTT.

**Căn cứ.** NĐ 47/2020 Điều 24 (thiết lập và công bố dịch vụ), Điều 25 (công khai thông tin), Điều 26 (đăng ký lên hệ thống trung ương) → CMP-02, CMP-03.

```mermaid
sequenceDiagram
    autonumber
    actor OWNER as Chủ quản CSDL
    participant PORTAL as API Developer Portal
    participant APIM as API Manager
    participant CAT as Service Catalog
    actor ADMIN as Quản trị viên LGSP
    participant CAMEL as Camel Runtime
    participant GW as APISIX Gateway
    participant BTTTT as Hệ thống quản lý DVCSDL<br/>(Bộ TTTT)

    OWNER->>PORTAL: Nộp đặc tả dịch vụ<br/>(OpenAPI 3.1 + mô tả nghiệp vụ)
    PORTAL->>APIM: Đăng ký API mới (trạng thái: DRAFT)
    APIM->>APIM: Kiểm tra đặc tả:<br/>· Đúng chuẩn OpenAPI 3.1?<br/>· Có ánh xạ CDM?<br/>· Đã khai báo mức độ mật?

    alt Đặc tả không hợp lệ
        APIM-->>OWNER: Trả lỗi + hướng dẫn sửa
    else Đặc tả hợp lệ
        APIM->>CAMEL: Sinh khung route từ đặc tả<br/>(template chuẩn 9 bước)
        CAMEL-->>APIM: Route đã triển khai môi trường thử
        APIM->>APIM: Chuyển trạng thái: TESTING
        OWNER->>GW: Kiểm thử dịch vụ trên môi trường thử
        GW-->>OWNER: Kết quả kiểm thử

        OWNER->>APIM: Đề nghị phát hành
        APIM->>ADMIN: Chờ phê duyệt phát hành
        ADMIN->>ADMIN: Rà soát: SLA, phân loại mật,<br/>chính sách truy cập
        ADMIN->>APIM: Phê duyệt
        APIM->>GW: Kích hoạt định tuyến chính thức
        APIM->>CAT: Ghi vào danh mục dịch vụ<br/>(trạng thái: PUBLISHED)
        CAT->>PORTAL: Hiển thị công khai<br/>tài liệu + endpoint (Đ.25)
        CAT->>BTTTT: Đồng bộ danh mục dịch vụ (Đ.26)
        BTTTT-->>CAT: Xác nhận đã ghi nhận
        APIM-->>OWNER: Thông báo dịch vụ đã phát hành
    end
```

### Thuyết minh F-02

**Vì sao bắt buộc OpenAPI 3.1 trước khi triển khai.** Đây là hiện thực nguyên tắc API-first (NT-01). Đặc tả là hợp đồng: bên cung cấp cam kết cấu trúc dữ liệu, bên khai thác lập trình dựa trên đó. Không có đặc tả chuẩn thì không thể sinh tài liệu tự động, không kiểm chứng được tương thích khi nâng phiên bản, và vi phạm nghĩa vụ "công bố tài liệu kỹ thuật" tại Điều 24.

**Sinh khung route tự động (bước 5).** API Manager không sinh mã hoàn chỉnh mà sinh **khung route theo template chuẩn chín bước** đã mô tả tại [kiến trúc tích hợp](../02-architecture/README.md#52-mô-hình-luồng-tích-hợp). Chủ quản chỉ điền phần logic riêng. Cách này bảo đảm mọi dịch vụ đều có kiểm tra quyền, ghi vết và xử lý lỗi — không thể "quên".

**Vòng đời dịch vụ:**

```mermaid
stateDiagram-v2
    [*] --> DRAFT: Nộp đặc tả
    DRAFT --> TESTING: Đặc tả hợp lệ
    DRAFT --> [*]: Hủy
    TESTING --> DRAFT: Kiểm thử thất bại
    TESTING --> PENDING: Đề nghị phát hành
    PENDING --> PUBLISHED: Phê duyệt
    PENDING --> TESTING: Yêu cầu sửa
    PUBLISHED --> DEPRECATED: Có phiên bản mới
    DEPRECATED --> RETIRED: Hết thời hạn chuyển đổi
    RETIRED --> [*]
    note right of DEPRECATED
        Vẫn phục vụ nhưng cảnh báo.
        Thời hạn chuyển đổi tối thiểu 6 tháng
        để bên khai thác kịp nâng cấp.
    end note
```

**Bước 18 — nghĩa vụ thường bị bỏ sót.** Đồng bộ danh mục lên hệ thống của Bộ TTTT là bắt buộc theo Điều 26 nhưng nhiều triển khai thực tế bỏ qua. Thiết kế này đưa nó vào luồng tự động, chạy ngay khi dịch vụ được phát hành, kèm cơ chế thử lại nếu hệ thống trung ương tạm thời không phản hồi.

---

## F-03 — Khai thác dữ liệu đồng bộ (nội bộ)

**Mục đích.** Một HTTT tra cứu dữ liệu từ HTTT khác trong cùng bộ/tỉnh, cần kết quả ngay.

**Đặc điểm.** Luồng có tần suất cao nhất trên trục — chiếm phần lớn lưu lượng. Nhạy cảm về độ trễ.

```mermaid
sequenceDiagram
    autonumber
    participant SRC as HTTT khai thác<br/>(VD: Cổng DVC)
    participant GW as APISIX Gateway
    participant KC as Keycloak
    participant OPA as OPA (Policy)
    participant CAMEL as Camel Runtime
    participant CACHE as Valkey Cache
    participant MDM as MDM Service
    participant TGT as HTTT cung cấp<br/>(VD: CSDL chuyên ngành)
    participant AUD as Audit Log

    SRC->>GW: GET /api/v1/{tài nguyên}<br/>Bearer token + mTLS
    GW->>GW: Chấm dứt TLS · Kiểm WAF · Hạn mức

    alt Vượt hạn mức
        GW-->>SRC: 429 Too Many Requests
    end

    GW->>KC: Xác minh JWT (chữ ký, hạn, phát hành)
    KC-->>GW: Token hợp lệ + claims

    alt Token không hợp lệ
        GW-->>SRC: 401 Unauthorized
    end

    GW->>CAMEL: Chuyển tiếp yêu cầu + traceId
    CAMEL->>CAMEL: Kiểm tra schema đầu vào
    CAMEL->>OPA: Kiểm quyền<br/>(client, tài nguyên, mức độ mật)
    OPA-->>CAMEL: Permit / Deny

    alt Bị từ chối
        CAMEL->>AUD: Ghi vết truy cập bị từ chối
        CAMEL-->>SRC: 403 Forbidden + lý do
    end

    CAMEL->>CACHE: Tra cache theo khóa

    alt Cache hit
        CACHE-->>CAMEL: Trả dữ liệu (< 10ms)
    else Cache miss
        CAMEL->>TGT: Gọi HTTT cung cấp<br/>(circuit breaker bảo vệ)

        alt HTTT cung cấp lỗi/timeout
            TGT-->>CAMEL: Lỗi
            CAMEL->>CAMEL: Thử lại (tối đa 3 lần, backoff)
            CAMEL-->>SRC: 503 + thông báo thân thiện
        else Thành công
            TGT-->>CAMEL: Dữ liệu thô
            CAMEL->>CAMEL: Chuẩn hóa về CDM
            CAMEL->>MDM: Làm giàu (đối chiếu dữ liệu chủ)
            MDM-->>CAMEL: Dữ liệu đã làm giàu
            CAMEL->>CACHE: Lưu cache (TTL theo loại dữ liệu)
        end
    end

    CAMEL->>CAMEL: Che dữ liệu nhạy cảm<br/>theo quyền của bên gọi
    CAMEL--)AUD: Ghi vết bất đồng bộ (wireTap)
    CAMEL-->>GW: Phản hồi CDM
    GW-->>SRC: 200 OK + dữ liệu
```

### Thuyết minh F-03

**Bốn chốt kiểm soát trước khi chạm dữ liệu.** Yêu cầu phải vượt qua: hạn mức (bước 3) → xác thực (bước 5) → kiểm tra schema (bước 10) → ủy quyền (bước 11). Thứ tự này cố ý: các kiểm tra rẻ tiền đặt trước để loại bỏ yêu cầu xấu sớm, tiết kiệm tài nguyên cho yêu cầu hợp lệ.

**Cache — yếu tố quyết định hiệu năng.** Thời gian sống của cache đặt theo bản chất dữ liệu:

| Loại dữ liệu | TTL | Lý do |
|---|---|---|
| Danh mục dùng chung (mã đơn vị hành chính, ngành nghề) | 24 giờ | Gần như bất biến |
| Dữ liệu chủ (thông tin công dân, doanh nghiệp) | 15 phút | Thay đổi chậm, cần độ tươi vừa phải |
| Dữ liệu giao dịch (trạng thái hồ sơ) | Không cache | Phải luôn chính xác thời điểm |

Với tỷ lệ trúng cache 70%, độ trễ trung bình giảm khoảng 60% và tải lên các HTTT cung cấp giảm tương ứng — đặc biệt quan trọng với hệ thống cũ có năng lực xử lý hạn chế.

**Che dữ liệu theo ngữ cảnh (bước 24).** Cùng một API, hai bên gọi khác nhau nhận mức chi tiết khác nhau. Ví dụ tra cứu công dân: cơ quan y tế thấy đầy đủ, đơn vị chỉ cần xác minh danh tính chỉ thấy họ tên và năm sinh, các trường còn lại bị che. Quy tắc che định nghĩa trong OPA, áp dụng ở tầng Camel — bên cung cấp dữ liệu không cần biết đến logic này.

**Ghi vết bất đồng bộ (bước 25).** Dùng `wireTap` của Camel: bản tin được sao chép sang nhánh ghi vết chạy song song, đường phản hồi chính không phải chờ. Ghi vết vẫn đầy đủ (CMP-28) nhưng không tính vào độ trễ người dùng cảm nhận.

**Ngân sách độ trễ mục tiêu:**

| Chặng | Ngân sách |
|---|---|
| Gateway (TLS, WAF, xác thực) | ≤ 20ms |
| Kiểm tra quyền OPA | ≤ 10ms |
| Tra cache (khi trúng) | ≤ 10ms |
| Gọi HTTT cung cấp (khi trượt cache) | ≤ 500ms |
| Chuẩn hóa + làm giàu | ≤ 50ms |
| **Tổng P95** | **≤ 1s** |

---

## F-04 — Khai thác dữ liệu từ CSDL Quốc gia qua NDXP

**Mục đích.** Khai thác dữ liệu từ các CSDLQG (Dân cư, Đăng ký doanh nghiệp, BHXH, Đất đai…) thông qua trục quốc gia NDXP/NGSP.

**Đặc thù so với F-03.** Phải tuân thủ TT 13/2017: định dạng bản tin riêng, **chữ ký số bắt buộc**, xác thực hai chiều với NDXP. LGSP là điểm kết nối duy nhất — HTTT nội bộ không được gọi thẳng NDXP.

```mermaid
sequenceDiagram
    autonumber
    participant SRC as HTTT nội bộ
    participant GW as APISIX Gateway
    participant CAMEL as Camel Runtime
    participant OPA as OPA
    participant CACHE as Cache
    participant VAULT as Vault (HSM)
    participant ADP as NDXP Adapter
    participant NDXP as NDXP / NGSP
    participant CSDLQG as CSDL Quốc gia
    participant AUD as Audit Log

    SRC->>GW: Yêu cầu tra cứu dữ liệu quốc gia
    GW->>CAMEL: Chuyển tiếp (đã xác thực)
    CAMEL->>OPA: Kiểm quyền khai thác CSDLQG
    OPA-->>CAMEL: Permit (kèm phạm vi trường được xem)

    CAMEL->>CACHE: Tra cache

    alt Cache hit (dữ liệu còn tươi)
        CACHE-->>CAMEL: Trả dữ liệu
    else Cache miss
        CAMEL->>ADP: Chuyển yêu cầu sang adapter chuyên biệt
        ADP->>ADP: Chuyển đổi CDM → định dạng NDXP<br/>(SOAP/XML theo TT 13/2017)
        ADP->>VAULT: Yêu cầu ký số bản tin
        Note over VAULT: Khóa riêng không rời Vault —<br/>thao tác ký thực hiện bên trong
        VAULT-->>ADP: Trả bản tin đã ký

        ADP->>NDXP: Gửi yêu cầu<br/>(mTLS + chữ ký số)
        NDXP->>NDXP: Xác minh chữ ký &<br/>quyền của bộ/tỉnh gọi
        NDXP->>CSDLQG: Truy vấn dữ liệu
        CSDLQG-->>NDXP: Kết quả
        NDXP-->>ADP: Phản hồi đã ký

        ADP->>ADP: Xác minh chữ ký phản hồi
        alt Chữ ký không hợp lệ
            ADP->>AUD: Ghi cảnh báo an ninh
            ADP-->>SRC: 502 — Phản hồi không tin cậy
        end

        ADP->>ADP: Chuyển đổi NDXP → CDM
        ADP-->>CAMEL: Dữ liệu chuẩn hóa
        CAMEL->>CACHE: Lưu cache (TTL 15 phút)
    end

    CAMEL->>CAMEL: Lọc trường theo phạm vi được duyệt
    CAMEL--)AUD: Ghi vết khai thác CSDLQG<br/>(bắt buộc, chi tiết)
    CAMEL-->>SRC: Trả dữ liệu
```

### Thuyết minh F-04

**Vì sao cần adapter chuyên biệt.** NDXP quy định định dạng bản tin cứng theo TT 13/2017 — không thương lượng được. Nếu để logic chuyển đổi này rải rác trong các route nghiệp vụ, mỗi lần trung ương thay đổi đặc tả sẽ phải sửa hàng chục nơi. NDXP Adapter cô lập toàn bộ đặc thù đó: các route nghiệp vụ chỉ làm việc với CDM, không biết NDXP tồn tại.

**Ký số trong ranh giới bảo mật (bước 10-11).** Khóa riêng của bộ/tỉnh dùng ký bản tin gửi NDXP là tài sản nhạy cảm bậc nhất. Thiết kế này gửi **bản tin vào Vault để ký** thay vì lấy khóa ra ngoài — kể cả khi pod ứng dụng bị chiếm quyền, kẻ tấn công không lấy được khóa, chỉ có thể yêu cầu ký trong thời gian còn giữ được quyền, và mọi yêu cầu ký đều bị ghi vết.

**Xác minh chữ ký hai chiều (bước 17).** Không chỉ LGSP ký khi gửi — phản hồi từ NDXP cũng phải được xác minh chữ ký trước khi tin dùng. Bỏ qua bước này tạo lỗ hổng cho tấn công xen giữa. Chữ ký sai được xử lý như sự cố an ninh, không phải lỗi kỹ thuật thông thường.

**Cache có ý nghĩa đặc biệt ở luồng này.** Các CSDLQG thường áp hạn mức truy vấn cho từng bộ/tỉnh. Cache 15 phút cho dữ liệu công dân giúp tránh chạm hạn mức trong giờ cao điểm — khi hàng nghìn hồ sơ dịch vụ công cùng tra cứu một số ít công dân. Đây là biện pháp thiết yếu chứ không phải tối ưu tùy chọn.

**Ghi vết chi tiết hơn luồng nội bộ.** Khai thác dữ liệu quốc gia phải ghi: ai gọi, tra cứu về ai, mục đích (hồ sơ nào), thời điểm, kết quả. Đây là yêu cầu truy vết của Luật Dữ liệu 2024 và cũng là căn cứ giải trình khi có khiếu nại về sử dụng dữ liệu cá nhân.

---

## F-05 — Đồng bộ dữ liệu bất đồng bộ theo sự kiện

**Mục đích.** Khi dữ liệu ở một HTTT thay đổi, tự động lan truyền tới các HTTT quan tâm mà không cần chúng liên tục hỏi.

**Khi nào dùng.** Đồng bộ khối lượng lớn, thông báo thay đổi, các trường hợp không cần phản hồi tức thì.

```mermaid
sequenceDiagram
    autonumber
    participant SRCDB as CSDL hệ thống nguồn
    participant CDC as Debezium CDC
    participant KAFKA as Kafka
    participant SR as Schema Registry
    participant CAMEL as Camel Consumer
    participant DQ as Data Quality
    participant MDM as MDM Service
    participant SUB1 as HTTT đăng ký 1
    participant SUB2 as HTTT đăng ký 2
    participant DLQ as Dead Letter Queue

    Note over SRCDB,CDC: Hệ thống nguồn KHÔNG cần sửa mã

    SRCDB->>SRCDB: Giao dịch: thêm/sửa/xóa bản ghi
    CDC->>SRCDB: Đọc nhật ký giao dịch (WAL/binlog)
    CDC->>SR: Đăng ký/kiểm tra schema sự kiện
    SR-->>CDC: Xác nhận tương thích
    CDC->>KAFKA: Phát sự kiện thay đổi<br/>(topic theo miền dữ liệu)

    KAFKA->>CAMEL: Tiêu thụ sự kiện
    CAMEL->>CAMEL: Chuẩn hóa về CDM
    CAMEL->>DQ: Kiểm tra chất lượng dữ liệu

    alt Dữ liệu không đạt chuẩn
        DQ-->>CAMEL: Không đạt + chi tiết lỗi
        CAMEL->>DLQ: Đẩy vào hàng đợi lỗi
        CAMEL->>CAMEL: Phát cảnh báo cho chủ quản nguồn
    else Dữ liệu đạt chuẩn
        DQ-->>CAMEL: Đạt
        CAMEL->>MDM: Cập nhật bản ghi vàng
        MDM->>MDM: Đối sánh thực thể,<br/>giải quyết xung đột nguồn
        MDM-->>CAMEL: Xác nhận

        par Phát tán song song tới các bên đăng ký
            CAMEL->>SUB1: Đẩy sự kiện (webhook/API)
            SUB1-->>CAMEL: ACK
        and
            CAMEL->>SUB2: Đẩy sự kiện
            SUB2-->>CAMEL: ACK
        end

        alt Bên đăng ký không phản hồi
            CAMEL->>CAMEL: Thử lại theo backoff<br/>(1p → 5p → 30p → 2h)
            CAMEL->>DLQ: Sau 4 lần thất bại
        end
    end
```

### Thuyết minh F-05

**Debezium giải bài toán hệ thống cũ.** Điểm mấu chốt ở bước 2-3: CDC đọc **nhật ký giao dịch** của CSDL, không truy vấn bảng và không cần trigger. Hệ quả: hệ thống nguồn hoàn toàn không biết mình đang bị theo dõi, không chịu thêm tải, không phải sửa một dòng mã. Đây thường là con đường khả thi duy nhất để đưa các HTTT cũ — vốn không có API và không còn nhà thầu bảo trì — lên trục.

**Schema Registry ngăn sự cố lan rộng.** Khi chủ quản hệ thống nguồn đổi cấu trúc bảng, Apicurio kiểm tra tương thích trước khi cho phép phát sự kiện. Thay đổi phá vỡ tương thích bị chặn ngay tại nguồn thay vì làm hỏng hàng loạt bên tiêu thụ ở hạ nguồn.

**Mô hình xuất bản – đăng ký.** Bên phát không biết ai đang nghe. Thêm một sở mới muốn nhận thông báo thay đổi dữ liệu dân cư chỉ cần đăng ký vào topic — không sửa gì ở phía nguồn, không phải thông báo cho ai. Đây là điều kiện để trục mở rộng mà không tăng độ phức tạp (NT-08).

**Bảo đảm giao nhận.** Kafka cấu hình `acks=all` với `min.insync.replicas=2`, Camel commit offset chỉ sau khi xử lý thành công. Kết quả là **at-least-once**: sự kiện không bao giờ mất, nhưng có thể lặp. Vì vậy các bên tiêu thụ **bắt buộc** xử lý idempotent — dùng khóa nghiệp vụ để nhận biết sự kiện đã xử lý. Yêu cầu này ghi rõ trong tài liệu kết nạp HTTT thành viên.

**Thứ tự sự kiện.** Kafka chỉ bảo đảm thứ tự trong cùng một phân vùng. Do đó khóa phân vùng chọn theo **định danh thực thể** (số định danh công dân, mã doanh nghiệp) — mọi thay đổi của cùng một công dân luôn vào cùng phân vùng, giữ đúng trình tự. Chọn sai khóa phân vùng sẽ gây hiện tượng cập nhật cũ ghi đè cập nhật mới.

---

## F-06 — Liên thông văn bản điện tử

**Mục đích.** Gửi/nhận văn bản điện tử giữa các cơ quan trong bộ/tỉnh và liên thông ra trục quốc gia.

```mermaid
sequenceDiagram
    autonumber
    actor SENDER as Cán bộ<br/>cơ quan gửi
    participant QLVB_S as HT Quản lý VB<br/>(bên gửi)
    participant CAMEL as Camel Runtime
    participant VAULT as Vault (ký số)
    participant MINIO as MinIO<br/>(lưu tệp đính kèm)
    participant KAFKA as Kafka
    participant QLVB_R as HT Quản lý VB<br/>(bên nhận)
    participant NDXP as NDXP<br/>(nếu liên thông ngoài)
    participant AUD as Audit Log

    SENDER->>QLVB_S: Phát hành văn bản
    QLVB_S->>CAMEL: Gửi văn bản + tệp đính kèm

    CAMEL->>CAMEL: Kiểm tra cấu trúc bản tin<br/>theo chuẩn liên thông văn bản
    CAMEL->>CAMEL: Kiểm tra: kích thước tệp,<br/>định dạng cho phép, quét mã độc

    alt Không hợp lệ
        CAMEL-->>QLVB_S: Từ chối + lý do cụ thể
    end

    CAMEL->>MINIO: Lưu tệp đính kèm<br/>(mã hóa at-rest)
    MINIO-->>CAMEL: Trả URI tham chiếu
    Note over CAMEL,MINIO: Bản tin chỉ mang URI,<br/>không nhúng tệp — tránh nghẽn

    CAMEL->>VAULT: Ký số văn bản
    VAULT-->>CAMEL: Văn bản đã ký

    alt Bên nhận trong nội bộ bộ/tỉnh
        CAMEL->>KAFKA: Phát vào topic văn bản
        KAFKA->>QLVB_R: Đẩy tới bên nhận
        QLVB_R->>MINIO: Tải tệp theo URI<br/>(kiểm quyền trước khi cho tải)
        QLVB_R-->>CAMEL: Biên nhận (ACK)
    else Bên nhận ngoài bộ/tỉnh
        CAMEL->>NDXP: Chuyển tiếp qua trục quốc gia
        NDXP-->>CAMEL: Biên nhận
    end

    CAMEL->>QLVB_S: Cập nhật trạng thái: ĐÃ NHẬN
    CAMEL--)AUD: Ghi vết luân chuyển văn bản

    alt Bên nhận không phản hồi trong 24h
        CAMEL->>CAMEL: Nhắc lại tự động
        CAMEL->>SENDER: Cảnh báo văn bản chưa được nhận
    end
```

### Thuyết minh F-06

**Tách tệp đính kèm khỏi bản tin (bước 7-9).** Văn bản hành chính thường kèm tệp quét nặng hàng chục MB. Nếu nhúng trực tiếp vào bản tin, Kafka sẽ nghẽn và bộ nhớ các pod bị đẩy lên cao. Giải pháp là mẫu **Claim Check** của EIP: tệp lưu ở MinIO, bản tin chỉ mang URI tham chiếu. Bên nhận tự tải khi cần, có kiểm tra quyền tại thời điểm tải.

**Quét mã độc là bắt buộc (bước 5).** Văn bản đính kèm là véc-tơ lây nhiễm phổ biến trong mạng cơ quan nhà nước. Camel gọi ClamAV qua tích hợp, tệp nhiễm bị chặn ngay tại trục — không lan sang cơ quan nhận.

**Biên nhận và cơ chế nhắc.** Văn bản hành chính có giá trị pháp lý nên phải xác nhận đã nhận. Cơ chế nhắc tự động sau 24 giờ giải quyết tình huống hệ thống bên nhận gặp sự cố mà không ai biết — vấn đề thường gặp trong thực tế vận hành.

---

## F-07 — Giải quyết thủ tục hành chính liên thông

**Mục đích.** Điều phối một thủ tục hành chính cần nhiều cơ quan xử lý tuần tự hoặc song song.

**Đặc điểm.** Quy trình dài (ngày đến tháng), có tác vụ con người, cần lưu trạng thái bền vững → dùng BPMN thay vì Camel route thuần.

**Ví dụ minh họa.** Đăng ký khai sinh liên thông: khai sinh → nhập hộ khẩu → cấp thẻ BHYT trẻ em.

```mermaid
sequenceDiagram
    autonumber
    actor CITIZEN as Công dân
    participant DVC as Cổng Dịch vụ công
    participant CAMEL as Camel Runtime
    participant BPM as Flowable (BPMN)
    participant TP as HT Tư pháp<br/>(khai sinh)
    participant CA as HT Công an<br/>(hộ khẩu)
    participant BH as HT BHXH<br/>(thẻ BHYT)
    participant SAGA as Saga Coordinator
    participant NOTI as Dịch vụ thông báo

    CITIZEN->>DVC: Nộp hồ sơ khai sinh liên thông
    DVC->>CAMEL: Gửi hồ sơ
    CAMEL->>BPM: Khởi tạo quy trình BPMN<br/>(processInstanceId)
    BPM-->>CAMEL: Trả mã hồ sơ
    CAMEL-->>CITIZEN: Biên nhận + mã tra cứu

    Note over BPM: BƯỚC 1 — ĐĂNG KÝ KHAI SINH
    BPM->>CAMEL: Tác vụ: gửi Tư pháp
    CAMEL->>TP: Yêu cầu đăng ký khai sinh
    TP->>TP: Cán bộ thẩm định (tác vụ người dùng)
    TP-->>CAMEL: Kết quả + số định danh trẻ
    CAMEL->>BPM: Hoàn thành bước 1
    CAMEL->>NOTI: Thông báo tiến độ
    NOTI-->>CITIZEN: SMS/Email: đã có giấy khai sinh

    Note over BPM: BƯỚC 2 & 3 — SONG SONG
    par Nhập hộ khẩu
        BPM->>CAMEL: Tác vụ: gửi Công an
        CAMEL->>CA: Yêu cầu nhập hộ khẩu
        CA-->>CAMEL: Kết quả
        CAMEL->>BPM: Hoàn thành bước 2
    and Cấp thẻ BHYT
        BPM->>CAMEL: Tác vụ: gửi BHXH
        CAMEL->>BH: Yêu cầu cấp thẻ BHYT
        BH-->>CAMEL: Kết quả
        CAMEL->>BPM: Hoàn thành bước 3
    end

    alt Một nhánh thất bại
        CAMEL->>SAGA: Kích hoạt bù trừ
        SAGA->>TP: Hủy/đánh dấu khai sinh chờ xử lý
        SAGA->>CA: Hoàn tác nhập hộ khẩu (nếu đã thực hiện)
        SAGA->>NOTI: Thông báo cần bổ sung
        NOTI-->>CITIZEN: Hướng dẫn khắc phục
    else Tất cả thành công
        BPM->>CAMEL: Quy trình hoàn tất
        CAMEL->>NOTI: Thông báo kết quả cuối
        NOTI-->>CITIZEN: Hoàn tất — nhận kết quả
    end
```

### Thuyết minh F-07

**Vì sao BPMN chứ không phải Camel route.** Quy trình này kéo dài nhiều ngày và có tác vụ chờ cán bộ xử lý. Camel route là stateless, sống trong bộ nhớ — pod khởi động lại là mất. Flowable ghi trạng thái quy trình xuống PostgreSQL sau mỗi bước, nên quy trình sống sót qua mọi sự cố hạ tầng và có thể tiếp tục đúng chỗ đang dở.

**Phân vai rõ ràng.** Flowable quyết định **"làm gì tiếp theo"** (logic nghiệp vụ, điều kiện rẽ nhánh, song song, chờ đợi); Camel thực hiện **"làm bằng cách nào"** (gọi hệ thống nào, giao thức gì, chuyển đổi ra sao). Ranh giới này giữ cho quy trình nghiệp vụ đọc được bởi người làm nghiệp vụ, còn chi tiết kỹ thuật nằm gọn ở tầng tích hợp.

**Saga — nhất quán không cần giao dịch phân tán.** Không thể dùng giao dịch hai pha (2PC) trên các hệ thống độc lập của nhiều cơ quan. Mẫu Saga giải bằng cách: mỗi bước có một **hành động bù trừ** tương ứng. Nếu bước cấp thẻ BHYT thất bại, Saga Coordinator lần ngược gọi các hành động bù trừ của những bước đã hoàn tất. Trạng thái cuối cùng nhất quán, dù trải qua giai đoạn trung gian không nhất quán.

| Bước xuôi | Hành động bù trừ |
|---|---|
| Đăng ký khai sinh | Đánh dấu hồ sơ chờ xử lý (không xóa — văn bản đã có giá trị pháp lý) |
| Nhập hộ khẩu | Hoàn tác bản ghi nhập khẩu |
| Cấp thẻ BHYT | Hủy thẻ đã cấp |

Lưu ý về bù trừ khai sinh: không xóa mà chỉ đánh dấu, vì giấy khai sinh đã phát hành là văn bản pháp lý. Đây là ví dụ cho thấy hành động bù trừ phải do **nghiệp vụ** định nghĩa, không suy ra máy móc từ hành động xuôi.

**Thông báo tiến độ liên tục.** Người dân được thông báo sau mỗi bước hoàn thành thay vì chỉ biết kết quả cuối. Yêu cầu này hiện thực tinh thần "lấy người dân làm trung tâm" của Khung Kiến trúc CPĐT 3.0.

---

## F-08 — Xác thực người dùng qua VNeID / SSO

**Mục đích.** Đăng nhập một lần, dùng chung cho mọi ứng dụng trên trục; liên kết với nền tảng định danh quốc gia VNeID.

**Căn cứ.** CV 631 (SSO, SAML2, OIDC, MFA → CMP-06, CMP-07); QĐ 1729 bổ sung nền tảng định danh điện tử (CMP-27).

```mermaid
sequenceDiagram
    autonumber
    actor USER as Người dùng
    participant APP as Ứng dụng<br/>(DVC / QLVB)
    participant GW as APISIX Gateway
    participant KC as Keycloak
    participant VNEID as VNeID<br/>(định danh quốc gia)
    participant MFA as Kênh MFA<br/>(TOTP/WebAuthn)
    participant AUD as Audit Log

    USER->>APP: Truy cập tài nguyên cần đăng nhập
    APP->>GW: Yêu cầu không có phiên hợp lệ
    GW-->>APP: Chuyển hướng tới Keycloak
    APP-->>USER: Hiển thị trang đăng nhập

    alt Đăng nhập bằng tài khoản nội bộ
        USER->>KC: Nhập tài khoản + mật khẩu
        KC->>KC: Xác minh thông tin
        KC->>MFA: Yêu cầu yếu tố thứ hai
        MFA-->>USER: Nhắc nhập mã / chạm khóa
        USER->>MFA: Cung cấp yếu tố thứ hai
        MFA-->>KC: Xác nhận
    else Đăng nhập bằng VNeID
        USER->>KC: Chọn "Đăng nhập bằng VNeID"
        KC->>VNEID: Chuyển hướng OIDC<br/>(authorization request)
        VNEID-->>USER: Xác thực trên ứng dụng VNeID
        USER->>VNEID: Xác nhận danh tính
        VNEID-->>KC: Mã ủy quyền (authorization code)
        KC->>VNEID: Đổi mã lấy token
        VNEID-->>KC: ID token + thông tin định danh
        KC->>KC: Liên kết danh tính VNeID<br/>với tài khoản trên trục
    end

    KC->>KC: Sinh phiên SSO
    KC-->>APP: Trả mã ủy quyền
    APP->>KC: Đổi mã lấy token
    KC-->>APP: Access token (JWT) + Refresh token
    KC--)AUD: Ghi vết đăng nhập

    APP->>GW: Gọi API kèm Bearer token
    GW->>GW: Xác minh chữ ký JWT<br/>(khóa công khai từ JWKS)
    GW-->>APP: Cho phép truy cập
    APP-->>USER: Hiển thị nội dung

    Note over USER,KC: Ứng dụng thứ hai — không phải đăng nhập lại
    USER->>APP: Mở ứng dụng khác trên trục
    APP->>KC: Kiểm tra phiên SSO
    KC-->>APP: Phiên còn hiệu lực → cấp token mới
```

### Thuyết minh F-08

**Keycloak làm cầu nối định danh.** Keycloak vừa là nhà cung cấp định danh cho các ứng dụng nội bộ, vừa là bên tin cậy (relying party) của VNeID. Cách bố trí này cho phép thêm nguồn định danh mới (chứng thư số, tài khoản của bộ ngành khác) mà **không ứng dụng nào phải sửa mã** — tất cả đều chỉ nói chuyện với Keycloak.

**Vòng đời token — cân bằng an toàn và trải nghiệm:**

| Loại token | Thời hạn | Lý do |
|---|---|---|
| Access token | 5 phút | Ngắn để giảm thiệt hại nếu rò rỉ |
| Refresh token | 8 giờ | Đủ một ca làm việc, không phải đăng nhập lại |
| Phiên SSO | 8 giờ (nghỉ 30 phút thì hết) | Cân bằng tiện dụng và an toàn |

**Xác thực token không cần gọi Keycloak (bước 25).** APISIX xác minh chữ ký JWT bằng khóa công khai lấy từ điểm cuối JWKS và lưu cache. Nghĩa là mỗi lời gọi API **không** phát sinh một lượt hỏi Keycloak — Keycloak không trở thành nút thắt cổ chai, và sự cố tạm thời của Keycloak không làm sập toàn bộ trục (token đang hiệu lực vẫn dùng được).

**MFA bắt buộc theo mức nhạy cảm.** Không áp dụng máy móc cho mọi người dùng: tra cứu dữ liệu công khai chỉ cần một yếu tố; truy cập dữ liệu công dân, thao tác quản trị và mọi hành vi ghi dữ liệu bắt buộc hai yếu tố. Chính sách phân tầng này định nghĩa trong Keycloak Authentication Flow.

---

## F-09 — Quản lý dữ liệu chủ và đối sánh thực thể

**Mục đích.** Tạo và duy trì bản ghi vàng cho các thực thể cốt lõi (công dân, doanh nghiệp, đơn vị) từ nhiều nguồn dữ liệu khác nhau.

**Căn cứ.** NĐ 47/2020 — dữ liệu chủ (CMP-20).

```mermaid
sequenceDiagram
    autonumber
    participant SRC1 as Nguồn A<br/>(HT Y tế)
    participant SRC2 as Nguồn B<br/>(HT Giáo dục)
    participant SRC3 as CSDLQG Dân cư<br/>(qua NDXP)
    participant CAMEL as Camel Runtime
    participant MDM as MDM Service
    participant MATCH as Match Engine
    participant GOLD as Golden Record Store
    actor STEWARD as Cán bộ quản trị<br/>dữ liệu

    par Thu nhận từ nhiều nguồn
        SRC1->>CAMEL: Bản ghi công dân (nguồn A)
    and
        SRC2->>CAMEL: Bản ghi công dân (nguồn B)
    and
        SRC3->>CAMEL: Bản ghi công dân (CSDLQG)
    end

    CAMEL->>CAMEL: Chuẩn hóa về CDM<br/>(định dạng tên, ngày, địa chỉ)
    CAMEL->>MDM: Nộp bản ghi ứng viên
    MDM->>MATCH: Đối sánh thực thể

    MATCH->>MATCH: Đối sánh xác định:<br/>trùng số định danh cá nhân

    alt Trùng khớp xác định (điểm = 1.0)
        MATCH-->>MDM: Cùng một thực thể
    else Không có số định danh
        MATCH->>MATCH: Đối sánh xác suất:<br/>họ tên + ngày sinh + địa chỉ<br/>(thuật toán fuzzy)

        alt Điểm ≥ 0.9 — chắc chắn
            MATCH-->>MDM: Tự động hợp nhất
        else Điểm 0.7–0.9 — nghi ngờ
            MATCH->>STEWARD: Chuyển hàng đợi xử lý thủ công
            STEWARD->>STEWARD: Rà soát, quyết định
            STEWARD-->>MDM: Hợp nhất / Tách riêng
        else Điểm < 0.7 — khác nhau
            MATCH-->>MDM: Tạo thực thể mới
        end
    end

    MDM->>MDM: Giải quyết xung đột thuộc tính<br/>theo thứ tự ưu tiên nguồn
    Note over MDM: CSDLQG Dân cư > HT chuyên ngành > nhập tay<br/>Khi cùng mức: dữ liệu mới hơn thắng

    MDM->>GOLD: Ghi bản ghi vàng + lịch sử phiên bản
    GOLD-->>MDM: Xác nhận
    MDM->>CAMEL: Phát sự kiện "bản ghi vàng cập nhật"
    CAMEL->>CAMEL: Vô hiệu hóa cache liên quan
```

### Thuyết minh F-09

**Hai chế độ đối sánh.** Số định danh cá nhân là khóa vàng — khi có, đối sánh là xác định, không cần suy đoán. Nhưng dữ liệu cũ thường thiếu số định danh, buộc phải đối sánh xác suất dựa trên tổ hợp họ tên, ngày sinh, địa chỉ với thuật toán so khớp mờ để chịu được sai khác chính tả và dấu tiếng Việt.

**Vùng xám cần con người quyết định.** Khoảng điểm 0,7–0,9 cố ý không tự động hóa. Hợp nhất sai hai công dân khác nhau gây hậu quả nghiêm trọng — hồ sơ y tế, quyền lợi bảo hiểm bị trộn lẫn. Chi phí một lượt rà soát thủ công rẻ hơn nhiều so với chi phí khắc phục một lần hợp nhất sai.

**Thứ tự ưu tiên nguồn — chính sách chứ không phải kỹ thuật.** Khi nguồn A ghi "Nguyễn Văn A" và CSDLQG ghi "Nguyễn Văn Á", chọn giá trị nào? Nguyên tắc: nguồn có thẩm quyền pháp lý cao hơn thắng. CSDLQG Dân cư là nguồn xác thực về nhân thân, nên luôn được ưu tiên. Thứ tự này phải được lãnh đạo phê duyệt, không do đội kỹ thuật tự quyết.

**Lịch sử phiên bản bắt buộc.** Mọi thay đổi bản ghi vàng lưu lại phiên bản cũ. Khi phát hiện hợp nhất sai, có thể tách ngược. Không có lịch sử thì sai lầm là vĩnh viễn.

---

## F-10 — Xử lý lỗi và phát lại bản tin

**Mục đích.** Bảo đảm không mất bản tin khi có sự cố, và có công cụ xử lý bản tin lỗi.

```mermaid
sequenceDiagram
    autonumber
    participant CAMEL as Camel Route
    participant TGT as Hệ thống đích
    participant CB as Circuit Breaker
    participant DLQ as Dead Letter Queue
    participant ALERT as Cảnh báo
    actor OPS as Cán bộ vận hành
    participant REPLAY as Replay Service

    CAMEL->>TGT: Gửi bản tin

    alt Lỗi tạm thời (mạng chập chờn, timeout)
        TGT-->>CAMEL: Lỗi
        loop Tối đa 3 lần, backoff nhân đôi
            CAMEL->>CAMEL: Chờ (1s → 2s → 4s)
            CAMEL->>TGT: Thử lại
        end

        alt Thành công ở lần thử lại
            TGT-->>CAMEL: OK
            Note over CAMEL: Kết thúc bình thường
        else Vẫn thất bại
            CAMEL->>DLQ: Đẩy vào hàng đợi lỗi<br/>(kèm ngữ cảnh đầy đủ)
        end

    else Hệ thống đích hỏng kéo dài
        CB->>CB: Tỷ lệ lỗi > 50%/20 lời gọi<br/>→ MỞ MẠCH
        Note over CB: Ngừng gọi trong 30s —<br/>bảo vệ cả hai phía
        CAMEL->>DLQ: Đẩy trực tiếp, không thử vô ích
        CB->>ALERT: Cảnh báo mức NGHIÊM TRỌNG
        ALERT-->>OPS: Gọi trực

        Note over CB: Sau 30s → BÁN MỞ
        CB->>TGT: Thử một lời gọi thăm dò
        alt Thành công
            CB->>CB: ĐÓNG MẠCH — hoạt động lại
        else Vẫn lỗi
            CB->>CB: MỞ tiếp 30s
        end

    else Lỗi nghiệp vụ (dữ liệu sai)
        TGT-->>CAMEL: 400 — dữ liệu không hợp lệ
        Note over CAMEL: KHÔNG thử lại —<br/>thử lại cũng vô ích
        CAMEL->>DLQ: Đẩy kèm chi tiết lỗi
        CAMEL->>ALERT: Cảnh báo chủ quản dữ liệu nguồn
    end

    OPS->>DLQ: Xem danh sách bản tin lỗi
    OPS->>OPS: Phân tích nguyên nhân
    alt Đã khắc phục nguyên nhân
        OPS->>REPLAY: Yêu cầu phát lại (đơn lẻ / hàng loạt)
        REPLAY->>CAMEL: Đưa bản tin vào lại luồng
        CAMEL->>TGT: Xử lý lại
    else Bản tin không thể xử lý
        OPS->>DLQ: Đánh dấu bỏ qua + ghi lý do
    end
```

### Thuyết minh F-10

**Phân loại lỗi quyết định cách xử lý.** Đây là điểm cốt lõi của luồng này:

| Loại lỗi | Ví dụ | Chiến lược | Vì sao |
|---|---|---|---|
| **Tạm thời** | Timeout, mất gói, 503 | Thử lại có backoff | Có khả năng tự khỏi |
| **Kéo dài** | Hệ thống đích sập | Ngắt mạch + cảnh báo | Thử lại chỉ làm hại thêm |
| **Nghiệp vụ** | Dữ liệu sai định dạng | **Không thử lại**, chuyển DLQ | Thử lại 1000 lần vẫn sai |

Nhầm lẫn ba loại này là lỗi thiết kế phổ biến: thử lại lỗi nghiệp vụ gây lãng phí và làm nhiễu cảnh báo; không thử lại lỗi tạm thời gây mất bản tin không đáng có.

**Circuit breaker bảo vệ cả hai phía.** Khi hệ thống đích quá tải, việc tiếp tục gửi yêu cầu khiến nó càng khó phục hồi. Ngắt mạch cho hệ thống đích "thở" đồng thời giải phóng luồng xử lý ở phía LGSP — ngăn hiệu ứng domino lan sang các luồng khác đang khỏe mạnh (NT-08).

**DLQ phải chứa đủ ngữ cảnh.** Bản tin trong DLQ đi kèm: nội dung gốc, traceId, thời điểm, thông báo lỗi đầy đủ, số lần đã thử, tên route. Thiếu bất kỳ thông tin nào trong số này thì cán bộ vận hành không thể chẩn đoán, và bản tin lỗi trở thành rác không xử lý được.

**Phát lại phải idempotent.** Vì bản tin có thể đã được xử lý một phần trước khi lỗi, thao tác phát lại phải an toàn khi lặp. Đây là lý do yêu cầu idempotent với mọi bên tiêu thụ đã nêu ở F-05.

---

## F-11 — Đánh giá chất lượng dữ liệu định kỳ

**Mục đích.** Thực hiện nghĩa vụ kiểm tra, đánh giá chất lượng dữ liệu định kỳ hằng năm.

**Căn cứ.** NĐ 47/2020 (CMP-22).

```mermaid
sequenceDiagram
    autonumber
    participant SCHED as Bộ lập lịch<br/>(CronJob)
    participant DQ as Data Quality Service
    participant RULES as Kho luật kiểm tra
    participant GOLD as Golden Record Store
    participant RDM as Reference Data
    participant REPORT as Báo cáo
    actor OWNER as Chủ quản CSDL
    actor LEADER as Lãnh đạo

    SCHED->>DQ: Kích hoạt đánh giá định kỳ
    DQ->>RULES: Nạp bộ luật theo từng miền dữ liệu
    RULES-->>DQ: Danh sách luật

    loop Với từng miền dữ liệu
        DQ->>GOLD: Lấy mẫu / quét toàn bộ

        par Sáu chiều chất lượng
            DQ->>DQ: Đầy đủ — trường bắt buộc có giá trị?
        and
            DQ->>DQ: Chính xác — đúng định dạng, đúng miền?
        and
            DQ->>DQ: Nhất quán — các nguồn có mâu thuẫn?
        and
            DQ->>DQ: Kịp thời — dữ liệu còn tươi?
        and
            DQ->>DQ: Duy nhất — có bản ghi trùng?
        and
            DQ->>RDM: Hợp lệ — mã danh mục có tồn tại?
        end

        DQ->>DQ: Tính điểm tổng hợp theo trọng số
    end

    DQ->>REPORT: Sinh báo cáo chất lượng
    REPORT->>REPORT: Tổng hợp:<br/>· Điểm theo miền dữ liệu<br/>· Danh sách bản ghi lỗi<br/>· So sánh với kỳ trước<br/>· Khuyến nghị khắc phục

    REPORT-->>OWNER: Gửi chủ quản từng CSDL
    REPORT-->>LEADER: Báo cáo tổng hợp toàn bộ/tỉnh

    OWNER->>OWNER: Lập kế hoạch khắc phục
    OWNER->>DQ: Cập nhật dữ liệu đã sửa
    DQ->>DQ: Đánh giá lại, ghi nhận cải thiện
```

### Thuyết minh F-11

**Đánh giá liên tục thay vì chỉ mỗi năm một lần.** Quy định yêu cầu tối thiểu hằng năm, nhưng thiết kế này chạy đánh giá hằng tháng và báo cáo chính thức hằng năm. Lý do thực tiễn: phát hiện suy giảm chất lượng sớm rẻ hơn nhiều so với sửa chữa sau một năm tích lũy lỗi.

**Điểm chất lượng có trọng số theo mức quan trọng.** Không phải mọi trường đều ngang nhau — thiếu số định danh cá nhân nghiêm trọng hơn thiếu số điện thoại. Trọng số do chủ quản dữ liệu xác lập dựa trên tác động nghiệp vụ.

**Báo cáo hướng hành động.** Báo cáo không chỉ nêu "chất lượng đạt 82%" mà phải chỉ rõ: bản ghi nào lỗi, lỗi gì, nguồn nào gây ra, cách khắc phục. Báo cáo không kèm khuyến nghị cụ thể sẽ nằm im trong ngăn kéo.

---

## F-12 — Giám sát và cảnh báo vận hành

**Mục đích.** Phát hiện sớm sự cố và bảo đảm khả năng chẩn đoán trên hệ thống phân tán.

**Căn cứ.** CV 631 — giám sát, thống kê, báo cáo, phân tích nghiệp vụ thời gian thực (CMP-10).

```mermaid
sequenceDiagram
    autonumber
    participant COMP as Các thành phần<br/>(Camel, APISIX, Flowable...)
    participant OTEL as OTel Collector
    participant PROM as Prometheus
    participant LOKI as Loki
    participant TEMPO as Tempo
    participant AM as Alertmanager
    participant GRAF as Grafana
    actor OPS as Cán bộ trực vận hành
    actor MGR as Lãnh đạo

    loop Liên tục
        COMP--)OTEL: Phát metrics, logs, traces<br/>(giao thức OTLP, kèm traceId)
    end

    OTEL->>OTEL: Lọc nhiễu · Làm giàu nhãn<br/>Lấy mẫu trace (giữ 100% trace lỗi)
    OTEL->>PROM: Chỉ số
    OTEL->>LOKI: Nhật ký
    OTEL->>TEMPO: Vết truy nguyên

    PROM->>PROM: Đánh giá luật cảnh báo

    alt Ngưỡng NGHIÊM TRỌNG<br/>(lỗi > 5% trong 5 phút)
        PROM->>AM: Kích hoạt cảnh báo
        AM->>AM: Gom nhóm, chống trùng lặp,<br/>áp lịch trực
        AM-->>OPS: Gọi ngay (điện thoại/chat)

        OPS->>GRAF: Mở dashboard sự cố
        GRAF->>PROM: Truy vấn chỉ số
        GRAF->>LOKI: Truy vấn nhật ký theo traceId
        GRAF->>TEMPO: Xem vết truy nguyên đầy đủ
        Note over OPS,TEMPO: Ba nguồn liên kết bằng traceId —<br/>chẩn đoán nhanh chặng nào lỗi

        OPS->>OPS: Xác định nguyên nhân, xử lý
        OPS->>AM: Xác nhận đã xử lý

    else Ngưỡng CẢNH BÁO<br/>(P99 > 10s trong 15 phút)
        PROM->>AM: Kích hoạt
        AM-->>OPS: Thông báo (không gọi trực)
    end

    loop Định kỳ
        GRAF->>GRAF: Sinh báo cáo vận hành
        GRAF-->>MGR: Dashboard nghiệp vụ:<br/>lưu lượng theo đơn vị, SLA, xu hướng
    end
```

### Thuyết minh F-12

**traceId là sợi chỉ xuyên suốt.** Giá trị lớn nhất của thiết kế này nằm ở bước 14-16: từ một cảnh báo, cán bộ vận hành lấy traceId của yêu cầu lỗi, rồi dùng chính traceId đó để lọc nhật ký (Loki) và xem toàn bộ hành trình (Tempo). Không phải đoán mò "chắc là do hệ thống X" — thấy chính xác chặng nào chậm, chặng nào lỗi, mất bao lâu.

**Chiến lược lấy mẫu trace.** Lưu 100% trace sẽ tốn dung lượng khổng lồ. Chính sách: giữ **toàn bộ** trace có lỗi hoặc chậm bất thường, lấy mẫu 1–5% trace thành công. Nghịch lý cần tránh: lấy mẫu ngẫu nhiên đều thường bỏ sót đúng những trace cần nhất.

**Cảnh báo dựa trên triệu chứng người dùng, không dựa trên nguyên nhân.** Cảnh báo "CPU 90%" ít giá trị — CPU cao mà người dùng không bị ảnh hưởng thì không phải sự cố. Cảnh báo "tỷ lệ lỗi API vượt 5%" mới đáng gọi trực lúc nửa đêm. Nguyên tắc này giảm mạnh mệt mỏi cảnh báo, giữ cho cán bộ trực nghiêm túc với mỗi lần bị gọi.

**Dashboard nghiệp vụ cho lãnh đạo.** CV 631 yêu cầu "phân tích hoạt động nghiệp vụ" — không chỉ chỉ số kỹ thuật. Dashboard cho lãnh đạo trả lời các câu hỏi quản lý: đơn vị nào dùng trục nhiều nhất, dịch vụ nào có nhu cầu cao, đơn vị nào chưa kết nối, xu hướng tăng trưởng ra sao. Đây là đầu vào cho quyết định đầu tư và điều hành.

---

## Liên kết

- Kiến trúc thành phần → [02-architecture](../02-architecture/README.md)
- Yêu cầu pháp lý tương ứng → [01-legal](../01-legal/README.md)
- Các bước triển khai → [04-deployment](../04-deployment/README.md)
