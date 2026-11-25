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

## 4. Camel Quarkus và Camel YAML DSL

Luồng tích hợp của PH-04, bộ điều hợp của PH-05 và kết nối quốc gia của PH-14 chạy trên `dh-runtime` là ứng dụng Camel Quarkus biên dịch native (ADR-002), luồng được viết bằng Camel YAML DSL (ADR-010) và đi vào sản xuất qua Git và Argo CD (ADR-009). Luồng có thể do người viết tay hoặc do trình thiết kế sinh ra; cả hai đều phải tuân thủ mục này, và bộ kiểm tra luồng (validator) của `dh-integration` áp các luật tự động trước khi cho phép gửi duyệt.

### 4.1. Cấu trúc tệp và đặt tên

**CC-CAMEL-01 · Một luồng một thư mục [tự động].** Mỗi luồng nằm ở `routes/{tenant}/{mã-luồng}/` trong kho Git cấu hình, gồm `route.camel.yaml` (định nghĩa), `route.meta.yaml` (mã luồng, tenant, chủ sở hữu, phân loại dữ liệu cao nhất đi qua, FR liên quan, phiên bản), `application.properties` (tham số không bí mật) và thư mục `test/` chứa bản tin mẫu đã ẩn danh. Mã luồng theo `T-CODE` viết thường gạch nối khi dùng làm tên thư mục.

**CC-CAMEL-02 · `routeId` duy nhất, có nghĩa [tự động].** Mọi route khai báo `id` tường minh theo mẫu `{tenant}-{mã-luồng}-{chặng}` viết thường gạch nối, ví dụ `t68-tra-cuu-ho-tich-receive`, `t68-tra-cuu-ho-tich-deliver`. Không để Camel tự sinh `route1`, vì `routeId` là nhãn trên chỉ số, log và trace dùng để chẩn đoán. Mọi bước quan trọng (`to`, `toD`, `process`, `transform`) cũng có `id` để hiện tên trên trace.

**CC-CAMEL-03 · Theo khung chín chặng chuẩn [review].** Luồng chuẩn đi qua các chặng `receive → schema → authz → transform → enrich → route → deliver → audit → respond` (mẫu `routes/_templates/standard-9-stage.camel.yaml` hiện có). Chặng có thể rỗng nhưng không được đảo thứ tự kiểm tra lược đồ và ủy quyền ra sau chuyển đổi, vì chuyển đổi dữ liệu chưa được kiểm tra là nguồn lỗi chèn mã.

### 4.2. Xử lý lỗi và DLQ

**CC-CAMEL-04 · Bộ xử lý lỗi tường minh trên mọi luồng [tự động].** Mỗi tệp luồng khai báo `errorHandler` kiểu `deadLetterChannel` trỏ tới Kamelet DLQ chuẩn `dh-dlq-sink`, với chính sách thử lại có giới hạn: tối đa 3 lần, lùi theo cấp số nhân (khởi đầu 1 giây, hệ số 2, trần 30 giây), chỉ thử lại lỗi tạm thời (lỗi kết nối, `5xx`, `429`); lỗi `4xx` khác và lỗi kiểm tra lược đồ đưa thẳng vào DLQ không thử lại. Cấm `errorHandler: noErrorHandler` và cấm `onException` với `handled: true` mà không ghi DLQ hoặc phản hồi lỗi.

**CC-CAMEL-05 · DLQ mang đủ ngữ cảnh, không mang bí mật [tự động].** Bản tin vào DLQ (topic `{tenant}.integration.dlq.v1`) mang header CloudEvents `dhtenant`, `traceparent`, `routeId`, mã lỗi, số lần thử, thời điểm; thân bản tin được giữ nguyên để xử lý lại ở PH-18 nhưng trường mức Nhạy cảm đã được mã hóa hoặc che theo phân loại khai báo trong `route.meta.yaml`. Header xác thực (`Authorization`, cookie, khóa API) bị xóa trước khi ghi DLQ.

**CC-CAMEL-06 · Lỗi trả cho bên gọi theo RFC 9457 [tự động].** Luồng nhận đồng bộ (`platform-http`) trả lỗi bằng Kamelet `dh-problem-response` để có cùng định dạng `application/problem+json` với API Spring (mục 3.5), không trả ngăn xếp hay thông điệp ngoại lệ.

### 4.3. Kamelet và cấu hình

**CC-CAMEL-07 · Kết nối ra ngoài chỉ qua Kamelet đã duyệt [tự động].** Luồng nghiệp vụ không dùng trực tiếp URI thành phần kết nối ra ngoài (`http:`, `https:`, `sql:`, `ftp:`, `sftp:`, `kafka:`, `jms:`, `file:`), mà dùng Kamelet trong danh mục đã duyệt của PH-05 (`dh-http-sink`, `dh-sql-source`…). Kamelet đóng gói sẵn TLS, xác thực, giới hạn thời gian chờ (connect ≤ 5 giây, đọc ≤ 30 giây mặc định), giới hạn kích thước phản hồi, danh sách đích cho phép và che log. Validator chặn URI thành phần ngoài danh sách cho phép.

**CC-CAMEL-08 · Tham số qua property, bí mật qua kho bí mật [tự động].** Địa chỉ, thời gian chờ, ngưỡng dùng placeholder `{{datahub.route.xxx}}` đọc từ `application.properties` của luồng. Thông tin xác thực dùng tham chiếu kho bí mật `{{secret:kv/dh/{tenant}/...}}` (giải qua tích hợp OpenBao của Quarkus hoặc tệp do External Secrets gắn vào), không bao giờ ghi giá trị trong YAML. Kamelet có tham số đánh dấu `x-descriptors: urn:camel:group:credentials` để trình thiết kế không hiển thị và không lưu giá trị.

**CC-CAMEL-09 · Đích động phải qua danh sách cho phép [tự động].** `toD` với URI ghép từ dữ liệu bản tin là nguồn SSRF (CC-SEC-15). Chỉ được dùng `toD` khi phần động là tham số đường dẫn đã kiểm tra theo mẫu; máy chủ đích luôn tĩnh hoặc lấy từ danh sách đích đăng ký của HTTT thành viên.

### 4.4. Biểu thức bị cấm

**CC-CAMEL-10 · Không thực thi mã tùy ý trong luồng [tự động].** Luồng YAML chỉ được dùng ngôn ngữ biểu thức an toàn: `simple` (giới hạn ở truy cập header, thuộc tính, thân), `jq`, `jsonpath`, `xpath` (với bộ phân tích tắt thực thể ngoài, mục 9), `constant`, `header`, `exchangeProperty`. Các ngôn ngữ và thành phần sau bị cấm trong luồng nghiệp vụ vì cho phép thực thi mã hoặc truy cập hệ thống: `groovy`, `joor`, `java`, `js`, `python`, `mvel`, `ognl`, `spel`, `bean` với tên lớp động, `exec:`, `language:` với script từ bản tin, `class:`, `freemarker`/`velocity` với mẫu lấy từ dữ liệu. Biểu thức `simple` không được chứa `${bean:...}`, `${sys...}`, `${env...}` hay gọi phương thức qua `${body.xxx()}` trên đối tượng không phải dữ liệu. Validator và luật Semgrep YAML chặn các mẫu này.

**CC-CAMEL-11 · Mã Java trong `dh-runtime` tối thiểu [review].** Processor Java chỉ viết khi không diễn đạt được bằng YAML và Kamelet; nằm trong package `vn.datahub.runtime.{miền}`, đăng ký là bean có tên trong danh mục cho phép, tuân thủ toàn bộ mục 3 (null-safety, log, không ghép SQL). Không viết route bằng Java DSL cho luồng nghiệp vụ.

### 4.5. Native và quan sát

**CC-CAMEL-12 · Tương thích native [tự động].** Phụ thuộc mới của `dh-runtime` phải là extension Camel Quarkus có hỗ trợ native; lớp dùng phản chiếu phải đăng ký `@RegisterForReflection`. CI build ảnh native và chạy kiểm thử luồng ở chế độ native (`@QuarkusIntegrationTest`) trước khi phát hành phiên bản `dh-runtime`. Không dùng `Class.forName` với tên lấy từ cấu hình.

**CC-CAMEL-13 · Mọi luồng có trace, chỉ số, tenant [tự động].** Bật `camel-quarkus-opentelemetry` và `camel-quarkus-micrometer`; chỉ số mang nhãn `tenant`, `route_id`, không mang nhãn có số lượng giá trị lớn (mã bản tin, mã công dân). Header `traceparent` được nhận ở `receive` và truyền tiếp ở `deliver`. Tenant của bản tin lấy từ header `X-DH-Tenant` do APISIX đặt sau xác minh token hoặc từ `dhtenant` của sự kiện, được đối chiếu với tenant sở hữu luồng trong `route.meta.yaml`; không khớp thì từ chối và cảnh báo an ninh (D03-10 §3).

**CC-CAMEL-14 · Kiểm thử luồng [tự động].** Mỗi luồng có kiểm thử dùng `camel-quarkus-junit` hoặc Citrus, thay Kamelet ngoài bằng điểm cuối giả (`mock:`, WireMock), chạy ít nhất: một ca thành công, một ca lỗi lược đồ, một ca đích lỗi tạm thời để kiểm tra thử lại và DLQ, một ca tenant không khớp.

Ví dụ dưới đây là một luồng đúng quy chuẩn. Luồng có `routeId` tường minh, bộ xử lý lỗi DLQ, kiểm tra lược đồ trước chuyển đổi, gọi ra ngoài qua Kamelet và không chứa bí mật.

```yaml
- errorHandler:
    deadLetterChannel:
      deadLetterUri: kamelet:dh-dlq-sink?tenant={{datahub.tenant}}
      useOriginalMessage: true
      redeliveryPolicy:
        maximumRedeliveries: 3
        redeliveryDelay: 1000
        backOffMultiplier: 2
        maximumRedeliveryDelay: 30000
        useExponentialBackOff: true
        retryAttemptedLogLevel: WARN
- route:
    id: t68-tra-cuu-ho-tich-receive
    from:
      uri: platform-http:/api/flows/v1/tra-cuu-ho-tich
      parameters: { httpMethodRestrict: POST }
      steps:
        - to: { id: validate-schema, uri: "kamelet:dh-json-schema-validate?schemaRef=ho-tich-request-v1" }
        - to: { id: authorize, uri: "kamelet:dh-opa-authorize?policy=flows/tra_cuu_ho_tich" }
        - transform: { id: to-cdm, jq: { expression: "{ soDinhDanh: .so_dinh_danh, hoTen: .ho_ten }" } }
        - to: { id: deliver, uri: "kamelet:dh-http-sink?target={{datahub.route.target}}&timeoutMs=10000" }
        - to: { id: audit, uri: "kamelet:dh-audit-sink" }
```

Ví dụ sai dưới đây vi phạm CC-CAMEL-02 (không có `id`), CC-CAMEL-04 (không có xử lý lỗi), CC-CAMEL-07 và CC-CAMEL-09 (gọi `toD` với máy chủ lấy từ bản tin, gây SSRF), CC-CAMEL-08 (mật khẩu trong YAML) và CC-CAMEL-10 (dùng Groovy).

