---
ma_tai_lieu: D02-04-PH10
ten: Đặc tả use case phân hệ PH-10 Sự kiện
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Hội đồng thẩm định, kỹ sư, kiểm thử viên
phan_he: PH-10
---

# D02-04-PH10 · Đặc tả use case Sự kiện

## Tóm tắt cho hội đồng thẩm định

Tài liệu đặc tả 28 use case của PH-10, phủ toàn bộ 66 FR mức M và 8 FR mức S của [D02-03-PH10](../frs/D02-03-PH10-frs-su-kien.md); FR-10-048 (lọc và gộp lô, mức C, Đợt sau) chỉ có ca kiểm thử, FR-10-071 (nhập khai báo, mức C) có ở UC-10-28 dạng luồng thay thế. Use case đi theo vòng đời thật của một sự kiện nghiệp vụ ở tỉnh: kỹ sư tích hợp lập dự án, khai báo topic kèm lược đồ, người duyệt duyệt và nền tảng cấp phát trên cụm Kafka; HTTT phát được sau khi publication được duyệt; HTTT khác đăng ký nhận theo chế độ đẩy (webhook ký HMAC) hoặc kéo; vận hành tỉnh theo dõi độ trễ tiêu thụ, xử lý DLQ và phát lại có duyệt; PH-04, PH-05 và các DU nội bộ đăng ký, kiểm tra quyền theo kênh máy với máy; quản trị tỉnh di trú dần từ Hub Pulsar cũ. Căn cứ pháp lý như FRS: CMP-LAW-09 (trao đổi bất đồng bộ tin cậy), CMP-LAW-03 (NĐ 278/2025), CMP-LAW-06 và CMP-LAW-08 (NĐ 331/2026, TCVN 14423:2026 cấp độ 3), CMP-LAW-05 (Luật BVDLCN 91/2025).

## 1. Mục đích và phạm vi

Phạm vi là toàn bộ FR-10-001…076. Tài liệu mô tả trình tự tương tác giữa tác nhân và hệ thống, ai làm bước nào, dữ liệu ví dụ và cách xử lý khi có sai lệch; hành vi chi tiết của từng bước (ràng buộc tham số, thứ tự kiểm tra, mã lỗi) nằm ở FR tương ứng và không chép lại. Chức năng dùng chung FR-00 (đăng nhập, chọn tenant, danh sách, kiểm toán, hộp "Việc của tôi", thông báo, xác nhận thao tác) không đặc tả lại; bước dựa vào chúng ghi "Tuân thủ FR-00-nnn".

Mọi enum, trạng thái, tên trường, mã quyền, tham số `10.*`, mã màn hình và mã sự kiện dùng đúng Phụ lục A của FRS. Chỗ use case cần một khái niệm mà Phụ lục A chưa có được ghi ở §8.2 "Đề nghị bổ sung cho FRS", không tự đặt mã.

Ngoài phạm vi: biểu đồ CPU, bộ nhớ của cụm Kafka (PH-13, thay LGC-HUB-005, 006); màn xử lý lỗi vận hành chung (PH-18, PH-10 chỉ cung cấp DLQ tầng sự kiện và API phát lại); thiết kế luồng tiêu thụ sự kiện (PH-04); khai báo CDC (PH-05).

## 2. Quy ước đọc đặc tả

Luồng chính đánh số 1, 2, 3. Luồng thay thế ghi `số bước + chữ` (ví dụ `3a`) và quay lại luồng chính ở bước nêu rõ. Luồng ngoại lệ ghi `E1`, `E2` kèm bước phát sinh, mã lỗi `ERR-10-nnn` của FRS §8.1, và kết thúc use case hoặc quay lại bước nêu rõ. Luồng phụ dùng chung (bốn mắt, lý do bắt buộc, cấp phát bất đồng bộ…) ghi `LP-10-nn` và đặc tả một lần ở §7.

Quy ước chung không nhắc lại trong từng use case (FRS §5): lệnh ghi qua `/api/event/v1` mang `Idempotency-Key` và `If-Match` khi sửa; đối tượng của tenant khác trả như không tồn tại (ERR-10-001); tenant đang tạm ngừng hoặc đóng băng thay đổi trả ERR-10-039 cho mọi lệnh ghi; phụ thuộc không khả dụng trả ERR-10-029 theo LP-10-04.

Dữ liệu ví dụ đều giả lập, tenant `T68` (topic tiền tố `t68.`):

| Vai | Người hoặc hệ thống | Ghi chú |
|---|---|---|
| IE | **An**, Sở KH&CN | Kỹ sư tích hợp |
| IA | **Bình**, Sở KH&CN | Người duyệt tích hợp |
| TA | **Mai**, Sở KH&CN | Quản trị tỉnh |
| TO | **Chi**, Trung tâm dữ liệu tỉnh | Vận hành tỉnh |
| SO | **Dũng**, Sở KH&CN | Cán bộ ATTT |
| OR | **Thảo**, Sở Tài chính | Người đề nghị của tổ chức |
| PA | **Hà**, đơn vị vận hành nền tảng | Quản trị nền tảng |
| HTTT | `HT-DKKD` (đăng ký kinh doanh), `HT-THUE` (hệ thống thuế tỉnh), `HT-BHXH`, `HT-DVC` (cổng dịch vụ công) | Bản sao PH-01 |
| Dự án | `dang-ky-kinh-doanh` | Tổ chức chủ quản `SO-KHDT` |
| Topic | `t68.dkkd.doanh-nghiep.da-cap-phep.v1` | `KEY_HASH`, khóa `maDoanhNghiep`, 6 phân vùng, `INTERNAL` |
| Bên phát, bên nhận | `ht-dkkd` (`HTTP_PUBLISH`), `ht-thue` (`WEBHOOK_PUSH`), `ht-bhxh` (`HTTP_PULL`) | |
| Subscription | `ht-thue-dn-cap-phep` (`PUSH`), `ht-bhxh-dn-cap-phep` (`PULL_API`) | Nhóm `dh-sub-t68-ht-thue-dn-cap-phep` |

## 3. Tác nhân

| Tác nhân | Loại | Use case chính |
|---|---|---|
| ROLE-INTEGRATION_ENGINEER (An) | Chính | 01, 02, 04, 05, 06, 07, 09, 12, 16, 17, 28 |
| ROLE-INTEGRATION_APPROVER (Bình) | Chính | 03, 04, 06, 09, 13, 19, 27 |
| ROLE-TENANT_ADMIN (Mai) | Chính | 22, 26, 27, 28 (và mọi UC của IE, IA trong giới hạn bốn mắt) |
| ROLE-TENANT_OPERATOR (Chi) | Chính | 16, 17, 18, 19, 20 |
| ROLE-SECURITY_OFFICER (Dũng) | Chính | 08, 11, 17 |
| ROLE-ORG_REQUESTER (Thảo) | Chính | 12, 16 (trong phạm vi tổ chức) |
| ROLE-SERVICE_OWNER | Chính | 01, 02, 07, 09 (trong phạm vi tổ chức) |
| ROLE-PLATFORM_ADMIN (Hà) | Chính | 22, 24, 27 |
| ROLE-VIEWER, ROLE-AUDITOR, ROLE-PLATFORM_OPERATOR | Chính (chỉ xem) | 21 |
| HTTT thành viên | Chính (máy) | 10, 11, 15; phụ ở 12, 14 |
| `dh-runtime` (cổng sự kiện, bộ giao nhận, bộ phát lại, bộ giám sát tuân thủ) | Chính (máy) | 14; phụ ở 10, 11, 15, 18, 19 |
| `dh-integration` mô-đun PH-05 | Chính (máy) | 23 |
| `dh-integration` mô-đun PH-04 | Chính (máy) | 25 |
| DU nội bộ (`dh-connect`, `dh-data`, `dh-platform`, `dh-payment`) | Chính (máy) | 24 |
| PH-18 (scope `event:dlq-read`, `event:replay`) | Chính (máy) | 18, 19 |
| PH-01, PH-12 (Keycloak, OPA), PH-13, PH-20, Apicurio, Strimzi qua kho `dh-config-{tenant}`, OpenBao | Phụ | Nhiều use case |

## 4. Sơ đồ use case tổng

```mermaid
flowchart LR
  IE([Kỹ sư tích hợp])
  IA([Người duyệt tích hợp])
  TA([Quản trị tỉnh])
  TO([Vận hành tỉnh])
  SO([Cán bộ ATTT])
  PA([Quản trị nền tảng])
  HT([HTTT thành viên])
  RT([dh-runtime])
  P5([PH-05])
  P4([PH-04])
  DU([DU nội bộ])
  subgraph KB["Khai báo trục sự kiện"]
    U01[UC-10-01 Dự án tích hợp]
    U02[UC-10-02 Tạo topic]
    U03[UC-10-03 Duyệt, cấp phát topic]
    U04[UC-10-04 Đổi cấu hình topic]
    U05[UC-10-05 Ngừng topic, phiên bản mới]
    U06[UC-10-06 Phiên bản lược đồ]
  end
  subgraph BT["Bên tham gia và quan hệ"]
    U07[UC-10-07 Đăng ký bên phát, bên nhận]
    U08[UC-10-08 Tạm ngừng bên tham gia]
    U09[UC-10-09 Publication]
    U12[UC-10-12 Đăng ký nhận]
    U13[UC-10-13 Duyệt subscription]
  end
  subgraph GN["Phát và giao nhận"]
    U10[UC-10-10 Phát qua API]
    U11[UC-10-11 Phát Kafka trực tiếp]
    U14[UC-10-14 Giao ĐẨY, thử lại, DLQ]
    U15[UC-10-15 Nhận KÉO]
  end
  subgraph VH["Vận hành"]
    U16[UC-10-16 Vận hành subscription]
    U17[UC-10-17 Xoay khóa ký]
    U18[UC-10-18 Xử lý DLQ]
    U19[UC-10-19 Phát lại theo khoảng]
    U20[UC-10-20 Theo dõi lag]
    U21[UC-10-21 Dashboard, sơ đồ]
    U22[UC-10-22 Cấu hình, hạn mức]
  end
  subgraph MM["Máy với máy và di trú"]
    U23[UC-10-23 Topic CDC]
    U24[UC-10-24 Topic SYSTEM]
    U25[UC-10-25 Kiểm tra quyền PH-04]
    U26[UC-10-26 Kiểm kê Pulsar]
    U27[UC-10-27 Cầu nối, chuyển hẳn]
    U28[UC-10-28 Xuất, nhập khai báo]
  end
  IE --> U01 & U02 & U04 & U05 & U06 & U07 & U09 & U12 & U28
  IA --> U03 & U13 & U19
  TA --> U22 & U26 & U27
  TO --> U16 & U17 & U18 & U20
  SO --> U08 & U11
  PA --> U22 & U27
  HT --> U10 & U11 & U15
  RT --> U14
  P5 --> U23
  DU --> U24
  P4 --> U25
  TO --> U21
```

