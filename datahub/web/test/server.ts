import { setupServer } from 'msw/node';

/** Máy chủ MSW dùng chung; mỗi bài kiểm thử tự đăng ký handler bằng `server.use`. */
export const server = setupServer();