```yaml
# SAI — không làm theo
- route:
    from:
      uri: platform-http:/proxy
      steps:
        - setBody: { groovy: "request.body.replace('a','b')" }
        - toD: "https://${header.target}/api?user=admin&password=Secret123"
```

## 5. TypeScript, React 19, antd v6

Giao diện `dh-console` và `dh-portal` dùng React 19, TypeScript 5, Vite, antd v6 với phong cách Liquid Glass của design system `@datahub/ui` (ADR-020), TanStack Query cho trạng thái máy chủ và React Router. Mục này quy định cách viết mã giao diện; thiết kế thành phần và token ở D03-05, mẫu màn hình ở D03-06.

### 5.1. Cấu trúc thư mục

**CC-FE-01 · Kho mã giao diện theo workspace [tự động].** Giao diện là workspace pnpm (hoặc npm workspaces) gồm `apps/console`, `apps/portal`, `packages/ui` (`@datahub/ui`: thành phần, token, theme antd), `packages/api-client` (`@datahub/api-client`: kiểu và client sinh từ OpenAPI), `packages/i18n` (`@datahub/i18n`: chuỗi tiếng Việt) và `packages/eslint-config`. Ứng dụng tổ chức theo tính năng (feature) chứ không theo loại tệp. Cây dưới đây minh họa.

```text
apps/console/src/
├── app/                  # khởi tạo: router, QueryClient, ConfigProvider, AuthProvider
├── features/
│   └── rdm/              # PH-07
│       ├── api/          # hook TanStack Query: useCatalogs, useCreateCatalog
│       ├── components/   # CatalogTree.tsx, CatalogForm.tsx (chỉ dùng trong rdm)
│       ├── pages/        # CatalogListPage.tsx (UI-07-01), CatalogDetailPage.tsx
│       ├── routes.tsx    # khai báo route của tính năng, gắn quyền PERM-07-*
│       └── index.ts      # điểm xuất duy nhất của tính năng
├── shared/               # hook, tiện ích dùng chung trong ứng dụng
└── main.tsx
```

Cây trên cho thấy mỗi tính năng tương ứng một phân hệ và tự chứa mọi thứ của nó. Tính năng chỉ import tính năng khác qua `index.ts`; luật `import/no-restricted-paths` của ESLint chặn import sâu vào thư mục con của tính năng khác, tương tự ranh giới module ở backend.

### 5.2. Thành phần và hook

**CC-FE-02 · Thành phần hàm, có kiểu đầy đủ [tự động].** Chỉ dùng thành phần hàm; props khai báo bằng `type {Tên}Props`; không dùng `React.FC`; không dùng `any` (`@typescript-eslint/no-explicit-any: error`), dùng `unknown` rồi thu hẹp kiểu. `tsconfig` bật `strict`, `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`, `noImplicitOverride`. Một tệp một thành phần xuất ra, tên tệp trùng tên thành phần `PascalCase.tsx` (D00-01 §6).

**CC-FE-03 · Hook đặt tên `useXxx`, tuân thủ luật hook [tự động].** Hook tùy biến đặt tên `useCamelCase`, đặt trong `api/` (hook dữ liệu) hoặc `shared/hooks`. Bật `eslint-plugin-react-hooks` (`rules-of-hooks: error`, `exhaustive-deps: error`). Bật React Compiler của React 19 khi ổn định với antd v6 thì bỏ `useMemo`/`useCallback` thủ công; trước đó chỉ dùng khi đo được lợi ích.

**CC-FE-04 · Không thao tác DOM trực tiếp, không HTML thô [tự động].** Cấm `dangerouslySetInnerHTML` (trừ thành phần hiển thị Markdown của `@datahub/ui` có làm sạch bằng DOMPurify), `innerHTML`, `eval`, `new Function`, `document.write`. Luật `react/no-danger` và `no-eval` ở mức lỗi.

### 5.3. Dữ liệu máy chủ với TanStack Query

**CC-FE-05 · Mọi gọi API qua client sinh từ OpenAPI và TanStack Query [tự động].** Kiểu yêu cầu và phản hồi sinh bằng `openapi-typescript` vào `@datahub/api-client`; lời gọi dùng `openapi-fetch` với kiểu sinh, nên gọi đường dẫn không có trong hợp đồng là lỗi biên dịch. Không gọi `fetch` hay `axios` trực tiếp trong thành phần (luật `no-restricted-globals`/`no-restricted-imports`). Mỗi tài nguyên có một tệp hook trong `features/{x}/api/` với khóa truy vấn theo hàm tạo khóa (`catalogKeys.list(filters)`), không viết khóa dạng mảng tay rải rác.

**CC-FE-06 · Trạng thái máy chủ không sao chép vào trạng thái cục bộ [review].** Dữ liệu từ API sống trong bộ đệm TanStack Query; không chép vào `useState` hay kho toàn cục. Trạng thái lọc, sắp xếp, trang đặt trên URL qua search params (FR-00-022). Sau khi ghi, làm mới bằng `invalidateQueries` theo khóa; cập nhật lạc quan chỉ dùng khi có hoàn tác.

**CC-FE-07 · Gửi `If-Match` và `Idempotency-Key` [tự động].** Hook sửa gửi `If-Match` từ `version`/ETag đã đọc và xử lý `412` bằng hộp thoại xung đột chuẩn của `@datahub/ui` (FR-00-052). Hook tạo sinh `Idempotency-Key` một lần cho mỗi lần mở biểu mẫu, dùng lại khi người dùng bấm gửi lại.

**CC-FE-08 · Lỗi hiển thị theo mã, không theo câu chữ [review].** Lỗi `application/problem+json` được chuyển thành thông báo bằng thành phần `ProblemAlert` của `@datahub/ui`, hiển thị `title`, `detail` và `traceId` có nút sao chép; lỗi theo trường (`errors`) gắn vào trường biểu mẫu tương ứng.

### 5.4. Biểu mẫu

**CC-FE-09 · Biểu mẫu dùng `Form` của antd với lược đồ kiểm tra dùng chung [review].** Biểu mẫu dùng `Form` của antd v6 bọc qua thành phần `DhForm` của `@datahub/ui`. Quy tắc kiểm tra phía giao diện sinh từ ràng buộc OpenAPI hoặc khai báo bằng Zod theo cùng giới hạn, chỉ để phản hồi nhanh cho người dùng; máy chủ vẫn kiểm tra lại toàn bộ (CC-VAL-01). Biểu mẫu không gửi trường mà người dùng không được sửa (tenant, id, trạng thái).

### 5.5. Tiếng Việt và i18n

**CC-FE-10 · Không chuỗi hiển thị viết cứng trong thành phần [tự động].** Chuỗi hiển thị lấy từ `@datahub/i18n` qua hàm `t('rdm.catalog.publish.confirm')`; ngôn ngữ mặc định và duy nhất ở đợt đầu là tiếng Việt (`vi-VN`), cấu trúc sẵn sàng thêm ngôn ngữ khác. `ConfigProvider` của antd dùng `locale={viVN}`; ngày giờ hiển thị theo giờ Việt Nam định dạng `dd/MM/yyyy HH:mm:ss` (T-TS), số theo `Intl.NumberFormat('vi-VN')`, tiền theo đồng không phần thập phân. Luật ESLint `i18next/no-literal-string` (hoặc tương đương) chặn chuỗi chữ trong JSX.

### 5.6. Khả năng truy cập

**CC-FE-11 · WCAG 2.2 mức AA [tự động + review].** Mọi màn đạt 0 lỗi mức A/AA với axe-core (NFR-00-040), kiểm tra bằng `@axe-core/playwright` trong kiểm thử E2E và `eslint-plugin-jsx-a11y` ở mức lỗi. Mọi điều khiển có nhãn truy cập được; biểu tượng không chữ có `aria-label`; thứ tự focus hợp lý, có lối tắt "Bỏ qua tới nội dung" (NFR-00-042); vòng focus nhìn thấy với tương phản ≥ 3:1 kể cả trên nền glass (NFR-00-041); tôn trọng `prefers-reduced-motion` và `prefers-reduced-transparency` (NFR-00-043).

### 5.7. Design system và token, không CSS tự do

**CC-FE-12 · Chỉ dùng thành phần `@datahub/ui` [tự động].** Màn hình dùng thành phần của `@datahub/ui` (`CMP-*`, D03-05); import trực tiếp từ `antd` trong `apps/` chỉ được phép với danh sách thành phần nguyên thủy mà `@datahub/ui` tái xuất, kiểm tra bằng `no-restricted-imports` (NFR-00-045).

**CC-FE-13 · Không CSS tùy biến ngoài token [tự động].** Màu, khoảng cách, bo góc, bóng, độ mờ, cỡ chữ chỉ lấy từ token `--dh-{nhóm}-{vai-trò}-{biến-thể}` (`TKN-*`) hoặc từ `theme.useToken()` của antd đã ánh xạ token. Cấm: giá trị màu viết cứng (hex, `rgb()`, `oklch()`), `px` viết cứng ngoài token, thuộc tính `style={{...}}` mang giá trị trình bày, tệp `.css`/`.less` riêng trong `apps/` ngoài tệp luật bố cục chung. Stylelint với `stylelint-declaration-strict-value` và luật ESLint tùy biến `datahub/no-inline-style` ở mức lỗi; ngoại lệ (ví dụ kích thước canvas của trình thiết kế luồng) khai báo trong tệp cho phép có lý do.

**CC-FE-14 · Bố cục khóa chiều cao cửa sổ [review].** Tuân thủ luật bố cục ở `AGENTS.md` §6.1: không `height: 100vh` bên trong màn, mọi tổ tiên flex của vùng cuộn có `min-height: 0`, bảng rộng cuộn trong khối của nó.

### 5.8. Bảo mật phía trình duyệt

**CC-FE-15 · Token trong bộ nhớ, không trong `localStorage` [tự động].** Xác thực theo OIDC Authorization Code + PKCE với Keycloak (FR-00-001) qua `oidc-client-ts`; access token giữ trong bộ nhớ, refresh token theo cấu hình rotation của Keycloak; không lưu token trong `localStorage` hay `sessionStorage`. Không ghi dữ liệu Nhạy cảm vào kho trình duyệt. Ứng dụng chạy dưới CSP chặt (`default-src 'self'`, không `unsafe-inline` cho script) do APISIX đặt; mã không được cần `unsafe-eval`.

**CC-FE-16 · Ẩn nút không phải là phân quyền [review].** Giao diện ẩn hoặc vô hiệu hành động theo quyền để trải nghiệm tốt, nhưng mọi quyết định thật nằm ở backend; không có logic "nếu là quản trị thì gọi API khác".

### 5.9. ESLint, Prettier và kiểm thử giao diện

**CC-FE-17 · Bộ công cụ chuẩn [tự động].** ESLint 9 cấu hình phẳng (`eslint.config.js`) từ `@datahub/eslint-config` gồm `typescript-eslint` (strict-type-checked), `react`, `react-hooks`, `jsx-a11y`, `import`, `eslint-plugin-security`, `no-unsanitized` và luật tùy biến của Datahub; Prettier 3 (`printWidth: 100`, `singleQuote: true`, `trailingComma: 'all'`) chạy qua `eslint-config-prettier` để hai công cụ không xung đột. `tsc --noEmit`, `eslint --max-warnings 0`, `prettier --check`, `stylelint` chạy trong cổng lint giao diện.