Sơ đồ gom 28 use case thành năm nhóm theo vòng đời. Nhóm "Khai báo" và "Bên tham gia" là việc của người trên control plane (`/api/event/v1`), luôn qua duyệt bốn mắt trước khi có hiệu lực trên cụm. Nhóm "Phát và giao nhận" là data plane (`/event/v1` và Kafka), tác nhân chính là HTTT và `dh-runtime`. Nhóm "Vận hành" do TO, TA làm hằng ngày. Nhóm "Máy với máy và di trú" gồm ba kênh đăng ký của PH-04, PH-05, DU nội bộ và chuỗi di trú từ Pulsar. Mọi vai trò có `PERM-10-read` (VW, AU, PO) dùng UC-10-21; mũi tên chỉ vẽ tác nhân chính tiêu biểu để sơ đồ dễ đọc, bảng §3 là danh sách đủ.

## 5. Bảng tổng hợp use case và truy vết

### 5.1. Use case và FR

| UC | Tên | Tác nhân chính | Mức | FR |
|---|---|---|---|---|
| UC-10-01 | Lập và quản lý dự án tích hợp | IE | M | 001, 002, 003, 004, 005, 065 |
| UC-10-02 | Tạo topic kèm lược đồ và gửi duyệt | IE | M | 006, 007, 008, 013, 017 |
| UC-10-03 | Duyệt tạo topic và theo dõi cấp phát | IA | M | 009, 010 |
| UC-10-04 | Thay đổi cấu hình topic đang hoạt động | IE, IA | M | 011, 012, 013, 021 |
| UC-10-05 | Ngừng topic và tạo phiên bản chính mới | IE | M | 014, 015, 016 |
| UC-10-06 | Soạn, kiểm tra và duyệt phiên bản lược đồ | IE, IA | M | 017, 018, 019, 020, 022 |
| UC-10-07 | Đăng ký bên phát và bên nhận | IE | M | 025, 026, 027 |
| UC-10-08 | Tạm ngừng, tiếp tục và ngừng dùng bên tham gia | SO, hệ thống | M | 028, 029 |
| UC-10-09 | Đề nghị và duyệt publication | IE, IA | M | 030, 031 |
| UC-10-10 | HTTT phát sự kiện qua API phát | HTTT | M | 033, 024, 064 |
| UC-10-11 | Phát trực tiếp qua Kafka và xử lý vi phạm lược đồ | HTTT, SO | M | 034, 023, 032 |
| UC-10-12 | Đăng ký nhận sự kiện và xác minh endpoint | IE, OR | M | 035, 036, 040 |
| UC-10-13 | Duyệt subscription và cấp phát nhóm tiêu thụ | IA | M | 037 |
| UC-10-14 | Giao nhận ĐẨY, thử lại và chuyển DLQ | `dh-runtime` | M | 038, 039, 049 |
| UC-10-15 | HTTT nhận sự kiện theo chế độ KÉO | HTTT | M | 043, 044 |
| UC-10-16 | Vận hành subscription: tạm dừng, sửa, thu hồi | TO, IE | M | 041, 046, 047, 056 |
| UC-10-17 | Xoay và thu hồi khẩn khóa ký webhook | TO, SO | M | 042 |
| UC-10-18 | Xử lý mục DLQ và phát lại mục DLQ | TO | M | 050, 053 |
| UC-10-19 | Đề nghị, duyệt và chạy phát lại theo khoảng | TO, IA | M | 051, 052 |
| UC-10-20 | Theo dõi độ trễ tiêu thụ và xác nhận cảnh báo | TO | M | 054, 055, 059 |
| UC-10-21 | Xem dashboard và sơ đồ kết nối | Mọi vai trò xem | M | 057, 058 |
| UC-10-22 | Cấu hình danh mục, hạn mức và tham số | TA, PA | M | 060, 061, 062, 063 |
| UC-10-23 | PH-05 đăng ký topic CDC và báo thay đổi lược đồ | PH-05 | M | 066, 068 |
| UC-10-24 | DU nội bộ đăng ký topic SYSTEM và topic nền tảng | DU nội bộ | M | 067, 064 |
| UC-10-25 | PH-04 kiểm tra quyền phát, nhận và tiêu thụ nội bộ | PH-04 | M | 069, 045 |
| UC-10-26 | Nhập kiểm kê Hub Pulsar và lập ánh xạ | TA | M | 072 |
| UC-10-27 | Chạy cầu nối, đối chiếu, chuyển hẳn và quay lui | TA, IA | M | 073, 074, 075, 076 |
| UC-10-28 | Xuất và nhập khai báo sự kiện | IE | S | 070, 071 |

FR-10-048 (C, Đợt sau) không có use case; khi được đưa vào phạm vi sẽ bổ sung luồng thay thế cho UC-10-12 và UC-10-14.

### 5.2. Use case, màn hình và API

| UC | UI | API |
|---|---|---|
| UC-10-01 | UI-10-02, 03, 04 | API-10-001, 002, 003, 004, 005, 006 |
| UC-10-02 | UI-10-03, 05, 06, 07 | API-10-008, 009, 010, 011, 012, 026 |
| UC-10-03 | UI-10-13, 06 | API-10-057, 058, 059, 013, 014 |
| UC-10-04 | UI-10-06, 13 | API-10-015, 059 |
| UC-10-05 | UI-10-06, 01 | API-10-016, 017, 018, 019 |
| UC-10-06 | UI-10-08, 13 | API-10-021, 022, 023, 024, 025, 026, 027, 028, 029, 030 |
| UC-10-07 | UI-10-09, 10 | API-10-032, 033, 034, 037, 038, 039 |
| UC-10-08 | UI-10-09, 10 | API-10-035, 036, 040, 041 |
| UC-10-09 | UI-10-09, 06, 13 | API-10-042, 043, 044, 059 |
| UC-10-10 | UI-10-06 (tab Cách kết nối) | API-10-020, 079, 084 |
| UC-10-11 | UI-10-06 | API-10-020, 031, 045 |
| UC-10-12 | UI-10-11 | API-10-046, 047, 051 |
| UC-10-13 | UI-10-13, 12 | API-10-057, 058, 059, 048 |
| UC-10-14 | UI-10-12 | API-10-073 |
| UC-10-15 | UI-10-12 | API-10-080, 081, 082, 083, 084 |
| UC-10-16 | UI-10-12 | API-10-048, 049, 050, 052, 053 |
| UC-10-17 | UI-10-12 | API-10-054 |
| UC-10-18 | UI-10-15 | API-10-060, 061, 062, 064 |
| UC-10-19 | UI-10-16, 13 | API-10-063, 064, 065, 059 |
| UC-10-20 | UI-10-17, 12 | API-10-055, 056 |
| UC-10-21 | UI-10-01, 14 | API-10-066, 007 |
| UC-10-22 | UI-10-18 | API-10-067, 068, 069, 070 |
| UC-10-23 | Không (máy); kết quả xem ở UI-10-06 | API-10-009, 023, 018 |
| UC-10-24 | Không (máy) | API-10-009 |
| UC-10-25 | Không (máy); kết quả hiện ở trình thiết kế PH-04 | API-10-071, 072, 008 |
| UC-10-26 | UI-10-20 | API-10-075, 076 |
| UC-10-27 | UI-10-20, 13 | API-10-077, 078, 059 |
| UC-10-28 | UI-10-02, 19 | API-10-074, 075 |

### 5.3. Use case, REQ, quy trình và hệ cũ

