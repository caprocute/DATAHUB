---
ma_tai_lieu: D02-04-PH07
ten: Đặc tả use case phân hệ PH-07 Danh mục dùng chung
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Dự thảo
nguoi_doc: Nhóm phân tích nghiệp vụ, đội phát triển PH-07, đội kiểm thử, hội đồng thẩm định
phan_he: PH-07
nguoi_lap: Nhóm phân hệ PH-07
---

# D02-04-PH07 · Đặc tả use case phân hệ PH-07 Danh mục dùng chung

## 1. Mục đích và phạm vi

### 1.1. Mục đích

Tài liệu này đặc tả mười bảy use case (ca sử dụng) của phân hệ PH-07 Danh mục dùng chung (Reference Data Management, viết tắt RDM) trong sản phẩm Datahub. Mỗi use case mô tả trọn vẹn một mục tiêu nghiệp vụ mà một tác nhân muốn đạt được khi làm việc với hệ thống, theo trình tự tương tác từng bước giữa tác nhân và hệ thống, kèm các nhánh thay thế, các tình huống ngoại lệ và các đảm bảo mà hệ thống phải giữ dù kết quả thành công hay thất bại.

Tài liệu đóng vai trò cầu nối giữa đặc tả yêu cầu chức năng [D02-03-PH07 FRS](../frs/D02-03-PH07-frs-danh-muc.md) (nói hệ thống phải làm gì) và thiết kế chi tiết [D03-02-PH07 SDD](../../03-thiet-ke/sdd/D03-02-PH07-sdd-danh-muc.md), [D03-04-PH07 API](../../03-thiet-ke/api/D03-04-PH07-api-danh-muc.md), [D03-06-PH07 Màn hình](../../03-thiet-ke/uiux/D03-06-PH07-man-hinh-danh-muc.md) (nói hệ thống làm như thế nào). Đội phát triển dùng luồng chính và luồng ngoại lệ để biết thứ tự gọi màn hình, gọi API và mã lỗi phải trả; đội kiểm thử dùng từng luồng làm khung sinh ca kiểm thử trong [D05-02-PH07](../../05-kiem-thu/test-case/D05-02-PH07-test-case.md); hội đồng thẩm định dùng các sơ đồ và bảng tổng hợp để đánh giá mức độ bao phủ nghiệp vụ so với hệ cũ.

### 1.2. Phạm vi

Phạm vi tài liệu gồm toàn bộ chức năng PH-07 trong danh sách FR-07-001 đến FR-07-053 của FRS: quản trị danh mục và lược đồ thuộc tính động, vòng đời phiên bản (bản nháp, trình duyệt, duyệt, phát hành), nhập xuất Excel/CSV/JSON và nhập lô qua API, khai thác danh mục qua API (tra cứu, truy vấn có cấu trúc, cây, delta, ảnh chụp), đồng bộ danh mục quốc gia qua NDXP, ánh xạ mã với hệ thống ngoài, danh mục đơn vị hành chính (ĐVHC) và sự kiện sắp xếp, mô hình đa tenant với danh mục `COMMON` và danh mục mở rộng `HYBRID`, nạp gói danh mục nền khi khởi tạo tenant và di trú dữ liệu từ hệ cũ Aita.

Tài liệu không đặc tả lại các chức năng dùng chung FR-00 (đăng nhập, phân quyền, kiểm toán, hộp "Việc của tôi", thông báo, tìm kiếm không dấu chung). Khi một bước dựa vào chức năng dùng chung, tài liệu ghi "Tuân thủ FR-00-nnn" theo [D02-02 SRS](../D02-02-srs.md) §4. Các tác vụ hạ tầng như quét mã độc tệp tải lên (DD-12), gửi sự kiện qua outbox và Debezium (DD-11) và lưu tham số (DD-14) được mô tả ở mức tương tác, chi tiết nằm trong SDD.

### 1.3. Tài liệu liên quan

Bảng dưới liệt kê các tài liệu mà người đọc cần mở song song khi đọc đặc tả use case, kèm lý do tham chiếu.

