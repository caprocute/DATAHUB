import { Alert, Button } from 'antd';
import { t } from '@datahub/i18n';
import './problem-alert.css';

export interface ProblemAlertProps {
  /** Câu hiển thị cho người dùng (tra từ mã lỗi), không phải `detail` thô của máy chủ. */
  title: string;
  /** Gợi ý khắc phục hoặc mô tả thêm. */
  detail?: string;
  /** Mã lỗi ERR-nn-nnn. */
  code?: string;
  /** Mã truy vết để gửi hỗ trợ (FR-00-080). */
  traceId?: string;
  onRetry?: () => void;
  className?: string;
}

/**
 * Hiển thị lỗi theo D03-06-PH07 §5.3: câu chính, gợi ý, và dòng phụ "Mã lỗi: … · Mã truy vết: …"
 * kèm nút Sao chép để người dùng gửi cho bộ phận hỗ trợ.
 */
export function ProblemAlert({ title, detail, code, traceId, onRetry, className }: ProblemAlertProps) {
  const reference = code && traceId ? t('err.codeLine', { code, traceId }) : code ? code : undefined;
  const copy = () => {
    if (reference && typeof navigator !== 'undefined' && (navigator.clipboard as Clipboard | undefined)) {
      void navigator.clipboard.writeText(reference);
    }
  };
  return (
    <Alert
      {...(className !== undefined ? { className } : {})}
      type="error"
      showIcon
      role="alert"
      title={title}
      description={
        <div className="dh-problem">
          {detail ? <p className="dh-problem__detail">{detail}</p> : null}
          {reference ? (
            <p className="dh-problem__meta">
              <span>{reference}</span>
              <Button size="small" type="link" onClick={copy}>
                {t('err.copy')}
              </Button>
            </p>
          ) : null}
          {onRetry ? (
            <Button size="small" onClick={onRetry}>
              {t('action.retry')}
            </Button>
          ) : null}
        </div>
      }
    />
  );
}