| UC | REQ | Quy trình | LGC |
|---|---|---|---|
| UC-10-01 | REQ-10, REQ-13 | Khai báo trục sự kiện | LGC-HUB-008 |
| UC-10-02 | REQ-10 | Khai báo trục sự kiện | LGC-HUB-009, LGC-HUB-014 |
| UC-10-03 | REQ-10 | Khai báo trục sự kiện | LGC-HUB-009 |
| UC-10-04 | REQ-10 | Thay đổi cấu hình | LGC-HUB-009, LGC-HUB-014 |
| UC-10-05 | REQ-10 | Thay đổi cấu hình | LGC-HUB-009 |
| UC-10-06 | REQ-10 | Khai báo trục sự kiện | LGC-HUB-009 |
| UC-10-07 | REQ-10, REQ-01 | Kết nạp, tích hợp | LGC-HUB-010, LGC-HUB-011 |
| UC-10-08 | REQ-10, REQ-01, REQ-04 | Ứng phó sự cố | LGC-HUB-010, LGC-HUB-011 |
| UC-10-09 | REQ-10, REQ-12 | Cấp quyền phát | LGC-HUB-012 |
| UC-10-10 | REQ-10, REQ-20 | Trao đổi bất đồng bộ | LGC-HUB-012, LGC-BUS-039 |
| UC-10-11 | REQ-10 | Trao đổi bất đồng bộ | LGC-TOOL-010, LGC-HUB-012 |
| UC-10-12 | REQ-10 | Cấp quyền nhận | LGC-HUB-013 |
| UC-10-13 | REQ-10, REQ-12 | Cấp quyền nhận | LGC-HUB-013 |
| UC-10-14 | REQ-10, REQ-18 | Trao đổi bất đồng bộ | LGC-HUB-013, LGC-BUS-039 |
| UC-10-15 | REQ-10 | Trao đổi bất đồng bộ | LGC-HUB-013, LGC-TOOL-010, LGC-BUS-039 |
| UC-10-16 | REQ-10 | Vận hành | LGC-HUB-013 |
| UC-10-17 | REQ-10 | Vận hành | LGC-HUB-013 (nâng cấp) |
| UC-10-18 | REQ-10, REQ-18 | Xử lý lỗi | Không có ở hệ cũ |
| UC-10-19 | REQ-10, REQ-18 | Xử lý lỗi | Không có ở hệ cũ |
| UC-10-20 | REQ-10, REQ-13 | Giám sát | LGC-HUB-007 (phủ lag) |
| UC-10-21 | REQ-10, REQ-13 | Giám sát | LGC-HUB-001, 002, 003, 004, 007; LGC-HUB-005, 006 chuyển PH-13 |
| UC-10-22 | REQ-10, REQ-18, REQ-20 | Quản trị tỉnh | LGC-HUB-014 |
| UC-10-23 | REQ-10, REQ-05 | Máy với máy | LGC-TOOL-010 |
| UC-10-24 | REQ-10, REQ-20 | Máy với máy, khởi tạo tenant | LGC-TOOL-010, LGC-BUS-039 |
| UC-10-25 | REQ-10, REQ-04 | Máy với máy | LGC-HUB-011, LGC-TOOL-010 |
| UC-10-26 | REQ-22 | Di trú song song | LGC-HUB-008 … LGC-HUB-014 |
| UC-10-27 | REQ-22 | Di trú song song | LGC-HUB-008 … LGC-HUB-014 |
| UC-10-28 | REQ-22 | Rà soát, chuyển môi trường | Không có ở hệ cũ |

Truy vết ngược từ chức năng hệ cũ: LGC-HUB-001…004 ở UC-10-21; LGC-HUB-005, 006 thay bằng PH-13, UC-10-21 chỉ có liên kết sang; LGC-HUB-007 ở UC-10-20, 21; LGC-HUB-008 ở UC-10-01; LGC-HUB-009 ở UC-10-02…06; LGC-HUB-010, 011 ở UC-10-07, 08, 25; LGC-HUB-012 ở UC-10-09…11; LGC-HUB-013 ở UC-10-12…17; LGC-HUB-014 ở UC-10-02, 04, 22; LGC-TOOL-010 ở UC-10-11, 15, 23…25; LGC-BUS-039 ở UC-10-10, 14, 15, 24. Mọi mục `LGC-HUB` đều có use case; UC-10-26, 27 phủ việc chuyển dữ liệu khai báo của cả mười bốn mục sang Datahub.

## 6. Đặc tả chi tiết use case

### 6.1. UC-10-01 · Lập và quản lý dự án tích hợp

| Mục | Nội dung |
|---|---|
| Mục tiêu | Kỹ sư tích hợp có một dự án gom các topic của một nghiệp vụ liên thông, có tổ chức chủ quản rõ, lưu trữ được khi hết dùng mà không mất truy vết |
| Tác nhân chính | ROLE-INTEGRATION_ENGINEER (An) |
| Tác nhân phụ | PH-12 (danh sách tổ chức), dịch vụ kiểm toán (FR-00-041) |
| Mức ưu tiên | M |
| FR hiện thực | FR-10-001, 002, 003, 004, 005, 065 |
| Tiền điều kiện | An có `PERM-10-create`, `PERM-10-update`; tenant T68 `ACTIVE`; số dự án dưới `10.quota.max-projects` (200) |
| Điều kiện kích hoạt | An bấm "Tạo dự án" ở UI-10-02 |
| Đảm bảo tối thiểu | Không có dự án nửa vời; mã đã nhập không bị giữ chỗ nếu tạo thất bại |
| Đảm bảo thành công | Dự án `dang-ky-kinh-doanh` ở `ACTIVE`, có bản ghi kiểm toán người tạo |

**Luồng chính**

1. An mở UI-10-02. Hệ thống gọi API-10-001 với `status=ACTIVE`, hiện bảng dự án kèm `topicCount`, `publisherCount`, `subscriberCount`, `maxLagSeconds` và khối lọc theo `ownerOrgCode`, nhãn (tuân thủ FR-00-020…023).
2. An bấm "Tạo dự án". Hệ thống mở UI-10-04 (Drawer PTN-04), nạp danh sách tổ chức của tenant từ PH-12.
3. An nhập `projectCode` `dang-ky-kinh-doanh`, tên "Liên thông đăng ký kinh doanh", tổ chức chủ quản `SO-KHDT`, nhãn `doanh-nghiep`. Hệ thống kiểm tra mẫu mã và từ dành riêng ngay khi rời ô.
4. An bấm "Lưu". Hệ thống gọi API-10-002 với `Idempotency-Key`; nhận `201`, `Location`, `ETag`; dự án `ACTIVE`.
5. Hệ thống chuyển sang UI-10-03 của dự án mới: tab Tổng quan trống, nút "Tạo topic" (tiếp UC-10-02), tab Lịch sử có một dòng "Tạo dự án · An · 26/11/2026 08:30" (FR-10-065, tuân thủ FR-00-043).
6. Về sau, An sửa mô tả ở UI-10-04 chế độ sửa. Hệ thống gọi API-10-004 với `If-Match`; tab Lịch sử ghi giá trị trước và sau.

**Luồng thay thế**

- **3a. SV tạo dự án cho tổ chức mình.** Ô tổ chức chủ quản chỉ có tổ chức của SV, chọn sẵn; tiếp bước 4.
- **6a. Lưu trữ dự án hết dùng.** An chọn "Lưu trữ", nhập lý do theo LP-10-02. Hệ thống gọi API-10-005; dự án sang `ARCHIVED`, topic `DRAFT` còn lại bị xóa mềm (tuân thủ FR-00-051). Danh sách mặc định không còn hiện dự án; lọc `status=ARCHIVED` vẫn thấy.
- **6b. Khôi phục.** Trên dự án `ARCHIVED`, An chọn "Khôi phục". Hệ thống gọi API-10-006; dự án về `ACTIVE`.
- **6c. Đổi tổ chức chủ quản.** Hệ thống chỉ cho lưu khi An có quyền ở cả tổ chức cũ và mới; ngược lại E5.

**Luồng ngoại lệ**

- **E1. Mã sai mẫu hoặc trùng từ dành riêng (bước 3, 4),** ví dụ `tong-quan`. ERR-10-003; ô mã báo "Mã không hợp lệ hoặc là từ dành riêng của đường dẫn"; quay lại bước 3.
- **E2. Mã đã dùng (bước 4), kể cả dự án `ARCHIVED`.** ERR-10-002; quay lại bước 3 (BR-10-003).
- **E3. Vượt hạn mức dự án (bước 4).** ERR-10-011; thông điệp nêu trần hiện hành và liên hệ TA (UC-10-22); use case kết thúc.
- **E4. Lưu trữ khi còn topic hoạt động (6a).** ERR-10-010 kèm danh sách topic `PENDING_APPROVAL`, `PROVISIONING`, `ACTIVE`, `DEPRECATED`; An phải ngừng dùng các topic trước (UC-10-05).
- **E5. Ngoài phạm vi tổ chức (3a, 6c).** ERR-10-044; không lưu.
- **E6. Sửa dự án `ARCHIVED` (bước 6).** ERR-10-006; nút "Sửa" bị ẩn trên giao diện, lỗi chỉ xảy ra khi gọi thẳng API.
- **E7. Người khác vừa sửa (bước 6).** ERR-10-007 theo LP-10-03.

**Quy tắc áp dụng:** BR-10-003.

### 6.2. UC-10-02 · Tạo topic kèm lược đồ và gửi duyệt

| Mục | Nội dung |
|---|---|
| Mục tiêu | Kỹ sư tích hợp khai báo một loại sự kiện nghiệp vụ có tên đúng quy ước, cấu hình hợp lệ và lược đồ bắt buộc, gửi duyệt trong một lượt |
| Tác nhân chính | ROLE-INTEGRATION_ENGINEER (An) |
| Tác nhân phụ | Apicurio (trình phân tích lược đồ), dịch vụ thông báo (FR-00-060) |
| Mức ưu tiên | M |
| FR hiện thực | FR-10-006, 007, 008, 013, 017 |
| Tiền điều kiện | An có `PERM-10-create`; dự án `dang-ky-kinh-doanh` `ACTIVE`; tenant chưa vượt `maxTopics`, `maxPartitionsTotal`; `KEY_HASH` được bật (FR-10-061) |
| Điều kiện kích hoạt | An bấm "Tạo topic" ở UI-10-05 hoặc ở tab Topic của UI-10-03 |
| Đảm bảo tối thiểu | Chưa có gì trên cụm Kafka hay Apicurio trước khi được duyệt |
| Đảm bảo thành công | Topic `t68.dkkd.doanh-nghiep.da-cap-phep.v1` và phiên bản lược đồ 1 ở `PENDING_APPROVAL`, có yêu cầu `TOPIC_CREATE` trong "Việc của tôi" của IA |

