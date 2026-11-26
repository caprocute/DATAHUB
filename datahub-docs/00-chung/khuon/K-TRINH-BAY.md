---
ma_tai_lieu: D00-04-KTB
ten: Quy chuẩn trình bày và mức chi tiết cho mọi tài liệu datahub-docs
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Dự thảo chờ duyệt
nguoi_doc: Người viết tài liệu phân hệ
---

# D00-04-KTB · Quy chuẩn trình bày và mức chi tiết

Quy chuẩn này áp dụng cho mọi tài liệu của bộ datahub-docs, cùng với khuôn riêng của từng loại tập (K-FRS, K-UC, K-SDD, K-CSDL, K-API, K-MH, K-TC). Mục tiêu: bản .docx xuất ra đọc như một hồ sơ thiết kế chuẩn của ngành CNTT (bìa, thông tin tài liệu, mục lục, bảng và hình có đánh số, đặc tả chức năng dạng bảng), và nội dung đủ sâu để hội đồng thẩm định, kỹ sư, kiểm thử viên dùng ngay. Mẫu đối chiếu: "Thiết kế các hệ thống dùng chung, Quyển 1. Thuyết minh kiến trúc và đặc tả chức năng" do henry cung cấp ngày 26/11/2026. Tài liệu viết thử theo quy chuẩn: D02-03-PH05 bản 0.2.

## 1. Metadata và phần đầu tài liệu

Bìa, trang "Thông tin tài liệu" (lịch sử phiên bản, ký duyệt, phân phối) và mục lục được bộ xuất (`build/build-docx.sh`) dựng tự động. Người viết chỉ khai metadata:

```yaml
---
ma_tai_lieu: D02-03-PH05
ten: Đặc tả yêu cầu chức năng phân hệ PH-05 Bộ điều hợp và kết nối
phien_ban: 0.2
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Hội đồng thẩm định, kỹ sư, kiểm thử viên
phan_he: PH-05
mo_ta: Một câu nói tài liệu đặc tả gì và dùng làm gì (in ở bìa).
tai_lieu_lien_quan: D02-02 SRS; D03-02-PH05; D03-04-PH05
# tùy chọn: co_quan, du_an, don_vi_soan_thao, ky_duyet: [{vai_tro, ho_ten, chuc_vu}]
---
```

Mục `## Lịch sử phiên bản` (bảng Phiên bản | Ngày | Người | Nội dung) vẫn để cuối nguồn; bộ xuất chuyển nó lên trang thông tin tài liệu. Tiêu đề cấp 1 của nguồn không in lại (đã ở bìa); `##` thành chương, `###` thành mục, `####` thành tiểu mục và đều vào mục lục.

## 2. Bảng và hình

| Quy tắc | Cách viết trong Markdown |
|---|---|
| Mọi bảng dữ liệu có chú thích "Bảng n. …" | Dòng `: Tên bảng` ngay sau bảng. Thiếu dòng này thì bộ xuất lấy tên mục chứa bảng; chỉ chấp nhận khi mục có một bảng |
| Mọi sơ đồ có chú thích "Hình n. …" | Khối ` ```{.mermaid caption="Tên hình"} ` |
| Ảnh màn hình, hi-fi | `![Tên hình](đường/dẫn.png)`; ảnh rộng tối đa 16 cm |
| Bảng đặc tả hai cột (chức năng, màn hình, API, ca kiểm thử) | Khối `::: dac-ta` (mục 4) hoặc bảng có tiêu đề cột đúng "Trường \| Nội dung" |
| Không dán sơ đồ dạng chữ ASCII khi có thể vẽ Mermaid | Wireframe dạng chữ chỉ dùng ở K-MH, kèm ảnh hi-fi |

Sơ đồ ngang (`flowchart LR`) chỉ dùng khi có ít hơn sáu nút; nhiều nút hơn dùng `flowchart TB` để chữ không quá nhỏ trên trang A4. Mỗi hình có một đoạn thuyết minh ngay sau, nói người đọc cần thấy gì ở hình.

## 3. Văn phong

1. Mỗi chương, mỗi mục lớn mở bằng một hoặc hai đoạn văn xuôi nói mục đích và ý chính trước khi vào bảng. Không để một mục chỉ có bảng.
2. Viết cho người đọc ở chương: chương tổng quan viết cho hội đồng thẩm định (vì sao, lợi ích, rủi ro), chương đặc tả viết cho kỹ sư và kiểm thử viên (bước, điều kiện, mã lỗi).
3. Câu đầy đủ chủ vị. Trong luồng xử lý, chủ ngữ là tác nhân hoặc "Hệ thống"; mỗi bước một hành động kiểm chứng được.
4. Thuật ngữ tiếng Anh lần đầu xuất hiện có giải thích tiếng Việt; tên trường, mã, đường dẫn để trong dấu `` ` ``.
5. Số liệu có đơn vị và điều kiện đo; thiếu số thật thì ghi "giả định" kèm cơ sở (không hỏi người dùng).
6. Không dồn một chức năng thành một đoạn văn dài; mọi chức năng dùng khối đặc tả đầy đủ (mục 4).