| Tài liệu | Lý do tham chiếu |
|---|---|
| [D00-01 Thuật ngữ và quy ước](../../00-chung/D00-01-thuat-ngu-quy-uoc.md) | Hệ mã truy vết (UC, FR, BR, UI, API, ERR), kiểu dữ liệu T-*, quy ước trình bày |
| [D02-01 BRD](../D02-01-brd.md) | Yêu cầu nghiệp vụ REQ-07, REQ-20, REQ-22; quy trình BP-03; mục tiêu BO-05; chỉ số KPI-10, KPI-11 |
| [D02-02 SRS](../D02-02-srs.md) | Yêu cầu dùng chung FR-00 và NFR-00 |
| [D02-03-PH07 FRS](../frs/D02-03-PH07-frs-danh-muc.md) | Đặc tả chi tiết FR-07-001…053, BR-07-001…027, NFR-07-001…015 |
| [D02-05-PH07 User story](../user-story/D02-05-PH07-user-story-danh-muc.md) | Backlog US-07-nnn và tiêu chí chấp nhận Gherkin tương ứng với từng use case |
| [D02-06-PH07 DFD](../dfd/D02-06-PH07-dfd-danh-muc.md) | Luồng dữ liệu giữa các tiến trình PH-07 và các kho |
| [D02-07 Từ điển dữ liệu](../D02-07-tu-dien-du-lieu.md) | DD-07 `admin_unit`, DD-11 outbox, DD-12 tệp, DD-14 tham số |
| [D02-08 Ma trận phân quyền](../D02-08-ma-tran-phan-quyen.md) | Vai trò `ROLE-*` và quyền `PERM-07-*` |
| [D03-10 Thiết kế đa tenant](../../03-thiet-ke/D03-10-thiet-ke-da-tenant.md) | RLS, tenant `COMMON` và `PLATFORM` |

## 2. Quy ước đọc đặc tả

### 2.1. Mẫu đặc tả một use case

Mỗi use case trong mục 6 được viết theo cùng một mẫu để người đọc dễ so sánh và để công cụ sinh ca kiểm thử có thể bóc tách. Bảng dưới giải thích ý nghĩa từng mục của mẫu.

| Mục | Ý nghĩa |
|---|---|
| Mã, tên | Mã `UC-07-nn` theo khung chung và tên bắt đầu bằng động từ |
| Mục tiêu | Kết quả nghiệp vụ mà tác nhân chính muốn đạt, viết theo góc nhìn tác nhân |
| Tác nhân chính, tác nhân phụ | Tác nhân chính khởi xướng use case; tác nhân phụ là người hoặc hệ thống tham gia hay nhận kết quả |
| Mức ưu tiên | M, S, C theo D00-01 §4.1, lấy mức cao nhất của các FR hiện thực |
| FR hiện thực | Các yêu cầu chức năng mà use case hiện thực một phần hoặc toàn bộ |
| Tiền điều kiện | Điều phải đúng trước khi use case bắt đầu; hệ thống không kiểm tra lại trong luồng |
| Điều kiện kích hoạt | Sự kiện làm use case bắt đầu |
| Đảm bảo tối thiểu | Điều hệ thống luôn giữ kể cả khi use case thất bại giữa chừng |
| Đảm bảo thành công | Trạng thái hệ thống sau khi luồng chính hoặc một luồng thay thế kết thúc thành công (hậu điều kiện) |
| Luồng chính | Kịch bản thành công điển hình, đánh số bước; mỗi bước ghi rõ ai làm, màn hình `UI-07-nn` và API `API-07-nnn` liên quan |
| Luồng thay thế | Nhánh hợp lệ khác của luồng chính, đánh số theo bước rẽ nhánh (ví dụ `3a` rẽ tại bước 3) và ghi điểm quay về |
| Luồng ngoại lệ | Tình huống lỗi, đánh số `E1`, `E2`…, ghi mã lỗi `ERR-07-nnn`, thông điệp tiếng Việt hiển thị cho người dùng và cách khắc phục |
| Quy tắc nghiệp vụ | Các `BR-07-nnn` mà use case phải tuân thủ |
| Yêu cầu phi chức năng | Các `NFR-07-nnn` hoặc `NFR-00-nnn` ràng buộc trực tiếp use case |
| Tần suất, khối lượng | Ước lượng số lần thực hiện và khối lượng dữ liệu để thiết kế hiệu năng |
| Sơ đồ | Sơ đồ hoạt động (activity) hoặc tuần tự (sequence) Mermaid cho use case phức tạp, kèm thuyết minh |

### 2.2. Quy ước trong luồng

