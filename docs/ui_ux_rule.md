## 1. Phân tích cấu trúc giao diện hiện tại

Giao diện đang thể hiện một màn hình **quản lý danh sách phiên bản**, gồm đầy đủ các thành phần nền tảng của màn hình CRUD:

| Khu vực             | Thành phần                                                     |
| ------------------- | -------------------------------------------------------------- |
| Điều hướng          | Breadcrumb, tab chức năng, nút quay lại                        |
| Tiêu đề             | “Danh sách phiên bản”                                          |
| Thao tác chính      | Thêm mới                                                       |
| Tìm kiếm            | Tên phiên bản, nội dung, trạng thái thông báo, khoảng ngày tạo |
| Điều khiển tìm kiếm | Tìm kiếm, đặt lại, ẩn/hiện bộ lọc                              |
| Danh sách           | Bảng dữ liệu có checkbox chọn dòng                             |
| Thao tác bản ghi    | Sửa, xóa, gửi thông báo                                        |
| Thao tác hàng loạt  | Xóa các bản ghi đã chọn                                        |
| Hiển thị trạng thái | Chip “Mới/Cũ”, “Đã thông báo/Chưa thông báo”                   |
| Cá nhân hóa bảng    | Sắp xếp, cấu hình cột                                          |
| Phân trang          | Tổng số bản ghi, số dòng/trang, chọn trang, đi đến trang       |

Về bố cục, đây là khung khá chuẩn cho màn hình CRUD dạng danh sách. Tuy nhiên, để dùng làm **chuẩn chung cho toàn hệ thống**, cần đặc tả rõ hành vi, trạng thái, phân quyền và quy tắc nghiệp vụ; không chỉ mô tả phần nhìn.

---

# 2. Chuẩn yêu cầu chung cho một màn hình CRUD

## 2.1. Cấu trúc màn hình

| Mã         | Yêu cầu                                                                                        |
| ---------- | ---------------------------------------------------------------------------------------------- |
| CRUD-UI-01 | Màn hình phải có breadcrumb thể hiện đầy đủ đường dẫn chức năng.                               |
| CRUD-UI-02 | Tiêu đề màn hình phải dùng tên nghiệp vụ, ví dụ: “Danh sách phiên bản”.                        |
| CRUD-UI-03 | Nút thao tác chính như **Thêm mới** phải đặt phía trên bên phải và có màu nhấn chính.          |
| CRUD-UI-04 | Nút quay lại chỉ xuất hiện khi màn hình có màn hình cha xác định.                              |
| CRUD-UI-05 | Màn hình được chia tối thiểu thành: tiêu đề, bộ lọc, bảng dữ liệu và phân trang.               |
| CRUD-UI-06 | Các nút, biểu tượng phải có tooltip khi rê chuột.                                              |
| CRUD-UI-07 | Biểu tượng không phổ biến như đặt lại bộ lọc, cấu hình cột phải có nhãn hoặc tooltip rõ nghĩa. |

---

## 2.2. Bộ lọc và tìm kiếm

### Yêu cầu chức năng

| Mã          | Yêu cầu                                                                                                   |
| ----------- | --------------------------------------------------------------------------------------------------------- |
| CRUD-FLT-01 | Bộ lọc phải cho phép ẩn/hiện để tối ưu diện tích màn hình.                                                |
| CRUD-FLT-02 | Bộ lọc cơ bản nên hiển thị mặc định; bộ lọc nâng cao có thể thu gọn.                                      |
| CRUD-FLT-03 | Nhấn **Enter** tại trường nhập liệu phải thực hiện tìm kiếm.                                              |
| CRUD-FLT-04 | Nút **Tìm kiếm** gửi toàn bộ điều kiện lọc hiện tại lên máy chủ.                                          |
| CRUD-FLT-05 | Nút **Đặt lại** xóa toàn bộ bộ lọc và tải lại trang đầu tiên.                                             |
| CRUD-FLT-06 | Khi thay đổi bộ lọc, trang hiện tại phải được đưa về trang 1.                                             |
| CRUD-FLT-07 | Giá trị lọc nên được giữ lại khi người dùng mở bản ghi rồi quay lại danh sách.                            |
| CRUD-FLT-08 | Bộ lọc phải hỗ trợ tải dữ liệu bằng phân trang phía máy chủ, không lọc trên dữ liệu đã tải ở trình duyệt. |

### Quy tắc tìm kiếm đề xuất

