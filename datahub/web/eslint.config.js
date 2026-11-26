import js from '@eslint/js';
import jsxA11y from 'eslint-plugin-jsx-a11y';
import reactHooks from 'eslint-plugin-react-hooks';
import globals from 'globals';
import tseslint from 'typescript-eslint';

const restrictedGlobals = [
  { name: 'fetch', message: 'Gọi API qua @datahub/api-client, không dùng fetch trực tiếp.' },
];

export default tseslint.config(
  { ignores: ['**/dist/**', '**/coverage/**', '**/node_modules/**', '**/generated/**', '**/playwright-report/**', '**/test-results/**', '**/.e2e/**'] },
  js.configs.recommended,
  ...tseslint.configs.recommendedTypeChecked,
  jsxA11y.flatConfigs.recommended,
  {
    languageOptions: {
      globals: { ...globals.browser },
      parserOptions: { projectService: { allowDefaultProject: ['eslint.config.js'] }, tsconfigRootDir: import.meta.dirname },
    },
    plugins: { 'react-hooks': reactHooks },
    rules: {
      ...reactHooks.configs.recommended.rules,
      'no-restricted-globals': ['error', ...restrictedGlobals],
      'no-restricted-imports': ['error', { paths: [{ name: 'axios', message: 'Gọi API qua @datahub/api-client.' }] }],
      '@typescript-eslint/no-non-null-assertion': 'error',
      '@typescript-eslint/no-unnecessary-condition': 'error',
      '@typescript-eslint/no-confusing-void-expression': ['error', { ignoreArrowShorthand: true }],
      '@typescript-eslint/restrict-template-expressions': ['error', { allowNumber: true }],
    },
  },
  {
    files: ['packages/api-client/src/**/*.ts', 'apps/*/e2e/**/*.ts'],
    rules: { 'no-restricted-globals': 'off' },
  },
  {
    files: ['apps/**/*.{ts,tsx}'],
    rules: {
      'no-restricted-imports': [
        'error',
        {
          paths: [{ name: 'axios', message: 'Gọi API qua @datahub/api-client.' }],
          patterns: [
            { group: ['antd', 'antd/*', '@ant-design/*'], message: 'Chỉ import antd qua @datahub/ui (danh sách tái xuất).' },
          ],
        },
      ],
      'no-restricted-syntax': [
        'error',
        { selector: 'JSXAttribute[name.name="style"]', message: 'Không dùng style nội tuyến; dùng class CSS với token --dh-*.' },
        { selector: 'Literal[value=/^#[0-9a-fA-F]{3,8}$/]', message: 'Không ghi màu cứng; dùng token --dh-*.' },
      ],
    },
  },
  {
    files: ['**/*.test.{ts,tsx}', '**/test/**', 'apps/*/e2e/**'],
    rules: {
      '@typescript-eslint/no-non-null-assertion': 'off',
      '@typescript-eslint/no-unsafe-assignment': 'off',
      '@typescript-eslint/no-floating-promises': 'off',
    },
  },
  {
    files: ['eslint.config.js'],
    rules: { '@typescript-eslint/no-unsafe-argument': 'off', '@typescript-eslint/no-unsafe-member-access': 'off' },
  },
  {
    files: ['*.config.{js,ts}', 'apps/*/*.config.ts'],
    languageOptions: { globals: { ...globals.node } },
  },
);
