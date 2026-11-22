---
ma_tai_lieu: D04-01
ten: Quy chuẩn lập trình (Coding convention)
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Dự thảo
nguoi_doc: Đội phát triển backend, frontend, tích hợp; Trưởng nhóm kỹ thuật; Kiểm thử; Đội ATTT; Hội đồng thẩm định
---

# D04-01 · Quy chuẩn lập trình (Coding convention)

## 1. Mục đích, phạm vi và cách dùng

### 1.1. Mục đích

Tài liệu này là bộ luật viết mã nguồn của Datahub. Nó biến các quyết định kiến trúc trong D03-01 (SAD), thiết kế đa tenant trong D03-10, yêu cầu phi chức năng trong D02-02 và các ADR thành những quy tắc cụ thể mà một lập trình viên áp dụng được ngay khi viết một lớp Java, một luồng Camel, một màn React hay một changeset Liquibase. Mỗi quy tắc nêu rõ điều phải làm, lý do và cách máy kiểm tra quy tắc đó; quy tắc nào chưa kiểm tra tự động được thì nêu cách kiểm tra khi review.

Bộ quy chuẩn phục vụ ba mục tiêu. Mục tiêu thứ nhất là **an toàn**: Datahub được thiết kế đạt cấp độ 3 theo Nghị định 331/2026/NĐ-CP và TCVN 14423:2026, trong đó nhóm yêu cầu "phát triển ứng dụng an toàn" là nhóm mới so với cấp độ 2; tài liệu này là bằng chứng chính cho nhóm yêu cầu đó, cùng với kết quả kiểm thử ASVS 5.0 mức 2 (NFR-00-024). Mục tiêu thứ hai là **cách ly tenant**: một dòng mã sai có thể làm lộ dữ liệu của tỉnh này cho tỉnh khác, nên các quy tắc đa tenant được nhắc lại nguyên văn và gắn với kiểm tra tự động. Mục tiêu thứ ba là **bảo trì được lâu dài**: sản phẩm phục vụ nhiều tỉnh trong nhiều năm, đội phát triển sẽ thay đổi, nên mã phải đồng nhất tới mức người mới đọc một module bất kỳ cũng nhận ra cấu trúc quen thuộc.

### 1.2. Phạm vi

Quy chuẩn áp dụng cho toàn bộ mã nguồn trong kho mã Datahub: các đơn vị triển khai (DU) Spring Boot, DU Camel Quarkus (`dh-runtime`), luồng tích hợp viết bằng Camel YAML DSL, Kamelet, giao diện `dh-console` và `dh-portal`, thư viện dùng chung, migration Liquibase, hợp đồng OpenAPI và AsyncAPI, chính sách Rego của OPA, manifest Kustomize và mã kiểm thử. Mã do nhà thầu phụ hoặc tỉnh tự phát triển rồi đóng góp vào kho mã cũng phải tuân thủ. Quy trình làm việc với Git, review, cổng chất lượng CI và quản lý phiên bản nằm ở D04-02; tài liệu này chỉ nhắc tới khi cần nói một quy tắc được kiểm tra ở cổng nào.

### 1.3. Mức bắt buộc và mã quy tắc

Mỗi quy tắc có một mã dạng `CC-{nhóm}-{nn}` để review code, cấu hình công cụ và ngoại lệ có thể trích dẫn chính xác. Đây là loại mã mới, được đề xuất bổ sung vào D00-01 §3.1 (xem mục 12). Các nhóm quy tắc được liệt kê trong bảng dưới đây; bảng cũng cho biết mục nào của tài liệu chứa nhóm đó.

| Nhóm | Phạm vi | Mục |
|---|---|---|
| `CC-GEN` | Nguyên tắc chung, mọi ngôn ngữ | 2 |
| `CC-JAVA` | Java 21, phong cách, đặt tên, record, null-safety | 3.1–3.4 |
| `CC-MOD` | Spring Modulith, ranh giới module, ArchUnit | 3.2 |
| `CC-ERR` | Xử lý lỗi, RFC 9457, mã `ERR` | 3.5 |
| `CC-TX` | Giao dịch, outbox, idempotency | 3.6–3.7 |
| `CC-JPA` | JPA, Hibernate, truy cập dữ liệu | 3.8 |
| `CC-VAL` | Kiểm tra đầu vào | 3.9 |
| `CC-LOG` | Nhật ký vận hành, che dữ liệu, trace | 3.10 |
| `CC-CFG` | Cấu hình, bí mật | 3.11 |
| `CC-TEST` | Kiểm thử | 3.12 |
| `CC-CAMEL` | Camel Quarkus, YAML DSL, Kamelet | 4 |
| `CC-FE` | TypeScript, React, antd, design system | 5 |
| `CC-SQL` | PostgreSQL, Liquibase | 6 |
| `CC-API` | OpenAPI, AsyncAPI, sự kiện | 7 |
| `CC-TEN` | Đa tenant | 8 |
| `CC-SEC` | Lập trình an toàn theo OWASP ASVS 5.0 mức 2 | 9 |

Mức bắt buộc được diễn đạt bằng hai động từ. **"Phải"** (tương đương MUST) nghĩa là vi phạm làm PR bị chặn, hoặc bởi công cụ trong CI, hoặc bởi người review. **"Nên"** (tương đương SHOULD) nghĩa là được phép làm khác nếu PR giải thích lý do; người review có quyền yêu cầu sửa. Quy tắc nào được đánh dấu **[tự động]** thì đã có hoặc phải có công cụ kiểm tra trong cổng CI tương ứng ở D04-02 §6; quy tắc đánh dấu **[review]** dựa vào người duyệt và danh mục kiểm tra review ở D04-02 §5.

### 1.4. Quan hệ với tài liệu khác

Tài liệu này không định nghĩa lại thuật ngữ, kiểu dữ liệu hay quy ước đặt tên đã có ở D00-01 mà chỉ trỏ tới. Khi D00-01 thay đổi, quy chuẩn này phải được rà lại trong vòng một chu kỳ phát hành. Hướng dẫn lập trình hiện có trong kho mã (`docs/08-implementation/02-huong-dan-lap-trinh.md`, gọi tắt là IP-02) và tệp `AGENTS.md` là bản tiền thân; khi có mâu thuẫn, D04-01 được ưu tiên và `AGENTS.md` phải được cập nhật trỏ về D04-01 (xem mục 11). Biện pháp an toàn thông tin được định nghĩa ở D03-07 với mã `SEC-nn`; tài liệu này hiện thực các biện pháp thuộc dải **SEC-40–49 (ứng dụng và API, phát triển an toàn)**, đồng thời đóng góp vào dải SEC-30–39 (bảo vệ dữ liệu, bí mật), SEC-60–69 (nhật ký) và SEC-80–89 (cách ly tenant) ở mức mã nguồn.

## 2. Nguyên tắc chung

Các nguyên tắc dưới đây áp dụng cho mọi ngôn ngữ trong kho mã. Chúng là nền để hiểu các quy tắc chi tiết ở các mục sau: phần lớn quy tắc chi tiết là hệ quả của một trong những nguyên tắc này.

**CC-GEN-01 · Mọi thay đổi có căn cứ truy vết [review].** Mỗi PR phải tham chiếu ít nhất một mã `FR`, `US`, `NFR`, `ADR` hoặc mã việc trong kế hoạch phát triển. Mã nghiệp vụ không có căn cứ là "mã tự nghĩ ra", tạo bề mặt tấn công và chi phí bảo trì không ai yêu cầu. Quy tắc này kế thừa nguyên tắc "không vibe coding" của `AGENTS.md`.