Trong các luồng, "Hệ thống" là PH-07 chạy trong DU `dh-data` cùng giao diện quản trị; "Cổng API" là API Gateway của Datahub đứng trước các API khai thác. Khi một bước gọi API, tài liệu ghi mã API trong ngoặc, ví dụ "(API-07-012)"; đường dẫn đầy đủ có tiền tố `/api/rdm/v1` như quy định ở [D03-04-PH07](../../03-thiet-ke/api/D03-04-PH07-api-danh-muc.md). Mọi API tạo mới nhận tiêu đề `Idempotency-Key`; mọi API sửa yêu cầu `If-Match` mang ETag của tài nguyên; lỗi trả theo RFC 9457 (Problem Details) với trường `code` là mã `ERR-07-nnn` và trường `detail` là thông điệp tiếng Việt.

Mọi thao tác ghi trong mọi use case đều sinh bản ghi kiểm toán theo FR-00-040 (NFR-07-015) và mọi truy vấn cơ sở dữ liệu đều chạy dưới chính sách RLS theo tenant hiện hành như [D03-10](../../03-thiet-ke/D03-10-thiet-ke-da-tenant.md) quy định. Để tránh lặp, các luồng không nhắc lại hai điều này ở từng bước, trừ khi bước đó có xử lý kiểm toán hoặc tenant đặc thù.

Thông điệp lỗi trong luồng ngoại lệ là văn bản hiển thị đề xuất cho giao diện; văn bản cuối cùng do tài liệu màn hình D03-06-PH07 chốt nhưng phải giữ nguyên ý. Dữ liệu ví dụ đều là giả lập: tenant `T68` (Lâm Đồng), cán bộ giả lập "Nguyễn Văn An" (cán bộ quản lý danh mục Sở Nội vụ), "Trần Thị Bình" (lãnh đạo phòng duyệt danh mục), "Lê Văn Cường" (quản trị Datahub tỉnh), HTTT giả lập "Hệ thống một cửa điện tử tỉnh" với mã client `t68-motcua`.

## 3. Tác nhân

### 3.1. Danh sách tác nhân

Bảng dưới liệt kê các tác nhân của PH-07. Các tác nhân con người dùng đúng mã vai trò của [D02-08](../D02-08-ma-tran-phan-quyen.md); quyền ghi theo D02-08 §3.1, các quyền đánh dấu "(đề xuất bổ sung D02-08)" là quyền PH-07 đề nghị luồng lõi thêm vào ma trận. Ký hiệu ○ nghĩa là quyền chỉ áp dụng cho danh mục do tổ chức của người dùng làm chủ, căn cứ `catalog.owner_org_id`.

