import { fileURLToPath } from 'node:url';
import path from 'node:path';

const here = path.dirname(fileURLToPath(import.meta.url));

/** Gốc dự án console (apps/console). */
export const consoleDir = path.resolve(here, '..', '..');
/** Gốc repo (thư mục chứa datahub-docs). */
export const repoRoot = path.resolve(consoleDir, '..', '..', '..', '..');
/** Thư mục tệp sinh lúc chạy (khóa thử, nhật ký); đã được .gitignore. */
export const e2eDir = path.join(consoleDir, '.e2e');

export const DB_CONTAINER = 'dh-e2e-pg';
export const DB_PORT = 55432;
export const DB_NAME = 'datahub';
export const API_PORT = 18080;
export const CONSOLE_PORT = 14173;
export const API_URL = `http://localhost:${API_PORT}`;
export const CONSOLE_URL = `http://localhost:${CONSOLE_PORT}`;

export const privateKeyPath = path.join(e2eDir, 'jwt-private.pem');
export const publicKeyPath = path.join(e2eDir, 'jwt-public.pem');