**Luồng chính**

1. Hệ thống mở UI-10-07 bước "Dự án và tên", điền sẵn dự án đang đứng.
2. An nhập miền `dkkd`, thực thể `doanh-nghiep`, sự kiện `da-cap-phep`, mô tả "Phát khi Sở KH&CN cấp giấy chứng nhận đăng ký doanh nghiệp; mang mã doanh nghiệp và ngày cấp". Hệ thống ghép và hiện tên xem trước `t68.dkkd.doanh-nghiep.da-cap-phep.v1`, kiểm tra trùng bằng API-10-008 với `q`.
3. Ở bước "Cấu hình", hệ thống điền mặc định: `partitions` 6, `retentionHours` 168, `cleanupPolicy` `DELETE`, `routingMode` `KEY_HASH`; hệ số nhân bản 3 và `min.insync.replicas` 2 hiện dạng chỉ đọc (BR-10-004). An chọn `dataClass` `INTERNAL`, `orderingRequired` bật.
4. Ở bước "Định tuyến", An nhập `partitionKeyField` `maDoanhNghiep`. Hệ thống giải thích: sự kiện cùng mã doanh nghiệp vào cùng phân vùng và giữ thứ tự (FR-10-013).
5. Ở bước "Lược đồ", An chọn `AVRO`, dán lược đồ `record DoanhNghiepDaCapPhep`, namespace `vn.datahub.t68.dkkd`, các trường `maDoanhNghiep`, `tenDoanhNghiep`, `ngayCap`, `coQuanCap`, mỗi trường có `doc`.
6. An bấm "Kiểm tra". Hệ thống kiểm tra cú pháp, quy ước, trường khóa và dữ liệu cá nhân theo FR-10-017 (dùng API-10-026 trên bản nháp); kết quả: đạt, một cảnh báo quy ước "trường `coQuanCap` nên là mã T-CODE".
7. Ở bước "Gửi duyệt", hệ thống tóm tắt cấu hình, lược đồ, kết quả kiểm tra. An giữ ô "Gửi duyệt ngay" và bấm "Tạo".
8. Hệ thống gọi API-10-009 với `submit=true`; nhận `201` kèm `approvalRequestCode` `apr-01jdx5…`. Topic và phiên bản lược đồ 1 sang `PENDING_APPROVAL`; yêu cầu vào "Việc của tôi" của Bình (tuân thủ FR-00-070).
9. Hệ thống mở UI-10-06 của topic: thẻ trạng thái "Chờ duyệt", tab Lược đồ hiện phiên bản 1, tab Cách kết nối ghi "Có sau khi topic hoạt động".

**Luồng thay thế**

- **1a. Tạo nhanh từ chi tiết dự án.** An bấm "Tạo topic nhanh" ở UI-10-03. Hệ thống mở Drawer PTN-04 chỉ hỏi miền, thực thể, sự kiện, mô tả, phân loại và lược đồ; mọi tham số còn lại dùng mặc định; tiếp bước 6.
- **3a. Topic trạng thái hiện hành, ví dụ danh mục.** An chọn `cleanupPolicy` `COMPACT`; hệ thống cảnh báo chỉ bản tin mới nhất theo khóa được giữ lâu dài; hợp lệ vì đã có khóa.
- **3b. Chọn `SINGLE_PARTITION`.** Hệ thống đặt `partitions` 1 và khóa ô; ẩn ô khóa phân vùng ở bước 4.
- **7a. Lưu nháp, gửi sau.** An bỏ ô "Gửi duyệt ngay". Topic ở `DRAFT`; về sau An bấm "Gửi duyệt" trên UI-10-06, hệ thống gọi API-10-012. Trong lúc nháp, An sửa mô tả, cấu hình qua API-10-011.
- **9a. Tìm lại topic.** An mở UI-10-05, lọc `projectCode=dang-ky-kinh-doanh`, `status=PENDING_APPROVAL` (FR-10-006); mỗi dòng có `latestSchemaVersion`, `publicationCount`, `subscriptionCount`.

**Luồng ngoại lệ**

- **E1. Tên sai quy ước hoặc dùng miền dành riêng (bước 2),** ví dụ miền `cdc` hay `rdm`. ERR-10-004; hệ thống nêu danh sách miền chỉ nhận đăng ký máy (BR-10-030); quay lại bước 2.
- **E2. Tên trùng, kể cả topic `RETIRED` (bước 8).** ERR-10-002; quay lại bước 2.
- **E3. Số phân vùng vượt `10.topic.max-partitions` hoặc lưu giữ vượt trần (bước 3).** ERR-10-012; quay lại bước 3.
- **E4. Vượt hạn mức tenant, tính cả topic đang chờ duyệt (bước 8).** ERR-10-011; use case kết thúc, An liên hệ TA.
- **E5. `KEY_HASH` thiếu khóa, hoặc `orderingRequired` với `ROUND_ROBIN` (bước 4).** ERR-10-046; quay lại bước 4.
- **E6. `COMPACT` với chế độ không có khóa (3a).** ERR-10-048; quay lại bước 3.
- **E7. Lược đồ sai cú pháp (bước 6).** ERR-10-015 kèm dòng, cột; quay lại bước 5.
- **E8. Lược đồ không có trường `maDoanhNghiep` hoặc trường cho phép null (bước 6).** ERR-10-017; quay lại bước 5.
- **E9. Trường nghi dữ liệu cá nhân, ví dụ `soDinhDanhChuDoanhNghiep`, khi `10.schema.pii-check-mode` là `BLOCK` (bước 6).** ERR-10-018; hệ thống gợi ý chỉ mang định danh doanh nghiệp (BR-10-014); quay lại bước 5. Ở chế độ `WARN`, phát hiện ghi vào `piiFindings` mức `WARNING` và người duyệt phải xác nhận (UC-10-03).
- **E10. Định dạng `JSON_SCHEMA` bị tắt ở tenant (bước 5).** ERR-10-020.
- **E11. Dự án đã `ARCHIVED` (bước 8).** ERR-10-006.

**Quy tắc áp dụng:** BR-10-002, 003, 004, 006, 011, 014, 030.

### 6.3. UC-10-03 · Duyệt tạo topic và theo dõi cấp phát

| Mục | Nội dung |
|---|---|
| Mục tiêu | Người duyệt kiểm soát topic trước khi lên cụm; sau duyệt, nền tảng đăng ký lược đồ, sinh tài nguyên vào Git và topic hoạt động trong ≤ 3 phút ở p95 |
| Tác nhân chính | ROLE-INTEGRATION_APPROVER (Bình) |
| Tác nhân phụ | Apicurio, kho `dh-config-{tenant}`, Argo CD và Strimzi, bộ đối soát của `dh-integration`, An (người gửi) |
| Mức ưu tiên | M |
| FR hiện thực | FR-10-009, 010 |
| Tiền điều kiện | Yêu cầu `TOPIC_CREATE` ở `PENDING`; Bình có `PERM-10-approve`, không phải người tạo topic hay người gửi duyệt |
| Điều kiện kích hoạt | Bình mở yêu cầu từ "Việc của tôi" (UI-10-13) |
| Đảm bảo tối thiểu | Không có artifact Apicurio hay tài nguyên Git dở dang khi duyệt thất bại; yêu cầu giữ `PENDING` |
| Đảm bảo thành công | Topic `ACTIVE`, topic DLQ `t68.dkkd.doanh-nghiep.da-cap-phep.v1.dlq` có trên cụm, phiên bản lược đồ 1 `ENABLED`; phát EVT-10-01 và EVT-10-05 |

**Luồng chính**

1. Bình mở UI-10-13 lọc `requestType=TOPIC_CREATE`. Hệ thống gọi API-10-057 rồi API-10-058, hiện cấu hình, lược đồ, kết quả kiểm tra (`checks`), cảnh báo quy ước của An và mức dùng hạn mức sau khi thêm topic.
2. Bình đọc lược đồ, thấy cảnh báo về `coQuanCap`, nhập ý kiến "Đồng ý; lần sau dùng mã cơ quan" và chọn "Duyệt".
3. Hệ thống kiểm tra bốn mắt theo LP-10-01, rồi gọi API-10-059 hành động `:approve`. Máy chủ chạy lại kiểm tra hạn mức và tên.
4. Hệ thống tạo artifact Apicurio `groupId = t68`, `artifactId = t68.dkkd.doanh-nghiep.da-cap-phep.v1`, quy tắc tương thích `BACKWARD`, phiên bản 1 `ENABLED`; lưu `apicurioGlobalId`.
5. Hệ thống sinh `KafkaTopic` cho topic và cho topic DLQ (BR-10-023), commit vào `dh-config-t68` thư mục `kafka/topics/`; topic sang `PROVISIONING`, lưu `provisioningCommit` (LP-10-05).
6. Bộ đối soát đọc trạng thái `Ready` mỗi 10 giây. Khi cả hai tài nguyên sẵn sàng, topic sang `ACTIVE`, ghi `activatedAt`; outbox phát EVT-10-01 và EVT-10-05.
7. Hệ thống thông báo An (FR-00-060). UI-10-06 hiện trạng thái "Đang hoạt động", tab Cách kết nối có đường dẫn API phát và URI lược đồ.

**Luồng thay thế**

