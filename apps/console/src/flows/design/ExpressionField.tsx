import { Input, Tooltip } from 'antd';
import { useMemo, useState } from 'react';
import {
  contextFromSample,
  detectLang,
  evaluate,
  suggestTokens,
  type EvalContext,
} from '../core/expression';

interface Props {
  value: string;
  onChange: (v: string) => void;
  /** Bản tin mẫu hiệu lực của chặng (FR-04-033); thiếu thì không xem trước được. */
  sample?: string;
  /** Mẫu lấy từ chặng trước trên đường đi, không phải pin của chính chặng này. */
  inherited?: boolean;
  env?: Record<string, string>;
  placeholder?: string;
  rows?: number;
}

/**
 * Ô nhập biểu thức có gợi ý và xem trước trên dữ liệu mẫu (FR-04-031).
 *
 * Xem trước chạy tại trình duyệt trên **tập con** Camel Simple / JSONPath. Cú pháp
 * ngoài tập con được báo rõ là “chưa xem trước được”, không kết luận biểu thức sai —
 * máy chủ mới là nơi diễn giải thật.
 */
export function ExpressionField({
  value,
  onChange,
  sample,
  inherited,
  env,
  placeholder,
  rows = 2,
}: Props) {
  const [focused, setFocused] = useState(false);

  const ctx: EvalContext = useMemo(() => contextFromSample(sample, env), [sample, env]);
  const lang = useMemo(() => detectLang(value ?? ''), [value]);
  const result = useMemo(() => (value?.trim() ? evaluate(value, ctx, lang) : undefined), [value, ctx, lang]);
  const tokens = useMemo(() => (focused ? suggestTokens(ctx) : []), [focused, ctx]);

  const hasSample = Boolean(sample?.trim());

  return (
    <div className="expr">
      <Input.TextArea
        className="t-mono"
        size="small"
        autoSize={{ minRows: rows, maxRows: 6 }}
        value={value}
        placeholder={placeholder ?? '${body.truong} hoặc $.duong.dan'}
        onChange={(e) => onChange(e.target.value)}
        onFocus={() => setFocused(true)}
        // Hoãn đóng để bấm được vào chip gợi ý.
        onBlur={() => window.setTimeout(() => setFocused(false), 150)}
        status={result && !result.ok && hasSample ? 'warning' : undefined}
      />

      <div className="expr__meta">
        <span className="badge badge--muted badge--plain">
          {lang === 'simple' ? 'Camel Simple' : lang === 'jsonpath' ? 'JSONPath' : 'Hằng'}
        </span>
        {!hasSample && (
          <span className="t-small t-muted">
            Chưa có bản tin mẫu — gắn ở tab «Dữ liệu mẫu» để xem trước.
          </span>
        )}
        {hasSample && inherited && (
          <span className="t-small t-muted">Mẫu lấy từ chặng trước trên đường đi.</span>
        )}
      </div>

      {hasSample && result && (
        <div className={result.ok ? 'expr__preview' : 'expr__preview expr__preview--warn'}>
          <span className="expr__preview-label">{result.ok ? 'Kết quả' : 'Chưa xem trước được'}</span>
          <span className="t-mono expr__preview-value">
            {result.ok ? result.rendered || '(chuỗi rỗng)' : result.error}
          </span>
        </div>
      )}

      {focused && tokens.length > 0 && (
        <div className="expr__tokens">
          {tokens.map((t) => (
            <Tooltip key={t.token} title={t.hint || 'không có giá trị trong mẫu'}>
              <button
                type="button"
                className="expr__token"
                // `onMouseDown` chạy trước `onBlur` nên chèn được trước khi panel đóng.
                onMouseDown={(e) => {
                  e.preventDefault();
                  onChange((value ?? '') + t.token);
                }}
              >
                {t.token}
              </button>
            </Tooltip>
          ))}
        </div>
      )}
    </div>
  );
}