| Tác nhân | Mã vai trò hoặc định danh | Mô tả | Quyền PH-07 chính |
|---|---|---|---|
| Cán bộ quản lý danh mục | `ROLE-DATA_STEWARD` | Cán bộ của sở, ngành hoặc văn phòng UBND tỉnh được giao quản lý danh mục; phạm vi tổ chức hoặc tenant | `PERM-07-read`, `PERM-07-create`/`update` (○), `PERM-07-submit` (○), `PERM-07-export`, `PERM-07-mapping` (đề xuất bổ sung D02-08) |
| Người duyệt danh mục | `ROLE-DATA_APPROVER` | Lãnh đạo phòng hoặc đơn vị được giao duyệt phát hành danh mục; bắt buộc MFA | `PERM-07-read`, `PERM-07-publish` (duyệt và phát hành), `PERM-07-export`, `PERM-07-sync` |
| Quản trị tỉnh | `ROLE-TENANT_ADMIN` | Quản trị Datahub của tỉnh; không có quyền duyệt phát hành | `PERM-07-read`, `PERM-07-create`/`update`, `PERM-07-submit`, `PERM-07-export`, `PERM-07-sync`, `PERM-07-retire`, `PERM-07-mapping`, `PERM-07-grant`, `PERM-07-configure` (bốn quyền cuối đề xuất bổ sung D02-08) |
| Quản trị nền tảng | `ROLE-PLATFORM_ADMIN` | Quản trị viên thuộc tenant `PLATFORM`; người duy nhất ghi danh mục `COMMON` | Toàn bộ quyền PH-07 trên danh mục `COMMON`, gồm `PERM-07-publish` và `PERM-07-retire` với `COMMON`; gọi API nạp gói nền |
| Kỹ sư tích hợp | `ROLE-INTEGRATION_ENGINEER` | Kỹ sư thiết kế luồng tích hợp, cần tra cứu và chuyển mã khi ghép nối | `PERM-07-read`, `PERM-07-export`, `PERM-07-mapping` (đề xuất bổ sung D02-08); dùng trình thử API |
| Nhà phát triển | `ROLE-DEVELOPER` | Lập trình viên của ứng dụng được giao, dùng cổng nhà phát triển và sandbox | `PERM-07-read` trên cổng nhà phát triển, trình thử API |
| Người xem | `ROLE-VIEWER` | Cán bộ cơ quan nhà nước cần tra cứu danh mục | `PERM-07-read`, `PERM-07-export` |
| Kiểm toán | `ROLE-AUDITOR` | Thanh tra, kiểm toán tỉnh | `PERM-07-read`, đọc lịch sử kiểm toán danh mục |
| Ứng dụng HTTT | Client OAuth2 của HTTT thành viên | Hệ thống thông tin khai thác hoặc đẩy danh mục bằng máy | Scope `rdm.read`, `rdm.query`, `rdm.write` |
| NDXP (qua PH-14) | Adapter `NDXP_DMDC` của PH-14 | Nền tảng tích hợp quốc gia cung cấp danh mục dùng chung quốc gia | Tác nhân phụ, được PH-07 gọi |
| PH-20 Quản lý tenant | Dịch vụ nội bộ | Khởi tạo tenant, gọi nạp gói danh mục nền | Gọi API-07-073 bằng định danh dịch vụ |
| Bộ lập lịch | Tác vụ định kỳ trong `dh-data` (ShedLock) | Kích hoạt đồng bộ định kỳ, dọn bảng tạm, hết hạn tác vụ | Tác nhân thời gian |
| Bên nhận sự kiện | HTTT và phân hệ đăng ký topic Kafka | Nhận EVT-07-nn để làm mới bộ đệm, đồng bộ cục bộ | Tác nhân phụ |
| Hộp "Việc của tôi" | Chức năng dùng chung FR-00-070 | Tạo, đóng việc chờ duyệt từ sự kiện EVT-07-04, EVT-07-05, EVT-07-06 | Tác nhân phụ |
| Công cụ di trú | Tác vụ di trú FR-00-090 do quản trị tỉnh chạy | Đọc dữ liệu Aita, ghi vào PH-07 | Tác nhân phụ trong UC-07-16 |

### 3.2. Quan hệ giữa vai trò và mức truy cập danh mục

Mức truy cập thực tế của một người dùng vào một danh mục là giao của ba điều kiện: quyền theo vai trò, phạm vi tổ chức và nguồn của danh mục. Một cán bộ quản lý danh mục chỉ sửa được danh mục `LOCAL` hoặc `HYBRID` thuộc tổ chức mình (○), không sửa được danh mục `NATIONAL` (chỉ cập nhật qua đồng bộ, BR-07-009) và không sửa được danh mục `COMMON` (chỉ tenant `PLATFORM` ghi). Người duyệt danh mục duyệt được mọi danh mục trong tenant nhưng không được duyệt phiên bản do chính mình trình hoặc sửa lần cuối (BR-07-011 mở rộng theo D02-08). Quản trị tỉnh có quyền soạn và trình nhưng không có `PERM-07-publish`, nên không thể một mình đưa thay đổi ra khai thác ở danh mục cần duyệt; đây là chủ ý để giữ nguyên tắc bốn mắt.

Với danh mục phân loại `RESTRICTED`, ứng dụng HTTT chỉ khai thác được khi có bản ghi cấp quyền trong `catalog_access_grant` (BR-07-019); người dùng giao diện có `PERM-07-read` vẫn xem được trên màn hình quản trị vì danh mục không chứa dữ liệu cá nhân (BR-07-025), nhưng mọi lần xem được ghi kiểm toán.

## 4. Sơ đồ use case tổng

Sơ đồ dưới thể hiện các tác nhân và mười bảy use case của PH-07, nhóm theo bốn cụm: quản trị vòng đời danh mục, nhập xuất, khai thác, tích hợp quốc gia và nền tảng. Mermaid không có ký pháp UML use case nên sơ đồ dùng `flowchart`: hình chữ nhật bo tròn là tác nhân, hình bầu dục là use case, mũi tên liền nối tác nhân chính với use case, mũi tên chấm nối use case với tác nhân phụ hoặc thể hiện quan hệ «include»/«extend».