| Trường                   | Quy tắc                                                                            |
| ------------------------ | ---------------------------------------------------------------------------------- |
| Tên phiên bản            | Tìm gần đúng, không phân biệt chữ hoa/chữ thường, tự loại bỏ khoảng trắng đầu cuối |
| Nội dung phiên bản       | Tìm kiếm chứa chuỗi                                                                |
| Trạng thái thông báo     | Danh sách chọn; nên hỗ trợ chọn nhiều trạng thái nếu nghiệp vụ yêu cầu             |
| Ngày tạo                 | Khoảng ngày từ ngày – đến ngày, bao gồm cả hai ngày                                |
| Khoảng ngày không hợp lệ | Không cho phép ngày bắt đầu lớn hơn ngày kết thúc                                  |
| Không nhập điều kiện     | Trả về toàn bộ dữ liệu theo phân quyền                                             |

Nên đặc tả rõ `Tên phiên bản` tìm chính xác hay tìm chứa chuỗi. Đây là điểm thường bị frontend và backend hiểu khác nhau.

---

## 2.3. Bảng dữ liệu

| Mã          | Yêu cầu                                                                                                         |
| ----------- | --------------------------------------------------------------------------------------------------------------- |
| CRUD-TBL-01 | Bảng phải có tiêu đề cột rõ ràng và thống nhất thuật ngữ nghiệp vụ.                                             |
| CRUD-TBL-02 | Dữ liệu phải được phân trang phía máy chủ.                                                                      |
| CRUD-TBL-03 | Thứ tự mặc định nên là `Ngày tạo giảm dần`.                                                                     |
| CRUD-TBL-04 | Các cột được phép sắp xếp phải có biểu tượng thể hiện chiều sắp xếp.                                            |
| CRUD-TBL-05 | Mỗi thời điểm chỉ nên có một tiêu chí sắp xếp chính, trừ khi hệ thống hỗ trợ sắp xếp đa cột.                    |
| CRUD-TBL-06 | Cột số thứ tự phải tính theo toàn bộ tập dữ liệu, không bắt đầu lại từ 1 ở mỗi trang nếu không có yêu cầu khác. |
| CRUD-TBL-07 | Nội dung dài phải cắt bằng dấu `…` và hiển thị đầy đủ bằng tooltip.                                             |
| CRUD-TBL-08 | Ngày tháng hiển thị thống nhất theo định dạng `DD/MM/YYYY`.                                                     |
| CRUD-TBL-09 | Trạng thái phải dùng chip màu kèm chữ, không chỉ dùng màu.                                                      |
| CRUD-TBL-10 | Tiêu đề bảng nên cố định khi cuộn với danh sách dài.                                                            |
| CRUD-TBL-11 | Cột thao tác nên cố định bên phải khi bảng có cuộn ngang.                                                       |
| CRUD-TBL-12 | Khi không có dữ liệu phải hiển thị trạng thái rỗng, không để bảng trắng.                                        |

### Chuẩn căn chỉnh

| Loại dữ liệu  | Căn chỉnh                         |
| ------------- | --------------------------------- |
| STT, số lượng | Căn phải hoặc căn giữa            |
| Checkbox      | Căn giữa                          |
| Nội dung chữ  | Căn trái                          |
| Ngày tháng    | Căn giữa hoặc căn trái thống nhất |
| Trạng thái    | Căn giữa hoặc căn trái thống nhất |
| Thao tác      | Căn giữa                          |

---

## 2.4. Chọn bản ghi và thao tác hàng loạt

| Mã          | Yêu cầu                                                                                          |
| ----------- | ------------------------------------------------------------------------------------------------ |
| CRUD-SEL-01 | Checkbox tại tiêu đề cho phép chọn toàn bộ bản ghi trên trang hiện tại.                          |
| CRUD-SEL-02 | Checkbox tiêu đề phải có ba trạng thái: chưa chọn, chọn một phần và chọn toàn bộ.                |
| CRUD-SEL-03 | Thanh thao tác hàng loạt chỉ xuất hiện khi có ít nhất một bản ghi được chọn.                     |
| CRUD-SEL-04 | Thanh thao tác phải hiển thị chính xác số bản ghi đã chọn.                                       |
| CRUD-SEL-05 | Dòng được chọn phải có màu nền hoặc trạng thái trực quan rõ ràng.                                |
| CRUD-SEL-06 | Phải quy định rõ việc chọn bản ghi có được giữ lại khi đổi trang hay không.                      |
| CRUD-SEL-07 | Không cho phép thao tác hàng loạt trên các bản ghi mà người dùng không có quyền.                 |
| CRUD-SEL-08 | Nếu một số bản ghi không đủ điều kiện xử lý, hệ thống phải chỉ rõ bản ghi nào thất bại và lý do. |

