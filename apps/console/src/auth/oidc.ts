import { UserManager, WebStorageStateStore } from 'oidc-client-ts'

const authority =
  import.meta.env.VITE_OIDC_AUTHORITY ?? 'http://localhost:8081/realms/lgsp'
const clientId = import.meta.env.VITE_OIDC_CLIENT_ID ?? 'lgsp-console'
const redirectUri =
  import.meta.env.VITE_OIDC_REDIRECT_URI ?? `${window.location.origin}/`

/**
 * Bắt đầu đăng nhập, ghi nhớ nơi người dùng đang muốn tới.
 *
 * `state` được Keycloak trả lại nguyên vẹn sau khi xác thực, nên dùng nó mang
 * đường dẫn đích thay vì lưu ở `sessionStorage` (dễ lệch khi mở nhiều thẻ).
 */
export function startLogin(returnTo?: string): Promise<void> {
  const target = returnTo ?? `${window.location.pathname}${window.location.search}`
  return userManager.signinRedirect({
    // `url_state` được gắn vào tham số `state` của OIDC và trả lại nguyên vẹn sau
    // khi xác thực. Không dùng `state` của thư viện: nó chỉ sống ở bộ nhớ phía
    // trình duyệt trước lúc chuyển trang, không đi kèm về trên `User`.
    //
    // Lọc ngay ở đầu ra cho chắc — đây là chỗ duy nhất gửi đích đi nên chặn ở đây là
    // chặn được mọi lối gọi. Xem ghi chú open redirect ở `handleOidcCallback`.
    url_state: safeTarget(target),
  })
}

/** Chỉ nhận đường dẫn nội bộ, một dấu `/` mở đầu; còn lại đổ về trang chủ. */
function safeTarget(target: string | undefined): string {
  if (!target || target === '/login' || !/^\/(?!\/)/.test(target)) return '/'
  return target
}

export const userManager = new UserManager({
  authority,
  client_id: clientId,
  redirect_uri: redirectUri,
  response_type: 'code',
  scope: 'openid profile email',
  userStore: new WebStorageStateStore({ store: window.sessionStorage }),
  automaticSilentRenew: true,
})

/**
 * Xử lý lượt quay về từ Keycloak.
 *
 * Trả về đường dẫn người dùng định vào trước khi bị đẩy đi đăng nhập, để nơi gọi
 * điều hướng **bằng React Router**. Trước đây hàm này tự gọi `history.replaceState`:
 * thanh địa chỉ đổi nhưng Router không hay biết nên vẫn giữ nguyên màn đang vẽ —
 * người dùng đăng nhập xong vẫn thấy trang đăng nhập.
 */
/**
 * Đích deep link, đọc **ngay lúc nạp mô-đun** — trước khi React vẽ lần đầu.
 *
 * Keycloak nhét đường dẫn vào tham số `state` theo dạng `<id>;<url_state>`. Đọc thẳng
 * từ URL ở đây thay vì chờ `signinRedirectCallback()` trả về, vì lượt trả về đó là
 * bất đồng bộ: StrictMode kịp gắn–tháo–gắn effect và **mọi lượt đều bị đánh dấu hủy**
 * trước khi nó xong, nên không lượt nào đặt được đích qua `setState`. Đọc đồng bộ thì
 * giá trị có sẵn ngay từ lượt vẽ đầu, không phụ thuộc thứ tự effect.
 */
function readTargetFromUrl(): string | null {
  const raw = new URLSearchParams(window.location.search).get('state')
  if (!raw) return null
  const semi = raw.indexOf(';')
  if (semi === -1) return null
  const path = decodeURIComponent(raw.slice(semi + 1))
  return /^\/(?!\/)/.test(path) && path !== '/' ? path : null
}

/** Đích bắt được lúc trang vừa nạp; `OidcRedirect` lấy ra dùng đúng một lần. */
let bootTarget = readTargetFromUrl()

export function takeBootTarget(): string | null {
  const t = bootTarget
  bootTarget = null
  return t
}

export async function handleOidcCallback(): Promise<string | null> {
  const params = new URLSearchParams(window.location.search)
  if (!params.has('code') && !params.has('state') && !params.has('error')) {
    return null
  }
  const user = await userManager.signinRedirectCallback()
  // `url_state` do `startLogin()` gửi đi lúc bắt đầu; thiếu thì về trang mặc định.
  //
  // Chỉ nhận **một** dấu `/` mở đầu: `//evil.com` cũng bắt đầu bằng `/` nhưng trình
  // duyệt hiểu là URL tuyệt đối theo giao thức hiện tại, tức là đá người dùng sang
  // trang ngoài ngay sau khi đăng nhập thành công (open redirect).
  const target = user.url_state && /^\/(?!\/)/.test(user.url_state) ? user.url_state : '/'
  // Chỉ dọn `code`/`state` khỏi thanh địa chỉ, **giữ nguyên đường dẫn**.
  //
  // Trước đây hàm này `replaceState` thẳng sang `target`: thanh địa chỉ nhảy đúng chỗ
  // nhưng React Router không hay biết nên `location` bên trong nó vẫn là `/` — route
  // `index` của `/` liền chuyển tiếp sang `/flows`, **đè mất** deep link vừa khôi phục.
  // Điều hướng thật để `OidcRedirect` làm bằng Router.
  window.history.replaceState({}, document.title, window.location.pathname)
  return target
}
