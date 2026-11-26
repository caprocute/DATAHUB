import { Button, Modal } from 'antd';
import { useState } from 'react';
import { t } from '@datahub/i18n';
import './conflict-dialog.css';

export interface ConflictRow {
  field: string;
  mine: string;
  server: string;
}

export interface ConflictDialogProps {
  open: boolean;
  /** Người và thời điểm cập nhật gần nhất trên máy chủ (nếu biết). */
  updatedBy?: string;
  updatedAt?: string;
  rows: readonly ConflictRow[];
  /** Bỏ thay đổi của người dùng, nạp bản mới (mặc định, có focus). */
  onReload: () => void;
  /** Gửi lại thay đổi với ETag mới; chỉ gọi sau khi xác nhận lần hai. */
  onOverwrite: () => void;
  onClose: () => void;
}

/**
 * Hộp thoại xung đột ETag 412 ERR-07-018 (D03-06-PH07 §6.5): bảng ba cột các trường khác nhau,
 * nút Tải lại (mặc định) và Ghi đè (xác nhận lần hai).
 */
export function ConflictDialog({ open, updatedBy, updatedAt, rows, onReload, onOverwrite, onClose }: ConflictDialogProps) {
  const [confirming, setConfirming] = useState(false);
  const who = updatedBy ?? '';

  return (
    <Modal
      open={open}
      title={t('conflict.title')}
      onCancel={onClose}
      destroyOnHidden
      afterClose={() => setConfirming(false)}
      footer={
        confirming ? (
          <>
            <span className="dh-conflict__confirm">{t('conflict.overwriteConfirm', { updatedBy: who || '—' })}</span>
            <Button onClick={() => setConfirming(false)}>{t('rdm.groups.form.cancel')}</Button>
            <Button danger type="primary" onClick={onOverwrite}>
              {t('conflict.overwrite')}
            </Button>
          </>
        ) : (
          <>
            <Button onClick={() => setConfirming(true)}>{t('conflict.overwrite')}</Button>
            {/* eslint-disable-next-line jsx-a11y/no-autofocus -- D03-06-PH07 §6.5: Tải lại là nút mặc định, có focus khi hộp thoại mở */}
            <Button type="primary" autoFocus onClick={onReload}>
              {t('conflict.reload')}
            </Button>
          </>
        )
      }
    >
      <p>
        {updatedBy && updatedAt
          ? t('conflict.body', { updatedBy, updatedAt })
          : t('conflict.bodyAnonymous')}
      </p>
      {rows.length === 0 ? (
        <p>{t('conflict.noDiff')}</p>
      ) : (
        <table className="dh-conflict__table">
          <thead>
            <tr>
              <th scope="col">{t('conflict.col.field')}</th>
              <th scope="col">{t('conflict.col.mine')}</th>
              <th scope="col">{t('conflict.col.server')}</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((row) => (
              <tr key={row.field}>
                <th scope="row">{row.field}</th>
                <td>{row.mine}</td>
                <td>{row.server}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </Modal>
  );
}