Khuyến nghị mặc định: lựa chọn bị xóa khi người dùng thay đổi bộ lọc; lựa chọn có thể được giữ khi chuyển trang nếu hệ thống hỗ trợ chọn nhiều trang.

---

# 3. Chuẩn thao tác CRUD

## 3.1. Create – Thêm mới

Khi nhấn **Thêm mới**, hệ thống mở trang hoặc hộp thoại tạo mới.

### Yêu cầu biểu mẫu

| Mã        | Yêu cầu                                                                                |
| --------- | -------------------------------------------------------------------------------------- |
| CRUD-C-01 | Các trường bắt buộc phải có ký hiệu `*`.                                               |
| CRUD-C-02 | Hiển thị độ dài tối đa đối với trường nội dung dài.                                    |
| CRUD-C-03 | Kiểm tra dữ liệu tại frontend và kiểm tra lại tại backend.                             |
| CRUD-C-04 | Không cho gửi biểu mẫu nhiều lần khi người dùng nhấn liên tục.                         |
| CRUD-C-05 | Trong thời gian xử lý, nút lưu phải chuyển sang trạng thái loading và bị khóa.         |
| CRUD-C-06 | Khi thành công, hiển thị thông báo và quay lại danh sách hoặc trang chi tiết.          |
| CRUD-C-07 | Khi quay lại danh sách, phải giữ nguyên bộ lọc trước đó nếu có.                        |
| CRUD-C-08 | Nếu tên phiên bản không được trùng, backend phải kiểm tra và trả lỗi xung đột rõ ràng. |

### Ví dụ quy tắc dữ liệu

| Trường               | Quy tắc đề xuất                                     |
| -------------------- | --------------------------------------------------- |
| Tên phiên bản        | Bắt buộc, tối đa 100 ký tự                          |
| Nội dung phiên bản   | Bắt buộc, tối đa 2.000 hoặc 5.000 ký tự             |
| Trạng thái phiên bản | Hệ thống tự xác định nếu đây là phiên bản hiện hành |
| Trạng thái thông báo | Mặc định “Chưa thông báo”                           |
| Người tạo            | Lấy từ tài khoản đăng nhập                          |
| Ngày tạo             | Lấy theo thời gian máy chủ                          |

---

## 3.2. Read – Xem danh sách và chi tiết

| Mã        | Yêu cầu                                                                               |
| --------- | ------------------------------------------------------------------------------------- |
| CRUD-R-01 | Người dùng có thể xem danh sách theo phân quyền dữ liệu.                              |
| CRUD-R-02 | Nhấn vào tên bản ghi hoặc hành động “Xem” phải mở chi tiết bản ghi.                   |
| CRUD-R-03 | Trang chi tiết phải hiển thị cả thông tin nghiệp vụ và thông tin hệ thống.            |
| CRUD-R-04 | Thông tin hệ thống gồm tối thiểu: người tạo, ngày tạo, người cập nhật, ngày cập nhật. |
| CRUD-R-05 | Trường không có dữ liệu hiển thị `—`, không để trống gây hiểu nhầm.                   |

Giao diện hiện tại chưa thể hiện rõ thao tác **Xem chi tiết**. Nên cho phép nhấn vào tên phiên bản hoặc bổ sung biểu tượng xem.

---

## 3.3. Update – Cập nhật

| Mã        | Yêu cầu                                                                                |
| --------- | -------------------------------------------------------------------------------------- |
| CRUD-U-01 | Nút sửa chỉ hiển thị khi người dùng có quyền và bản ghi ở trạng thái cho phép sửa.     |
| CRUD-U-02 | Biểu mẫu sửa phải tải đúng dữ liệu mới nhất từ máy chủ.                                |
| CRUD-U-03 | Các trường không được chỉnh sửa phải ở trạng thái chỉ đọc, không chỉ bị ẩn.            |
| CRUD-U-04 | Khi rời trang mà chưa lưu, hệ thống phải cảnh báo dữ liệu chưa được lưu.               |
| CRUD-U-05 | Phải xử lý trường hợp bản ghi đã bị người khác cập nhật trong lúc người dùng đang sửa. |
| CRUD-U-06 | Sau khi cập nhật, hệ thống ghi nhận người cập nhật và thời gian cập nhật.              |

