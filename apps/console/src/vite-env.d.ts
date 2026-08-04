/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_OIDC_AUTHORITY?: string
  readonly VITE_OIDC_CLIENT_ID?: string
  readonly VITE_OIDC_REDIRECT_URI?: string
  readonly VITE_API_BASE?: string
  readonly VITE_API_ADMIN_BASE?: string
  /** WP-24/25 — mặc định stub waterfall khi chưa có test-runner */
  readonly VITE_TEST_RUN_STUB?: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
