/**
 * CHỈ DÙNG CHO DEV/E2E. Module này được nạp động có điều kiện `VITE_DH_E2E_AUTH === '1'` nên bản
 * production (không đặt biến) loại bỏ hẳn nó khỏi gói. Token do kịch bản e2e đặt vào
 * `window.__DH_E2E_TOKEN__` trước khi trang chạy (Playwright addInitScript).
 */
declare global {
  interface Window {
    __DH_E2E_TOKEN__?: string;
  }
}

export function readE2eToken(): string {
  const token = window.__DH_E2E_TOKEN__;
  if (token === undefined || token === '') {
    throw new Error('Thiếu window.__DH_E2E_TOKEN__ ở chế độ e2e');
  }
  return token;
}