```mermaid
flowchart LR
    DS([Cán bộ quản lý danh mục<br/>ROLE-DATA_STEWARD])
    DA([Người duyệt danh mục<br/>ROLE-DATA_APPROVER])
    TA([Quản trị tỉnh<br/>ROLE-TENANT_ADMIN])
    PA([Quản trị nền tảng<br/>ROLE-PLATFORM_ADMIN])
    IE([Kỹ sư tích hợp / Nhà phát triển<br/>ROLE-INTEGRATION_ENGINEER, ROLE-DEVELOPER])
    VW([Người xem / Kiểm toán<br/>ROLE-VIEWER, ROLE-AUDITOR])
    APP([Ứng dụng HTTT<br/>OAuth2 rdm.*])
    NDXP([NDXP qua PH-14])
    PH20([PH-20 Quản lý tenant])
    SCH([Bộ lập lịch])
    SUB([Bên nhận sự kiện / Việc của tôi])

    subgraph G1[Quản trị vòng đời danh mục]
        UC01((UC-07-01<br/>Tạo danh mục và<br/>khai báo lược đồ))
        UC02((UC-07-02<br/>Cập nhật bản ghi<br/>trên bản nháp))
        UC06((UC-07-06<br/>Trình duyệt và<br/>phê duyệt phiên bản))
        UC07((UC-07-07<br/>Phát hành phiên bản))
        UC14((UC-07-14<br/>Ngừng hiệu lực<br/>hoặc xóa danh mục))
        UC17((UC-07-17<br/>Mở rộng danh mục<br/>quốc gia HYBRID))
    end
    subgraph G2[Nhập xuất]
        UC03((UC-07-03<br/>Nhập bản ghi<br/>từ Excel/CSV))
        UC04((UC-07-04<br/>Tạo danh mục từ tệp<br/>gồm khuôn Aita))
        UC05((UC-07-05<br/>Nhập bản ghi<br/>qua API theo lô))
        UC08((UC-07-08<br/>Xuất danh mục))
    end
    subgraph G3[Khai thác]
        UC09((UC-07-09<br/>Khai thác danh mục<br/>qua API))
        UC10((UC-07-10<br/>Truy vấn có cấu trúc))
        UC13((UC-07-13<br/>Quản lý ánh xạ mã<br/>và chuyển mã))
    end
    subgraph G4[Tích hợp quốc gia và nền tảng]
        UC11((UC-07-11<br/>Đồng bộ danh mục<br/>quốc gia))
        UC12((UC-07-12<br/>Sắp xếp ĐVHC<br/>và chuyển đổi mã))
        UC15((UC-07-15<br/>Nạp gói danh mục nền))
        UC16((UC-07-16<br/>Di trú dữ liệu Aita))
    end

    DS --> UC01 & UC02 & UC03 & UC04 & UC08 & UC13 & UC17
    DS --> UC06
    DA --> UC06 & UC07 & UC11
    TA --> UC14 & UC16 & UC11 & UC13
    PA --> UC12 & UC15 & UC11
    IE --> UC09 & UC10 & UC13
    VW --> UC08 & UC09
    APP --> UC05 & UC09 & UC10 & UC13
    SCH --> UC11
    PH20 --> UC15

    UC11 -.-> NDXP
    UC07 -.-> SUB
    UC06 -.-> SUB
    UC03 -.->|«include»| UC02
    UC04 -.->|«include»| UC03
    UC06 -.->|«include»| UC07
    UC12 -.->|«extend»| UC07
    UC17 -.->|«include»| UC02
    UC11 -.->|«include»| UC07
    UC16 -.->|«include»| UC07
```

Sơ đồ cho thấy cán bộ quản lý danh mục là tác nhân trung tâm của cụm quản trị và nhập xuất: họ tạo danh mục (UC-07-01), soạn bản ghi trên bản nháp (UC-07-02), nhập tệp (UC-07-03, UC-07-04), mở rộng danh mục quốc gia (UC-07-17) và khởi động trình duyệt (UC-07-06). Người duyệt danh mục khép vòng bốn mắt bằng cách duyệt và phát hành (UC-07-06, UC-07-07). Các quan hệ «include» thể hiện rằng mọi con đường đưa dữ liệu vào danh mục, dù nhập tay, nhập tệp, đồng bộ quốc gia hay di trú, đều hội tụ vào cùng một bản nháp và cùng một thao tác phát hành; nhờ vậy quy tắc kiểm tra hợp lệ, ngưỡng thay đổi lớn và phát sự kiện chỉ cần cài đặt một lần. Quan hệ «extend» giữa UC-07-12 và UC-07-07 cho biết phát hành phiên bản ĐVHC có thêm bước làm mới bảng chiếu `admin_unit` và phát EVT-07-10.

