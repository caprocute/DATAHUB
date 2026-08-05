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
  // Dọn `code`/`state` khỏi thanh địa chỉ; điều hướng thật do Router lo.
  window.history.replaceState({}, document.title, target)
  return target
}