## 4. Khối đặc tả chức năng

Mỗi FR viết bằng khối `::: dac-ta`. Mỗi mục là một đoạn bắt đầu bằng nhãn in đậm kết thúc bằng dấu chấm; nội dung của mục có thể là câu, danh sách đánh số hoặc gạch đầu dòng. Bộ xuất dựng thành bảng hai cột, cột nhãn tô nền.

```markdown
#### FR-05-004 · Tạo kết nối nguồn

::: dac-ta
**Mục đích.** Chức năng giúp ai làm được gì, vì sao cần (1–3 câu).

**Tác nhân.** IE, TA (`PERM-05-connection`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-05; LGC-BUS-011.

**Điều kiện trước.** HTTT `ACTIVE` ở PH-01; loại kết nối được bật.

**Kích hoạt.** Người dùng bấm "+ Tạo kết nối" ở UI-05-01.

**Luồng xử lý chính.**

1. Người dùng … rồi bấm "Tiếp tục".
2. Hệ thống kiểm tra …
3. Hệ thống tạo … ở trạng thái `DRAFT`, ghi kiểm toán.

**Luồng thay thế.** Nhánh hợp lệ khác, hoặc "Không".

**Luồng ngoại lệ.**

- Mã đã dùng: ERR-05-002 (409); "Mã {mã} đã được dùng. Chọn mã khác."

**Quy tắc nghiệp vụ.** BR-05-001; BR-05-004.

**Kết quả.** Điều người dùng nhận được, nói theo góc nhìn người dùng.

**Hậu điều kiện.** Trạng thái dữ liệu sau khi xong.

**Sự kiện, kiểm toán.** EVT-…; dữ liệu ghi kiểm toán.

**Màn hình, API.** UI-05-03 bước 1–2; API-05-004.
:::

| Trường | Kiểu | Bắt buộc | Ràng buộc | Ví dụ |
|---|---|---|---|---|
| `connectionCode` | T-CODE | Có | `^[a-z][a-z0-9-]{2,62}$` | `qlvb-soap` |

: Dữ liệu vào của FR-05-004
```

**Mức sàn cho mọi FR (kể cả mức S, C):** đủ 14 mục; luồng chính tối thiểu 3 bước; luồng ngoại lệ nêu mã lỗi, mã HTTP và **câu thông báo người dùng nhìn thấy** trong ngoặc kép (lấy từ bảng thông báo của tập màn hình hoặc viết mới rồi ghi vào đề nghị đồng bộ); mục không áp dụng ghi "Không". FR có từ năm trường nhập trở lên có bảng "Dữ liệu vào". FR có trao đổi giữa từ ba thành phần trở lên, hoặc có duyệt bốn mắt, có sơ đồ trình tự Mermaid.

## 5. Phần bắt buộc theo loại tập

Ngoài các mục [BB] trong khuôn riêng, mỗi tập phân hệ có:

| Phần | FRS | UC | SDD | CSDL | API | MH | TC |
|---|---|---|---|---|---|---|---|
| Giới thiệu: mục đích, phạm vi, người đọc, thuật ngữ và viết tắt, tài liệu tham chiếu, cấu trúc tài liệu | ● | ● | ● | ● | ● | ● | ● |
| Mục tiêu đo được của phân hệ | ● | | | | | | |
| Kiến trúc thành phần, sơ đồ trình tự luồng chính | ● | | ● | | ● | | |
| Bảng danh sách (chức năng, use case, bảng, API, màn hình, ca kiểm thử) trước phần chi tiết | ● | ● | ● | ● | ● | ● | ● |
| Khối đặc tả hai cột cho từng phần tử | FR | UC | Thành phần | Bảng | Endpoint | Màn hình | Ca |
| Thông báo hiển thị theo mã lỗi | ● | | | | ● | ● | |
| Giao diện tiêu biểu (ảnh hi-fi có chú thích, thuyết minh) | 2 màn | | | | | mọi màn | |
| ERD dạng hình | | | | ● | | | |

## 6. Tự soát trước khi xuất

- [ ] Metadata đủ trường bắt buộc; có `mo_ta`.
- [ ] Mọi bảng có dòng `: chú thích` (hoặc là bảng đặc tả); mọi khối Mermaid có `caption`.
- [ ] Mọi FR (UC, endpoint, màn hình) dùng khối đặc tả đủ mục; không còn FR viết thành một đoạn văn.
- [ ] `python3 build/tools/kiem_tra_ma.py` sạch lỗi mới.
- [ ] `DH_PDF=1 build/build-docx.sh <tệp>` chạy không cảnh báo "Không vẽ được sơ đồ"; mở PDF xem bìa, mục lục, vài trang đặc tả.
