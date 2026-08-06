package vn.lgsp.control.shared.events;

/**
 * Một hệ thống thành viên vừa được kết nạp và đang hiệu lực (PH-01 → các phân hệ khác).
 *
 * <p>Đặt ở {@code shared} — mô-đun khai {@code Type.OPEN} và là phụ thuộc hợp lệ duy nhất
 * của mọi mô-đun khác. Nhờ vậy PH-04 biết được sự kiện này **mà không cần** phụ thuộc
 * thẳng vào {@code onboarding :: api}: mở phụ thuộc đó làm {@code ApplicationModules
 * .verify()} đỏ, vì kiến trúc cố ý giữ hai phân hệ độc lập (IP-07 K1-7c).
 *
 * <p>Tương ứng hợp đồng {@code contracts/events/onboarding.system-approved.v1.json}, vốn
 * đã được PH-01 ghi vào outbox. Bản ghi này là **kênh trong tiến trình**; outbox vẫn giữ
 * nguyên cho bus ngoài khi có broker.
 *
 * @param systemCode mã hệ thống chính thức, dùng để đối chiếu {@code source_system} của luồng
 */
public record SystemApprovedEvent(String systemCode) {}