**CC-FE-18 · Kiểm thử giao diện [tự động].** Kiểm thử đơn vị và thành phần dùng Vitest và Testing Library, truy vấn theo vai trò truy cập (`getByRole`) thay vì lớp CSS; giả lập API bằng MSW với dữ liệu sinh từ OpenAPI. Độ phủ ≥ 70% (NFR-00-053). E2E dùng Playwright cho luồng chính, kèm axe-core và Lighthouse CI (LCP ≤ 2,5 giây, INP ≤ 200 ms, NFR-00-005).

Ví dụ dưới đây là một hook và một thành phần đúng quy chuẩn.

```tsx
// features/rdm/api/useCatalogs.ts
import { useQuery } from '@tanstack/react-query';
import { api, type components } from '@datahub/api-client';

export type CatalogFilter = { q?: string; status?: components['schemas']['CatalogStatus']; page: number };

export const catalogKeys = {
  all: ['rdm', 'catalogs'] as const,
  list: (f: CatalogFilter) => [...catalogKeys.all, 'list', f] as const,
};

export function useCatalogs(filter: CatalogFilter) {
  return useQuery({
    queryKey: catalogKeys.list(filter),
    queryFn: async () => {
      const { data, error } = await api.GET('/api/rdm/v1/catalogs', {
        params: { query: { q: filter.q, status: filter.status, page: filter.page, size: 20 } },
      });
      if (error) throw error; // problem+json đã có kiểu
      return data;
    },
  });
}
```

```tsx
// features/rdm/pages/CatalogListPage.tsx  (UI-07-01)
import { DhPage, DhDataTable, StatusTag, ProblemAlert } from '@datahub/ui';
import { useT } from '@datahub/i18n';
import { useCatalogFilterFromUrl } from '../hooks/useCatalogFilterFromUrl';
import { useCatalogs } from '../api/useCatalogs';

export function CatalogListPage() {
  const t = useT();
  const [filter, setFilter] = useCatalogFilterFromUrl();
  const { data, error, isPending } = useCatalogs(filter);
  return (
    <DhPage title={t('rdm.catalog.list.title')}>
      {error && <ProblemAlert problem={error} />}
      <DhDataTable
        rowKey="id"
        loading={isPending}
        dataSource={data?.items}
        columns={[
          { key: 'code', title: t('rdm.catalog.code'), dataIndex: 'code', sorter: true },
          { key: 'name', title: t('rdm.catalog.name'), dataIndex: 'name' },
          { key: 'status', title: t('common.status'), render: (_, r) => <StatusTag status={r.status} /> },
        ]}
        onQueryChange={setFilter}
      />
    </DhPage>
  );
}
```

Ví dụ sai dưới đây vi phạm CC-FE-05 (gọi `fetch` trực tiếp, đường dẫn tự gõ), CC-FE-06 (chép dữ liệu máy chủ vào `useState`), CC-FE-10 (chuỗi viết cứng), CC-FE-13 (màu và khoảng cách viết cứng) và CC-FE-02 (`any`).

```tsx
// SAI — không làm theo
const [rows, setRows] = useState<any[]>([]);
useEffect(() => { fetch('/api/rdm/catalogs').then(r => r.json()).then(setRows); }, []);
return <div style={{ color: '#1677ff', padding: 13 }}>Danh mục: {rows.length}</div>;
```

## 6. SQL, PostgreSQL 18 và Liquibase

Mỗi DU Spring Boot quản lý lược đồ CSDL của các phân hệ mình bằng Liquibase định dạng YAML (một công cụ cho toàn kho mã, không trộn Flyway). Mục này áp quy ước đặt tên D00-01 §6, kiểu chuẩn §5 và cột bắt buộc §5.1 vào migration.

### 6.1. Đặt tên và kiểu

**CC-SQL-01 · Đặt tên theo D00-01 §6 [tự động].** Schema `ph{nn}_{tên-ngắn}` (ví dụ `ph07_rdm`); bảng và cột `snake_case`, tiếng Anh, danh từ số ít (`catalog_item`, `published_at`). Tên ràng buộc và chỉ mục theo mẫu trong bảng dưới đây để thông báo lỗi CSDL tự giải thích và để migration sau tìm được đối tượng theo tên.

| Đối tượng | Mẫu | Ví dụ |
|---|---|---|
| Khóa chính | `pk_{bảng}` | `pk_catalog` |
| Khóa ngoại | `fk_{bảng}_{bảng-đích}` hoặc `fk_{bảng}_{cột}` | `fk_catalog_item_catalog` |
| Duy nhất | `uq_{bảng}_{cột...}` | `uq_catalog_tenant_id_code` |
| Kiểm tra | `ck_{bảng}_{cột}` | `ck_catalog_status` |
| Chỉ mục | `ix_{bảng}_{cột...}` | `ix_catalog_item_tenant_id_catalog_id` |
| Chính sách RLS | `tenant_isolation` (đọc ghi), `common_read` (đọc dữ liệu `COMMON`) | — |
| Changeset `id` | `{số-thứ-tự-tệp}-{mô-tả-kebab}` | `012-create-catalog-item` |
| Tệp changelog | `changes/{nnn}-{mô-tả}.yaml` | `changes/012-catalog-item.yaml` |

**CC-SQL-02 · Kiểu chuẩn và cột bắt buộc [tự động].** Cột dùng kiểu PostgreSQL theo D00-01 §5 (`uuid` cho `T-ID`, `varchar(64)` cho `T-CODE`, `timestamptz` cho `T-TS`, `numeric(19,0)` cho `T-MONEY`, `varchar(32)` + `CHECK` cho `T-ENUM`, `jsonb` cho `T-JSON`, `varchar(16)` cho `T-TENANT`, `varchar(255)` cho `T-SECRET-REF`). Mọi bảng nghiệp vụ có `id`, `tenant_id`, `created_at`, `created_by`, `updated_at`, `updated_by`, `version`; bảng xóa mềm có `deleted_at`. Cấm `timestamp without time zone`, `float`/`real`/`double precision` cho tiền, `serial`/`identity` cho khóa chính bảng nghiệp vụ, `text` không giới hạn cho trường có giới hạn ở API. Tính duy nhất của mã nghiệp vụ luôn tính trong tenant: `UNIQUE (tenant_id, code)`, không phải `UNIQUE (code)`.

### 6.2. RLS trong cùng changeset

**CC-SQL-03 · Bảng mới kèm `tenant_id NOT NULL` và RLS trong cùng changeset [tự động].** Đây là quy tắc 3 của D03-10 §6. Changeset tạo bảng phải chứa, theo thứ tự: tạo bảng có `tenant_id varchar(16) NOT NULL`, `ENABLE ROW LEVEL SECURITY`, `FORCE ROW LEVEL SECURITY`, `CREATE POLICY tenant_isolation` với `USING` và `WITH CHECK` dùng `current_setting('app.tenant_id', false)`, và cấp quyền cho vai trò ứng dụng. Đặt trong cùng changeset để không có thời điểm nào bảng tồn tại mà không có chính sách, kể cả khi migration dừng giữa chừng. Bộ lint migration (mục 6.4) chặn changeset `createTable` không có các lệnh này; ngoài ra DU tự kiểm tra lúc khởi động và từ chối chạy nếu có bảng trong schema của mình thiếu chính sách hoặc vai trò kết nối có `BYPASSRLS` (D03-10 §4).

**CC-SQL-04 · Vai trò CSDL tách bạch [review].** Migration chạy bằng vai trò chủ sở hữu schema (`ph07_rdm_owner`), ứng dụng chạy bằng vai trò không sở hữu bảng và không có `BYPASSRLS` (`ph07_rdm_app`), chỉ có `SELECT, INSERT, UPDATE, DELETE` trên bảng của schema mình. Bảng nhật ký kiểm toán và outbox chỉ cấp `INSERT, SELECT` (không `UPDATE`, `DELETE`) cho vai trò ứng dụng.

Ví dụ dưới đây là một changeset tạo bảng đúng quy chuẩn.

```yaml
databaseChangeLog:
  - changeSet:
      id: 012-create-catalog-item
      author: team-ph07
      comment: EN-07-03 Mục danh mục (FR-07-003)
      changes:
        - sql:
            splitStatements: true
            sql: |
              CREATE TABLE ph07_rdm.catalog_item (
                id          uuid         NOT NULL,
                tenant_id   varchar(16)  NOT NULL,
                catalog_id  uuid         NOT NULL,
                code        varchar(64)  NOT NULL,
                name        varchar(255) NOT NULL,
                status      varchar(32)  NOT NULL,
                attributes  jsonb        NOT NULL DEFAULT '{}'::jsonb,
                valid_from  date         NOT NULL,
                valid_to    date,
                created_at  timestamptz  NOT NULL,
                created_by  uuid         NOT NULL,
                updated_at  timestamptz  NOT NULL,
                updated_by  uuid         NOT NULL,
                version     integer      NOT NULL DEFAULT 0,
                deleted_at  timestamptz,
                CONSTRAINT pk_catalog_item PRIMARY KEY (id),
                CONSTRAINT fk_catalog_item_catalog FOREIGN KEY (catalog_id) REFERENCES ph07_rdm.catalog (id),
                CONSTRAINT uq_catalog_item_tenant_id_catalog_id_code UNIQUE (tenant_id, catalog_id, code),
                CONSTRAINT ck_catalog_item_status CHECK (status IN ('DRAFT','ACTIVE','RETIRED'))
              );
              CREATE INDEX ix_catalog_item_tenant_id_catalog_id ON ph07_rdm.catalog_item (tenant_id, catalog_id);
              ALTER TABLE ph07_rdm.catalog_item ENABLE ROW LEVEL SECURITY;
              ALTER TABLE ph07_rdm.catalog_item FORCE ROW LEVEL SECURITY;
              CREATE POLICY tenant_isolation ON ph07_rdm.catalog_item
                USING (tenant_id = current_setting('app.tenant_id', false))
                WITH CHECK (tenant_id = current_setting('app.tenant_id', false));
              GRANT SELECT, INSERT, UPDATE, DELETE ON ph07_rdm.catalog_item TO ph07_rdm_app;
      rollback:
        - sql: { sql: "DROP TABLE ph07_rdm.catalog_item;" }
```

### 6.3. Migration an toàn, không khóa bảng

Datahub nâng cấp cuốn chiếu không gián đoạn data plane (NFR-00-013), nên migration phải chạy được khi phiên bản cũ của ứng dụng vẫn đang phục vụ. Mỗi thay đổi lược đồ phá vỡ được tách thành chuỗi các bước tương thích theo mẫu mở rộng rồi thu hẹp (expand–contract): thêm cái mới, chạy song song, chuyển dữ liệu, rồi mới bỏ cái cũ ở một phiên bản phát hành sau.

**CC-SQL-05 · Mỗi migration tương thích với phiên bản ứng dụng liền trước [review].** Đổi tên cột hay bảng làm bằng thêm cột mới, ghi cả hai, chuyển dữ liệu theo lô, đọc cột mới, rồi xóa cột cũ ở phiên bản sau. Không xóa cột còn được phiên bản đang chạy đọc.