**CC-GEN-02 · Hợp đồng trước, mã sau [tự động].** API REST phải có đặc tả OpenAPI 3.1 và sự kiện phải có đặc tả AsyncAPI 3.0 cùng schema trong Apicurio trước khi viết mã hiện thực (nguyên tắc kiến trúc NT-04 của SAD). Mã máy chủ và mã khách được sinh hoặc kiểm tra đối chiếu với hợp đồng, không viết tay theo trí nhớ. Chi tiết ở mục 7.

**CC-GEN-03 · Từ chối mặc định (deny-by-default) [tự động].** Endpoint, topic, route, quyền truy cập tệp, CORS, network policy mới đều bắt đầu ở trạng thái đóng và chỉ mở bằng khai báo tường minh. Một endpoint không gắn quyền phải trả `403` trong kiểm thử, không được "tạm mở để thử".

**CC-GEN-04 · Không tin dữ liệu từ ngoài ranh giới tin cậy [review].** Mọi dữ liệu đến từ client, từ HTTT thành viên, từ tệp tải lên, từ Kafka, từ header HTTP và từ phản hồi của dịch vụ bên ngoài đều là dữ liệu không tin cậy; chúng phải được kiểm tra kiểu, độ dài, định dạng và giá trị cho phép trước khi dùng. Riêng ngữ cảnh tenant và danh tính chủ thể chỉ được lấy từ token đã xác minh (mục 8).

**CC-GEN-05 · Không bí mật trong mã [tự động].** Mã nguồn, cấu hình, tệp mẫu, kiểm thử, ảnh container, tài liệu và thông điệp commit không được chứa mật khẩu, khóa, token hay chuỗi kết nối có thông tin xác thực (NFR-00-022, ADR-012). Giá trị bí mật chỉ đến từ OpenBao qua External Secrets Operator hoặc từ biến môi trường do nền tảng nạp. CI chạy gitleaks trên toàn lịch sử và chặn merge khi có phát hiện.

**CC-GEN-06 · Đơn giản, rõ ràng hơn khéo léo [review].** Mã được viết để người khác đọc. Ưu tiên cấu trúc tường minh, tên đầy đủ, hàm ngắn (Java nên ≤ 40 dòng, độ phức tạp vòng ≤ 10; TypeScript tương tự), tránh siêu lập trình (metaprogramming), phản chiếu (reflection) và sinh mã lúc chạy trừ khi framework yêu cầu. Mã khó đọc là mã khó review bảo mật.

**CC-GEN-07 · Ngôn ngữ trong mã [review].** Định danh trong mã (lớp, hàm, biến, bảng, cột, khóa cấu hình) viết bằng tiếng Anh theo D00-01 §6. Chú thích (comment), Javadoc, thông điệp commit, mô tả PR và chuỗi hiển thị cho người dùng viết bằng tiếng Việt có dấu. Lý do: tiếng Anh cho định danh giúp dùng được thuật ngữ chuẩn ngành và công cụ phân tích tĩnh; tiếng Việt cho giải thích giúp mọi thành viên đội và hội đồng thẩm định đọc được. Thuật ngữ nghiệp vụ không có từ tiếng Anh tương đương rõ ràng được dịch theo bảng thuật ngữ D00-01 §2 (ví dụ danh mục dùng chung là `catalog`, HTTT thành viên là `member_system`).

**CC-GEN-08 · Mã hóa ký tự và định dạng tệp [tự động].** Mọi tệp văn bản dùng UTF-8 không BOM, kết thúc dòng LF, có dòng trống cuối tệp, thụt lề bằng dấu cách (Java 2 dấu cách theo Google Java Style, TypeScript, YAML, JSON 2 dấu cách). Tệp `.editorconfig` ở gốc kho mã là nguồn cấu hình; formatter (mục 3.1, 5.9) áp dụng tự động.

**CC-GEN-09 · Phụ thuộc là mã của mình [tự động].** Thêm một thư viện là nhận trách nhiệm về lỗ hổng của nó. Thư viện mới phải có giấy phép nằm trong danh sách cho phép, còn được bảo trì (có bản phát hành trong 12 tháng gần nhất), không có lỗ hổng CRITICAL hoặc HIGH chưa vá, và được ghim phiên bản theo chính sách ở D04-02 §8. PR thêm phụ thuộc phải nêu lý do không dùng được thư viện sẵn có.

**CC-GEN-10 · Ghi nhận cái gì, không ghi nhận cái gì [tự động + review].** Nhật ký vận hành ghi đủ để chẩn đoán (mã truy vết, tenant, mã lỗi, thời lượng) nhưng không bao giờ ghi giá trị trường mức Nhạy cảm, token, mật khẩu hay nội dung bản tin nghiệp vụ đầy đủ (NFR-00-029, SAD §8.2). Chi tiết ở mục 3.10.

**CC-GEN-11 · Lỗi phải nhìn thấy được [review].** Không nuốt ngoại lệ (catch rỗng, catch rồi chỉ log ở mức DEBUG). Lỗi hoặc được xử lý có chủ đích, hoặc được ném lên tầng có thể chuyển thành phản hồi RFC 9457 hoặc đưa vào DLQ. Hệ thống thất bại theo hướng an toàn (fail closed): khi không quyết định được quyền, từ chối; khi không đọc được tenant, dừng xử lý.

**CC-GEN-12 · Mã sinh tự động không sửa tay [tự động].** Mã sinh từ OpenAPI, AsyncAPI, schema Avro/JSON hay từ trình thiết kế luồng nằm trong thư mục `generated/` hoặc được sinh lúc build, được đánh dấu bỏ qua trong formatter và độ phủ, và không được sửa tay. Muốn thay đổi thì sửa nguồn rồi sinh lại.

## 3. Java 21, Spring Boot 4, Spring Modulith

### 3.1. Phong cách và công cụ định dạng

**CC-JAVA-01 · Định dạng theo Google Java Style bằng Spotless [tự động].** Mã Java được định dạng bằng `spotless-maven-plugin` với `google-java-format` (kiểu mặc định, thụt 2 dấu cách, dòng tối đa 100 ký tự). Bước `spotless:check` chạy trong cổng build; lập trình viên chạy `mvn spotless:apply` trước khi commit (có thể gắn vào pre-commit hook). Lý do chọn Google Java Style: mã hiện có trong kho đã theo thụt 2 dấu cách, và công cụ định dạng không có tùy chọn nên chấm dứt tranh luận về phong cách.

**CC-JAVA-02 · Dùng tính năng Java 21 đúng chỗ [review].** Nên dùng `record` cho dữ liệu bất biến, `sealed interface` cho tập kết quả hữu hạn (ví dụ kết quả kiểm tra hợp lệ), `switch` mẫu (pattern matching) thay chuỗi `if instanceof`, khối văn bản (text block) cho SQL và JSON mẫu, và luồng ảo (virtual threads) qua `spring.threads.virtual.enabled=true` cho DU có nhiều I/O. Không dùng `var` khi kiểu không hiển nhiên từ vế phải. Không dùng tính năng xem trước (preview) của JDK trong mã sản xuất.

**CC-JAVA-03 · Cấm các cấu trúc dễ sinh lỗi [tự động].** Không dùng `System.out`/`System.err`/`printStackTrace()` (dùng SLF4J); không dùng `java.util.Date`, `Calendar`, `SimpleDateFormat` (dùng `java.time`, lưu `Instant` hoặc `OffsetDateTime` UTC theo kiểu `T-TS`); không dùng `double`/`float` cho tiền (dùng `long` hoặc `BigDecimal` theo `T-MONEY`); không dùng `new Random()` cho giá trị bảo mật (dùng `SecureRandom`); không bắt `Throwable` hoặc `Exception` chung chung trừ ở tầng biên xử lý lỗi toàn cục. Các luật này được bật trong Error Prone hoặc PMD và trong Semgrep (mục 9.3).