Nên sử dụng `version`, `updatedAt` hoặc cơ chế optimistic locking để tránh người sau ghi đè dữ liệu của người trước.

---

## 3.4. Delete – Xóa

| Mã        | Yêu cầu                                                                                          |
| --------- | ------------------------------------------------------------------------------------------------ |
| CRUD-D-01 | Xóa phải có hộp thoại xác nhận.                                                                  |
| CRUD-D-02 | Hộp thoại phải hiển thị tên bản ghi hoặc số lượng bản ghi bị xóa.                                |
| CRUD-D-03 | Nút xác nhận xóa phải dùng màu cảnh báo.                                                         |
| CRUD-D-04 | Phải quy định rõ xóa mềm hay xóa vật lý.                                                         |
| CRUD-D-05 | Không cho phép xóa bản ghi đang được dữ liệu khác tham chiếu, trừ khi có cơ chế xử lý liên quan. |
| CRUD-D-06 | Khi không thể xóa, thông báo phải nêu rõ nguyên nhân.                                            |
| CRUD-D-07 | Sau khi xóa thành công, tải lại trang hiện tại và giữ nguyên điều kiện lọc.                      |
| CRUD-D-08 | Nếu xóa bản ghi cuối cùng của trang, tự chuyển về trang trước đó.                                |
| CRUD-D-09 | Xóa hàng loạt phải trả kết quả cho từng bản ghi khi có thành công một phần.                      |

Ví dụ nội dung xác nhận:

> Bạn có chắc chắn muốn xóa phiên bản “MB01” không? Thao tác này không thể hoàn tác.

---

# 4. Chuẩn cho thao tác nghiệp vụ ngoài CRUD

Trong giao diện có biểu tượng hình máy bay giấy, nhiều khả năng là thao tác **gửi thông báo**. Đây là một **nghiệp vụ riêng**, không nên gộp vào cập nhật CRUD thông thường.

| Mã          | Yêu cầu                                                                                                 |
| ----------- | ------------------------------------------------------------------------------------------------------- |
| CRUD-ACT-01 | Mỗi thao tác nghiệp vụ phải có tên và tooltip rõ ràng.                                                  |
| CRUD-ACT-02 | Chỉ hiển thị thao tác khi bản ghi đáp ứng điều kiện nghiệp vụ.                                          |
| CRUD-ACT-03 | Trước khi gửi thông báo phải có bước xác nhận.                                                          |
| CRUD-ACT-04 | Trong thời gian xử lý phải khóa thao tác để tránh gửi trùng.                                            |
| CRUD-ACT-05 | Hệ thống phải bảo đảm tính idempotent hoặc phát hiện yêu cầu gửi lặp.                                   |
| CRUD-ACT-06 | Sau khi gửi thành công, cập nhật trạng thái thành “Đã thông báo”.                                       |
| CRUD-ACT-07 | Phải lưu người gửi, thời gian gửi, kênh gửi và kết quả gửi.                                             |
| CRUD-ACT-08 | Nếu được phép gửi lại, thao tác phải mang tên “Gửi lại thông báo”, không dùng lại nhãn “Gửi thông báo”. |

---

# 5. Trạng thái màn hình bắt buộc

Một màn hình CRUD hoàn chỉnh phải có ít nhất các trạng thái sau:

| Trạng thái                | Yêu cầu hiển thị                                                     |
| ------------------------- | -------------------------------------------------------------------- |
| Đang tải                  | Skeleton hoặc loading tại khu vực bảng                               |
| Chưa có dữ liệu           | Minh họa hoặc thông báo “Chưa có dữ liệu”; có thể kèm nút Thêm mới   |
| Không có kết quả tìm kiếm | “Không tìm thấy dữ liệu phù hợp”; có nút đặt lại bộ lọc              |
| Lỗi tải dữ liệu           | Thông báo lỗi và nút thử lại                                         |
| Đang lưu                  | Khóa nút lưu và hiển thị loading                                     |
| Lưu thành công            | Toast thông báo thành công                                           |
| Lỗi nghiệp vụ             | Hiển thị thông báo dễ hiểu, không đưa mã lỗi kỹ thuật cho người dùng |
| Mất kết nối               | Thông báo kết nối và cho phép thử lại                                |
| Không có quyền            | Hiển thị trang hoặc thông báo 403 phù hợp                            |
| Bản ghi không còn tồn tại | Thông báo dữ liệu đã bị xóa hoặc thay đổi                            |

---

