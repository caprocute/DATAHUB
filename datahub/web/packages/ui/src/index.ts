// @datahub/ui: theme antd từ token D03-05-02, khung ứng dụng và thành phần dùng chung.
export * from './theme/tokens';
export { buildAntdTheme } from './theme/antd-theme';
export { DhThemeProvider } from './theme/DhThemeProvider';
export type { DhThemeProviderProps } from './theme/DhThemeProvider';
export { AppShell } from './components/AppShell';
export type { AppShellProps, ShellNavGroup, ShellNavItem } from './components/AppShell';
export { ProblemAlert } from './components/ProblemAlert';
export type { ProblemAlertProps } from './components/ProblemAlert';
export { ConflictDialog } from './components/ConflictDialog';
export type { ConflictDialogProps, ConflictRow } from './components/ConflictDialog';

// Danh sách tái xuất antd được phép dùng trong apps/ (ESLint cấm import antd trực tiếp ngoài danh sách này).
export {
  Alert,
  App,
  Button,
  Dropdown,
  Empty,
  Form,
  Input,
  InputNumber,
  Modal,
  Select,
  Skeleton,
  Space,
  Spin,
  Tag,
  Tooltip,
  Typography,
} from 'antd';
export type { FormInstance, MenuProps } from 'antd';
export { EllipsisOutlined, PlusOutlined, CaretRightOutlined, CaretDownOutlined } from '@ant-design/icons';