### 3.2. Cấu trúc package và ranh giới module

Mỗi DU Spring Boot là một ứng dụng Spring Modulith (ADR-001). Mỗi phân hệ trong DU là một module ứng dụng (application module). Package gốc của DU là `vn.datahub.{du}`, trong đó `{du}` là tên DU bỏ tiền tố `dh-` (ví dụ `connect`, `integration`, `data`, `platform`, `payment`, `assist`); module là package con trực tiếp, đặt tên theo tên ngắn của phân hệ, khớp với tên ngắn trong tên schema PostgreSQL (D00-01 §6). Cây thư mục dưới đây minh họa DU `dh-data` với module danh mục dùng chung PH-07.

```text
vn.datahub.data/
├── DataApplication.java          # @SpringBootApplication, @Modulithic
├── shared/                       # nhân dùng chung của DU (không phải module nghiệp vụ)
│   ├── security/                 # bộ lọc tenant, chuyển đổi JWT
│   ├── web/                      # @RestControllerAdvice, cấu hình Jackson
│   └── persistence/              # cấu hình JPA, bộ đặt app.tenant_id
├── rdm/                          # PH-07 Danh mục dùng chung (schema ph07_rdm)
│   ├── package-info.java         # @ApplicationModule, @NullMarked
│   ├── api/                      # giao diện công bố cho module khác trong DU
│   │   ├── package-info.java     # @NamedInterface("api")
│   │   ├── CatalogQueries.java   # interface dịch vụ truy vấn
│   │   └── CatalogView.java      # record DTO trả ra
│   ├── events/                   # sự kiện miền công bố (record, có phiên bản)
│   │   ├── package-info.java     # @NamedInterface("events")
│   │   └── CatalogPublishedV1.java
│   └── internal/                 # mọi thứ còn lại: không ai ngoài module được import
│       ├── web/CatalogController.java
│       ├── CatalogService.java
│       ├── Catalog.java          # entity JPA
│       ├── CatalogRepository.java
│       └── CatalogMapper.java
├── mdm/                          # PH-06 (schema ph06_mdm)
└── privacy/                      # PH-09 (schema ph09_privacy)
```

Cây trên cho thấy ba vùng của một module. Vùng `api` chứa những gì module khác trong cùng DU được phép gọi đồng bộ: interface dịch vụ và record dữ liệu, không chứa entity JPA hay repository. Vùng `events` chứa sự kiện miền mà module phát ra, là cách giao tiếp ưu tiên giữa các module vì nó không tạo phụ thuộc gọi trực tiếp. Vùng `internal` chứa toàn bộ hiện thực, kể cả controller REST, vì controller là điểm vào từ bên ngoài DU chứ không phải giao diện cho module khác. Package `shared` là nhân kỹ thuật của DU; nó không được phụ thuộc vào bất kỳ module nghiệp vụ nào.

**CC-MOD-01 · Package theo mẫu `vn.datahub.{du}.{module}.{api|internal|events}` [tự động].** Mọi lớp nghiệp vụ nằm trong một trong ba package con này của module. Lớp nằm trực tiếp ở package module (ngoài `package-info.java`) bị ArchUnit báo lỗi. Thư viện dùng chung giữa các DU có package gốc `vn.datahub.common.{chủ-đề}` (ví dụ `vn.datahub.common.tenant`, `vn.datahub.common.problem`).

**CC-MOD-02 · Chỉ phụ thuộc vào `api` và `events` của module khác [tự động].** Một module chỉ được import lớp trong `api` hoặc `events` của module khác. Import `internal` xuyên module, phụ thuộc vòng giữa các module, và truy cập bảng thuộc schema của module khác đều bị cấm. Kiểm tra bằng `ApplicationModules.of(XxxApplication.class).verify()` trong kiểm thử đơn vị của mỗi DU (NFR-00-054) và bằng các luật ArchUnit bổ sung ở CC-MOD-05.

**CC-MOD-03 · Khai báo module tường minh [tự động].** Mỗi module có `package-info.java` gắn `@ApplicationModule(displayName = "PH-07 Danh mục dùng chung", allowedDependencies = {...})`. Danh sách `allowedDependencies` liệt kê tường minh module và named interface được dùng, ví dụ `"privacy :: api"`. Thêm một phụ thuộc mới giữa hai module là thay đổi kiến trúc, cần người duyệt thuộc nhóm kiến trúc (D04-02 §5.2).

**CC-MOD-04 · Giao tiếp giữa module ưu tiên sự kiện [review].** Khi module A cần phản ứng với việc xảy ra ở module B, B phát sự kiện miền trong `events` và A lắng nghe bằng `@ApplicationModuleListener` (bất đồng bộ, sau commit, có lưu bản ghi phát hành của Spring Modulith). Gọi đồng bộ qua `api` chỉ dùng khi A cần kết quả ngay để quyết định. Giao tiếp giữa các DU dùng REST theo hợp đồng OpenAPI hoặc Kafka, không bao giờ dùng chung bảng (SAD §7.3).

**CC-MOD-05 · Luật ArchUnit bổ sung [tự động].** Ngoài kiểm tra của Spring Modulith, mỗi DU chạy bộ luật ArchUnit dùng chung từ thư viện `vn.datahub.common.archtest`. Bộ luật tối thiểu được liệt kê trong bảng sau; bảng nêu luật, mục đích và quy tắc mà luật bảo vệ.

| Luật ArchUnit | Mục đích | Bảo vệ quy tắc |
|---|---|---|
| Lớp `@Entity` và `@Repository` chỉ nằm trong `..internal..` | Không lộ mô hình lưu trữ ra ngoài module | CC-MOD-02 |
| Lớp `@RestController` chỉ nằm trong `..internal.web..` | Controller là điểm vào ngoài, không là API nội DU | CC-MOD-01 |
| Lớp trong `..api..` và `..events..` không phụ thuộc `jakarta.persistence..` | DTO và sự kiện không mang annotation JPA | CC-JAVA-05 |
| Không lớp nào phụ thuộc `java.sql.DriverManager` hoặc tạo `DataSource` ngoài `shared.persistence` | Không mở kết nối ngoài DataSource được quản lý | CC-TEN-02 |
| Không phương thức nào gắn `@Query(nativeQuery = true)` ngoài danh sách cho phép có lý do | Không vượt qua RLS bằng SQL tự do | CC-TEN-02 |
| Không lớp nào gọi `TenantContext.set` ngoài `shared.security` và `TenantContext.runAs` | Tenant chỉ được đặt từ token hoặc khối `runAs` | CC-TEN-01, CC-TEN-05 |
| Không lớp nào dùng `System.out`, `java.util.Date`, `printStackTrace` | Phong cách và nhật ký | CC-JAVA-03 |
| Mọi phương thức public của `@RestController` có `@PreAuthorize` hoặc annotation quyền `@RequiresPermission` | Từ chối mặc định | CC-GEN-03, CC-SEC-08 |
| Lớp `@Scheduled` hoặc `@KafkaListener` phải gọi qua `TenantContext.runAs` (kiểm tra bằng luật tùy biến trên bytecode) | Tác vụ nền có tenant | CC-TEN-05 |

Đoạn mã sau minh họa cách DU dùng bộ luật chung. Kiểm thử này chạy trong pha `test` nên thất bại ở cổng build, trước mọi kiểm thử chậm hơn.

