---
ma_tai_lieu: D00-04-K
ten: Khuôn rỗng cho bảy tập tài liệu phân hệ
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Người viết tài liệu phân hệ
---

# D00-04-K · Khuôn rỗng cho bảy tập tài liệu phân hệ

Mỗi phân hệ có bảy tập. Thay vì nạp nguyên bộ PH-07 (khoảng 1,4 MB) làm mẫu, người viết chép khuôn tương ứng dưới đây, điền theo thứ tự mục, và chỉ mở tập PH-07 hoặc PH-04 ở đúng mục khi ví dụ ngắn trong khuôn chưa đủ. Mỗi khuôn gồm: metadata, các mục bắt buộc theo dàn ý đã duyệt (đánh dấu **[BB]**), một ví dụ ngắn rút từ PH-07 hoặc PH-04, và danh sách tự soát trước khi commit.

| Khuôn | Tập | Mẫu đầy đủ khi cần xem thêm |
|---|---|---|
| [K-TRINH-BAY](K-TRINH-BAY.md) | Mọi tập: metadata bìa, chú thích bảng và hình, văn phong, khối đặc tả `::: dac-ta`, mức sàn | `02-yeu-cau/frs/D02-03-PH05-frs-bo-dieu-hop.md` bản 0.2 |
| [K-FRS](K-FRS.md) | D02-03 Đặc tả yêu cầu chức năng | `02-yeu-cau/frs/D02-03-PH05-frs-bo-dieu-hop.md` bản 0.2 §1–§6.3 |
| [K-UC](K-UC.md) | D02-04 Đặc tả use case | `02-yeu-cau/use-case/D02-04-PH07-use-case-danh-muc.md` §6.3 |
| [K-SDD](K-SDD.md) | D03-02 Thiết kế chi tiết | `03-thiet-ke/sdd/D03-02-PH07-sdd-danh-muc.md` |
| [K-CSDL](K-CSDL.md) | D03-03 Thiết kế CSDL | `03-thiet-ke/csdl/D03-03-PH04-csdl-tich-hop.md` §3 |
| [K-API](K-API.md) | D03-04 Đặc tả API và sự kiện | `03-thiet-ke/api/D03-04-PH04-api-tich-hop.md` §3, §6 |
| [K-MH](K-MH.md) | D03-06 Thiết kế giao diện màn hình | `03-thiet-ke/uiux/D03-06-PH04-man-hinh-tich-hop.md` §7, §10 |
| [K-TC](K-TC.md) | D05-02 Kịch bản và test case | `05-kiem-thu/test-case/D05-02-PH04-test-case.md` |
| [K-GOI-DAC-TA](K-GOI-DAC-TA.md) | Gói đặc tả máy đọc cho tác nhân viết mã (sinh từ bảy tập) | `datahub/spec/PH07/` (lát cắt F-07-010) |

## Cách làm một phân hệ theo cách mới

1. Đọc [D00-04](../D00-04-so-tra-cuu-gon.md) để biết mã kế tiếp, quy ước, quyết định đã chốt. Đọc phần kiểm kê `LGC` của khối hệ cũ liên quan trong D00-03 (chỉ các hàng của phân hệ).
2. Mỗi tập một phiên ngắn: chép khuôn, điền, ghi và commit theo chương (không nối từng đoạn nhỏ).
3. Thứ tự: FRS → UC → SDD → CSDL → API → màn hình → test case. Tập sau đọc bảng tổng hợp của tập trước (danh sách FR, UC, API, UI), không đọc lại toàn văn.
4. Trước mỗi commit chạy `python3 datahub-docs/build/tools/kiem_tra_ma.py`; sửa hết lỗi mới.
5. Cuối phân hệ: một lượt soát chéo bằng subagent Sonnet. Sửa chéo tài liệu cũ (đổi tên token, route, quyền ở D02-08…) gom vào đợt đồng bộ cuối, ghi vào mục "Đề nghị đồng bộ" của tập.

## Mục chung cho mọi tập

Từ 26/11/2026 mọi tập theo thêm [K-TRINH-BAY](K-TRINH-BAY.md): chương Giới thiệu đầy đủ, bảng danh sách trước phần chi tiết, khối đặc tả hai cột cho từng phần tử, chú thích cho mọi bảng và hình, kiểm tra bản xuất bằng `DH_PDF=1 build/build-docx.sh`.


Mọi tập mở bằng khối metadata sáu trường và trường `phan_he`, tiêu đề cấp 1 `# D0x-0y-PH{nn} · {tên}`, rồi mục **Tóm tắt cho hội đồng thẩm định** (mục tiêu, phạm vi, căn cứ pháp lý, con số chính). Mọi tập kết thúc bằng **Câu hỏi mở** (mã `Q{nn}-..` theo dải ở D00-04 §3.1) và **Lịch sử phiên bản**. Không còn "TBD" ngoài danh sách câu hỏi mở; thiếu số liệu thật thì dùng giả định có ghi "giả định" kèm cơ sở.