Phía khai thác, ứng dụng HTTT là tác nhân máy chính với ba use case UC-07-09, UC-07-10 và UC-07-13 (chuyển mã). Kỹ sư tích hợp và nhà phát triển dùng cùng các use case này qua trình thử API UI-07-12. Phía nền tảng, quản trị nền tảng giữ danh mục `COMMON` gồm ĐVHC (UC-07-12) và gói nền (UC-07-15); bộ lập lịch kích hoạt đồng bộ quốc gia định kỳ (UC-07-11) và PH-20 gọi nạp gói nền khi khởi tạo tenant.

## 5. Bảng tổng hợp use case và truy vết

### 5.1. Use case và yêu cầu chức năng

Bảng dưới là danh sách chính thức mười bảy use case, tác nhân chính, mức ưu tiên và các FR được hiện thực. Mỗi FR-07 xuất hiện ở ít nhất một use case, trừ các FR thuần cấu hình hoặc thuần đọc được gộp như ghi chú cuối bảng.

| Mã | Tên use case | Tác nhân chính | Mức | FR hiện thực |
|---|---|---|---|---|
| UC-07-01 | Tạo danh mục và khai báo lược đồ | ROLE-DATA_STEWARD | M | FR-07-001, 002, 003, 004, 005, 006, 007, 008, 010 |
| UC-07-02 | Cập nhật bản ghi trên bản nháp | ROLE-DATA_STEWARD | M | FR-07-011, 012, 013, 017, 018, 019 |
| UC-07-03 | Nhập bản ghi từ tệp Excel/CSV | ROLE-DATA_STEWARD | M | FR-07-020, 021, 025 |
| UC-07-04 | Tạo danh mục từ tệp (gồm khuôn Aita) | ROLE-DATA_STEWARD | M | FR-07-022, 003, 005 |
| UC-07-05 | Nhập bản ghi qua API theo lô | Ứng dụng HTTT | M | FR-07-023 |
| UC-07-06 | Trình duyệt và phê duyệt phiên bản | ROLE-DATA_STEWARD, ROLE-DATA_APPROVER | M | FR-07-013, 014, 015 |
| UC-07-07 | Phát hành phiên bản | ROLE-DATA_APPROVER | M | FR-07-016, 034, 050 |
| UC-07-08 | Xuất danh mục | ROLE-DATA_STEWARD, ROLE-VIEWER | M | FR-07-024, 025 |
| UC-07-09 | Khai thác danh mục qua API (một mã, lô, toàn bộ, cây, delta) | Ứng dụng HTTT | M | FR-07-026, 027, 028, 029, 030, 031, 033, 047, 052 |
| UC-07-10 | Truy vấn có cấu trúc qua API | Ứng dụng HTTT | M | FR-07-032, 033 |
| UC-07-11 | Đồng bộ danh mục quốc gia | Bộ lập lịch, ROLE-DATA_APPROVER | M | FR-07-035, 036, 037, 038, 039 |
| UC-07-12 | Ghi nhận sắp xếp ĐVHC và chuyển đổi mã | ROLE-PLATFORM_ADMIN, Ứng dụng HTTT | M | FR-07-044, 045, 046, 047 |
| UC-07-13 | Quản lý ánh xạ mã và chuyển mã | ROLE-DATA_STEWARD, Ứng dụng HTTT | M | FR-07-040, 041, 042, 043 |
| UC-07-14 | Ngừng hiệu lực hoặc xóa danh mục | ROLE-TENANT_ADMIN | M | FR-07-009 |
| UC-07-15 | Nạp gói danh mục nền khi khởi tạo tenant | PH-20, ROLE-PLATFORM_ADMIN | M | FR-07-048, 049 |
| UC-07-16 | Di trú dữ liệu Aita | ROLE-TENANT_ADMIN | M | FR-07-051 |
| UC-07-17 | Mở rộng danh mục quốc gia cho địa phương (HYBRID) | ROLE-DATA_STEWARD | S | FR-07-008, 048 |