**CC-SQL-06 · Tránh lệnh giữ khóa lâu [tự động].** Các mẫu sau bị bộ lint migration chặn hoặc bắt buộc viết theo cách an toàn, như liệt kê trong bảng dưới đây.

| Thao tác | Cách cấm | Cách đúng |
|---|---|---|
| Tạo chỉ mục trên bảng đã có dữ liệu | `CREATE INDEX` thường | `CREATE INDEX CONCURRENTLY` trong changeset riêng có `runInTransaction: false` |
| Thêm khóa ngoại | `ADD CONSTRAINT ... FOREIGN KEY` một bước | `ADD CONSTRAINT ... NOT VALID`, sau đó `VALIDATE CONSTRAINT` ở changeset riêng |
| Thêm `CHECK` | Một bước | `NOT VALID` rồi `VALIDATE` |
| Thêm cột `NOT NULL` | `ADD COLUMN ... NOT NULL` không mặc định trên bảng lớn | Thêm cột cho phép rỗng hoặc có `DEFAULT` hằng, điền dữ liệu theo lô, thêm `CHECK (col IS NOT NULL) NOT VALID`, `VALIDATE`, rồi `SET NOT NULL` |
| Đổi kiểu cột | `ALTER COLUMN TYPE` gây ghi lại bảng | Thêm cột mới, chuyển dữ liệu, đổi đọc ghi |
| Cập nhật hàng loạt | Một `UPDATE` cho cả bảng | Cập nhật theo lô ≤ 10.000 dòng mỗi giao dịch, bằng tác vụ của ứng dụng hoặc changeset lặp |
| Mọi changeset | Không đặt thời gian chờ | Đặt `SET lock_timeout = '5s'` và `statement_timeout` hợp lý ở đầu changeset để thất bại sớm thay vì xếp hàng chặn lưu lượng |

**CC-SQL-07 · Changeset bất biến, có rollback [tự động].** Changeset đã chạy ở môi trường dùng chung không được sửa (Liquibase kiểm tra checksum); sửa sai bằng changeset mới. Mỗi changeset có `rollback` hoặc ghi lý do không thể hoàn tác trong `comment`. Không dùng `runAlways`, trừ changeset tạo lại hàm hoặc view có `runOnChange` được duyệt.

**CC-SQL-08 · Dữ liệu tham chiếu tách khỏi lược đồ [review].** Dữ liệu nền (danh mục bắt buộc) nạp bằng changeset có `context: seed` và chỉ chứa dữ liệu `COMMON` hoặc dữ liệu mẫu; dữ liệu theo tenant được nạp bởi saga khởi tạo tenant (D03-10 §5.2), không bằng migration.

### 6.4. Chỉ mục, khóa ngoại và kiểm tra tự động

**CC-SQL-09 · Chỉ mục bắt đầu bằng `tenant_id` [review].** Chỉ mục phục vụ truy vấn nghiệp vụ đặt `tenant_id` làm cột đầu (vì mọi truy vấn đều có điều kiện RLS theo tenant). Mọi khóa ngoại có chỉ mục trên cột tham chiếu. Chỉ mục mới phải kèm câu truy vấn mà nó phục vụ trong `comment`. Bảng nhật ký lớn (siêu dữ liệu lượt gọi, NFR-00-062) dùng phân vùng theo thời gian (`PARTITION BY RANGE (created_at)`), không xóa bằng `DELETE`.

**CC-SQL-10 · Khóa ngoại trong phạm vi schema [review].** Khóa ngoại chỉ trỏ trong cùng schema phân hệ. Tham chiếu tới dữ liệu của phân hệ khác lưu dưới dạng mã hoặc `id` không có khóa ngoại, tính nhất quán bảo đảm bằng sự kiện (SAD §7.3).

**CC-SQL-11 · Lint migration trong CI [tự động].** Cổng build chạy bộ lint migration gồm Squawk (bắt mẫu khóa bảng) và luật tùy biến của Datahub (kiểm tra cột bắt buộc, RLS trong cùng changeset, tên ràng buộc, kiểu cấm), cùng một kiểm thử tích hợp chạy toàn bộ changelog trên PostgreSQL 18 Testcontainers rồi truy vấn `pg_class`, `pg_policy` để xác nhận mọi bảng trong schema phân hệ có `relrowsecurity` và `relforcerowsecurity` bằng `true` và có chính sách `tenant_isolation`.

## 7. Hợp đồng OpenAPI và AsyncAPI

**CC-API-01 · Hợp đồng nằm trong `contracts/` và là nguồn sự thật [tự động].** Đặc tả OpenAPI 3.1 đặt ở `contracts/openapi/{nhóm}-v{n}.yaml`, AsyncAPI 3.0 ở `contracts/asyncapi/{miền}-v{n}.yaml`, schema sự kiện (JSON Schema hoặc Avro) ở `contracts/schemas/`. Mã máy chủ kiểm tra khớp với hợp đồng bằng kiểm thử hợp đồng; mã khách sinh từ hợp đồng. PR thay đổi hợp đồng phải được duyệt trước hoặc cùng lúc với PR hiện thực (quy trình ở D04-02 §13).

**CC-API-02 · Quy ước nội dung hợp đồng [tự động].** Mỗi operation có `operationId` dạng `camelCase` duy nhất, nhãn `x-datahub-id: API-{PH}-{nnn}`, `x-datahub-fr` liệt kê FR phục vụ, `x-datahub-permission: PERM-{PH}-{động-từ}`, `security` khai báo tường minh (không có operation nào thiếu `security` trừ `health`), phản hồi lỗi tham chiếu `components/responses/Problem` (RFC 9457), đường dẫn theo `/api/{nhóm}/v{n}/{tài-nguyên-số-nhiều}` kebab-case (D00-01 §6). Mọi schema có `additionalProperties: false` ở yêu cầu, mọi chuỗi có `maxLength`, mọi mảng có `maxItems`, mọi số có `minimum`/`maximum`, mọi trường dùng kiểu chuẩn D00-01 §5 (pattern, format). Spectral chạy bộ luật `@datahub/spectral-ruleset` (kế thừa `spectral:oas` và luật OWASP API Security của Spectral) với mức lỗi chặn merge.

**CC-API-03 · Không thay đổi phá vỡ trong một phiên bản chính [tự động].** oasdiff so sánh hợp đồng với nhánh chính và chặn thay đổi phá vỡ (xóa trường, đổi kiểu, thêm trường bắt buộc ở yêu cầu, thu hẹp enum ở phản hồi…) trừ khi tăng phiên bản chính trong đường dẫn (NFR-00-055). Phiên bản cũ được duy trì ≥ 6 tháng, có header `Deprecation` và `Sunset`.

**CC-API-04 · Sự kiện theo CloudEvents và đặt tên topic chuẩn [tự động].** Sự kiện là CloudEvents 1.0 chế độ có cấu trúc hoặc nhị phân với `id` (UUID v7), `source` (`/datahub/{du}/{module}`), `type` (`vn.datahub.{miền}.{thực-thể}.{sự-kiện}.v{n}`), `time`, phần mở rộng `dhtenant`, `traceparent`, `dataschema` trỏ tới Apicurio. Topic theo `{tenant}.{miền}.{thực-thể}.{sự-kiện}.v{n}` (D00-01 §6), tạo bằng hàm chung `Topics.forTenant(...)`. Mỗi sự kiện có mã `EVT-{PH}-{nn}`. Schema đăng ký Apicurio với chế độ tương thích `BACKWARD` (hoặc `FULL` cho sự kiện công bố cho HTTT ngoài), consumer đọc khoan dung (tolerant reader): bỏ qua trường lạ, không lỗi khi thiếu trường tùy chọn.

**CC-API-05 · Sự kiện không mang dữ liệu Nhạy cảm không cần thiết [review].** Sự kiện mang mã và trường tối thiểu để bên nhận phản ứng (mẫu "thông báo có tham chiếu"); bên nhận cần chi tiết thì gọi API có kiểm soát quyền. Trường mức Nhạy cảm không đặt vào sự kiện trừ khi SDD ghi rõ và trường được mã hóa.

## 8. Quy tắc đa tenant

Mục này nhắc lại **nguyên văn** sáu quy tắc cho người phát triển của D03-10 §6, gán mã `CC-TEN-01` đến `CC-TEN-06`, và chỉ ra cách mỗi quy tắc được kiểm tra tự động. Nguyên văn được giữ để không có khác biệt diễn giải giữa thiết kế và quy chuẩn; khi D03-10 thay đổi, bảng này phải được cập nhật theo.

Bảng dưới đây gồm cột quy tắc nguyên văn, cột công cụ kiểm tra và cột cổng CI chặn vi phạm (định nghĩa cổng ở D04-02 §6).

| Mã | Quy tắc (nguyên văn D03-10 §6) | Kiểm tra tự động | Cổng |
|---|---|---|---|
| CC-TEN-01 | Không đọc tenant từ tham số đường dẫn, query hay thân yêu cầu. | Luật Semgrep cấm `@PathVariable`/`@RequestParam`/trường record yêu cầu có tên `tenant`, `tenantId`, `tenant_id` trong controller ngoài nhóm `/api/platform/`; luật Spectral cấm tham số hoặc thuộc tính tên `tenant*` trong hợp đồng ngoài nhóm `platform`; luật ArchUnit cấm gọi `TenantContext.set` ngoài `shared.security`; kiểm thử gửi `tenant_id` khác trong thân và xác nhận bị bỏ qua (FR-00-010) | Build, SAST, Hợp đồng |
| CC-TEN-02 | Không dùng `@Query` native vượt qua RLS; không tạo kết nối CSDL ngoài `DataSource` được quản lý. | Luật ArchUnit: `nativeQuery = true` chỉ trong danh sách cho phép; cấm `DriverManager`, cấm tạo `DataSource`/`HikariDataSource` ngoài `shared.persistence`; DU tự kiểm tra lúc khởi động vai trò không có `BYPASSRLS`; Semgrep cấm `SET ROLE`, `SET app.tenant_id` trong mã nghiệp vụ | Build, SAST |
| CC-TEN-03 | Mọi bảng mới phải có `tenant_id NOT NULL` và chính sách RLS trong cùng changeset. | Lint migration tùy biến (CC-SQL-11); kiểm thử tích hợp truy vấn `pg_class`/`pg_policy`; kiểm tra lúc khởi động DU | Build, Tích hợp |
| CC-TEN-04 | Mọi khóa bộ nhớ đệm, tên topic, khóa đối tượng phải dùng hàm tạo tên có tenant của thư viện dùng chung, không ghép chuỗi tay. | Semgrep cấm ghép chuỗi làm đối số của `KafkaTemplate.send`, `RedisTemplate`/`ValkeyTemplate` khóa, `S3Client.putObject` key, `@Cacheable(key=...)` không dùng `TenantKeys`; ArchUnit cấm phụ thuộc trực tiếp các client này ngoài `shared` | SAST, Build |
| CC-TEN-05 | Mọi tác vụ nền phải được bọc trong `TenantContext.runAs(tenant, …)`. | Luật ArchUnit tùy biến trên phương thức `@Scheduled`, `@KafkaListener`, `@ApplicationModuleListener`, `@Async`; khi chạy, `TenantContext.require()` ném lỗi nếu chưa đặt tenant và kiểm thử tích hợp của tác vụ nền kiểm tra điều này | Build, Tích hợp |
| CC-TEN-06 | Mỗi API mới phải có ít nhất một ca kiểm thử rò rỉ chéo tenant: tạo dữ liệu ở tenant A, truy cập bằng token tenant B, kỳ vọng `404` (không phải `403`, để không lộ sự tồn tại). | Kiểm thử meta đối chiếu mọi endpoint với danh sách kiểm thử rò rỉ đã đăng ký (CC-TEST-03); bộ kiểm thử rò rỉ chéo tenant chạy trong cổng tích hợp | Tích hợp |

