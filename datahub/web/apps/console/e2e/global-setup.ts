import { execFileSync, spawn, type ChildProcess } from 'node:child_process';
import { generateKeyPairSync, randomBytes } from 'node:crypto';
import { closeSync, mkdirSync, openSync, rmSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import {
  API_PORT,
  API_URL,
  DB_CONTAINER,
  DB_NAME,
  DB_PORT,
  e2eDir,
  privateKeyPath,
  publicKeyPath,
  repoRoot,
} from './support/env';

const SCRIPTS = [
  'datahub-docs/03-thiet-ke/csdl/ph07/ddl/ph07_rdm.sql',
  'datahub-docs/03-thiet-ke/csdl/ph07/seed/07-S01-nhom-danh-muc.sql',
  'datahub-docs/03-thiet-ke/csdl/ph07/seed/07-S02-gioi-tinh.sql',
  'datahub-docs/03-thiet-ke/csdl/ph07/seed/07-S03-dvhc-khung.sql',
];

const docker = (...args: string[]): string => execFileSync('docker', args, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });

function dockerQuiet(...args: string[]): void {
  try {
    docker(...args);
  } catch {
    /* container chưa tồn tại */
  }
}

async function sleep(ms: number): Promise<void> {
  await new Promise((resolve) => setTimeout(resolve, ms));
}

async function until(what: string, timeoutMs: number, probe: () => Promise<boolean> | boolean): Promise<void> {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    try {
      if (await probe()) {
        return;
      }
    } catch {
      /* thử lại */
    }
    await sleep(500);
  }
  throw new Error(`Hết thời gian chờ ${what}`);
}

/** Sinh khóa RSA thử lúc chạy: khóa riêng chỉ để ký token trong kiểm thử, khóa công khai đưa cho backend. */
function generateKeys(): void {
  mkdirSync(e2eDir, { recursive: true });
  const { publicKey, privateKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
  writeFileSync(publicKeyPath, publicKey.export({ type: 'spki', format: 'pem' }));
  writeFileSync(privateKeyPath, privateKey.export({ type: 'pkcs8', format: 'pem' }), { mode: 0o600 });
}

/** PostgreSQL 18 tự dựng: nạp NGUYÊN DDL và seed nguồn qua /docker-entrypoint-initdb.d/. */
async function startDatabase(appPassword: string): Promise<void> {
  dockerQuiet('rm', '-f', DB_CONTAINER);
  docker(
    'create', '--name', DB_CONTAINER,
    '-e', `POSTGRES_PASSWORD=${randomBytes(12).toString('hex')}`,
    '-e', `POSTGRES_DB=${DB_NAME}`,
    '-p', `127.0.0.1:${DB_PORT}:5432`,
    'postgres:18',
  );
  SCRIPTS.forEach((script, index) => {
    docker('cp', path.join(repoRoot, script), `${DB_CONTAINER}:/docker-entrypoint-initdb.d/0${index + 1}-${path.basename(script)}`);
  });
  docker('start', DB_CONTAINER);
  // Máy chủ tạm của initdb chỉ nghe socket; chỉ máy chủ thật mới nhận TCP 127.0.0.1.
  await until('PostgreSQL 18 sẵn sàng', 120_000, () => {
    docker('exec', DB_CONTAINER, 'psql', '-h', '127.0.0.1', '-U', 'postgres', '-d', DB_NAME, '-tAc', 'select count(*) from ph07_rdm.catalog_group');
    return true;
  });
  docker(
    'exec', DB_CONTAINER, 'psql', '-U', 'postgres', '-d', DB_NAME, '-v', 'ON_ERROR_STOP=1', '-c',
    `create role dh_data_app login password '${appPassword}' in role ph07_app`,
  );
}

function buildBackend(): void {
  execFileSync('mvn', ['-B', '-q', '-f', path.join(repoRoot, 'datahub/services/dh-data/pom.xml'), 'package', '-DskipTests', '-Djacoco.skip=true'], {
    stdio: 'inherit',
  });
}

async function startBackend(appPassword: string): Promise<ChildProcess> {
  const log = openSync(path.join(e2eDir, 'backend.log'), 'w');
  const jar = path.join(repoRoot, 'datahub/services/dh-data/target/dh-data-0.1.0-SNAPSHOT.jar');
  const child = spawn('java', ['-jar', jar, '--spring.profiles.active=e2e'], {
    stdio: ['ignore', log, log],
    env: {
      ...process.env,
      PORT: String(API_PORT),
      DH_DATA_DB_URL: `jdbc:postgresql://localhost:${DB_PORT}/${DB_NAME}`,
      DH_DATA_DB_USER: 'dh_data_app',
      DH_DATA_DB_PASSWORD: appPassword,
      DATAHUB_SECURITY_JWT_PUBLICKEYFILE: publicKeyPath,
    },
  });
  closeSync(log);
  let exited = false;
  child.once('exit', () => {
    exited = true;
  });
  await until('backend dh-data khởi động (xem .e2e/backend.log)', 120_000, async () => {
    if (exited) {
      throw new Error('Backend dh-data thoát sớm, xem .e2e/backend.log');
    }
    const response = await fetch(`${API_URL}/api/rdm/v1/catalog-groups`);
    return response.status === 401;
  });
  return child;
}

export default async function globalSetup(): Promise<() => Promise<void>> {
  generateKeys();
  const appPassword = randomBytes(16).toString('hex');
  buildBackend();
  await startDatabase(appPassword);
  const backend = await startBackend(appPassword);
  return () => {
    backend.kill('SIGTERM');
    dockerQuiet('rm', '-f', DB_CONTAINER);
    rmSync(privateKeyPath, { force: true });
    return Promise.resolve();
  };
}
