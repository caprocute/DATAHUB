# language: vi
# Sinh tự động từ D05-02-PH12 bằng ph12/tools/gen_gherkin.py; không sửa tay.
@PH-12 @TS-12-15
Tính năng: TS-12-15 · Chống dò mật khẩu và khóa tài khoản

  @TC-12-049 @P1 @Dương @Âm @Biên
  Kịch bản: TC-12-049 5 lần sai khóa tạm 15 phút, 3 lần khóa tạm thì khóa hẳn
    # Truy vết: FR-12-021 · UC-12-16 · UI-12-18 · BR-12-019 · ERR-12-111, 112, 113 · NFR-00-025
    Biết U-T68-VW; U-T68-TA1 để mở khóa; đồng hồ điều khiển được.
    Khi đăng nhập sai 4 lần, rồi lần 5; thử đúng mật khẩu ngay sau đó.
    Và hết 15 phút, lặp để có 3 lần khóa tạm trong 24 giờ.
    Và TA mở khóa hẳn.
    Thì lần 1–4 ERR-12-111; lần 5 và đúng mật khẩu ngay sau đó ERR-12-112 (423); sau lần khóa thứ 3 ERR-12-113 (403), chỉ TA hoặc SO mở được; KT: có.

  @TC-12-050 @P1 @Bảo @mật
  Kịch bản: TC-12-050 Tên không tồn tại cho phản hồi giống tên có thật, chặn theo địa chỉ
    # Truy vết: FR-12-021 · BR-12-017 · NFR-12-021 · ERR-12-111, ERR-12-125 · SEC-22
    Biết một địa chỉ thử; 1.000 cặp tên và mật khẩu sai.
    Khi đăng nhập sai tên có thật và tên không có, so thân và thời gian.
    Và bắn 1.000 lần từ một địa chỉ.
    Thì thân và thời gian giống nhau; bị chặn `429` ERR-12-125 sau ≤ 20 lần; cảnh báo tới SO ≤ 60 giây.