Ngoài sáu quy tắc trên, hai quy tắc bổ sung dưới đây cụ thể hóa D03-10 §3 cho mã nguồn.

**CC-TEN-07 · Tenant của sự kiện phải khớp hai nguồn [tự động].** Consumer Kafka so sánh header `dhtenant` với tiền tố tên topic; không khớp thì chuyển DLQ và phát cảnh báo an ninh, không xử lý. Thư viện chung `TenantAwareRecordInterceptor` làm việc này cho mọi listener.

**CC-TEN-08 · Truy cập liên tenant đi qua API nền tảng có lý do [review].** Chỉ mã trong nhóm `/api/platform/` với vai trò nền tảng được chuyển tenant, bằng `TenantContext.runAsCrossTenant(target, reason, …)`, hàm này bắt buộc lý do và ghi kiểm toán (FR-00-012). Không có cờ "bỏ qua tenant" trong mã nghiệp vụ.

## 9. Lập trình an toàn theo OWASP ASVS 5.0 mức 2

### 9.1. Mục tiêu và cách áp dụng

Datahub phải đạt OWASP ASVS 5.0 mức 2 cho mọi ứng dụng web và API (NFR-00-024). ASVS là chuẩn kiểm chứng, không phải quy chuẩn viết mã, nên mục này dịch từng chương ASVS thành quy tắc lập trình cụ thể và công cụ phát hiện vi phạm sớm nhất có thể, để đến lúc kiểm thử xâm nhập và kiểm thử ASVS ở D05-01 thì phần lớn yêu cầu đã được bảo đảm từ mã. Nhóm quy tắc này hiện thực các biện pháp thuộc dải SEC-40–49 của D03-07 ở mức mã nguồn; số hiệu biện pháp cụ thể trong dải sẽ được gắn khi D03-07 chốt (Q358).

**CC-SEC-01 · ASVS 5.0 mức 2 là đường cơ sở [review].** Mọi tính năng chạm vào xác thực, phân quyền, xử lý tệp, gọi ra ngoài, mật mã hoặc dữ liệu Nhạy cảm phải được gắn nhãn `security-impact` trên PR và qua người duyệt bảo mật (D04-02 §5.2). Danh mục kiểm tra review bảo mật ở D04-02 §5.4 được rút từ bảng 9.2.

**CC-SEC-02 · Mô hình hóa mối đe dọa cho tính năng mới có bề mặt ngoài [review].** Tính năng mở endpoint cho HTTT bên ngoài, thêm Kamelet kết nối loại hệ thống mới, hoặc xử lý loại dữ liệu Nhạy cảm mới phải có ghi chú mô hình mối đe dọa theo STRIDE (tối thiểu một trang trong SDD phân hệ) trước khi hiện thực.

### 9.2. Bảng ánh xạ chương ASVS 5.0 → quy tắc → công cụ

Bảng dưới đây liệt kê mười bảy chương của ASVS 5.0, quy tắc lập trình chính đáp ứng chương đó trong Datahub và công cụ kiểm tra. Chương V17 (WebRTC) không áp dụng vì Datahub không dùng WebRTC. Công cụ được viết tắt như sau: Semgrep là bộ luật Semgrep của Datahub kèm bộ luật cộng đồng `p/java`, `p/typescript`, `p/owasp-top-ten`; CodeQL là truy vấn `security-extended` cho Java và JavaScript/TypeScript; FSB là SpotBugs với plugin FindSecBugs; ESL-S là `eslint-plugin-security` và `eslint-plugin-no-unsanitized`; ZAP là quét DAST OWASP ZAP trên môi trường kiểm thử.

| Chương ASVS 5.0 | Quy tắc lập trình Datahub | Công cụ kiểm tra |
|---|---|---|
| V1 Encoding and Sanitization | Truy vấn tham số hóa (CC-JPA-03, CC-SEC-10, 11); không HTML thô ở giao diện (CC-FE-04); thoát ký tự theo ngữ cảnh khi sinh tệp (CC-SEC-16); không thực thi biểu thức tùy ý trong luồng (CC-CAMEL-10); không gọi lệnh hệ thống (CC-SEC-17) | Semgrep, CodeQL, FSB, ESL-S, validator luồng |
| V2 Validation and Business Logic | Kiểm tra đầu vào ở biên bằng danh sách cho phép (CC-VAL-01…05); quy tắc nghiệp vụ ở tầng dịch vụ (CC-VAL-04); idempotency và chống gửi lặp (CC-TX-05…07); hạn mức theo tenant tại APISIX | Kiểm thử đơn vị, kiểm thử hợp đồng, Spectral (`maxLength`, `additionalProperties`) |
| V3 Web Frontend Security | CSP chặt, không `unsafe-eval` (CC-FE-15); token trong bộ nhớ; header bảo mật (HSTS, `X-Content-Type-Options`, `frame-ancestors`) do APISIX đặt; cookie (nếu có) `Secure`, `HttpOnly`, `SameSite=Strict` | ESL-S, ZAP, Lighthouse (best practices), kiểm thử E2E kiểm header |
| V4 API and Web Service | Hợp đồng trước (CC-API-01, 02); phương thức HTTP đúng ngữ nghĩa, không đổi trạng thái bằng `GET`; giới hạn kích thước và độ sâu (CC-VAL-05); phân trang có trần (CC-JPA-05); không lộ trường thừa (CC-JAVA-05) | Spectral (OWASP API ruleset), oasdiff, kiểm thử hợp đồng, ZAP API scan |
| V5 File Handling | Tải lên theo danh sách phần mở rộng và kiểm tra nội dung thật (magic bytes), giới hạn kích thước, tên lưu là UUID, lưu vào kho đối tượng không vào hệ tệp máy chủ, quét mã độc (CC-SEC-18); chống path traversal (CC-SEC-14); chống chèn công thức khi xuất (CC-SEC-16) | Semgrep, CodeQL (path injection), kiểm thử đơn vị với tệp độc mẫu |
| V6 Authentication | Không có màn đăng nhập riêng, xác thực qua Keycloak OIDC + PKCE (FR-00-001); không tự lưu mật khẩu; MFA và khóa tài khoản do Keycloak thực thi (NFR-00-025, 026) | Review, kiểm thử cấu hình realm |
| V7 Session Management | Phiên do Keycloak quản lý; tự đăng xuất theo FR-00-003; thu hồi phiên (FR-00-005); giao diện không giữ token lâu (CC-FE-15) | Kiểm thử E2E, ZAP |
| V8 Authorization | Từ chối mặc định, mọi endpoint có quyền `PERM` (CC-SEC-08); kiểm tra quyền trên đối tượng chống IDOR/BOLA (CC-SEC-20); chống leo quyền chức năng (CC-SEC-22); cách ly tenant (mục 8); chính sách OPA có kiểm thử Rego | ArchUnit, kiểm thử phân quyền âm tính (CC-TEST-04), kiểm thử rò rỉ chéo tenant, `opa test` |
| V9 Self-contained Tokens | Xác minh chữ ký JWT bằng JWKS của realm, kiểm `iss`, `aud`, `exp`, `nbf`, chỉ chấp nhận thuật toán bất đối xứng được liệt kê (RS256/ES256/PS256), từ chối `none` và `HS*` (CC-SEC-27) | Kiểm thử đơn vị với token giả mạo, Semgrep (JWT không xác minh) |
| V10 OAuth and OIDC | Client giao diện là client công khai + PKCE; máy–máy dùng `client_credentials` với mTLS (RFC 8705) hoặc `private_key_jwt` (RFC 7523) theo RFC 9700; không dùng luồng implicit hay password grant | Review cấu hình client Keycloak, kiểm thử tích hợp |
| V11 Cryptography | Chỉ dùng thư viện chung `vn.datahub.common.crypto` bọc OpenBao transit và JCA với thuật toán được duyệt (AES-256-GCM, SHA-256 trở lên, HMAC-SHA256, Ed25519/ECDSA P-256); cấm MD5, SHA-1, DES, ECB, IV cố định; số ngẫu nhiên bảo mật bằng `SecureRandom` (CC-SEC-25, 26) | Semgrep, FSB (WEAK_MESSAGE_DIGEST, CIPHER_INTEGRITY, PREDICTABLE_RANDOM), CodeQL |
| V12 Secure Communication | Mọi gọi ra ngoài qua HTTPS với kiểm tra chứng chỉ và tên máy (không `TrustAllCerts`, không tắt hostname verification); mTLS nội bộ do Istio ambient; TLS 1.2 tối thiểu cho HTTT cũ, 1.3 ưu tiên (NFR-00-020) | Semgrep, FSB (WEAK_TRUST_MANAGER, WEAK_HOSTNAME_VERIFIER) |
| V13 Configuration | Không bí mật trong mã (CC-GEN-05, CC-CFG-02); Actuator tối thiểu (CC-CFG-05); phụ thuộc không có lỗ hổng nghiêm trọng (CC-GEN-09); ảnh container tối thiểu, chạy không root; không bật chế độ gỡ lỗi ở sản xuất | gitleaks, Trivy (phụ thuộc, ảnh, IaC), OWASP Dependency-Check hoặc Trivy SCA, Checkov/Trivy config cho Kustomize |
| V14 Data Protection | Phân loại dữ liệu bốn mức (SAD §8.2); mã hóa trường Nhạy cảm ở tầng ứng dụng (CC-JPA-07); che khi hiển thị và khi xuất (FR-00-034); không đặt dữ liệu Nhạy cảm vào URL, log, sự kiện (CC-LOG-04, CC-API-05); `Cache-Control: no-store` cho phản hồi có dữ liệu Hạn chế trở lên | Bộ quét mẫu dữ liệu trên log, Semgrep, review |
| V15 Secure Coding and Architecture | Ranh giới module (CC-MOD-*); phụ thuộc được ghim và kiểm kê bằng SBOM (D04-02 §8, §10); chống giải tuần tự không an toàn (CC-SEC-12); chống gán hàng loạt (CC-SEC-21); xử lý đồng thời an toàn bằng khóa lạc quan (CC-TX-04) | ArchUnit, Modulith verify, Semgrep, FSB, Syft/CycloneDX |
| V16 Security Logging and Error Handling | Log JSON có trace và tenant (CC-LOG-01, 02); nhật ký kiểm toán chỉ-thêm (CC-LOG-07); không lộ chi tiết lỗi (CC-ERR-03); chống chèn log (CC-LOG-05, CC-SEC-30); ghi sự kiện an ninh (đăng nhập thất bại, từ chối quyền, tenant không khớp) ở dạng có thể đưa lên SIEM | Semgrep, kiểm thử tích hợp kiểm trường log, bộ quét mẫu dữ liệu |
| V17 WebRTC | Không áp dụng | — |