- **2a. Từ chối.** Bình chọn "Từ chối" và nhập lý do ≥ 10 ký tự. Yêu cầu `REJECTED`, topic và phiên bản lược đồ về `DRAFT`; An được thông báo kèm lý do, sửa rồi gửi lại (UC-10-02 bước 7a).
- **2b. Có phát hiện dữ liệu cá nhân mức `WARNING`.** Nút "Duyệt" chỉ bật khi Bình đánh dấu ô xác nhận (`acknowledgePii`); thiếu thì E2.
- **2c. Mai (TA) duyệt thay.** Hợp lệ nếu Mai không tạo, không gửi topic này (BR-10-010).
- **6a. Cấp phát thất bại.** Quá `10.provisioning.timeout-minutes` (10) hoặc Strimzi báo lỗi, ví dụ Kyverno từ chối nhãn: topic sang `FAILED`, lưu `provisioningError`, cảnh báo An và Mai. An mở UI-10-06, đọc lỗi rồi bấm "Thử lại cấp phát" (API-10-013, commit mới, quay lại bước 6) hoặc "Hủy cấp phát" (API-10-014, topic về `DRAFT`, xóa artifact Apicurio khi chưa có bản tin).
- **6b. Lệch cấu hình về sau.** Đối chiếu 10 phút một lần phát hiện `retention.ms` trên cụm khác Git: hệ thống ghi cảnh báo mức cao kèm khác biệt, không tự sửa đè ngoài Git (BR-10-036); TO xử lý theo quy trình GitOps.
- **6c. Yêu cầu quá hạn.** Yêu cầu `PENDING` quá `10.approval.expire-days` (30) ngày sang `EXPIRED`, topic về `DRAFT`.

**Luồng ngoại lệ**

- **E1. Bình là người gửi duyệt (bước 3).** ERR-10-008 theo LP-10-01.
- **E2. Thiếu ý kiến hoặc thiếu xác nhận dữ liệu cá nhân (bước 3).** ERR-10-009; quay lại bước 2.
- **E3. Apicurio hoặc Git không khả dụng (bước 4, 5).** ERR-10-029 theo LP-10-04; artifact vừa tạo được xóa bù; yêu cầu giữ `PENDING`.
- **E4. Hạn mức đã kín trong lúc chờ (bước 3).** ERR-10-011; Bình từ chối hoặc chờ TA nâng trần.
- **E5. Lệnh phụ thuộc gửi khi topic `FAILED` (6a),** ví dụ đề nghị publication. ERR-10-038.

**Quy tắc áp dụng:** BR-10-004, 010, 011, 014, 023, 036.

### 6.4. UC-10-04 · Thay đổi cấu hình topic đang hoạt động

| Mục | Nội dung |
|---|---|
| Mục tiêu | Điều chỉnh số phân vùng, lưu giữ, chính sách dọn, chế độ định tuyến và mức tương thích mà không làm mất sự kiện hay phá thứ tự ngoài ý muốn |
| Tác nhân chính | ROLE-INTEGRATION_ENGINEER (An) đề nghị; ROLE-INTEGRATION_APPROVER (Bình) duyệt |
| Tác nhân phụ | Kho `dh-config-{tenant}`, Strimzi, Apicurio, `dh-runtime` (nhận EVT-10-02) |
| Mức ưu tiên | M |
| FR hiện thực | FR-10-011, 012, 013, 021 |
| Tiền điều kiện | Topic `ACTIVE` (hoặc `DEPRECATED` với lưu giữ); An có `PERM-10-update`; topic có `topicKind` `BUSINESS` |
| Điều kiện kích hoạt | An chọn "Thay đổi cấu hình" ở tab Cấu hình của UI-10-06 |
| Đảm bảo tối thiểu | Cấu hình trên cụm không đổi cho tới khi được duyệt và commit thành công |
| Đảm bảo thành công | Topic có `partitions` 12; EVT-10-02 phát; cổng và Kamelet áp dụng trong ≤ 60 giây |

**Luồng chính**

1. Lưu lượng cấp phép doanh nghiệp tăng sau đợt cải cách. An mở tab Cấu hình, chọn tăng `partitions` từ 6 lên 12, nhập lý do, chọn `plannedAt` 22:00.
2. Vì topic dùng `KEY_HASH` và `orderingRequired`, hệ thống hiện cảnh báo: khóa sẽ ánh xạ sang phân vùng khác, thứ tự giữa sự kiện trước và sau thời điểm đổi của cùng mã doanh nghiệp không còn bảo đảm, kèm gợi ý tạo phiên bản topic mới (UC-10-05). An đánh dấu `acknowledgeOrderingImpact`.
3. Hệ thống gọi API-10-015; nhận yêu cầu `TOPIC_CHANGE` kèm khác biệt `partitions: 6 → 12`.
4. Bình mở yêu cầu ở UI-10-13, xem danh sách subscription đang chạy và lag, nhập ý kiến, chọn "Duyệt" (API-10-059, LP-10-01).
5. Đến 22:00, hệ thống commit cập nhật `KafkaTopic` (LP-10-05). Khi Strimzi báo sẵn sàng, hệ thống cập nhật `partitions`, phát EVT-10-02 và gợi ý tăng `workerCount` của `ht-thue-dn-cap-phep` (không tự đổi).
6. An nhận thông báo, mở UI-10-12 của subscription để chỉnh worker (UC-10-16 bước 6a).

**Luồng thay thế**

- **1a. Tăng lưu giữ trong trần tenant hoặc tăng `maxMessageBytes`.** Áp dụng không cần duyệt: hệ thống commit ngay, phát EVT-10-02; bỏ bước 4.
- **1b. Giảm lưu giữ từ 168 xuống 72 giờ.** Hệ thống tính trước danh sách subscription có `lagSeconds` lớn hơn 72 giờ; nếu khác rỗng, ở bước 4 nút "Duyệt" chỉ bật khi Bình đánh dấu xác nhận mất dữ liệu (`acknowledgeDataLoss`).
- **1c. Đổi định tuyến `ROUND_ROBIN` sang `KEY_HASH`.** Chiều không phá bên nhận; yêu cầu `TOPIC_CHANGE` thông thường; sau khi áp dụng, cổng sự kiện bắt đầu đặt khóa theo `partitionKeyField` (FR-10-013).
- **1d. Đổi mức tương thích từ `BACKWARD` sang `FULL_TRANSITIVE`.** Hệ thống kiểm tra trước mọi phiên bản `ENABLED` thỏa mức mới; đạt thì tạo `TOPIC_CHANGE`; khi duyệt, ghi quy tắc vào artifact Apicurio (FR-10-021).
- **1e. Đổi sang `COMPACT_DELETE`.** Như 1b, kèm cảnh báo về compaction.

**Luồng ngoại lệ**

- **E1. Giảm số phân vùng (bước 1).** ERR-10-013 (BR-10-005).
- **E2. Thiếu xác nhận tác động thứ tự (bước 3).** ERR-10-014; quay lại bước 2.
- **E3. Vượt trần phân vùng hoặc hạn mức tổng phân vùng (bước 3).** ERR-10-012 hoặc ERR-10-011.
- **E4. Topic `SINGLE_PARTITION` (bước 1).** Nút tăng phân vùng bị ẩn; gọi thẳng API trả ERR-10-046.
- **E5. Đổi định tuyến theo chiều phá vỡ (1c), ví dụ `KEY_HASH` sang `ROUND_ROBIN`.** ERR-10-047; hệ thống hướng dẫn tạo phiên bản topic mới.
- **E6. Chế độ đích bị tắt ở danh mục (1c).** ERR-10-043.
- **E7. Mức tương thích không được phép, ví dụ `NONE` cho topic đã từng `ACTIVE` (1d).** ERR-10-019 (BR-10-012).
- **E8. Siết mức mà có phiên bản không thỏa (1d).** ERR-10-016 kèm cặp phiên bản vi phạm.
- **E9. Topic `CDC` hoặc `SYSTEM` (bước 1).** ERR-10-045; cấu hình chỉ do tài khoản dịch vụ chủ quản đổi (UC-10-23, 24).
- **E10. Compaction với topic không khóa (1e).** ERR-10-048.
- **E11. Bình là người đề nghị (bước 4).** ERR-10-008.

**Quy tắc áp dụng:** BR-10-005, 006, 010, 012, 030, 036.

### 6.5. UC-10-05 · Ngừng topic và tạo phiên bản chính mới

| Mục | Nội dung |
|---|---|
| Mục tiêu | Khi cần thay đổi phá vỡ, tạo topic `.v2` chạy song song, đưa topic cũ sang ngừng khuyến nghị, theo dõi bên nhận chuyển đổi rồi ngừng dùng có kiểm soát |
| Tác nhân chính | ROLE-INTEGRATION_ENGINEER (An) |
| Tác nhân phụ | Bình (duyệt), đầu mối các HTTT bên phát, bên nhận (thông báo FR-00-060), Strimzi |
| Mức ưu tiên | M |
| FR hiện thực | FR-10-014, 015, 016 |
| Tiền điều kiện | Topic `t68.dkkd.doanh-nghiep.da-cap-phep.v1` `ACTIVE`; chưa có kế nhiệm khác `RETIRED`; An có `PERM-10-create`, `PERM-10-update` |
| Điều kiện kích hoạt | An chọn "Tạo phiên bản chính mới" ở UI-10-06 sau khi UC-10-06 báo lược đồ mới không tương thích |
| Đảm bảo tối thiểu | Topic cũ vẫn phát, nhận bình thường tới `sunsetAt`; không quan hệ nào bị thu hồi khi chưa được phép |
| Đảm bảo thành công | Topic `.v2` `ACTIVE`; topic `.v1` `DEPRECATED` với `successorTopic`, `sunsetAt`; về sau `.v1` `RETIRED` |

**Luồng chính**