```java
package vn.datahub.data;

import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.junit.ArchTests;
import org.junit.jupiter.api.Test;
import org.springframework.modulith.core.ApplicationModules;
import org.springframework.modulith.docs.Documenter;
import vn.datahub.common.archtest.DatahubArchRules;

@AnalyzeClasses(packages = "vn.datahub.data", importOptions = ImportOption.DoNotIncludeTests.class)
class ArchitectureTest {

  @ArchTest
  static final ArchTests datahubRules = ArchTests.in(DatahubArchRules.class);

  @Test
  void modulesRespectBoundaries() {
    ApplicationModules modules = ApplicationModules.of(DataApplication.class);
    modules.verify();
    // Sinh sơ đồ module (PlantUML/C4) làm tài liệu sống, đính kèm vào artefact CI.
    new Documenter(modules).writeModulesAsPlantUml().writeIndividualModulesAsPlantUml();
  }
}
```

### 3.3. Đặt tên

Quy ước đặt tên Java dưới đây bổ sung cho D00-01 §6. Bảng nêu loại định danh, quy ước và ví dụ; mọi định danh viết bằng tiếng Anh theo CC-GEN-07.

| Loại | Quy ước | Ví dụ đúng | Ví dụ sai |
|---|---|---|---|
| Package | chữ thường, không gạch dưới | `vn.datahub.data.rdm.internal` | `vn.datahub.data.RDM`, `vn.lgsp.data` |
| Lớp, record, interface | `PascalCase`, danh từ | `CatalogItem`, `CatalogQueries` | `CatalogItemDTO`, `ICatalog` |
| Controller | `{TàiNguyên}Controller` | `CatalogController` | `CatalogRest` |
| Dịch vụ ứng dụng | `{TàiNguyên}Service` | `CatalogService` | `CatalogManager`, `CatalogHelper` |
| Repository | `{Entity}Repository` | `CatalogRepository` | `CatalogDao` |
| DTO yêu cầu, phản hồi | `{Hành động}{TàiNguyên}Request`, `{TàiNguyên}Response` hoặc `View` | `CreateCatalogRequest`, `CatalogView` | `CatalogDto` |
| Sự kiện miền | `{TàiNguyên}{QuáKhứPhânTừ}V{n}` | `CatalogPublishedV1` | `PublishCatalogEvent` |
| Ngoại lệ nghiệp vụ | `{Lý do}Exception`, kế thừa `DatahubException` | `CatalogCodeConflictException` | `MyException` |
| Phương thức | `camelCase`, động từ | `publishCatalog`, `findByCode` | `catalogPublish`, `doIt` |
| Hằng | `UPPER_SNAKE_CASE` | `MAX_PAGE_SIZE` | `maxPageSize` |
| Khóa cấu hình | `datahub.{module}.{khóa-kebab}` | `datahub.rdm.import-max-rows` | `lgsp.rdm.importMaxRows` |
| Lớp kiểm thử | `{LớpĐượcThử}Test` (đơn vị), `{TínhNăng}IT` (tích hợp) | `CatalogServiceTest`, `CatalogApiIT` | `TestCatalog` |
| Phương thức kiểm thử | `should{KếtQuả}_when{ĐiềuKiện}` hoặc `@DisplayName` tiếng Việt | `shouldReturn404_whenOtherTenant` | `test1` |

Hậu tố `DTO`, tiền tố `I` cho interface và hậu tố `Impl` khi chỉ có một hiện thực đều không được dùng: chúng không mang thông tin. Khi một interface trong `api` có đúng một hiện thực trong `internal`, hiện thực đặt tên theo vai trò, ví dụ `CatalogQueries` (interface) và `CatalogService` (hiện thực).

### 3.4. Record, DTO và null-safety

**CC-JAVA-04 · DTO là `record` bất biến [tự động].** Mọi đối tượng đi qua ranh giới (yêu cầu, phản hồi REST, sự kiện, kết quả của `api`) là `record`. Tập hợp trong record được sao chép phòng thủ bằng `List.copyOf` trong hàm tạo gọn (compact constructor). Record không chứa logic nghiệp vụ ngoài kiểm tra bất biến cục bộ và phương thức tiện ích thuần.

**CC-JAVA-05 · Không trả entity ra ngoài [tự động].** Entity JPA không bao giờ được trả qua REST, đặt vào sự kiện hay trả ra từ `api`. Ánh xạ entity sang DTO bằng lớp `Mapper` viết tay hoặc MapStruct (cấu hình `unmappedTargetPolicy = ERROR`). Lý do: trả entity làm lộ trường nội bộ (ví dụ `tenant_id`, cột mã hóa), gây lỗi tải lười (lazy loading) ngoài giao dịch và mở đường cho gán hàng loạt (mass assignment, xem CC-SEC-21).

**CC-JAVA-06 · Null-safety bằng JSpecify [tự động].** Mọi package có `package-info.java` gắn `@org.jspecify.annotations.NullMarked`: mặc định mọi kiểu là không rỗng; chỗ nào được rỗng phải gắn `@Nullable`. NullAway (plugin của Error Prone) chạy ở chế độ JSpecify trong cổng build và coi vi phạm là lỗi biên dịch. Spring Framework 7 và Spring Boot 4 đã dùng JSpecify cho API của chính chúng, nên kiểm tra này bắt được cả lỗi dùng sai API Spring. Không dùng `Optional` làm kiểu tham số hay kiểu trường; `Optional` chỉ dùng làm kiểu trả về của truy vấn có thể không có kết quả.

Ví dụ dưới đây cho thấy một record yêu cầu và một record phản hồi đúng quy chuẩn. Record yêu cầu không có trường `tenantId`, `id`, `createdBy` hay `version` vì các giá trị này không bao giờ đến từ client; `version` đi qua header `If-Match`.

```java
// vn/datahub/data/rdm/package-info.java
@ApplicationModule(displayName = "PH-07 Danh mục dùng chung",
    allowedDependencies = {"privacy :: api"})
@NullMarked
package vn.datahub.data.rdm;

import org.jspecify.annotations.NullMarked;
import org.springframework.modulith.ApplicationModule;
```

```java
package vn.datahub.data.rdm.internal.web;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.util.List;
import org.jspecify.annotations.Nullable;

/** Yêu cầu tạo danh mục (API-07-001). Không chứa tenant, id, người tạo: lấy từ ngữ cảnh. */
public record CreateCatalogRequest(
    @NotBlank @Pattern(regexp = "^[A-Z0-9][A-Z0-9_.-]{0,63}$") String code, // T-CODE
    @NotBlank @Size(max = 255) String name,                                 // T-NAME
    @Nullable @Size(max = 4000) String description,                         // T-TEXT
    @Size(max = 50) List<@Pattern(regexp = "^[A-Z0-9_]{1,32}$") String> tags) {

  public CreateCatalogRequest {
    tags = tags == null ? List.of() : List.copyOf(tags);
  }
}
```

```java
package vn.datahub.data.rdm.api;

import java.time.Instant;
import java.util.UUID;
import org.jspecify.annotations.Nullable;

/** Dạng xem danh mục công bố cho module khác và cho REST. */
public record CatalogView(
    UUID id, String code, String name, @Nullable String description,
    CatalogStatus status, Instant updatedAt, int version) {}
```

Ví dụ sai thường gặp được nêu tiếp theo để người review nhận ra. Lớp này vi phạm cùng lúc CC-JAVA-04 (lớp có setter), CC-JAVA-05 (trả entity), CC-TEN-01 (nhận tenant từ thân yêu cầu) và CC-SEC-21 (gán hàng loạt).

