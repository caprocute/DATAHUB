/// <reference types="vite/client" />

interface ImportMetaEnv {
  /** "1" chỉ khi build cho dev/e2e: bật nhận token qua window.__DH_E2E_TOKEN__. Không có trong production. */
  readonly VITE_DH_E2E_AUTH?: string;
  readonly VITE_OIDC_AUTHORITY?: string;
  readonly VITE_OIDC_CLIENT_ID?: string;
  readonly VITE_OIDC_REDIRECT_URI?: string;
  readonly VITE_OIDC_SCOPE?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