1. Nghiệp vụ đổi `ngayCap` từ chuỗi sang `date` logic, phá vỡ `BACKWARD`. An chọn "Tạo phiên bản chính mới". Hệ thống gọi API-10-018, sinh tên `t68.dkkd.doanh-nghiep.da-cap-phep.v2`, sao cấu hình `.v1` làm mặc định.
2. An dán lược đồ mới, nhập `migrationNote` "Trường ngayCap đổi kiểu date; bên nhận cập nhật bộ giải tuần tự", `sunsetDays` 90. Hệ thống kiểm tra như UC-10-02 bước 6, tạo topic `.v2` `DRAFT` với `predecessorTopic`, gửi duyệt `TOPIC_CREATE` kèm khác biệt lược đồ với `.v1`.
3. Bình duyệt theo UC-10-03. Khi `.v2` `ACTIVE`, hệ thống đưa `.v1` sang `DEPRECATED`, ghi `successorTopic`, `sunsetAt` = hôm nay + 90 ngày, chặn subscription mới trên `.v1`, phát EVT-10-01 (topic mới) và EVT-10-03 (topic cũ).
4. Hệ thống tạo sẵn bản nháp publication trên `.v2` cho `ht-dkkd` (chờ bên phát xác nhận và duyệt theo UC-10-09) và thông báo đầu mối `HT-THUE`, `HT-BHXH` kèm `migrationNote`.
5. An mở tab "Chuyển đổi phiên bản" của UI-10-06. Hệ thống gọi API-10-019, hiện bảng: `ht-thue` đã có subscription `.v2` `ACTIVE`, `ht-bhxh` chưa; lag ở hai bên; số ngày còn lại (FR-10-016). Trước `sunsetAt` 14 và 3 ngày, hệ thống nhắc đầu mối chưa chuyển.
6. Khi mọi bên nhận đã chuyển, An chọn "Ngừng dùng" trên `.v1`, nhập lý do (LP-10-02). Hệ thống gọi API-10-017; không còn subscription hiệu lực nên áp dụng ngay: thu hồi publication còn lại, gỡ ACL và scope, topic sang `RETIRED`, phát EVT-10-04, xếp lịch xóa `KafkaTopic` và DLQ sau `10.topic.delete-after-retire-days` (7) ngày.

**Luồng thay thế**

- **1a. Chỉ ngừng khuyến nghị, không có kế nhiệm.** An chọn "Ngừng khuyến nghị", nhập lý do, để trống `successorTopic`. Hệ thống gọi API-10-016; tiếp bước 5.
- **5a. Đến `sunsetAt` mà không còn subscription.** Hệ thống tự tạo đề nghị ngừng dùng trong "Việc của tôi" của An; tiếp bước 6.
- **6a. Còn subscription `ACTIVE`, `PAUSED` hoặc `SUSPENDED`.** Hệ thống tạo yêu cầu `TOPIC_RETIRE` liệt kê quan hệ sẽ bị thu hồi; Bình duyệt (LP-10-01); khi được phép, hệ thống thu hồi theo UC-10-16 nhánh 6c rồi tiếp bước 6.
- **6b. Còn mục DLQ `NEW`.** Topic vẫn `RETIRED` nhưng lịch xóa khỏi cụm hoãn tới khi mục DLQ được xử lý (BR-10-024).

**Luồng ngoại lệ**

- **E1. Đã có topic kế nhiệm (bước 1).** ERR-10-047.
- **E2. Topic kế nhiệm khai ở 1a không tồn tại hoặc khác dự án.** ERR-10-001.
- **E3. Ngừng dùng ngay khi còn phụ thuộc mà không qua duyệt (bước 6).** ERR-10-010; giao diện chuyển sang nhánh 6a.
- **E4. Trạng thái không hợp lệ (bước 6),** ví dụ ngừng khuyến nghị topic `DRAFT`. ERR-10-006.
- **E5. Lỗi lược đồ, tên, hạn mức (bước 2).** Như UC-10-02 E1…E10.

**Quy tắc áp dụng:** BR-10-003, 013, 016, 024.

### 6.6. UC-10-06 · Soạn, kiểm tra và duyệt phiên bản lược đồ

| Mục | Nội dung |
|---|---|
| Mục tiêu | Thêm trường cho sự kiện theo cách tương thích, người duyệt thấy rõ khác biệt và bên nhận bị ảnh hưởng, không ghi đè phiên bản đã dùng |
| Tác nhân chính | ROLE-INTEGRATION_ENGINEER (An) soạn; ROLE-INTEGRATION_APPROVER (Bình) duyệt |
| Tác nhân phụ | Apicurio, `dh-runtime` và PH-04 (nhận EVT-10-05) |
| Mức ưu tiên | M |
| FR hiện thực | FR-10-017, 018, 019, 020, 022 |
| Tiền điều kiện | Topic `ACTIVE` có phiên bản 1 `ENABLED`; không có phiên bản khác `PENDING_APPROVAL`; An có `PERM-10-create` |
| Điều kiện kích hoạt | An bấm "Phiên bản mới" ở UI-10-08 |
| Đảm bảo tối thiểu | Không gì được ghi vào Apicurio trước khi duyệt; bên phát hiện tại không bị ảnh hưởng |
| Đảm bảo thành công | Phiên bản 2 `ENABLED`, `latestVersionNo` = 2, EVT-10-05 phát |

**Luồng chính**

1. Hệ thống mở UI-10-08 với nội dung phiên bản 1 làm bản khởi đầu (API-10-021, API-10-022).
2. An thêm trường `diaChiTruSo` kiểu `["null","string"]`, `default: null`, có `doc`; nhập `changeNote` "Bổ sung địa chỉ trụ sở theo yêu cầu Sở Tài chính". Hệ thống gọi API-10-023, phiên bản 2 `DRAFT`.
3. An bấm "Kiểm tra". Hệ thống gọi API-10-026: cú pháp, quy ước, trường khóa, dữ liệu cá nhân (FR-10-017) và tương thích chạy thử với Apicurio (FR-10-018). Báo cáo `compatibilityReport`: đạt `BACKWARD`, một trường thêm có mặc định.
4. An xem khác biệt cấu trúc với phiên bản 1 (API-10-030) rồi bấm "Gửi duyệt". Hệ thống gọi API-10-027, chạy lại kiểm tra trên đúng băm nội dung, tạo yêu cầu `SCHEMA_VERSION` kèm danh sách bên nhận hiện có; phiên bản 2 `PENDING_APPROVAL`.
5. Bình mở yêu cầu ở UI-10-13, xem khác biệt, báo cáo tương thích và danh sách `ht-thue-dn-cap-phep`, `ht-bhxh-dn-cap-phep`; chọn "Duyệt" kèm ý kiến (LP-10-01).
6. Hệ thống tạo phiên bản ở Apicurio, phiên bản 2 `ENABLED`, cập nhật `latestVersionNo`, phát EVT-10-05. Cổng sự kiện chấp nhận bản tin theo phiên bản 1 và 2.
7. An mở tab Lịch sử phiên bản (API-10-022, API-10-024): hai phiên bản, người duyệt, ngày, `apicurioGlobalId`; tải `.avsc` và xem sự kiện ví dụ sinh từ lược đồ (giá trị giả lập).

**Luồng thay thế**

- **2a. Sửa nháp nhiều lần.** An sửa nội dung, hệ thống gọi API-10-025 trên phiên bản `DRAFT`; kết quả kiểm tra cũ hết hiệu lực khi băm đổi.
- **3a. Cảnh báo dữ liệu cá nhân ở chế độ `WARN`.** Báo cáo ghi `piiFindings` mức `WARNING`; ở bước 5 Bình phải xác nhận như UC-10-03 nhánh 2b.
- **5a. Từ chối.** Phiên bản 2 `REJECTED`, An được thông báo; An soạn phiên bản mới.
- **7a. Ngừng khuyến nghị phiên bản cũ (FR-10-022, S).** An đặt phiên bản 1 sang `DEPRECATED` (API-10-028); cổng vẫn nhận nhưng trả tiêu đề `Deprecation`; bên phát được thông báo; phát EVT-10-02.
- **7b. Vô hiệu phiên bản cũ.** An chọn "Vô hiệu" phiên bản 1 (API-10-029); hệ thống tạo yêu cầu cần IA duyệt; chỉ cho khi không còn bản tin theo phiên bản 1 trong lưu giữ (BR-10-015); khi duyệt, phiên bản 1 `DISABLED`.

**Luồng ngoại lệ**

- **E1. Đã có phiên bản khác `PENDING_APPROVAL` (bước 2).** ERR-10-006.
- **E2. Sai cú pháp (bước 3).** ERR-10-015; quay lại bước 2.
- **E3. Không tương thích, ví dụ xóa trường `tenDoanhNghiep` không mặc định (bước 4).** ERR-10-016 kèm báo cáo; hệ thống gợi ý sửa để tương thích hoặc tạo phiên bản topic mới (UC-10-05).
- **E4. Định dạng khác định dạng đã có của topic (bước 2).** ERR-10-020.
- **E5. Thiếu hoặc sai kiểu trường khóa (bước 3).** ERR-10-017.
- **E6. Dữ liệu cá nhân ở chế độ chặn (bước 3).** ERR-10-018.
- **E7. Apicurio từ chối vì có phiên bản khác vừa thêm (bước 6).** ERR-10-016, phiên bản về `DRAFT`.
- **E8. Apicurio không khả dụng (bước 3, 6).** ERR-10-029 theo LP-10-04.
- **E9. Vô hiệu khi còn bản tin dùng phiên bản, hoặc vô hiệu phiên bản mới nhất (7b).** ERR-10-006.

**Quy tắc áp dụng:** BR-10-010, 011, 012, 013, 014, 015.

### 6.7. UC-10-07 · Đăng ký bên phát và bên nhận