### 9.3. Mẫu cấm và cách viết đúng

Phần này liệt kê các mẫu mã bị cấm thường gặp nhất trong loại hệ thống như Datahub: nền tảng tích hợp nhận dữ liệu từ hàng trăm HTTT, gọi ra nhiều hệ thống khác, xuất nhập tệp Excel và phục vụ nhiều tenant. Mỗi mẫu có mã quy tắc, giải thích ngắn về nguy cơ, cách đúng và công cụ phát hiện.

**CC-SEC-08 · Mọi endpoint gắn quyền tường minh [tự động].** Phương thức controller phải có `@RequiresPermission("PERM-07-publish")` (annotation của thư viện chung, chuyển thành kiểm tra Spring Security và truy vấn OPA khi cần thuộc tính) hoặc `@PreAuthorize`. Cấu hình bảo mật mặc định `anyRequest().denyAll()` cho đường dẫn không khai báo. Luật ArchUnit ở CC-MOD-05 chặn phương thức thiếu annotation.

**CC-SEC-10 · Cấm SQL, JPQL ghép chuỗi [tự động].** Ghép đầu vào vào câu truy vấn mở đường cho SQL injection, kể cả khi đầu vào "đã kiểm tra". Phát hiện bằng Semgrep (`java.lang.security.audit.formatted-sql-string`, `jdbc-sqli`), CodeQL (`java/sql-injection`), FSB (`SQL_INJECTION_*`).

```java
// SAI
jdbc.queryForList("SELECT * FROM ph07_rdm.catalog WHERE code = '" + code + "'");
// ĐÚNG
jdbc.sql("SELECT id, code, name FROM ph07_rdm.catalog WHERE code = :code")
    .param("code", code).query(CatalogRow.class).list();
```

**CC-SEC-11 · Tên cột, chiều sắp xếp động qua danh sách cho phép [tự động].** Tên cột không tham số hóa được, nên tham số `sort` từ client được ánh xạ qua `Map<String, String>` cố định sang tên cột; giá trị không có trong bản đồ trả `400`. Với Spring Data, dùng `Sort` được dựng từ danh sách cho phép, không truyền nguyên `Pageable` từ client vào truy vấn native.

**CC-SEC-12 · Cấm giải tuần tự không an toàn [tự động].** Không dùng `ObjectInputStream`, `XMLDecoder`, XStream không cấu hình danh sách cho phép, SnakeYAML `new Yaml()` với constructor mặc định trên dữ liệu không tin cậy, Jackson `enableDefaultTyping`/`activateDefaultTyping` hay `@JsonTypeInfo(use = Id.CLASS)`. JSON đa hình dùng `@JsonTypeInfo(use = Id.NAME)` với `@JsonSubTypes` liệt kê đóng. YAML từ người dùng (luồng từ trình thiết kế) được đọc bằng `SafeConstructor` và kiểm tra lược đồ trước khi tới Camel. Phát hiện bằng FSB (`OBJECT_DESERIALIZATION`, `JACKSON_UNSAFE_DESERIALIZATION`), Semgrep, CodeQL (`java/unsafe-deserialization`).

**CC-SEC-13 · Cấm XXE [tự động].** Mọi bộ phân tích XML (DOM, SAX, StAX, `TransformerFactory`, `SchemaFactory`, XPath trong Camel, xử lý SOAP của PH-05/PH-14) tạo qua `SecureXml.newDocumentBuilder()` của thư viện chung, đã bật `XMLConstants.FEATURE_SECURE_PROCESSING`, tắt `DOCTYPE` (`disallow-doctype-decl`), tắt thực thể ngoài và `XInclude`. Đọc tệp `.xlsx` bằng Apache POI phiên bản đã vá và giới hạn tỉ lệ nén (`ZipSecureFile.setMinInflateRatio`) để chống bom nén. Phát hiện bằng FSB (`XXE_*`), CodeQL (`java/xxe`), Semgrep.

```java
// SAI
DocumentBuilder b = DocumentBuilderFactory.newInstance().newDocumentBuilder();
// ĐÚNG
DocumentBuilder b = SecureXml.newDocumentBuilder(); // DOCTYPE bị cấm, không thực thể ngoài
```

**CC-SEC-14 · Cấm path traversal [tự động].** Không dựng đường dẫn tệp hay khóa đối tượng từ đầu vào. Tệp lưu ở kho đối tượng với khóa do hệ thống sinh (`{tenant}/{mục-đích}/{uuid}`) qua `TenantKeys.objectKey(...)`; tên gốc chỉ lưu làm siêu dữ liệu đã làm sạch. Khi buộc phải ghép đường dẫn cục bộ (ví dụ giải nén), chuẩn hóa bằng `Path.normalize()` và kiểm tra `startsWith(baseDir)` sau chuẩn hóa; từ chối mục nén có `..` hoặc đường dẫn tuyệt đối (Zip Slip). Phát hiện bằng CodeQL (`java/path-injection`, `java/zipslip`), FSB (`PATH_TRAVERSAL_IN`), Semgrep.

**CC-SEC-15 · Cấm SSRF trong adapter và mọi gọi ra ngoài [tự động].** Bộ điều hợp là nơi Datahub gọi tới địa chỉ do người dùng cấu hình, nên là điểm SSRF nguy hiểm nhất: kẻ tấn công có thể khai báo đích trỏ vào dịch vụ nội bộ (metadata của cloud, Admin API của APISIX, OpenBao). Quy tắc: mọi HTTP client ra ngoài được tạo qua `OutboundHttpClientFactory` của thư viện chung (Spring) hoặc Kamelet `dh-http-sink` (Camel), các thành phần này phân giải DNS rồi kiểm tra địa chỉ IP đích không thuộc dải nội bộ, loopback, link-local, dải metadata `169.254.0.0/16`, dải dịch vụ và pod của cụm (trừ danh sách cho phép tường minh của HTTT đã kết nạp), kiểm tra lại sau mỗi chuyển hướng (hoặc tắt tự động chuyển hướng), chỉ cho phép lược đồ `https` (và `http` khi danh sách cho phép ghi rõ), giới hạn thời gian chờ và kích thước phản hồi. Đích được kiểm tra khi khai báo bộ điều hợp và kiểm tra lại khi gọi để chống DNS rebinding. Lớp mạng có thêm network policy Cilium giới hạn đường ra của `dh-runtime` (SEC-10–19). Phát hiện bằng Semgrep (cấm `RestClient.create()`, `HttpClient.newHttpClient()`, `new URL(input).openConnection()` ngoài factory), CodeQL (`java/ssrf`).

```java
// SAI: URL lấy từ cấu hình người dùng, gọi thẳng
restClient.get().uri(adapter.getEndpoint()).retrieve().body(String.class);
// ĐÚNG: factory kiểm tra đích, chặn dải nội bộ, giới hạn thời gian chờ và kích thước
outbound.forAdapter(adapter.id()).get(adapter.endpointRef()).retrieve().body(String.class);
```

**CC-SEC-16 · Chống chèn công thức khi xuất CSV và Excel [tự động].** Xuất danh sách ra `.xlsx` và CSV (FR-00-030) đưa dữ liệu do người dùng khác nhập vào tệp người dùng sẽ mở bằng Excel; ô bắt đầu bằng `=`, `+`, `-`, `@`, ký tự tab hoặc xuống dòng có thể bị hiểu là công thức (CSV injection). Mọi xuất tệp dùng `SpreadsheetExporter` của thư viện chung: với `.xlsx`, ghi giá trị kiểu chuỗi (`CellType.STRING`) không bao giờ đặt công thức từ dữ liệu; với CSV, thêm dấu nháy đơn trước giá trị bắt đầu bằng các ký tự trên và đặt mọi trường trong dấu nháy kép. Trường Nhạy cảm được che theo FR-00-034. Phát hiện bằng Semgrep (cấm `setCellFormula` với dữ liệu, cấm ghi CSV ngoài exporter) và kiểm thử đơn vị với chuỗi `=HYPERLINK(...)`.

**CC-SEC-17 · Cấm thực thi lệnh hệ thống [tự động].** Không dùng `Runtime.exec`, `ProcessBuilder` trong mã ứng dụng; thành phần `exec:` của Camel bị cấm (CC-CAMEL-10). Phát hiện bằng Semgrep, FSB (`COMMAND_INJECTION`).

**CC-SEC-18 · Tải lên tệp an toàn [tự động + review].** Kiểm tra phần mở rộng theo danh sách cho phép của chức năng, kiểm tra kiểu thật bằng Apache Tika (magic bytes), giới hạn kích thước ở APISIX và DU, quét mã độc bằng ClamAV trước khi đưa tệp vào trạng thái dùng được, tên lưu là UUID, trả tệp cho người tải xuống với `Content-Disposition: attachment` và `X-Content-Type-Options: nosniff`.

**CC-SEC-19 · Biểu thức chính quy an toàn [tự động].** Biểu thức chính quy áp lên đầu vào không có lượng từ lồng nhau dễ gây quay lui thảm họa (ReDoS); biểu thức do người dùng cung cấp (ví dụ cấu trúc mã danh mục) được kiểm tra bằng bộ phân tích an toàn và chạy với giới hạn thời gian hoặc bằng thư viện RE2/J. Phát hiện bằng Semgrep (`regex-dos`), CodeQL (`java/redos`, `js/redos`).

**CC-SEC-20 · Chống IDOR/BOLA: mọi truy cập đối tượng kiểm tra quyền trên chính đối tượng [tự động + review].** RLS bảo đảm không đọc chéo tenant, nhưng trong một tenant vẫn có ranh giới giữa tổ chức, giữa HTTT thành viên, giữa người tạo và người khác. Mọi phương thức nhận `id` từ đường dẫn phải tải đối tượng rồi gọi `authz.check(principal, action, resource)` (OPA với thuộc tính đối tượng: tổ chức sở hữu, phân loại, trạng thái) trước khi trả hoặc sửa; không tin rằng "người dùng chỉ biết id của mình". Không có quyền thì trả `404` khi việc lộ sự tồn tại là rủi ro, `403` khi người dùng đã biết đối tượng tồn tại (theo CC-ERR-04). Truy vấn danh sách áp cùng điều kiện quyền ở mức truy vấn. Kiểm tra bằng kiểm thử phân quyền âm tính với hai người dùng cùng tenant khác tổ chức (CC-TEST-04) và kiểm thử rò rỉ chéo tenant.

**CC-SEC-21 · Chống gán hàng loạt (mass assignment) [tự động].** Không ràng buộc thân yêu cầu trực tiếp vào entity; mỗi lệnh có record yêu cầu riêng chỉ chứa trường được phép sửa (CC-JAVA-04, 05); hợp đồng đặt `additionalProperties: false` và Jackson bật `FAIL_ON_UNKNOWN_PROPERTIES` cho yêu cầu. Trường `id`, `tenant_id`, `status`, `version`, `created_*`, `owner` không bao giờ có trong record yêu cầu sửa thuộc tính. Phát hiện bằng ArchUnit (cấm `@RequestBody` có kiểu là `@Entity`), Semgrep, Spectral.