```java
// SAI — không làm theo
@PostMapping("/catalogs")
public Catalog create(@RequestBody Catalog body) {   // nhận và trả entity
  body.setTenantId(body.getTenantId());               // tenant do client gửi
  return repository.save(body);                       // client đặt được id, version, status
}
```

### 3.5. Xử lý lỗi theo RFC 9457 và mã `ERR-{PH}-{nnn}`

Mọi lỗi trả về từ API REST của Datahub có kiểu nội dung `application/problem+json` theo RFC 9457 (SAD §7.2). Mỗi lỗi nghiệp vụ mang một mã `ERR-{PH}-{nnn}` định nghĩa ở D03-04, để HTTT thành viên xử lý lỗi theo mã chứ không theo câu chữ, và để bộ phận hỗ trợ tra cứu nhanh. Cấu trúc thân lỗi được chốt trong bảng dưới đây; bảng nêu tên trường, nguồn chuẩn và ý nghĩa.

| Trường | Nguồn | Ý nghĩa | Ví dụ |
|---|---|---|---|
| `type` | RFC 9457 | URI định danh loại lỗi, trỏ tới trang tài liệu mã lỗi trên cổng nhà phát triển | `https://developer.example.gov.vn/errors/ERR-07-004` |
| `title` | RFC 9457 | Tóm tắt ngắn, tiếng Việt, cố định theo mã lỗi | `Mã danh mục đã tồn tại` |
| `status` | RFC 9457 | Mã trạng thái HTTP | `409` |
| `detail` | RFC 9457 | Giải thích cho trường hợp cụ thể, không chứa dữ liệu Nhạy cảm, không chứa stack trace | `Mã CAT_GENDER đã được dùng trong tenant hiện tại.` |
| `instance` | RFC 9457 | Đường dẫn yêu cầu gây lỗi | `/api/rdm/v1/catalogs` |
| `code` | Mở rộng Datahub | Mã `ERR-{PH}-{nnn}` | `ERR-07-004` |
| `traceId` | Mở rộng Datahub | Trace ID W3C (`T-TRACE`) để đối chiếu nhật ký | `4bf92f3577b34da6a3ce929d0e0e4736` |
| `errors` | Mở rộng Datahub | Danh sách lỗi theo trường khi kiểm tra hợp lệ thất bại: `field`, `code`, `message` | `[{"field":"code","code":"PATTERN","message":"Mã chỉ gồm chữ hoa, số, _ . -"}]` |

**CC-ERR-01 · Một bộ xử lý lỗi toàn cục mỗi DU [tự động].** Mỗi DU có đúng một `@RestControllerAdvice` trong `shared.web`, kế thừa `ResponseEntityExceptionHandler` của Spring, chuyển mọi ngoại lệ thành `ProblemDetail` theo bảng trên. Controller không tự dựng phản hồi lỗi. Bật `spring.mvc.problemdetails.enabled=true` để lỗi khung (400, 405, 415) cũng theo RFC 9457.

**CC-ERR-02 · Ngoại lệ nghiệp vụ mang mã lỗi [tự động].** Ngoại lệ nghiệp vụ kế thừa `DatahubException` (thư viện chung), mang `ErrorCode` là một enum mỗi phân hệ (`Ph07Error`) với mã, trạng thái HTTP và tiêu đề tiếng Việt. Không ném `RuntimeException` trần cho lỗi nghiệp vụ. Một kiểm thử đơn vị tự động đối chiếu enum với danh mục mã lỗi trong hợp đồng OpenAPI (`components/responses`) để không có mã nào chỉ tồn tại ở một phía.

**CC-ERR-03 · Không lộ chi tiết nội bộ [tự động].** Phản hồi lỗi không được chứa stack trace, tên lớp, câu SQL, tên bảng, đường dẫn tệp máy chủ, phiên bản thư viện hay thông điệp gốc của ngoại lệ hạ tầng. Lỗi không lường trước trả `500` với `code = ERR-00-500`, `detail` chung chung và `traceId`; chi tiết chỉ nằm trong nhật ký (ASVS V16, CC-SEC-31). Cấu hình `server.error.include-stacktrace=never`, `server.error.include-message=never`.

**CC-ERR-04 · Ánh xạ trạng thái HTTP nhất quán [review].** `400` cho đầu vào sai cú pháp hoặc vi phạm ràng buộc; `401` khi thiếu hoặc sai token; `403` khi đã xác thực nhưng thiếu quyền trên loại tài nguyên; `404` khi tài nguyên không tồn tại **hoặc thuộc tenant khác hoặc chủ thể không được thấy** (để không lộ sự tồn tại, CC-TEN-06); `409` cho xung đột trạng thái hoặc trùng mã; `412` khi `If-Match` không khớp `version`; `422` cho vi phạm quy tắc nghiệp vụ `BR`; `428` khi thiếu `If-Match` hoặc `Idempotency-Key` bắt buộc; `429` khi vượt hạn mức; `503` khi phụ thuộc tạm không sẵn sàng, kèm `Retry-After`.

Đoạn mã sau minh họa enum mã lỗi và bộ xử lý toàn cục. Chú ý rằng ngoại lệ không lường trước được ghi nhật ký ở mức `ERROR` kèm đầy đủ ngăn xếp, còn phản hồi cho client chỉ có mã chung và `traceId`.

```java
package vn.datahub.data.rdm.internal;

public enum Ph07Error implements ErrorCode {
  CATALOG_NOT_FOUND("ERR-07-001", 404, "Không tìm thấy danh mục"),
  CATALOG_CODE_CONFLICT("ERR-07-004", 409, "Mã danh mục đã tồn tại"),
  CATALOG_NOT_EDITABLE("ERR-07-007", 422, "Danh mục ở trạng thái không cho phép sửa");

  private final String code; private final int status; private final String title;
  Ph07Error(String code, int status, String title) {
    this.code = code; this.status = status; this.title = title;
  }
  @Override public String code() { return code; }
  @Override public int status() { return status; }
  @Override public String title() { return title; }
}
```

```java
package vn.datahub.data.shared.web;

@RestControllerAdvice
class GlobalProblemHandler extends ResponseEntityExceptionHandler {

  private static final Logger log = LoggerFactory.getLogger(GlobalProblemHandler.class);

  @ExceptionHandler(DatahubException.class)
  ProblemDetail handleBusiness(DatahubException ex, HttpServletRequest req) {
    log.info("business_error code={}", ex.errorCode().code()); // mức INFO, không ghi dữ liệu nghiệp vụ
    return Problems.of(ex.errorCode(), ex.safeDetail(), req);
  }

  @ExceptionHandler(Exception.class)
  ProblemDetail handleUnexpected(Exception ex, HttpServletRequest req) {
    log.error("unexpected_error", ex); // đủ ngăn xếp trong nhật ký, có trace_id qua MDC
    return Problems.of(CommonError.INTERNAL, "Đã xảy ra lỗi hệ thống. Vui lòng liên hệ hỗ trợ kèm mã truy vết.", req);
  }
}
```

### 3.6. Giao dịch và outbox

**CC-TX-01 · Ranh giới giao dịch ở tầng dịch vụ [review].** `@Transactional` đặt trên phương thức public của lớp dịch vụ trong `internal`, không đặt trên controller, repository hay lớp `api`. Phương thức chỉ đọc gắn `@Transactional(readOnly = true)`. Không gọi dịch vụ bên ngoài (HTTP, Kafka trực tiếp, OpenBao) bên trong giao dịch CSDL vì làm giao dịch kéo dài và giữ khóa; nếu cần, tách thành bước sau commit qua sự kiện.

