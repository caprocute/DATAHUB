/**
 * Token truy cập chỉ giữ trong BỘ NHỚ của trang (biến module), không bao giờ ghi vào
 * localStorage, sessionStorage hay cookie (AGENTS §2, CC-SEC phía trình duyệt).
 */
let accessToken: string | undefined;

export const tokenStore = {
  get(): string | undefined {
    return accessToken;
  },
  set(token: string | undefined): void {
    accessToken = token;
  },
};
