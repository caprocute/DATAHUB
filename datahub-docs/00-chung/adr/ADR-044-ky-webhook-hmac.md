---
ma_tai_lieu: ADR-044
ten: Ký webhook HMAC-SHA256 kiểu t=,v1= và xoay bí mật có chuyển tiếp
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, trưởng nhóm PH-19, nhóm ATTT, Hội đồng thẩm định
---

# ADR-044 · Ký webhook HMAC-SHA256 kiểu t=,v1= và xoay bí mật có chuyển tiếp

## Bối cảnh

Đối tác phải tin được thông báo kết quả mà Datahub gửi, và phải chống được phát lại. Hệ cũ gửi kết quả không ký. Đối tác là HTTT của sở, ngành với năng lực kỹ thuật khác nhau, nên cơ chế phải dễ hiện thực bằng thư viện chuẩn của mọi ngôn ngữ.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Không ký, dựa vào TLS và allowlist IP | Đơn giản | Không chống giả mạo trong mạng nội bộ; không chống phát lại |
| B. **HMAC-SHA256 trên `{id}.{t}.{body}`, tiêu đề `X-Datahub-Signature: t=…,v1=…`, bí mật ≥ 256 bit riêng mỗi đầu nhận** | Phổ biến, thư viện sẵn ở mọi ngôn ngữ; có dấu thời gian chống phát lại; xoay được | Bí mật đối xứng phải giao an toàn cho đối tác |
| C. Chữ ký số bất đối xứng (JWS) | Không phải chia sẻ bí mật | Khó hơn cho đối tác nhỏ; phải quản lý khóa công khai, thu hồi |

## Quyết định

Chọn **phương án B**. Thân là CloudEvents JSON; tiêu đề `Webhook-Id`, `Webhook-Timestamp`, `X-Datahub-Signature`. Khi xoay, hai giá trị `v1` cùng có trong tiêu đề trong 7 ngày (NFR-19-021). Bí mật chỉ nằm trong OpenBao (`kv/dh/{tenant}/payment/partners/{partnerCode}/webhooks/{endpointId}`), hiển thị cho đối tác một lần khi tạo hoặc xoay. Lượt quay về của người nộp dùng cùng cơ chế với bí mật riêng, trên chuỗi `{transactionCode}.{status}.{ts}`. Bộ gửi chỉ dùng HTTPS, không theo chuyển hướng, chặn địa chỉ riêng và kiểm lại IP ngay trước khi gửi (chống DNS rebinding); lịch thử lại theo BR-19-020; giữ thứ tự `sequence` theo (đầu nhận, giao dịch) (BR-19-021). Phương án C được giữ làm điểm nâng cấp khi lên cấp độ 4.

## Hệ quả

Tích cực: đối tác xác minh được bằng vài dòng mã; có mẫu mã ở tài liệu hướng dẫn tích hợp. Tiêu cực: phải có quy trình giao bí mật cho đối tác và nhắc xoay định kỳ.

## Truy vết

FR-19-021, 025, 060, 062; NFR-19-021; BR-19-020, 021; ERR-19-044; D03-02-PH19 §6.5, §9.4; TS-19-27, 30.
