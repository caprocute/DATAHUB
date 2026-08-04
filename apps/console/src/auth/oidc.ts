import { UserManager, WebStorageStateStore } from 'oidc-client-ts'

const authority =
  import.meta.env.VITE_OIDC_AUTHORITY ?? 'http://localhost:8081/realms/lgsp'
const clientId = import.meta.env.VITE_OIDC_CLIENT_ID ?? 'lgsp-console'
const redirectUri =
  import.meta.env.VITE_OIDC_REDIRECT_URI ?? `${window.location.origin}/`

export const userManager = new UserManager({
  authority,
  client_id: clientId,
  redirect_uri: redirectUri,
  response_type: 'code',
  scope: 'openid profile email',
  userStore: new WebStorageStateStore({ store: window.sessionStorage }),
  automaticSilentRenew: true,
})

export async function handleOidcCallback(): Promise<boolean> {
  const params = new URLSearchParams(window.location.search)
  if (!params.has('code') && !params.has('state') && !params.has('error')) {
    return false
  }
  await userManager.signinRedirectCallback()
  window.history.replaceState({}, document.title, '/')
  return true
}