**CC-SEC-22 · Chống leo quyền chức năng (BFLA) [tự động].** Lệnh quản trị và lệnh hành động (`:publish`, `:suspend`, `:approve`) có quyền riêng, tách khỏi quyền sửa thuộc tính; API nền tảng nằm dưới `/api/platform/` với vai trò nền tảng. Kiểm thử phân quyền âm tính gọi mỗi lệnh hành động bằng vai trò chỉ có quyền đọc.

**CC-SEC-25 · Không tự viết mật mã [tự động].** Mã hóa, ký, băm mật khẩu (nếu có), sinh khóa chỉ qua thư viện chung `vn.datahub.common.crypto` hoặc OpenBao transit; thư viện chung chỉ phơi ra thao tác cấp cao (`encryptField`, `sign`, `hmac`) với thuật toán đã chốt. Khóa không bao giờ nằm trong mã hay cấu hình. Phát hiện bằng Semgrep (cấm `Cipher.getInstance` ngoài thư viện chung), FSB.

**CC-SEC-26 · Giá trị bí mật sinh bằng `SecureRandom` [tự động].** Token, mã xác nhận, `client_secret`, khóa idempotency phía máy chủ dùng `SecureRandom` (Java) hoặc `crypto.getRandomValues` (trình duyệt); cấm `Math.random`, `java.util.Random`, `ThreadLocalRandom` cho mục đích này. So sánh giá trị bí mật dùng so sánh thời gian hằng (`MessageDigest.isEqual`). Phát hiện bằng FSB (`PREDICTABLE_RANDOM`), ESL-S (`detect-pseudoRandomBytes`), Semgrep.

**CC-SEC-27 · Xác minh JWT đầy đủ [tự động].** Chỉ dùng `spring-boot-starter-oauth2-resource-server` (hoặc `quarkus-oidc`) với JWKS của realm, kiểm `iss` khớp realm của tenant, `aud` chứa tên DU, `exp`/`nbf` với độ lệch đồng hồ ≤ 30 giây, danh sách thuật toán đóng. Không tự giải mã JWT bằng Base64 để lấy claim trước khi xác minh. Webhook nhận vào xác minh chữ ký HMAC-SHA256 và chống phát lại bằng dấu thời gian ±5 phút và mã sự kiện đã thấy (SAD §7.1).

**CC-SEC-30 · Chống chèn log [tự động].** Như CC-LOG-05; Semgrep luật `crlf-injection-logs`, FSB (`CRLF_INJECTION_LOGS`).

**CC-SEC-31 · Không lộ thông tin qua lỗi và header [tự động].** Như CC-ERR-03; ngoài ra tắt header `Server`, `X-Powered-By`, không trả phiên bản thành phần ở trang lỗi; ZAP kiểm tra trong DAST.

### 9.4. Công cụ và mức chặn

Bảng dưới đây chốt công cụ phân tích bảo mật, phạm vi và mức chặn merge; cấu hình chạy ở cổng tương ứng trong D04-02 §6. Lý do dùng song song Semgrep và CodeQL là hai công cụ bổ sung nhau: Semgrep nhanh, viết luật tùy biến dễ cho các quy tắc riêng của Datahub (đa tenant, factory HTTP), còn CodeQL phân tích luồng dữ liệu liên thủ tục sâu hơn cho các lớp lỗi chèn. Trong môi trường không có GitHub Advanced Security hoặc chạy CI on-prem không kết nối mạng, CodeQL có thể được thay bằng SpotBugs FindSecBugs cộng với Semgrep (Q355).

| Công cụ | Phạm vi | Chặn merge khi |
|---|---|---|
| Semgrep (bộ luật Datahub + cộng đồng) | Java, TypeScript, YAML luồng Camel, Dockerfile | Bất kỳ phát hiện mức `ERROR`; mức `WARNING` báo trên PR |
| CodeQL `security-extended` | Java, JavaScript/TypeScript | Mức `error` hoặc độ nghiêm trọng bảo mật ≥ 7,0 |
| SpotBugs + FindSecBugs | Bytecode Java | Mọi phát hiện nhóm `SECURITY` không có loại trừ được duyệt |
| `eslint-plugin-security`, `no-unsanitized` | TypeScript | Mọi lỗi (chạy chung ESLint `--max-warnings 0`) |
| Trivy (`fs`, `image`, `config`) | Phụ thuộc Maven và npm, ảnh container, Kustomize/Helm, Dockerfile | CRITICAL bất kỳ; HIGH chưa có ngoại lệ được duyệt (NFR-00-023); cấu hình sai mức HIGH trở lên |
| gitleaks | Toàn bộ lịch sử Git và PR | Bất kỳ phát hiện (NFR-00-022) |
| OWASP ZAP | Môi trường kiểm thử (DAST) | Cảnh báo mức High; chạy hằng đêm và trước phát hành |

**CC-SEC-40 · Loại trừ phát hiện phải có lý do và hạn [review].** Một phát hiện được đánh dấu dương tính giả hoặc chấp nhận rủi ro bằng chú thích tại chỗ (`// nosemgrep: {rule-id} -- {lý do}, {mã việc}`, `@SuppressFBWarnings(value = "...", justification = "...")`) hoặc trong tệp loại trừ tập trung có ngày hết hạn ≤ 6 tháng. Mọi loại trừ cần người duyệt bảo mật; tệp loại trừ thuộc CODEOWNERS của nhóm ATTT (D04-02 §5.2).

## 10. Áp dụng cho mã hiện có và cơ chế miễn trừ

Quy chuẩn áp dụng ngay cho mọi mã mới. Mã đã có trong kho trước khi D04-01 được duyệt được đưa về quy chuẩn theo lộ trình ở mục 11; trong thời gian chuyển tiếp, công cụ chạy ở chế độ "chỉ chặn trên phần thay đổi" (diff-aware) để PR mới không làm tình trạng xấu thêm, còn phát hiện cũ được ghi thành đường cơ sở (baseline) và giảm dần. Đường cơ sở của Semgrep, SpotBugs, Squawk và luật ESLint tùy biến được commit trong `.quality/baseline/` và chỉ được phép co lại.

**CC-GEN-13 · Miễn trừ một quy tắc phải được ghi nhận [review].** Một mô-đun cần làm khác một quy tắc "Phải" (ví dụ trình thiết kế luồng cần kích thước canvas tính bằng điểm ảnh, trái CC-FE-13) ghi miễn trừ trong tệp `docs/exemptions.yaml` của kho mã gồm mã quy tắc, phạm vi tệp, lý do, người duyệt, ngày hết hạn. Miễn trừ liên quan nhóm `CC-SEC` hoặc `CC-TEN` cần người duyệt bảo mật; miễn trừ không có ngày hết hạn không được chấp nhận.

## 11. Hiện trạng mã nguồn so với quy chuẩn

Khảo sát kho mã tại thời điểm viết (các DU `apps/control`, `apps/data`, `apps/adapter-mgr`, `camel/dancu`, `camel/datdai`, `apps/console`, thư viện `libs/common-java`, migration Liquibase, quy trình CI trong `.github/workflows`) cho thấy nền móng đúng hướng ở nhiều điểm: Java 21, Spring Boot 4.0.2, Spring Modulith 2.0.1, cấu trúc `api`/`internal` theo module và kiểm thử `ApplicationModules.verify()` đã có ở `apps/control` và `apps/data`; Camel Quarkus 3.33.2 với YAML DSL; JDBC đã dùng tham số; có record `ProblemDetail` theo RFC 9457 trong thư viện chung; gitleaks đã chạy trong CI. Bảng dưới đây liệt kê các điểm lệch, mức độ và hướng xử lý; các điểm mức cao phải xử lý trước khi phát triển phân hệ đợt MVP tiếp theo.

| # | Điểm lệch | Quy tắc | Mức | Hướng xử lý |
|---|---|---|---|---|
| 1 | Package gốc `vn.lgsp.*`, groupId `vn.lgsp`, DU tên `control`, `data`, `adapter-mgr` khác bản đồ DU của SAD (`dh-connect`, `dh-integration`, `dh-data`, `dh-platform`…) | CC-MOD-01 | Trung bình | Đổi sang `vn.datahub.{du}` một lần bằng công cụ tái cấu trúc, cùng lúc chốt bản đồ DU (Q350) |
| 2 | Chưa có xử lý tenant: không `TenantContext`, không đặt `app.tenant_id`, bảng không có `tenant_id`, không có RLS | CC-TEN-01…06, CC-SQL-03 | **Cao** | Xây `vn.datahub.common.tenant` và `shared.persistence` trước mọi tính năng mới; migration bổ sung `tenant_id` + RLS cho bảng hiện có theo mẫu expand–contract |
| 3 | Schema `ph01`, `ph07` thay vì `ph01_onboarding`, `ph07_rdm`; bảng, cột đặt tên tiếng Việt không dấu (`danh_muc`, `ma_danh_muc`); khóa chính `danh_muc_id` thay vì `id`; `VARCHAR(60)` thay vì `varchar(64)`; thiếu `created_by`, `updated_*`, `version` | CC-SQL-01, 02, D00-01 §5–6 | Cao | Quyết định đổi tên hay chấp nhận ngoại lệ có thời hạn (Q351); bổ sung cột bắt buộc |
| 4 | Outbox được chuyển đi bằng tác vụ `@Scheduled` thăm dò bảng và ghi `payload` ra log ở mức INFO; chưa có Kafka, chưa có Debezium | CC-TX-03, CC-LOG-04, CC-TEN-05 | Cao (lộ dữ liệu khi có dữ liệu thật) | Bỏ ghi payload ra log ngay; chọn cơ chế chuyển outbox (Q352) |
| 5 | `ProblemDetail` của thư viện chung thiếu trường `code` (`ERR-{PH}-{nnn}`) và `errors`; chưa có `@RestControllerAdvice` chuẩn | CC-ERR-01, 02 | Trung bình | Mở rộng record, thêm bộ xử lý chung |
| 6 | Chưa dùng JSpecify, NullAway, Error Prone, Spotless, JaCoCo, ArchUnit (chỉ có Modulith verify) | CC-JAVA-01, 06, CC-MOD-05, CC-TEST-02 | Trung bình | Thêm vào `pluginManagement` của POM gốc |
| 7 | Chưa có log JSON có cấu trúc, chưa có `trace_id`, `tenant_id` trong log | CC-LOG-01, 02 | Trung bình | Bật structured logging của Boot 4 và JSON logging của Quarkus |
| 8 | Cấu hình có giá trị mặc định cho mật khẩu CSDL (`${POSTGRES_PASSWORD:lgsp_dev_change_me}`) trong `application.yml` và `application.properties` | CC-CFG-02 | Cao | Bỏ giá trị mặc định; dev cục bộ dùng `.env` hoặc Testcontainers |
| 9 | Actuator mở `health`, `info` trên cổng ứng dụng; chưa tách cổng quản trị | CC-CFG-05 | Thấp | Thêm `management.server.port` |
| 10 | Giao diện: chưa có ESLint, Prettier, Stylelint; chưa dùng TanStack Query; chưa có i18n; khoảng 87 chỗ `style={{...}}` và khoảng 2.500 dòng CSS tự do (`designer.css`, `catalog.css`, `tokens.css` dạng mockup); chưa có gói `@datahub/ui`, `@datahub/api-client` | CC-FE-05, 10, 12, 13, 17 | Cao (NFR-00-045) | Lập gói `@datahub/ui` theo D03-05; chuyển dần màn sang token; bật lint với đường cơ sở |
| 11 | Luồng mẫu (`ping.camel.yaml`, mẫu chín chặng) không khai báo `errorHandler`; `camel/dancu` dùng `camel-quarkus-sql` truy cập CSDL trực tiếp với datasource riêng | CC-CAMEL-04, 07, CC-TEN-02 | Trung bình | Thêm DLQ chuẩn; làm rõ ranh giới truy cập CSDL của `dh-runtime` (Q359) |
| 12 | Hai mô-đun Camel không nằm trong POM gốc; phiên bản phụ thuộc giao diện dùng khoảng `^`, `~` | D04-02 §8 | Trung bình | Đưa vào reactor hoặc BOM chung; ghim chính xác qua lockfile và Renovate |
| 13 | CI chỉ có biên dịch, kiểm thử đơn vị và gitleaks; thiếu SAST, SCA, quét ảnh, lint hợp đồng, kiểm thử giao diện; GitHub Actions ghim theo thẻ (`@v4`) chứ không theo SHA | D04-02 §6 | Cao | Triển khai đủ cổng theo D04-02 §6 |
| 14 | Chưa có `CODEOWNERS`, mẫu PR, `.github/dependabot.yml` hay `renovate.json` | D04-02 §4, §5, §8 | Trung bình | Tạo theo D04-02 |