**CC-TX-02 · Đặt tenant ở đầu mỗi giao dịch [tự động].** Mỗi giao dịch phải chạy `SET LOCAL app.tenant_id = :tenant` trước câu lệnh đầu tiên (D03-10 §3). Việc này do thành phần chung `TenantAwareDataSource` hoặc bộ lắng nghe giao dịch trong `shared.persistence` làm tự động từ `TenantContext`; mã nghiệp vụ không tự chạy `SET`. Vì chính sách RLS dùng `current_setting('app.tenant_id', false)`, quên đặt biến sẽ làm truy vấn lỗi ngay chứ không trả rỗng.

**CC-TX-03 · Sự kiện ra Kafka chỉ qua outbox [tự động].** Không gọi `KafkaTemplate.send` trực tiếp trong luồng nghiệp vụ. Sự kiện cần phát ra ngoài DU được ghi vào bảng `outbox` của schema phân hệ trong cùng giao dịch với thay đổi nghiệp vụ; Debezium đọc WAL của bảng outbox và phát lên Kafka (SAD §7.3). Bảng outbox có các cột tối thiểu `id` (UUID v7, dùng làm mã sự kiện CloudEvents `id`), `tenant_id`, `aggregate_type`, `aggregate_id`, `event_type`, `topic`, `payload` (`jsonb`), `headers` (`jsonb`, chứa `traceparent`), `created_at`. Luật ArchUnit cấm lớp ngoài `shared.messaging` phụ thuộc `KafkaTemplate`. Trong DU, sự kiện giữa các module dùng cơ chế phát hành sự kiện của Spring Modulith (bảng `event_publication`) để bảo đảm lắng nghe sau commit không bị mất khi DU khởi động lại.

**CC-TX-04 · Khóa lạc quan bằng `version` [tự động].** Mọi entity có trường `@Version int version` ánh xạ cột `version` (D00-01 §5.1). Lệnh sửa nhận `If-Match` chứa ETag sinh từ `version`; không khớp trả `412` với `ERR-00-412` (FR-00-052). Không dùng khóa bi quan (`SELECT ... FOR UPDATE`) trừ hàng đợi công việc nội bộ có lý do ghi trong SDD.

Ví dụ dưới đây cho thấy một phương thức dịch vụ đúng: kiểm tra tồn tại trong phạm vi tenant (RLS lo phần lọc), đổi trạng thái qua phương thức của entity, ghi outbox cùng giao dịch, và không gọi gì ra ngoài.

```java
@Transactional
public CatalogView publish(UUID id, int expectedVersion) {
  Catalog catalog = repository.findById(id)
      .orElseThrow(() -> new DatahubException(Ph07Error.CATALOG_NOT_FOUND)); // tenant khác → cũng 404
  if (catalog.getVersion() != expectedVersion) {
    throw new DatahubException(CommonError.PRECONDITION_FAILED);
  }
  catalog.publish(clock.instant(), currentUser.id());   // quy tắc chuyển trạng thái nằm trong entity
  outbox.append(OutboxMessage.of(                       // cùng giao dịch
      "catalog", catalog.getId(), "CatalogPublishedV1",
      Topics.forCurrentTenant("rdm", "catalog", "published", 1), // hàm chung, không ghép chuỗi tay
      new CatalogPublishedV1(catalog.getId(), catalog.getCode(), catalog.getPublishedAt())));
  return mapper.toView(catalog);
}
```

### 3.7. Idempotency

**CC-TX-05 · Lệnh tạo và lệnh hành động nhận `Idempotency-Key` [tự động].** Mọi `POST` tạo tài nguyên và mọi lệnh hành động `POST /{tài-nguyên}/{id}:{hành-động}` có tác dụng phụ ra ngoài (cấp thông tin xác thực, phát hành, thanh toán, hoàn tiền) phải chấp nhận header `Idempotency-Key` (chuỗi 16–64 ký tự, khuyến nghị UUID). Với PH-19 và các lệnh cấp thông tin xác thực, header là bắt buộc; thiếu trả `428`. Hợp đồng OpenAPI khai báo header này; kiểm tra lint hợp đồng (mục 7) chặn lệnh tạo không khai báo.

**CC-TX-06 · Lưu khóa idempotency theo tenant và chủ thể [review].** Thành phần chung `IdempotencyFilter` lưu bộ ba (`tenant_id`, chủ thể, khóa) kèm băm SHA-256 của thân yêu cầu, trạng thái và phản hồi đã trả, trong bảng `idempotency_record` của schema phân hệ (có RLS) với thời hạn mặc định 24 giờ. Gửi lại cùng khóa và cùng thân trả lại đúng phản hồi cũ; cùng khóa khác thân trả `422` với `ERR-00-422-IDEMPOTENCY`; yêu cầu trước còn đang xử lý trả `409`. Khóa không được dùng chung giữa tenant hay giữa chủ thể, để một client không đoán khóa của client khác mà đọc được phản hồi.

**CC-TX-07 · Consumer sự kiện xử lý trùng an toàn [tự động].** Kafka giao ít nhất một lần (at-least-once), nên mọi consumer phải idempotent: ghi mã sự kiện CloudEvents `id` đã xử lý vào bảng `processed_event` (khóa chính `tenant_id`, `consumer`, `event_id`) trong cùng giao dịch với tác dụng của sự kiện, và bỏ qua sự kiện đã có. Kiểm thử tích hợp của mỗi consumer phải gửi cùng một sự kiện hai lần và kiểm tra tác dụng chỉ xảy ra một lần.

### 3.8. JPA, Hibernate và truy cập dữ liệu

**CC-JPA-01 · Entity theo cột chuẩn [tự động].** Entity kế thừa `TenantScopedEntity` của thư viện chung, lớp này ánh xạ các cột bắt buộc `id`, `tenant_id`, `created_at`, `created_by`, `updated_at`, `updated_by`, `version` (D00-01 §5.1). `id` là UUID v7 sinh ở tầng ứng dụng (`@Id` gán bằng `UuidV7.generate()` trong hàm tạo, không dùng `@GeneratedValue` của CSDL). `tenant_id` được gán từ `TenantContext` trong `@PrePersist`, `updatable = false`, và không có setter public. Các cột kiểm toán do `AuditingEntityListener` gán.

**CC-JPA-02 · Entity có hành vi, không chỉ có getter và setter [review].** Thay đổi trạng thái đi qua phương thức có tên nghiệp vụ (`publish`, `suspend`, `archive`) kiểm tra quy tắc chuyển trạng thái; không có setter public cho `status`. Entity không phụ thuộc Spring bean.

**CC-JPA-03 · Truy vấn tham số hóa, ưu tiên Spring Data và Criteria [tự động].** Truy vấn dùng phương thức dẫn xuất của Spring Data, JPQL có tham số đặt tên, Criteria API hoặc `JdbcClient`/`NamedParameterJdbcTemplate` với tham số. Cấm ghép chuỗi vào JPQL, SQL hoặc tên cột; tên cột sắp xếp do client gửi phải đi qua danh sách cho phép (CC-SEC-11). Truy vấn native (`nativeQuery = true`) chỉ được dùng khi JPQL không diễn đạt được, phải nằm trong danh sách cho phép của luật ArchUnit kèm lý do, và vẫn chạy qua `DataSource` được quản lý nên vẫn chịu RLS.

**CC-JPA-04 · Kiểm soát tải lười và N+1 [tự động + review].** Mặc định quan hệ `@ManyToOne` và `@OneToOne` khai báo `fetch = LAZY`. Tắt `spring.jpa.open-in-view` (đặt `false`) để không có truy vấn ngoài giao dịch. Danh sách dùng `@EntityGraph` hoặc truy vấn chiếu (projection) sang record. Kiểm thử tích hợp của màn danh sách đo số câu lệnh bằng Hibernate Statistics hoặc datasource-proxy và thất bại nếu vượt ngưỡng ghi trong kiểm thử.

