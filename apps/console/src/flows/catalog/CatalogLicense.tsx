import { CATALOG_LICENSE, CATALOG_RUNTIME, CATALOG_SOURCE, CATALOG_TOTAL } from '../core/catalog'

/**
 * Nguồn và giấy phép của danh mục (K4-5 — FR-D-073).
 *
 * **Đây là nghĩa vụ tuân thủ, không phải chú thích trang trí.** Toàn bộ 751 nút — mô tả,
 * tiêu đề, bảng tham số — là tác phẩm phát hành theo Apache-2.0 của Apache Camel qua gói
 * `@kaoto/camel-catalog`. Điều 4 của giấy phép buộc bên phân phối lại phải giữ ghi nhận
 * nguồn; hiện ở đây là cách người dùng cuối thấy được điều đó.
 *
 * Ghi cả **phiên bản runtime** vì bảng tham số chỉ đúng với đúng phiên bản đó: người dùng
 * đối chiếu tài liệu Camel bản khác sẽ thấy lệch trường mà không hiểu vì sao.
 */
export function CatalogLicense() {
  return (
    <footer className="cat__license">
      <div>
        Dữ liệu danh mục: <strong>{CATALOG_SOURCE}</strong> · giấy phép{' '}
        <a
          href="https://www.apache.org/licenses/LICENSE-2.0"
          target="_blank"
          rel="noreferrer noopener"
        >
          {CATALOG_LICENSE}
        </a>
      </div>
      <div className="cat__license-sub">
        Nhánh runtime <code>{CATALOG_RUNTIME}</code> · {CATALOG_TOTAL} nút · bảng tham số chỉ đúng
        với phiên bản này
      </div>
    </footer>
  )
}
