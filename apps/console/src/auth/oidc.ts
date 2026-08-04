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
    url_state: target && target !== '/login' ? target : '/',
  })
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
  const target = user.url_state?.startsWith('/') ? user.url_state : '/'
  // Dọn `code`/`state` khỏi thanh địa chỉ; điều hướng thật do Router lo.
  window.history.replaceState({}, document.title, target)
  return target
}