# 6. Phân quyền

Nên phân quyền theo từng hành động, không chỉ phân quyền vào màn hình:

| Quyền                    | Mô tả                             |
| ------------------------ | --------------------------------- |
| `VERSION_VIEW`           | Xem danh sách và chi tiết         |
| `VERSION_CREATE`         | Thêm phiên bản                    |
| `VERSION_UPDATE`         | Chỉnh sửa phiên bản               |
| `VERSION_DELETE`         | Xóa một bản ghi                   |
| `VERSION_DELETE_BULK`    | Xóa hàng loạt                     |
| `VERSION_NOTIFY`         | Gửi thông báo                     |
| `VERSION_NOTIFY_AGAIN`   | Gửi lại thông báo                 |
| `VERSION_EXPORT`         | Xuất dữ liệu nếu có               |
| `VERSION_CONFIG_COLUMNS` | Cấu hình cột nếu hệ thống yêu cầu |

Frontend ẩn hoặc khóa thao tác để đảm bảo trải nghiệm, nhưng backend vẫn phải kiểm tra quyền trên mọi API.

---

# 7. Quy tắc nghiệp vụ riêng cho phiên bản

Giao diện đang có trạng thái “Mới” và “Cũ”, vì vậy cần làm rõ tối thiểu các quy tắc sau:

1. Một ứng dụng có được phép tồn tại nhiều phiên bản “Mới” cùng lúc không?
2. Khi tạo phiên bản mới, phiên bản hiện tại có tự động chuyển thành “Cũ” không?
3. Có cho phép sửa phiên bản đã gửi thông báo không?
4. Có cho phép xóa phiên bản “Mới” không?
5. Có cho phép xóa phiên bản đã thông báo không?
6. Phiên bản cũ có được phép gửi lại thông báo không?
7. Trạng thái phiên bản được người dùng chọn hay hệ thống tự cập nhật?
8. Việc chuyển “Mới” thành “Cũ” phải thực hiện trong cùng một transaction hay không?

Khuyến nghị: tại một thời điểm chỉ có một phiên bản hiện hành. Khi tạo phiên bản mới, việc đánh dấu phiên bản trước thành “Cũ” và phiên bản mới thành “Mới” phải được thực hiện nguyên tử trong cùng transaction.

---

# 8. Phân trang và số lượng dữ liệu

| Mã          | Yêu cầu                                                                       |
| ----------- | ----------------------------------------------------------------------------- |
| CRUD-PAG-01 | Hiển thị tổng số bản ghi sau khi áp dụng bộ lọc.                              |
| CRUD-PAG-02 | Cho phép chọn số dòng mỗi trang, ví dụ 10, 20, 50, 100.                       |
| CRUD-PAG-03 | Trang hiện tại phải được làm nổi bật.                                         |
| CRUD-PAG-04 | Nút trước/sau bị khóa ở trang đầu hoặc trang cuối.                            |
| CRUD-PAG-05 | Cho phép nhập số trang để di chuyển nhanh khi có nhiều trang.                 |
| CRUD-PAG-06 | Tổng số trang phải được tính theo công thức `ceil(totalElements / pageSize)`. |
| CRUD-PAG-07 | Không cho nhập số trang nhỏ hơn 1 hoặc lớn hơn tổng số trang.                 |

Trong ảnh đang hiển thị **1.000 bản ghi**, lựa chọn **100 bản ghi/trang** nhưng lại có tới **50 trang**. Các con số này không khớp nhau: 1.000 bản ghi với 100 bản ghi/trang chỉ có 10 trang. Chuẩn giao diện phải bảo đảm ba giá trị này luôn đồng nhất.

---

# 9. Chuẩn API đề xuất

## API lấy danh sách

```http
GET /api/v1/versions
    ?name=MB01
    &content=
    &notificationStatus=NOT_SENT
    &createdFrom=2026-09-01
    &createdTo=2026-09-30
    &page=0
    &size=100
    &sort=createdAt,desc
```

Phản hồi:

```json
{
  "items": [
    {
      "id": "123",
      "name": "MB01",
      "content": "MB01",
      "createdBy": "antt28",
      "createdAt": "2026-09-02T10:30:00+07:00",
      "versionStatus": "CURRENT",
      "notificationStatus": "SENT",
      "allowedActions": [
        "VIEW",
        "EDIT"
      ]
    }
  ],
  "page": 0,
  "size": 100,
  "totalElements": 1000,
  "totalPages": 10
}
```