**CC-JPA-05 · Phân trang có giới hạn [tự động].** Mọi truy vấn danh sách có `Pageable` hoặc con trỏ; kích thước trang tối đa 200 (SAD §7.2), mặc định 20 (FR-00-021). Không có endpoint trả "tất cả". Danh sách lớn dùng phân trang theo khóa (keyset) với con trỏ mờ (opaque) mã hóa Base64URL của bộ (`updated_at`, `id`), không lộ giá trị thô.

**CC-JPA-06 · Không đọc chéo schema [tự động].** Entity của module chỉ ánh xạ bảng trong schema của phân hệ đó (`@Table(schema = "ph07_rdm")`). Kiểm thử kiến trúc đọc annotation `@Table` và đối chiếu với tên module; vai trò CSDL của mỗi module chỉ được cấp quyền trên schema của mình (D03-03).

**CC-JPA-07 · Trường Nhạy cảm mã hóa ở tầng ứng dụng [review].** Trường mức Nhạy cảm (SAD §8.2) được mã hóa bằng envelope encryption qua OpenBao transit (ADR-032) thông qua `AttributeConverter` của thư viện chung `vn.datahub.common.crypto`; cột lưu bản mã kèm mã phiên bản khóa. Trường cần tìm kiếm chính xác dùng thêm cột băm có khóa (HMAC-SHA256 với khóa từ OpenBao), không dùng băm trần. Không tự viết thuật toán mã hóa (CC-SEC-25).

### 3.9. Kiểm tra đầu vào

**CC-VAL-01 · Kiểm tra ở biên bằng Jakarta Validation [tự động].** Record yêu cầu gắn ràng buộc Jakarta Validation khớp với kiểu chuẩn D00-01 §5 (độ dài, mẫu, phạm vi); controller gắn `@Valid` cho thân và `@Validated` cho lớp để kiểm tra tham số đường dẫn và query. Ràng buộc trong mã phải khớp với ràng buộc trong OpenAPI; kiểm thử hợp đồng phát hiện lệch.

**CC-VAL-02 · Danh sách cho phép thay vì danh sách chặn [review].** Giá trị liệt kê kiểm tra theo enum; mã theo mẫu `T-CODE`; tên tệp, phần mở rộng, kiểu MIME, tên cột sắp xếp, tên trường lọc đều theo danh sách cho phép. Không cố "lọc ký tự nguy hiểm" bằng danh sách chặn.

**CC-VAL-03 · Chuẩn hóa trước khi kiểm tra [review].** Chuỗi tên được chuẩn hóa Unicode NFC (theo `T-NAME`) trước khi kiểm tra độ dài và lưu; mã được chuyển chữ hoa (`T-CODE`); khoảng trắng đầu cuối được cắt. Tìm kiếm không dấu (FR-00-020) dùng cột hoặc chỉ mục `unaccent` ở CSDL, không biến đổi dữ liệu gốc.

**CC-VAL-04 · Quy tắc nghiệp vụ kiểm tra ở tầng dịch vụ [review].** Ràng buộc liên trường và ràng buộc phụ thuộc trạng thái (`BR-{PH}-{nnn}`) kiểm tra trong dịch vụ hoặc entity và ném `DatahubException` với mã `ERR` riêng, trả `422`. Ràng buộc toàn vẹn cũng được khai báo ở CSDL (`CHECK`, `UNIQUE`, khóa ngoại) làm lớp phòng thủ cuối.

**CC-VAL-05 · Giới hạn kích thước [tự động].** Thân yêu cầu JSON tối đa 1 MB mặc định (cấu hình được theo endpoint), tệp tải lên theo giới hạn từng chức năng; độ sâu lồng JSON tối đa 32 và độ dài chuỗi tối đa theo `StreamReadConstraints` của Jackson. Giới hạn đặt ở cả APISIX và DU để lớp sau không phụ thuộc lớp trước.

### 3.10. Nhật ký vận hành, trace và che dữ liệu

**CC-LOG-01 · Log JSON có cấu trúc [tự động].** Mọi DU ghi log ra stdout dạng JSON một dòng mỗi bản ghi, dùng structured logging có sẵn của Spring Boot (`logging.structured.format.console=ecs` hoặc `logstash`) hoặc JSON logging của Quarkus. Trường bắt buộc trong mọi bản ghi: `@timestamp` (UTC), `level`, `logger`, `message`, `service`, `service_version`, `trace_id`, `span_id`, `tenant_id`, `env`. Thiếu `trace_id` hoặc `tenant_id` trên bản ghi trong ngữ cảnh yêu cầu là lỗi (NFR-00-051); kiểm thử tích hợp chung kiểm tra điều này.

**CC-LOG-02 · Ngữ cảnh qua MDC, không tự ghép [tự động].** `trace_id` và `span_id` do OpenTelemetry (Micrometer Tracing) đưa vào MDC; `tenant_id` và `principal_type` (người hoặc máy) do bộ lọc tenant đưa vào MDC sau khi xác minh token. Mã nghiệp vụ không tự thêm các trường này vào chuỗi thông điệp. Tác vụ nền đặt MDC trong `TenantContext.runAs`.

**CC-LOG-03 · Thông điệp là sự kiện có tên, tham số là khóa–giá trị [review].** Thông điệp log là tên sự kiện ngắn dạng `snake_case` (ví dụ `catalog_published`, `adapter_call_failed`), tham số đi kèm dạng khóa–giá trị (`StructuredArguments.kv` hoặc API fluent của SLF4J 2 `log.atInfo().addKeyValue(...)`). Không ghép chuỗi bằng `+` trong lời gọi log.

**CC-LOG-04 · Không ghi dữ liệu Nhạy cảm và bí mật [tự động].** Không ghi giá trị trường mức Nhạy cảm, mật khẩu, token, khóa, header `Authorization`, cookie, `Idempotency-Key`, nội dung thân yêu cầu hoặc phản hồi nghiệp vụ đầy đủ. Trường mức Hạn chế được che một phần (ví dụ số điện thoại `+8490*****67`). Thư viện chung cung cấp `Masked.of(value, Classification)` và bộ lọc che (`MaskingJsonGeneratorDecorator`) áp các mẫu số định danh cá nhân 12 chữ số, số điện thoại, thư điện tử, số tài khoản lên mọi bản ghi như lớp phòng thủ thứ hai. Bộ quét mẫu dữ liệu chạy trên log của môi trường kiểm thử sau mỗi lượt kiểm thử E2E và phải cho 0 phát hiện (NFR-00-029).

**CC-LOG-05 · Chống chèn log (log injection) [tự động].** Giá trị không tin cậy đưa vào log chỉ đi qua tham số có cấu trúc (bộ mã hóa JSON tự thoát ký tự xuống dòng và ký tự điều khiển). Không ghi giá trị không tin cậy vào phần thông điệp dạng văn bản thuần. Semgrep có luật phát hiện ghép chuỗi đầu vào vào log (CC-SEC-30).

**CC-LOG-06 · Mức log có ý nghĩa [review].** `ERROR`: sự cố cần người can thiệp hoặc lỗi không lường trước; `WARN`: bất thường hệ thống tự xử lý được (thử lại thành công sau lỗi, gần chạm hạn mức); `INFO`: sự kiện nghiệp vụ quan trọng và lỗi nghiệp vụ trả cho client; `DEBUG`: chẩn đoán, tắt ở môi trường sản xuất. Lỗi do client (4xx) không ghi ở mức `ERROR`.