| Mục | Nội dung |
|---|---|
| Mục tiêu | Gắn HTTT thành viên (hoặc luồng, DU) vào trục sự kiện với kiểu giao tiếp phù hợp, chưa cấp quyền phát, nhận trên topic nào |
| Tác nhân chính | ROLE-INTEGRATION_ENGINEER (An) |
| Tác nhân phụ | PH-01 (bản sao HTTT, `clientId`), PH-04 (kiểm tra luồng), Thảo (OR) với bên nhận của tổ chức mình |
| Mức ưu tiên | M |
| FR hiện thực | FR-10-025, 026, 027 |
| Tiền điều kiện | `HT-DKKD`, `HT-THUE` `ACTIVE` ở PH-01; `HTTP_PUBLISH`, `WEBHOOK_PUSH` được bật (FR-10-060); An có `PERM-10-create` |
| Điều kiện kích hoạt | An bấm "Đăng ký bên phát" ở UI-10-09 |
| Đảm bảo tối thiểu | Bên tham gia mới không có quyền phát, nhận trên topic nào |
| Đảm bảo thành công | Bên phát `ht-dkkd` và bên nhận `ht-thue` ở `ACTIVE` |

**Luồng chính**

1. An mở UI-10-09. Hệ thống gọi API-10-032, hiện danh sách bên phát với `partyType`, đối tượng gắn kèm trạng thái ở phân hệ nguồn, `commType`, `referenceKey`, số publication theo trạng thái (FR-10-025).
2. An bấm "Đăng ký bên phát", nhập `publisherCode` `ht-dkkd`, tên "HTTT đăng ký kinh doanh", `partyType` `SYSTEM`, chọn HTTT `HT-DKKD` (ô tìm trên bản sao PH-01), `commType` `HTTP_PUBLISH`, `referenceKey` `PUB_DKKD_01`.
3. Hệ thống chỉ hiện các `commType` chiều phát hợp với `SYSTEM` theo Phụ lục A.2.8. An bấm "Lưu"; hệ thống gọi API-10-033.
4. Hệ thống tra PH-01, lấy `clientId` của `HT-DKKD`, tạo bên phát `ACTIVE`; trả `201`. UI-10-09 chi tiết (API-10-034) hiện khối "Chưa có publication" và nút "Đề nghị phát lên topic" (tiếp UC-10-09).
5. An mở UI-10-10, đăng ký bên nhận `ht-thue`, `SYSTEM`, `HT-THUE`, `commType` `WEBHOOK_PUSH` (API-10-038); hệ thống tạo bên nhận `ACTIVE` (API-10-039).

**Luồng thay thế**

- **2a. HTTT phát qua Kafka trực tiếp.** An chọn `KAFKA_NATIVE`; hệ thống kiểm tra tenant đã bật Kafka ngoài, xác định `kafkaPrincipal` `User:{clientId}` (OAUTHBEARER) hoặc `User:CN=HT-DKKD.t68` (mTLS).
- **2b. Bên phát `FLOW` hoặc `INTERNAL_SERVICE`.** An chọn luồng (`flowCode`, hệ thống tra PH-04) hoặc DU (`serviceCode` trong danh sách Phụ lục A.2.12); `kafkaPrincipal` là principal nội bộ theo tenant. Thông thường không cần tạo tay vì PH-04 tạo khi kỹ sư chọn topic (UC-10-25).
- **5a. Thảo (OR) đăng ký bên nhận cho HTTT của Sở Tài chính.** Thảo dùng `PERM-10-subscribe`; ô HTTT chỉ có HTTT của tổ chức mình.
- **5b. Bên nhận kéo.** `commType` `HTTP_PULL` cho `ht-bhxh`.

**Luồng ngoại lệ**

- **E1. Mã trùng hoặc sai mẫu (bước 3).** ERR-10-002 hoặc ERR-10-003; quay lại bước 2.
- **E2. HTTT không `ACTIVE` ở PH-01 (bước 4).** ERR-10-021; hệ thống liên kết tới hồ sơ kết nạp ở PH-01.
- **E3. Luồng không hợp lệ (2b).** ERR-10-022. **DU không có trong danh sách (2b).** ERR-10-023.
- **E4. Kafka ngoài chưa bật (2a).** ERR-10-028; hệ thống gợi ý TA đề nghị PA bật (UC-10-22).
- **E5. Tổ hợp `partyType` và `commType` không hợp lệ khi gọi thẳng API.** ERR-10-003 (BR-10-017).
- **E6. Đã có bên phát cho cặp (`HT-DKKD`, `HTTP_PUBLISH`).** ERR-10-024.
- **E7. Ngoài tổ chức (5a).** ERR-10-044.

**Quy tắc áp dụng:** BR-10-003, 017.

### 6.8. UC-10-08 · Tạm ngừng, tiếp tục và ngừng dùng bên tham gia

| Mục | Nội dung |
|---|---|
| Mục tiêu | Cắt ngay quyền phát, nhận của một HTTT có sự cố ATTT hoặc bị PH-01 tạm ngừng, khôi phục đúng trạng thái trước khi sự cố được khắc phục |
| Tác nhân chính | ROLE-SECURITY_OFFICER (Dũng); hệ thống (đồng bộ PH-01, PH-04) |
| Tác nhân phụ | OPA, Keycloak (PH-12), kho `dh-config-{tenant}`, bộ giao nhận, An (sửa, ngừng dùng) |
| Mức ưu tiên | M |
| FR hiện thực | FR-10-028, 029 |
| Tiền điều kiện | Bên phát `ht-dkkd` `ACTIVE` có publication `ACTIVE`; Dũng có `PERM-10-operate` |
| Điều kiện kích hoạt | Dũng nhận cảnh báo lộ `client_secret` của `HT-DKKD` và mở UI-10-09 chi tiết `ht-dkkd` |
| Đảm bảo tối thiểu | Mọi quan hệ bị ảnh hưởng đều được ghi kiểm toán và sự kiện, kể cả khi một bước gỡ quyền phải thử lại |
| Đảm bảo thành công | Bên phát `SUSPENDED` với `suspendSource` `SECURITY`; APISIX từ chối lượt phát mới trong ≤ 60 giây |

**Luồng chính**

1. Dũng bấm "Tạm ngừng", nhập lý do "Nghi lộ client_secret, chờ cấp lại" (LP-10-02). Hệ thống gọi API-10-036 hành động `:suspend`.
2. Hệ thống đưa `ht-dkkd` sang `SUSPENDED` (`suspendSource` `SECURITY`), mọi publication `ACTIVE` của bên này sang `SUSPENDED` theo FR-10-032: gỡ dữ liệu quyền ở OPA, gỡ scope, xóa ACL `WRITE` nếu có; phát EVT-10-07 cho từng publication.
3. HTTT gọi API phát trong lúc này nhận ERR-10-102 (UC-10-10 E2).
4. Sau khi PH-01 cấp lại client, Dũng bấm "Tiếp tục" với lý do khắc phục. Hệ thống gọi API-10-036 hành động `:resume`; bên phát về `ACTIVE`, các publication trở lại trạng thái trước khi tạm ngừng, cấp lại quyền không cần duyệt lại; phát EVT-10-07.

**Luồng thay thế**

- **1a. PH-01 tạm ngừng HTTT.** PH-10 nhận sự kiện đổi trạng thái HTTT (giả định `t68.connect.system.state-changed.v1`, Q10-17), trong ≤ 60 giây đưa mọi bên phát, bên nhận gắn `HT-DKKD` sang `SUSPENDED` với `suspendSource` `PH01`, lý do "Theo PH-01"; tiếp bước 2. Khi HTTT `ACTIVE` lại, hệ thống chỉ tiếp tục các bên do PH-01 tạm ngừng, không tiếp tục bên do SO tạm ngừng.
- **1b. PH-01 thu hồi kết nạp.** Hệ thống ngừng dùng các bên gắn HTTT như nhánh 4b.
- **1c. Luồng ngừng ở PH-04.** Nhận EVT-04-09 `t68.integration.flow.retired.v1`: thu hồi publication, subscription của bên `FLOW` tương ứng, xóa nhóm tiêu thụ sau khi luồng dừng hẳn.
- **1d. Bên nhận.** Tạm ngừng `ht-thue` (API-10-041) đưa subscription sang `SUSPENDED`, bộ giao nhận dừng, phát EVT-10-09.
- **2a. Đối chiếu bù.** Mỗi giờ hệ thống đối chiếu với bản sao PH-01 và danh sách luồng; trạng thái lệch do lỡ sự kiện được sửa theo nhánh 1a…1c.
- **4a. Sửa thông tin.** An (IE, `PERM-10-update`) sửa `name`, `description`, `referenceKey` qua API-10-035 hoặc API-10-040; mã, `partyType`, đối tượng gắn bất biến.
- **4b. Ngừng dùng.** An chọn "Ngừng dùng" với lý do; hệ thống thu hồi mọi quan hệ (FR-10-032, 047), bên sang `RETIRED`, mã không dùng lại.

**Luồng ngoại lệ**

- **E1. Thiếu lý do (bước 1, 4).** ERR-10-009.
- **E2. Dũng tiếp tục một bên do PH-01 tạm ngừng (bước 4).** ERR-10-006; SO chỉ tiếp tục bên do chính SO tạm ngừng.
- **E3. Keycloak hoặc Git không khả dụng khi gỡ quyền (bước 2).** Dữ liệu OPA vẫn được gỡ trước (đủ chặn ở APISIX); phần gỡ scope, ACL vào hàng thử lại theo LP-10-04; cảnh báo TO.
- **E4. Đổi `commType` khi sửa (4a).** ERR-10-003; hệ thống hướng dẫn đăng ký bên mới.

**Quy tắc áp dụng:** BR-10-003, 020, 036.

### 6.9. UC-10-09 · Đề nghị và duyệt publication