`AGENTS.md` và IP-02 hiện là luật cho tác tử AI và người phát triển; sau khi D04-01 được duyệt, `AGENTS.md` cần thêm một dòng trỏ tới D04-01 làm nguồn chuẩn và rút bớt các mục trùng (§4 Modulith, §5 bảo mật, §7 DoD) để tránh hai nguồn sự thật.

## 12. Mã và thuật ngữ mới đề xuất bổ sung D00-01

Tài liệu đề xuất bổ sung vào D00-01 các mục trong bảng dưới đây. Việc gộp vào D00-01 do luồng lõi thực hiện theo D00-01 §9.3.

| Loại | Đề xuất | Vị trí trong D00-01 |
|---|---|---|
| Mã | `CC-{nhóm}-{nn}`: quy tắc lập trình, định nghĩa tại D04-01. Nhóm ∈ `GEN`, `JAVA`, `MOD`, `ERR`, `TX`, `JPA`, `VAL`, `LOG`, `CFG`, `TEST`, `CAMEL`, `FE`, `SQL`, `API`, `TEN`, `SEC`. Ví dụ `CC-TEN-03` | §3.1 |
| Thuật ngữ | **Quy chuẩn lập trình** (Coding convention): bộ quy tắc viết mã bắt buộc, có mã `CC` | §2.2 |
| Thuật ngữ | **Kiểm thử rò rỉ chéo tenant** (Cross-tenant leak test): kiểm thử tạo dữ liệu ở tenant A, truy cập bằng danh tính tenant B và kỳ vọng `404` | §2.2 |
| Thuật ngữ | **Mở rộng rồi thu hẹp** (Expand–contract): cách thay đổi lược đồ CSDL qua nhiều phiên bản tương thích để không gián đoạn | §2.2 |
| Thuật ngữ | **Đường cơ sở phát hiện** (Findings baseline): tập phát hiện cũ của công cụ phân tích được ghi nhận để chỉ chặn phát hiện mới | §2.2 |
| Thuật ngữ | **IDOR/BOLA** (Insecure Direct Object Reference / Broken Object Level Authorization), **SSRF** (Server-Side Request Forgery), **XXE** (XML External Entity), **SAST/DAST/SCA** | §2.3 |
| Quy ước | Khóa cấu hình `datahub.{module}.{khóa-kebab}`; `routeId` Camel `{tenant}-{mã-luồng}-{chặng}`; tên ràng buộc CSDL `pk_`, `fk_`, `uq_`, `ck_`, `ix_` | §6 |
| Quy ước | Package thư viện dùng chung `vn.datahub.common.{chủ-đề}` | §6 |
| Chuẩn | STD-03 cập nhật từ "OWASP ASVS 4.x" thành "OWASP ASVS 5.0" để khớp NFR-00-024 | §7 |

## 13. Truy vết

Bảng dưới đây ánh xạ yêu cầu, quyết định kiến trúc và chuẩn tới mục đáp ứng trong tài liệu này.

| Yêu cầu, ADR, chuẩn | Đáp ứng tại |
|---|---|
| NFR-00-020 (mã hóa đường truyền) | 9.2 (V12) |
| NFR-00-021 (mã hóa khi lưu, trường Nhạy cảm) | CC-JPA-07 |
| NFR-00-022 (không bí mật trong mã) | CC-GEN-05, CC-CFG-02, 9.4 |
| NFR-00-023 (lỗ hổng phụ thuộc) | CC-GEN-09, 9.4 |
| NFR-00-024 (ASVS 5.0 mức 2) | Mục 9 |
| NFR-00-029 (che dữ liệu cá nhân trong log) | CC-LOG-04 |
| NFR-00-040…045 (truy cập, thống nhất giao diện) | CC-FE-11…14 |
| NFR-00-051 (trace_id, tenant_id trong log) | CC-LOG-01, 02 |
| NFR-00-052 (cấu hình không khởi động lại) | CC-CFG-04 |
| NFR-00-053 (độ phủ) | CC-TEST-02, CC-FE-18 |
| NFR-00-054 (ranh giới module) | CC-MOD-02, 05 |
| NFR-00-055 (tương thích ngược API) | CC-API-03 |
| NFR-00-013 (nâng cấp không gián đoạn) | 6.3 |
| FR-00-001, 003, 005 (xác thực, phiên) | CC-FE-15, 9.2 (V6, V7) |
| FR-00-010, 011, 012 (cách ly tenant) | Mục 8 |
| FR-00-020…022, 030, 034 (danh sách, xuất) | CC-VAL-03, CC-JPA-05, CC-FE-06, CC-SEC-16 |
| FR-00-040…042 (kiểm toán) | CC-LOG-07 |
| FR-00-052 (xung đột sửa) | CC-TX-04, CC-FE-07 |
| ADR-001 (Spring Boot, Modulith) | 3.2 |
| ADR-002, ADR-010 (Camel Quarkus, YAML DSL) | Mục 4 |
| ADR-003 (PostgreSQL RLS) | 6.2, mục 8 |
| ADR-004 (Kafka, Apicurio) | CC-API-04, CC-TX-03, 07 |
| ADR-006 (Keycloak, OPA) | CC-SEC-08, 20, 27 |
| ADR-009 (GitOps) | 4.1 |
| ADR-011 (OpenTelemetry) | CC-LOG-02, CC-CAMEL-13 |
| ADR-012 (OpenBao) | CC-CFG-02, CC-CAMEL-08 |
| ADR-020 (Liquid Glass trên antd v6) | 5.7 |
| ADR-031, ADR-032 (kiểm toán, mã hóa trường) | CC-LOG-07, CC-JPA-07 |
| ADR-037 (quy trình Git, cổng CI) | Mục 1.3 (mức tự động), 9.4 |
| D03-10 §6 | Mục 8 (nguyên văn) |
| SEC-40–49 (D03-07) | Mục 9 |
| TCVN 14423:2026 nhóm "phát triển ứng dụng an toàn" ở cấp độ 3 (cần đối chiếu số mục) | Mục 1.1, mục 9 |

## 14. Câu hỏi mở

> **Q350 (đã chốt 25/11/2026):** dùng bản đồ DU của SAD (`dh-*`), package gốc `vn.datahub.{du}`; package `vn.lgsp` hiện có được đổi dần khi chạm mã. *Câu hỏi gốc:* Bản đồ DU chính thức là bản đồ của SAD (`dh-connect`, `dh-integration`, `dh-data`, `dh-platform`, `dh-payment`, `dh-assist`, `dh-runtime`) hay bản đồ của IP-01 trong kho mã (`lgsp-control`, `lgsp-data`, `lgsp-process`, `lgsp-adapter-mgr`, `lgsp-ai`, `lgsp-camel-{miền}`)? Quyết định này chốt package gốc `vn.datahub.{du}` và thời điểm đổi package `vn.lgsp` hiện có.

> **Câu hỏi mở Q351:** Bảng, cột hiện có đặt tên tiếng Việt không dấu (`ph07.danh_muc`, `ma_danh_muc`) và schema thiếu tên ngắn (`ph07` thay vì `ph07_rdm`): đổi ngay sang quy ước D00-01 §6 khi dữ liệu còn ít, hay ghi ngoại lệ có thời hạn?

> **Câu hỏi mở Q352:** Cơ chế chuyển outbox ra Kafka: Debezium đọc WAL (SAD §7.3), tác vụ thăm dò trong DU (mã hiện tại), hay phần mở rộng externalization của Spring Modulith? Debezium cần quyền replication và slot logic trên CNPG, ảnh hưởng vận hành ở hồ sơ on-prem.

> **Câu hỏi mở Q355:** Tổ chức có giấy phép GitHub Advanced Security (CodeQL cho kho riêng) hoặc nền tảng CI on-prem tương đương không? Nếu không, bộ SAST chuẩn là Semgrep cộng SpotBugs FindSecBugs và tài liệu này cần bỏ CodeQL khỏi cổng chặn.

> **Câu hỏi mở Q356:** Giao diện có cần hỗ trợ ngôn ngữ thứ hai (tiếng Anh cho cổng nhà phát triển, hoặc tiếng dân tộc) trong các đợt sau không? Câu trả lời quyết định chọn thư viện i18n đầy đủ (i18next) hay chỉ tệp chuỗi tiếng Việt có kiểu.

> **Câu hỏi mở Q358:** Số hiệu cụ thể của các biện pháp trong dải SEC-40–49 (và SEC-30–39, SEC-60–69, SEC-80–89) do D03-07 chốt; khi có, bảng 9.2 cần thêm cột mã `SEC-nn` cho từng dòng.

> **Q359 (đã chốt 25/11/2026):** cho phép luồng Camel (`dh-runtime`) truy cập trực tiếp CSDL có kiểm soát: chỉ qua tài khoản chỉ đọc riêng cho từng luồng, kết nối phải được khai báo trong danh mục kết nối (PH-05) và mọi truy vấn được ghi kiểm toán; mỗi bản tin phải đặt `app.tenant_id` để RLS lọc theo tenant (thiết kế ở SDD PH-04); không bao giờ truy cập CSDL của control plane (ADR-002). *Câu hỏi gốc:* `dh-runtime` (Camel) có được truy cập trực tiếp CSDL nghiệp vụ của Datahub không (mã hiện tại dùng `camel-quarkus-sql` với datasource riêng)? Nếu có, cơ chế đặt `app.tenant_id` cho mỗi bản tin và vai trò CSDL riêng phải được thiết kế ở SDD PH-04; nếu không, truy cập CSDL chỉ dành cho Kamelet nguồn dữ liệu của HTTT thành viên, không phải CSDL của Datahub.

Các câu hỏi Q353, Q354 và Q357 thuộc quy trình kỹ thuật, được nêu ở D04-02.