FR-07-050 (lịch sử và kiểm toán) được hiện thực xuyên suốt mọi use case ghi và có màn đọc riêng ở tab Lịch sử UI-07-02 (API-07-072); FR-07-053 (tham số PH-07 theo tenant) là chức năng cấu hình do quản trị tỉnh thực hiện trên màn tham số chung của PH-18 lọc namespace `07.rdm` (UI-07-13), được mô tả như một luồng phụ trong mục 7.1 thay vì một use case riêng, vì nó không tạo giá trị nghiệp vụ trực tiếp mà chỉ điều chỉnh ngưỡng của các use case khác.

### 5.2. Use case và màn hình, API

Bảng dưới giúp đội phát triển biết mỗi use case chạm tới những màn hình và API nào, phục vụ chia việc theo lát dọc (vertical slice).

| Mã | Màn hình | API chính |
|---|---|---|
| UC-07-01 | UI-07-01, UI-07-02, UI-07-03, UI-07-04 | API-07-001…010, 022…025 |
| UC-07-02 | UI-07-02, UI-07-05 | API-07-012…016, 026…030 |
| UC-07-03 | UI-07-06, UI-07-08 | API-07-032…037, 040 |
| UC-07-04 | UI-07-01, UI-07-06 | API-07-033…036, 002 |
| UC-07-05 | Không có (máy) | API-07-031, 012 |
| UC-07-06 | UI-07-07 | API-07-016…019, 021 |
| UC-07-07 | UI-07-07 | API-07-014, 020, 049 |
| UC-07-08 | UI-07-02, UI-07-08 | API-07-038…040 |
| UC-07-09 | UI-07-12 (thử) | API-07-033 (danh sách), 041…046, 048…050 |
| UC-07-10 | UI-07-12 | API-07-047, 048 |
| UC-07-11 | UI-07-09 | API-07-055…063, 074 |
| UC-07-12 | UI-07-11, UI-07-05 | API-07-051…054, 050 |
| UC-07-13 | UI-07-10 | API-07-064…071 |
| UC-07-14 | UI-07-02 | API-07-005, 006 |
| UC-07-15 | Không có (máy), UI-07-01 kiểm tra | API-07-073 |
| UC-07-16 | UI-07-08 (theo dõi), công cụ di trú | API-07-002, 031, 020 |
| UC-07-17 | UI-07-03, UI-07-05 | API-07-002, 027, 041 |

### 5.3. Use case và quy trình nghiệp vụ, yêu cầu nghiệp vụ

Bảng dưới gắn use case với yêu cầu nghiệp vụ trong BRD và với các chức năng hệ cũ (mã LGC) để chứng minh không mất chức năng khi chuyển đổi.

| Mã | REQ | BP | LGC hệ cũ được phủ |
|---|---|---|---|
| UC-07-01 | REQ-07 | BP-03 | LGC-DMDC-001, 002, 003, 004, 009, 010, 017, 018 |
| UC-07-02 | REQ-07 | BP-03 | LGC-DMDC-011 |
| UC-07-03 | REQ-07 | BP-03 | LGC-DMDC-006, 007 |
| UC-07-04 | REQ-07 | BP-03 | LGC-DMDC-005 |
| UC-07-05 | REQ-07 | BP-03 | LGC-DMDC-008 |
| UC-07-06 | REQ-07 | BP-03 | Mới |
| UC-07-07 | REQ-07 | BP-03 | Mới |
| UC-07-08 | REQ-07 | — | LGC-DMDC-013, 014 |
| UC-07-09 | REQ-07 | — | LGC-DMDC-015 |
| UC-07-10 | REQ-07 | — | LGC-DMDC-016 |
| UC-07-11 | REQ-07 | BP-03 | LGC-DMDC-019, LGC-NGSP-006 |
| UC-07-12 | REQ-07 | — | Mới (sắp xếp ĐVHC 2025) |
| UC-07-13 | REQ-07 | — | LGC-BUS-036 |
| UC-07-14 | REQ-07 | — | LGC-DMDC-012 |
| UC-07-15 | REQ-20 | BP-08 | Mới |
| UC-07-16 | REQ-22 | — | Toàn bộ dữ liệu LGC-DMDC |
| UC-07-17 | REQ-07, REQ-20 | — | LGC-DMDC-017 |

## 6. Đặc tả chi tiết use case