| Mục | Nội dung |
|---|---|
| Mục tiêu | Cho `HT-DKKD` quyền phát lên topic sau khi người duyệt kiểm tra mục đích, phân loại và hạn mức |
| Tác nhân chính | ROLE-INTEGRATION_ENGINEER (An) đề nghị; ROLE-INTEGRATION_APPROVER (Bình) duyệt |
| Tác nhân phụ | Keycloak (PH-12), OPA, kho `dh-config-{tenant}`, PH-01 (cấp độ ATTT của HTTT) |
| Mức ưu tiên | M |
| FR hiện thực | FR-10-030, 031 |
| Tiền điều kiện | Bên phát `ht-dkkd` `ACTIVE`; topic `ACTIVE`; An có `PERM-10-create`; Bình có `PERM-10-approve` |
| Điều kiện kích hoạt | An bấm "Đề nghị phát lên topic" ở UI-10-09 chi tiết `ht-dkkd` hoặc tab Publication của UI-10-06 |
| Đảm bảo tối thiểu | Không có scope, ACL nào được cấp trước khi duyệt |
| Đảm bảo thành công | Publication `pub-01jdx7…` `ACTIVE`, `grantedScope` `topic:t68.dkkd.doanh-nghiep.da-cap-phep.v1:publish`; EVT-10-06 phát; HTTT phát được trong ≤ 2 phút |

**Luồng chính**

1. An chọn topic, nhập `purpose` "Phát sự kiện cấp phép doanh nghiệp cho cơ quan thuế, BHXH", `expectedRatePerMinute` 20. Hệ thống gọi API-10-043; publication `PENDING_APPROVAL`, yêu cầu `PUBLICATION` vào "Việc của tôi" của Bình.
2. Bình mở yêu cầu ở UI-10-13 (API-10-058): bên phát, HTTT, `commType`, topic, `dataClass`, mức dùng hạn mức tenant.
3. Bình nhập ý kiến, giữ `quotaBytesPerSecond` mặc định, chọn "Duyệt" (LP-10-01). Hệ thống gọi API-10-059.
4. Theo `commType` `HTTP_PUBLISH`, hệ thống gắn scope vào client của `HT-DKKD` ở Keycloak qua API quản trị PH-12 và đẩy dữ liệu quyền (bên phát, topic) vào gói dữ liệu OPA; publication `ACTIVE`, lưu `grantedScope`, `approvedBy`, `approvedAt`; phát EVT-10-06.
5. Hệ thống thông báo An và đầu mối `HT-DKKD`, nhắc lấy token mới để có scope. UI-10-09 hiện publication `ACTIVE` (API-10-042, API-10-044).

**Luồng thay thế**

- **1a. SV đề nghị cho HTTT của tổ chức mình.** Hợp lệ trong phạm vi tổ chức; ngoài phạm vi E5.
- **1b. Publication cho bên `INTERNAL_SERVICE` trên topic của chính DU.** Tự duyệt khi `10.approval.auto-approve-internal` bật: yêu cầu `APPROVED` với người duyệt `system:auto` (BR-10-031); bỏ bước 2, 3.
- **3a. Bình giảm hạn mức.** Bình hạ `quotaBytesPerSecond`; giá trị mới được ghi khi duyệt.
- **3b. Từ chối.** Publication `REJECTED`; An được thông báo; cặp này đề nghị lại được.
- **4a. `KAFKA_NATIVE`.** Hệ thống thêm ACL `WRITE`, `DESCRIBE` literal trên topic, `IDEMPOTENT_WRITE` trên cụm, hạn mức `producerByteRate` vào `KafkaUser`, commit `kafka/users/` (LP-10-05); publication `ACTIVE` khi Strimzi báo sẵn sàng.
- **4b. `INTERNAL_KAFKA` (luồng, DU).** Chỉ ghi nhận quyền cho VR-10; không cấp scope OAuth (BR-10-018).

**Luồng ngoại lệ**

- **E1. Topic `DEPRECATED` hoặc bên phát không `ACTIVE` (bước 1, 3).** ERR-10-025.
- **E2. Đã có publication chưa `REVOKED`, `REJECTED` cho cặp này (bước 1).** ERR-10-024.
- **E3. Topic `SENSITIVE`, `RESTRICTED` mà HTTT chưa đạt cấp độ ATTT yêu cầu (bước 1).** ERR-10-025 với chi tiết "cấp độ ATTT chưa đạt" (BR-10-019).
- **E4. Bình là người đề nghị (bước 3).** ERR-10-008.
- **E5. Ngoài tổ chức (1a).** ERR-10-044.
- **E6. Vượt hạn mức (bước 3).** ERR-10-011.
- **E7. Keycloak hoặc Git không khả dụng (bước 4).** ERR-10-029; publication giữ `PENDING_APPROVAL`, yêu cầu giữ `PENDING`.

**Quy tắc áp dụng:** BR-10-010, 016, 018, 019, 020, 029, 031.

### 6.10. UC-10-10 · HTTT phát sự kiện qua API phát

| Mục | Nội dung |
|---|---|
| Mục tiêu | `HT-DKKD` phát sự kiện cấp phép doanh nghiệp một lần, được ghi bền ở ít nhất hai bản sao, đúng lược đồ và đúng tenant |
| Tác nhân chính | HTTT `HT-DKKD` |
| Tác nhân phụ | APISIX và OPA, cổng sự kiện của `dh-runtime`, Apicurio, Kafka |
| Mức ưu tiên | M |
| FR hiện thực | FR-10-033, 024, 064 |
| Tiền điều kiện | Publication `ACTIVE`; token máy của `HT-DKKD` có scope `topic:t68.dkkd.doanh-nghiep.da-cap-phep.v1:publish`; topic `ACTIVE` hoặc `DEPRECATED` |
| Điều kiện kích hoạt | Cán bộ một cửa cấp giấy chứng nhận cho doanh nghiệp mã `0312345678` trên `HT-DKKD` |
| Đảm bảo tối thiểu | Sự kiện hoặc được ghi bền, hoặc bị từ chối với mã lỗi rõ; không có trạng thái ghi một nửa |
| Đảm bảo thành công | `202` với `partition`, `offset`, `schemaVersion`; sự kiện có trên topic với khóa `0312345678` |

**Luồng chính**

1. Lập trình viên của `HT-DKKD` mở tab Cách kết nối ở UI-10-06 (API-10-020), lấy đường dẫn API phát, tải lược đồ và đoạn mã mẫu. Ứng dụng đọc lược đồ qua đường chỉ đọc API-10-084 bằng token có scope (FR-10-024).
2. `HT-DKKD` lấy token client credentials từ Keycloak, gọi API-10-079 `POST /event/v1/topics/t68.dkkd.doanh-nghiep.da-cap-phep.v1/events`, thân `application/cloudevents+json`: `specversion` 1.0, `id` `dkkd-20261126-000123`, `source` `/t68/ht-dkkd`, `type` `vn.t68.dkkd.doanh-nghiep.da-cap-phep`, `subject` `0312345678`, `data` theo lược đồ.
3. APISIX xác thực token, OPA kiểm tra scope và quan hệ bên phát với topic, áp hạn mức theo publication.
4. Cổng sự kiện xác định tenant từ tiền tố topic `t68.` (không từ nội dung), kiểm tra phong bì CloudEvents, `source` thuộc `HT-DKKD`, bổ sung `time`, `traceparent`, ghi đè `dhtenant` (BR-10-021, FR-10-064).
5. Cổng kiểm tra `data` theo phiên bản lược đồ `ENABLED` mới nhất, lấy `maDoanhNghiep` làm khóa (`KEY_HASH`), ghi Kafka với `acks=all`.
6. Cổng trả `202` với `results[]`: `id`, `partition` 4, `offset` 18233, `schemaVersion` 2. Chỉ số `dh_event_published_total` tăng.

**Luồng thay thế**

- **2a. Gửi lô.** Thân `application/cloudevents-batch+json` ≤ `10.publish.max-batch` (100) sự kiện, ≤ 1 MiB; kết quả trả theo từng sự kiện.
- **2b. Gửi lại sau mất mạng.** `HT-DKKD` gửi lại cùng `id` (hoặc cùng `Idempotency-Key`); cổng trả kết quả lần trước, không ghi trùng.
- **5a. Topic `DEPRECATED`.** Ghi bình thường, phản hồi kèm tiêu đề cảnh báo và tên topic kế nhiệm.
- **5b. Phát theo phiên bản lược đồ `DEPRECATED`.** Ghi bình thường, phản hồi có tiêu đề `Deprecation`.

**Luồng ngoại lệ**

- **E1. Token hỏng hoặc hết hạn (bước 3).** ERR-10-101.
- **E2. Thiếu scope, publication `SUSPENDED` hoặc `REVOKED` (bước 3).** ERR-10-102; có hiệu lực ngay khi OPA cập nhật, không đợi token hết hạn (BR-10-020).
- **E3. Topic không tồn tại, `RETIRED`, hoặc thuộc tenant khác, ví dụ HTTT của T68 gọi topic `t01.…` (bước 4).** ERR-10-103 (BR-10-001).
- **E4. Phong bì sai hoặc `source` không thuộc bên phát (bước 4).** ERR-10-104.
- **E5. `data` không khớp lược đồ hoặc thiếu `maDoanhNghiep` khi `orderingRequired` (bước 5).** ERR-10-105.
- **E6. Vượt kích thước (bước 2).** ERR-10-106.
- **E7. Vượt hạn mức phát (bước 3).** ERR-10-107 kèm `Retry-After`; HTTT giãn tốc độ.
- **E8. Không đủ bản sao đồng bộ (bước 5).** ERR-10-108; cổng không hạ mức xác nhận (BR-10-007); HTTT thử lại theo `Retry-After`.
- **E9. Đọc lược đồ không có scope (bước 1).** ERR-10-102.

**Quy tắc áp dụng:** BR-10-001, 006, 007, 011, 020, 021.