Trường `allowedActions` giúp frontend hiển thị đúng các hành động theo cả quyền người dùng và trạng thái nghiệp vụ, tránh tự suy diễn bằng các điều kiện rải rác.

## Các API CRUD

```http
POST   /api/v1/versions
GET    /api/v1/versions/{id}
PUT    /api/v1/versions/{id}
DELETE /api/v1/versions/{id}
POST   /api/v1/versions/bulk-delete
POST   /api/v1/versions/{id}/notifications
```

Thao tác gửi thông báo nên là API nghiệp vụ riêng, không sử dụng `PUT /versions/{id}` để thay đổi trạng thái một cách gián tiếp.

---

# 10. Yêu cầu phi chức năng

| Nhóm         | Yêu cầu                                                                                                   |
| ------------ | --------------------------------------------------------------------------------------------------------- |
| Hiệu năng    | Danh sách tải trong khoảng 2 giây ở điều kiện vận hành bình thường                                        |
| Phân trang   | Xử lý phía máy chủ; không tải toàn bộ dữ liệu về trình duyệt                                              |
| Bảo mật      | Kiểm tra phân quyền tại backend; chống IDOR                                                               |
| Audit        | Ghi log tạo, sửa, xóa, gửi thông báo                                                                      |
| Truy cập     | Có thể sử dụng bằng bàn phím; có focus rõ ràng                                                            |
| Màu sắc      | Không dùng màu làm phương tiện duy nhất để thể hiện trạng thái                                            |
| Responsive   | Hỗ trợ tối thiểu độ phân giải desktop 1366×768; màn hình nhỏ sử dụng cuộn ngang hoặc chuyển sang dạng thẻ |
| Đồng thời    | Có cơ chế phát hiện cập nhật xung đột                                                                     |
| Dữ liệu      | Không tin dữ liệu từ frontend; backend kiểm tra lại toàn bộ                                               |
| Xuất dữ liệu | Nếu có chức năng xuất, phải áp dụng đúng bộ lọc và phân quyền hiện tại                                    |

---

# 11. Các điểm cần cải thiện trực tiếp trên giao diện mẫu

1. **Bổ sung thao tác xem chi tiết** hoặc cho phép nhấn vào tên phiên bản.
2. Dòng đã chọn cần có màu nền để người dùng nhận biết.
3. Các biểu tượng sửa, xóa, gửi thông báo phải có tooltip.
4. Cần giải thích vì sao một số dòng có thao tác, một số dòng không có; tốt nhất backend trả về `allowedActions`.
5. Biểu tượng đặt lại bộ lọc nên kèm tooltip “Đặt lại”.
6. Hai biểu tượng sắp xếp và cấu hình cột cần có tooltip và trạng thái đang áp dụng.
7. Cần sửa sự không nhất quán giữa tổng bản ghi, số dòng/trang và tổng số trang.
8. Cần bổ sung trạng thái loading, không có dữ liệu, không tìm thấy và lỗi tải dữ liệu.
9. Nội dung dài cần có tooltip hoặc cơ chế mở rộng.
10. Nên bổ sung thông tin `Ngày cập nhật` nếu phiên bản có thể chỉnh sửa.
11. Cần xác định rõ hành vi khi nhấn vào cả dòng, tránh xung đột với checkbox và các nút thao tác.
12. Thanh “Bạn đã chọn…” chỉ nên xuất hiện khi thực sự có bản ghi được chọn.

---

## 12. Bộ tiêu chí nghiệm thu tối thiểu

Một màn hình CRUD được coi là hoàn thành khi đáp ứng đủ:

* Tìm kiếm, lọc, đặt lại và phân trang hoạt động đúng.
* Có đầy đủ thêm, xem, sửa, xóa theo phân quyền.
* Có xác nhận đối với các thao tác nguy hiểm.
* Có loading, empty, no-result và error state.
* Giữ được bộ lọc khi quay lại danh sách.
* Không gửi trùng yêu cầu khi người dùng nhấn nhiều lần.
* Xử lý được lỗi xung đột và dữ liệu đã bị thay đổi.
* Tổng bản ghi, số dòng/trang và tổng số trang luôn khớp.
* Các thao tác hiển thị đúng theo quyền và trạng thái bản ghi.
* Có audit log cho các thao tác thay đổi dữ liệu.
* Backend kiểm tra lại quyền và điều kiện nghiệp vụ.
* Giao diện sử dụng được bằng bàn phím và không phụ thuộc hoàn toàn vào màu sắc.
