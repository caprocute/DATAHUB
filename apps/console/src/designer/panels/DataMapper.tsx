import { Button, Input, Select } from 'antd';
import type { FieldMapping } from '../flow/model';

/** Trường mẫu CDM — stub UI (chưa nối engine ánh xạ thật). */
export const SOURCE_FIELDS = [
  '$.soThuTu',
  '$.chuSoHuu.hoTen',
  '$.chuSoHuu.soDinhDanh',
  '$.viTri.maTinh',
  '$.viTri.maDonViHanhChinh',
  '$.dienTich',
  '$.loaiHoSo',
];

/** Trường mẫu của lược đồ đích (CDM chuẩn / phía hệ thống nhận). */
export const TARGET_FIELDS = [
  '$.ThuaDat.SoThuTu',
  '$.ThuaDat.ChuSoHuu.HoTen',
  '$.ThuaDat.ChuSoHuu.SoDinhDanh',
  '$.ThuaDat.ViTri.MaTinh',
  '$.ThuaDat.ViTri.MaDonViHanhChinh',
  '$.ThuaDat.DienTich',
  '$.ThuaDat.PhanLoai',
];

interface Props {
  mappings: FieldMapping[];
  onChange: (next: FieldMapping[]) => void;
  locked?: boolean;
}

/**
 * Bảng ánh xạ trường kiểu Kaoto DataMapper — STUB.
 * Chỉ ghi `mappings` vào chặng để sinh YAML; chưa nối engine CDM.
 */
export function DataMapperPanel({ mappings, onChange, locked }: Props) {
  const add = () => {
    const usedFrom = new Set(mappings.map((m) => m.from));
    const usedTo = new Set(mappings.map((m) => m.to));
    const from = SOURCE_FIELDS.find((f) => !usedFrom.has(f)) ?? SOURCE_FIELDS[0];
    const to = TARGET_FIELDS.find((f) => !usedTo.has(f)) ?? TARGET_FIELDS[0];
    onChange([...mappings, { from, to }]);
  };

  const patch = (i: number, next: Partial<FieldMapping>) => {
    onChange(mappings.map((m, idx) => (idx === i ? { ...m, ...next } : m)));
  };

  const remove = (i: number) => onChange(mappings.filter((_, idx) => idx !== i));

  return (
    <div className="mapper">
      <div className="mapper__head">
        <div className="mapper__title">Ánh xạ trường (DataMapper)</div>
        <div className="t-small t-muted">
          STUB — UI ánh xạ trường; runtime CDM chưa nối. Không dùng làm bằng chứng chạy thử.
        </div>
      </div>

      <div className="mapper__cols">
        <div className="mapper__col-label">Nguồn (bản tin vào)</div>
        <div className="mapper__col-label">Đích (CDM / lược đồ ra)</div>
        <div />
      </div>

      {mappings.length === 0 && (
        <p className="t-small t-muted" style={{ margin: '0 0 var(--sp-3)' }}>
          Chưa có dòng ánh xạ. Thêm cặp trường để chặng chuyển đổi biết cách đổ dữ liệu.
        </p>
      )}

      <div className="mapper__rows">
        {mappings.map((m, i) => (
          <div className="mapper__row" key={`${m.from}-${m.to}-${i}`}>
            <Select
              size="small"
              className="t-mono"
              style={{ width: '100%' }}
              value={m.from}
              disabled={locked}
              onChange={(v) => patch(i, { from: v })}
              options={SOURCE_FIELDS.map((f) => ({ value: f, label: f }))}
              dropdownRender={(menu) => (
                <>
                  {menu}
                  <div style={{ padding: 6 }}>
                    <Input
                      size="small"
                      className="t-mono"
                      placeholder="Hoặc gõ đường dẫn…"
                      onPressEnter={(e) => {
                        const v = (e.target as HTMLInputElement).value.trim();
                        if (v) patch(i, { from: v });
                      }}
                    />
                  </div>
                </>
              )}
            />
            <span className="mapper__arrow" aria-hidden="true">
              →
            </span>
            <Select
              size="small"
              className="t-mono"
              style={{ width: '100%' }}
              value={m.to}
              disabled={locked}
              onChange={(v) => patch(i, { to: v })}
              options={TARGET_FIELDS.map((f) => ({ value: f, label: f }))}
            />
            <Button size="small" type="text" danger disabled={locked} onClick={() => remove(i)} aria-label="Xóa dòng">
              ×
            </Button>
          </div>
        ))}
      </div>

      {!locked && (
        <Button size="small" onClick={add} style={{ marginTop: 'var(--sp-2)' }}>
          ＋ Thêm ánh xạ
        </Button>
      )}
    </div>
  );
}
