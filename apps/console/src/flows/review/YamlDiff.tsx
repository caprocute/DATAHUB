import { Empty, Segmented, Typography } from 'antd';
import { useMemo, useState } from 'react';
import { collapseUnchanged, diffLines, diffStat } from '../core/diff';

interface Props {
  /** Bản đang chạy (hoặc bản trước). Rỗng nghĩa là luồng mới hoàn toàn. */
  oldYaml: string;
  /** Bản đang chờ duyệt. */
  newYaml: string;
}

/**
 * So sánh hai bản định nghĩa luồng khi duyệt (B7-5 / FR-04-029).
 *
 * Người duyệt phải thấy đúng thứ mình đang phê duyệt, không chỉ tên và số phiên bản.
 */
export function YamlDiff({ oldYaml, newYaml }: Props) {
  const [mode, setMode] = useState<'thay-doi' | 'toan-bo'>('thay-doi');

  const lines = useMemo(() => diffLines(oldYaml, newYaml), [oldYaml, newYaml]);
  const stat = useMemo(() => diffStat(lines), [lines]);
  const shown = useMemo(
    () => (mode === 'toan-bo' ? lines : collapseUnchanged(lines, 3)),
    [lines, mode],
  );

  if (!newYaml.trim()) {
    return <Empty description="Phiên bản này chưa có định nghĩa" />;
  }

  return (
    <div className="ydiff">
      <div className="ydiff__head">
        <span className="t-small">
          <span className="ydiff__stat ydiff__stat--add">+{stat.added}</span>{' '}
          <span className="ydiff__stat ydiff__stat--del">−{stat.removed}</span>{' '}
          {stat.added + stat.removed === 0 && (
            <Typography.Text type="secondary">Không khác bản đang chạy</Typography.Text>
          )}
        </span>
        <Segmented
          size="small"
          value={mode}
          onChange={(v) => setMode(v as 'thay-doi' | 'toan-bo')}
          options={[
            { label: 'Chỗ thay đổi', value: 'thay-doi' },
            { label: 'Toàn bộ', value: 'toan-bo' },
          ]}
        />
      </div>

      <pre className="ydiff__body t-mono">
        {shown.map((l, i) =>
          l === null ? (
            <span className="ydiff__gap" key={`gap${i}`}>
              ⋯
              {'\n'}
            </span>
          ) : (
            <span className={`ydiff__line ydiff__line--${l.kind}`} key={`${l.kind}${i}`}>
              <span className="ydiff__no">{l.oldNo ?? ''}</span>
              <span className="ydiff__no">{l.newNo ?? ''}</span>
              <span className="ydiff__sign">
                {l.kind === 'add' ? '+' : l.kind === 'remove' ? '−' : ' '}
              </span>
              {l.text}
              {'\n'}
            </span>
          ),
        )}
      </pre>
    </div>
  );
}