**CC-LOG-07 · Nhật ký kiểm toán khác nhật ký vận hành [review].** Thao tác thuộc diện kiểm toán (FR-00-040) ghi qua `AuditRecorder` của thư viện chung vào kho nhật ký kiểm toán chỉ-thêm có chuỗi băm (ADR-031), không ghi bằng logger thông thường. Nhật ký kiểm toán được ghi trong cùng giao dịch với thao tác (qua outbox) để thao tác thành công thì chắc chắn có bản ghi kiểm toán.

Ví dụ dưới đây so sánh cách ghi log đúng và sai cho cùng một tình huống gọi bộ điều hợp thất bại.

```java
// ĐÚNG: tên sự kiện, khóa–giá trị, không có dữ liệu nghiệp vụ; trace_id, tenant_id có sẵn trong MDC
log.atWarn()
    .setMessage("adapter_call_failed")
    .addKeyValue("adapter_code", adapter.code())
    .addKeyValue("http_status", status)
    .addKeyValue("attempt", attempt)
    .log();

// SAI: ghép chuỗi, lộ số định danh và token, có thể bị chèn ký tự xuống dòng
log.warn("Call failed for citizen " + request.citizenId() + " token=" + token + " body=" + body);
```

### 3.11. Cấu hình

**CC-CFG-01 · Cấu hình có kiểu qua `@ConfigurationProperties` [review].** Mỗi module đọc cấu hình qua một record `@ConfigurationProperties("datahub.{module}")` có `@Validated` và ràng buộc. Không dùng `@Value` rải rác. Giá trị mặc định an toàn nằm trong record hoặc `application.yml`; giá trị theo môi trường đến từ biến môi trường hoặc ConfigMap do Kustomize sinh.

**CC-CFG-02 · Không có giá trị mặc định cho bí mật [tự động].** Khóa cấu hình chứa bí mật (mật khẩu CSDL, khóa client, khóa ký) không được có giá trị mặc định trong `application.yml` hay `application.properties`, kể cả giá trị "dev". Biến thiếu thì ứng dụng phải từ chối khởi động. Môi trường dev cục bộ lấy giá trị từ tệp `.env` không commit (sinh từ `.env.example` chỉ chứa tên biến) hoặc từ Testcontainers (D04-02 §12). Luật gitleaks tùy biến và Semgrep phát hiện mẫu `${...:giá-trị}` trên khóa có tên chứa `password`, `secret`, `token`, `key`.

**CC-CFG-03 · Hồ sơ (profile) tối thiểu [review].** Chỉ dùng các hồ sơ `local`, `test` và hồ sơ mặc định (sản xuất). Không có hồ sơ theo tên môi trường (`staging`, `prod`) trong mã; khác biệt môi trường nằm ở overlay Kustomize. Hồ sơ `local` không được nới lỏng bảo mật theo cách có thể vô tình bật ở sản xuất (ví dụ tắt xác thực); muốn chạy cục bộ thì chạy Keycloak cục bộ.

**CC-CFG-04 · Tham số thay đổi không khởi động lại [review].** Tham số nghiệp vụ thay đổi lúc chạy (hạn mức, ngưỡng, cờ tính năng) đọc từ bảng tham số của PH-18 hoặc ConfigMap được theo dõi, áp dụng trong ≤ 60 giây (NFR-00-052), không yêu cầu khởi động lại pod.

**CC-CFG-05 · Bề mặt quản trị Actuator tối thiểu [tự động].** Chỉ mở `health`, `info`, `prometheus` trên cổng quản trị riêng (`management.server.port`) không đi qua gateway; `env`, `heapdump`, `threaddump`, `loggers`, `configprops` không được mở ở sản xuất. Kiểm thử bảo mật gọi các đường dẫn này qua gateway và kỳ vọng `404`.

### 3.12. Kiểm thử

Chiến lược kiểm thử tổng thể ở D05-01 và ADR-038; mục này chỉ quy định cách viết mã kiểm thử để đạt cổng chất lượng ở D04-02.

**CC-TEST-01 · Cấu trúc và công cụ [tự động].** Kiểm thử đơn vị dùng JUnit 5, AssertJ, Mockito; đặt tên `*Test` và chạy bởi Surefire. Kiểm thử tích hợp dùng `@SpringBootTest` hoặc kiểm thử lát cắt (`@WebMvcTest`, `@DataJpaTest`), Testcontainers cho PostgreSQL 18, Kafka, Keycloak, Valkey; đặt tên `*IT` và chạy bởi Failsafe. Không dùng H2 hay CSDL nhúng thay PostgreSQL vì RLS, `jsonb` và hành vi giao dịch khác nhau. Kiểm thử module của Spring Modulith (`@ApplicationModuleTest`) dùng để kiểm tra một module tách biệt.

**CC-TEST-02 · Độ phủ [tự động].** JaCoCo đo độ phủ dòng; mã nghiệp vụ backend phải đạt ≥ 80% (NFR-00-053), không tính mã sinh, lớp cấu hình và `*Application`. Độ phủ của phần mã thay đổi trong PR (diff coverage) phải ≥ 80% để không cho phép hạ dần.

**CC-TEST-03 · Kiểm thử rò rỉ chéo tenant cho mọi API [tự động].** Mỗi endpoint có ít nhất một kiểm thử theo mẫu ở CC-TEN-06. Lớp cơ sở `CrossTenantLeakTestSupport` của thư viện kiểm thử chung cung cấp hai token của hai tenant giả lập (`T01`, `T02`) và các phương thức kiểm tra. Một kiểm thử meta duyệt mọi `@RequestMapping` của DU và đối chiếu với danh sách kiểm thử rò rỉ đã đăng ký; endpoint không có kiểm thử làm cổng CI đỏ.

**CC-TEST-04 · Kiểm thử phân quyền âm tính [tự động].** Mỗi endpoint có kiểm thử gọi không token (kỳ vọng `401`) và gọi bằng token thiếu quyền (kỳ vọng `403` hoặc `404` theo CC-ERR-04). Mỗi FR mức ưu tiên M có ít nhất một ca dương tính và một ca âm tính (D00-01 §3.2).

**CC-TEST-05 · Kiểm thử ổn định, không phụ thuộc thời gian thực [review].** Dùng `Clock` tiêm vào thay `Instant.now()`; không `Thread.sleep` (dùng Awaitility); dữ liệu kiểm thử tự tạo và tự dọn, không phụ thuộc thứ tự chạy; dữ liệu cá nhân trong kiểm thử là dữ liệu giả sinh bởi bộ sinh có hạt giống cố định, không dùng dữ liệu thật hay dữ liệu lấy từ môi trường sản xuất.

Đoạn mã sau minh họa một kiểm thử rò rỉ chéo tenant theo đúng quy tắc 6 của D03-10.

```java
class CatalogApiIT extends CrossTenantLeakTestSupport {

  @Test
  @DisplayName("Tenant B không đọc được danh mục của tenant A: trả 404, không phải 403")
  void shouldReturn404_whenOtherTenantReadsCatalog() {
    UUID id = asTenant(T01).post("/api/rdm/v1/catalogs", sampleCatalog("CAT_TEST"))
        .expectStatus(201).extractId();

    asTenant(T02).get("/api/rdm/v1/catalogs/{id}", id)
        .expectStatus(404)
        .expectProblemCode("ERR-07-001");

    asTenant(T02).get("/api/rdm/v1/catalogs?code=CAT_TEST")
        .expectStatus(200)
        .expectJsonPath("$.items.length()", 0); // không lộ qua danh sách hay bộ lọc
  }
}
```
