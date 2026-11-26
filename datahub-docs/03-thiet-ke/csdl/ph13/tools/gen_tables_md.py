#!/usr/bin/env python3
"""Sinh chương 3 (bảng mô tả cột, Markdown) từ ddl/ph13_audit.sql và ddl/ph13_obs.sql.

Chạy: python3 tools/gen_tables_md.py > /tmp/tables.md (từ thư mục csdl/ph13).
Kết quả được dán vào D03-03-PH13 §3 giữa hai dấu <!-- gen:tables:start/end -->; sau đó chạy
tools/them_dac_ta_bang.py để thêm khối đặc tả 10 mục cho từng bảng. Đọc CREATE TABLE và COMMENT ON TABLE/COLUMN;
cột không có COMMENT lấy ghi chú chuẩn của cột ngữ cảnh hoặc để trống."""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ddl_parse  # noqa: E402

D = ddl_parse.parse()
STD = {
    'id': 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5).',
    'tenant_id': 'Mã tenant `T{nn}` hoặc `PLATFORM`; khóa RLS (`app.tenant_id`).',
    'created_at': 'Thời điểm tạo.', 'created_by': 'Người tạo (mã người dùng hoặc `system:*`).',
    'updated_at': 'Thời điểm sửa cuối (trigger `tg_touch`).', 'updated_by': 'Người sửa cuối.',
    'version': 'Khóa lạc quan; thành phần của ETag (`If-Match`).',
}
# Ghi chú bổ sung cho cột chưa có COMMENT ON COLUMN: theo tên cột (mọi bảng) hoặc theo (bảng, cột).
GENERIC = {
    'name': 'Tên hiển thị.', 'description': 'Mô tả tự do.', 'owner': 'Người sở hữu (mã người dùng).', 'enabled': 'Bật hoặc tắt; tắt thì không tham gia xử lý.',
    'source_revision': 'Mã commit của kho cấu hình Git đã nạp mục này.', 'retired_at': 'Thời điểm ngừng dùng (xóa mềm).', 'retired_reason': 'Lý do ngừng dùng.',
    'requested_by': 'Người hoặc tác vụ yêu cầu (mã người dùng hoặc `system:*`).', 'started_at': 'Thời điểm bắt đầu.', 'finished_at': 'Thời điểm kết thúc.',
    'rule_code': 'Mã luật; cùng `tenant_id` trỏ tới bảng luật.', 'event_id': 'Mã sự kiện (UUID v7), khóa khử trùng ở bên nhận.',
    'aggregate_type': 'Loại thực thể phát sinh sự kiện.', 'aggregate_id': 'Mã thực thể phát sinh sự kiện.', 'payload': 'Nội dung sự kiện JSON; không chứa bí mật.',
}
PER = {
    ('audit_signing_key', 'key_name'): 'Tên khóa ở OpenBao Transit; chỉ một phiên bản `ACTIVE` mỗi tên.', ('audit_signing_key', 'public_key_pem'): 'Khóa công khai dạng PEM để xác minh ngoại tuyến.',
    ('audit_signing_key', 'activated_at'): 'Thời điểm phiên bản khóa bắt đầu dùng.', ('audit_signing_key', 'retired_at'): 'Thời điểm xoay sang phiên bản mới (`ROTATED`).',
    ('audit_chain', 'suspect_from_seq'): '`seq` bắt đầu đoạn nghi vấn khi `SUSPECT`.', ('audit_chain', 'suspect_since'): 'Thời điểm đánh dấu `SUSPECT`.',
    ('audit_chain', 'closed_at'): 'Thời điểm đóng chuỗi (tenant ngừng hoặc sáp nhập).', ('audit_chain', 'closed_reason'): 'Lý do đóng chuỗi; ghi cả vào bản ghi `CHAIN.CLOSE`.',
    ('audit_event', 'occurred_at'): 'Giờ DU ghi nhận thao tác (đồng hồ nguồn); lệch quá 2 giây về tương lai thì đặt `clock_skew`.',
    ('audit_event', 'actor_id'): 'Mã người dùng hoặc client; `system:{du}` cho tác vụ tự động.', ('audit_event', 'actor_name'): 'Tên hiển thị của tác nhân tại thời điểm thao tác.',
    ('audit_event', 'source_ip'): 'Địa chỉ nguồn (IPv4 hoặc IPv6) của thao tác.', ('audit_event', 'user_agent'): 'Chuỗi định danh trình khách.',
    ('audit_event', 'object_type'): 'Loại đối tượng bị tác động; dùng cho tab Lịch sử.', ('audit_event', 'object_id'): 'Mã đối tượng bị tác động.',
    ('audit_event', 'error_code'): 'Mã lỗi khi `outcome` là `DENIED` hoặc `FAILED`.', ('audit_event', 'reason'): 'Lý do do người thao tác nhập (10 đến 500 ký tự khi bắt buộc, kiểm ở dịch vụ).',
    ('audit_event', 'purpose'): 'Mục đích khai báo của thao tác truy cập dữ liệu.',
    ('audit_anchor', 'seq_last'): '`seq` của bản ghi cuối được neo.', ('audit_anchor', 'anchored_at'): 'Thời điểm ký neo; duy nhất theo tenant.', ('audit_anchor', 'key_version'): 'Phiên bản khóa ký, trỏ `audit_signing_key`.',
    ('audit_anchor_publish', 'anchor_id'): 'Neo được công bố (một nơi công bố cho một neo).', ('audit_anchor_publish', 'worm_object'): 'Khóa đối tượng `anchors/{tenant}/{yyyy}/{MM}/{dd}/{HH}.json` ở WORM.',
    ('audit_anchor_publish', 'worm_written_at'): 'Thời điểm ghi WORM thành công.', ('audit_anchor_publish', 'siem_target_code'): 'Mục tiêu SIEM đã nhận neo.', ('audit_anchor_publish', 'siem_ack_at'): 'Thời điểm SIEM xác nhận đã nhận.',
    ('audit_worm_batch', 'seq_from'): '`seq` đầu của lô; liền sau `seq_to` của lô trước.', ('audit_worm_batch', 'seq_to'): '`seq` cuối của lô.', ('audit_worm_batch', 'record_count'): 'Số bản ghi, bằng `seq_to - seq_from + 1`, tối đa 50.000.',
    ('audit_worm_batch', 'manifest_key'): 'Khóa tệp `manifest.json` đi kèm (đếm, dải `seq`, băm, băm lô trước).', ('audit_worm_batch', 'size_bytes'): 'Kích thước tệp nén (byte).',
    ('audit_verification', 'from_seq'): '`seq` bắt đầu đoạn kiểm tra (neo xuất phát).', ('audit_verification', 'to_seq'): '`seq` cuối đoạn kiểm tra.', ('audit_verification', 'checked_count'): 'Số bản ghi đã tính lại băm.',
    ('audit_verification', 'worm_mode'): 'Cách đối chiếu bản WORM: mẫu 1%, đủ hoặc không.',
    ('audit_export', 'record_count'): 'Số bản ghi trong gói, tối đa 10.000.000.', ('audit_export', 'manifest_signature'): 'Chữ ký số của bảng kê gói (chữ ký thứ hai).', ('audit_export', 'key_version'): 'Phiên bản khóa ký đã dùng.',
    ('audit_export', 'expires_at'): 'Hạn tải của tệp (7 ngày); sau đó `EXPIRED`.', ('audit_export', 'cancelled_at'): 'Thời điểm người yêu cầu hủy.', ('audit_export', 'error_code'): 'Mã lỗi khi `FAILED` (ERR-13-025, 026).',
    ('audit_export', 'download_count'): 'Số lượt tải; mỗi lượt ghi bản ghi kiểm toán riêng.',
    ('audit_reconciliation', 'diff'): 'Cột sinh: chênh lệch còn lại; `MATCH` chỉ khi bằng 0, `MISMATCH` khi dương, `SURPLUS` khi âm.', ('audit_reconciliation', 'day'): 'Ngày đối chiếu theo múi giờ `Asia/Ho_Chi_Minh`.', ('audit_reconciliation', 'received'): 'Số bản ghi PH-13 đã nhận (`source_du`, `occurred_at` trong ngày).', ('audit_reconciliation', 'checked_at'): 'Lần đối chiếu gần nhất.',
    ('audit_partition', 'month'): 'Ngày đầu tháng của phân vùng.', ('audit_partition', 'partition_name'): '`audit_event_YYYYMM`.', ('audit_partition', 'record_count'): 'Số bản ghi lúc chốt.',
    ('audit_partition', 'sealed_at'): 'Thời điểm chốt `SEALED`.', ('audit_partition', 'archived_at'): 'Thời điểm tách và xóa phân vùng.',
    ('audit_quarantine', 'du_code'): 'DU nguồn.', ('audit_quarantine', 'topic'): 'Topic Kafka nhận bản ghi.', ('audit_quarantine', 'kafka_partition'): 'Partition Kafka (null với kênh dự phòng).',
    ('audit_quarantine', 'kafka_offset'): 'Offset Kafka (null với kênh dự phòng).', ('audit_quarantine', 'resolved_by'): 'Người xử lý bản cách ly.', ('audit_quarantine', 'resolved_at'): 'Thời điểm xử lý.',
    ('audit_source_grant', 'granted_by'): 'Người cấp quyền nguồn.', ('audit_source_grant', 'revoked_at'): 'Thời điểm thu hồi.',
    ('tenant_obs_config', 'provision_key'): '`Idempotency-Key` của lần khởi tạo.', ('tenant_obs_config', 'grafana_org_id'): 'Mã tổ chức Grafana của tenant.',
    ('runbook', 'title'): 'Tiêu đề runbook.', ('alert_rule', 'runbook_id'): 'Runbook bắt buộc; khóa ngoại kèm `tenant_id`.', ('alert_rule', 'notify_group'): 'Mã nhóm nhận thông báo (lịch trực).',
    ('notification_channel', 'last_test_at'): 'Lần kiểm tra kênh gần nhất.', ('notification_channel', 'last_test_ok'): 'Kết quả lần kiểm tra gần nhất.',
    ('alert', 'summary'): 'Tóm tắt từ chú thích của luật; không chứa dữ liệu cá nhân.', ('alert', 'started_at'): 'Thời điểm `FIRING` đầu tiên.', ('alert', 'ended_at'): 'Thời điểm đóng (`RESOLVED`).',
    ('alert', 'acknowledged_by'): 'Người xác nhận.', ('alert', 'acknowledged_at'): 'Thời điểm xác nhận (tính MTTA).', ('alert', 'silence_reason'): 'Lý do tạm ẩn, bắt buộc khi `SILENCED`.',
    ('alert', 'last_firing_at'): 'Lần cuối webhook báo `firing`.',
    ('alert_action', 'alert_id'): 'Cảnh báo được xử lý.', ('alert_action', 'at'): 'Thời điểm thao tác.', ('alert_action', 'cause'): 'Nguyên nhân (bắt buộc khi đóng thủ công).', ('alert_action', 'measure'): 'Hành động đã làm (bắt buộc khi đóng thủ công).',
    ('alert_action', 'silence_until'): 'Hạn tạm ẩn (khi `SILENCE`).', ('alert_action', 'silence_id'): 'Mã silence ở Alertmanager.', ('alert_action', 'reason'): 'Lý do tạm ẩn.', ('alert_action', 'level_to'): 'Cấp leo thang mới (khi `ESCALATE`).',
    ('alert_notification', 'alert_id'): 'Cảnh báo được thông báo.', ('alert_notification', 'channel_id'): 'Kênh gửi; khóa ngoại kèm `tenant_id`.', ('alert_notification', 'channel_code'): 'Mã kênh tại thời điểm gửi.',
    ('alert_notification', 'attempt'): 'Số lần đã thử, tối đa 10.', ('alert_notification', 'next_attempt_at'): 'Thời điểm thử kế tiếp khi `PENDING`.', ('alert_notification', 'sent_at'): 'Thời điểm gửi thành công.',
    ('detection_rule', 'source'): 'Nguồn dữ liệu của luật (Keycloak, APISIX, AUDIT…).', ('detection_rule', 'recipients'): 'Vai trò nhận cảnh báo (`SO`, `TA`, `PA`, `AU`).',
    ('detection_rule', 'tuned_by'): 'Người tinh chỉnh ngưỡng gần nhất.', ('detection_rule', 'tuned_at'): 'Thời điểm tinh chỉnh.', ('detection_rule', 'threshold'): 'Ngưỡng hiện hành (JSON); đổi ghi `SECURITY.RULE.TUNE`.',
    ('detection_rule', 'threshold_default'): 'Ngưỡng mặc định của D03-07 §7.5; bất biến.',
    ('security_alert', 'occurrence_count'): 'Số lần luật thỏa với cùng chủ thể khi còn mở.', ('security_alert', 'detected_at'): 'Lần phát hiện đầu.', ('security_alert', 'last_seen_at'): 'Lần phát hiện gần nhất.',
    ('security_alert', 'assignee'): 'Cán bộ ATTT đang điều tra.', ('security_alert', 'acknowledged_at'): 'Thời điểm tiếp nhận.', ('security_alert', 'verdict_note'): 'Ghi chú kết luận (bắt buộc khi `ACCEPTED_RISK`).',
    ('security_alert', 'closed_by'): 'Người đóng.', ('security_alert', 'closed_at'): 'Thời điểm đóng.',
    ('incident_report', 'report_code'): 'Mã báo cáo, không dùng lại.', ('incident_report', 'template'): 'Mã mẫu báo cáo.', ('incident_report', 'security_alert_id'): 'Cảnh báo an ninh gốc (có thể rỗng).',
    ('incident_report', 'detected_at'): 'Thời điểm phát hiện, mốc tính hạn 72 giờ.', ('incident_report', 'finalized_at'): 'Thời điểm chốt `FINAL`.', ('incident_report', 'finalized_by'): 'Người chốt.',
    ('siem_target', 'last_ok_at'): 'Lần gửi thử hoặc gửi thật thành công gần nhất.', ('dashboard_set', 'grafana_org_id'): 'Tổ chức Grafana của tenant.', ('dashboard_set', 'synced_at'): 'Lần đồng bộ thành công gần nhất.',
    ('dashboard_set', 'last_error'): 'Lỗi đồng bộ gần nhất.', ('saved_query', 'shared'): 'true: chia sẻ cho người dùng khác trong tenant.', ('saved_query', 'owner'): 'Chủ sở hữu (mã người dùng).',
    ('probe_definition', 'enabled'): 'Tắt thì ngừng kiểm tra (ví dụ tenant tạm ngừng).', ('pii_finding', 'scan_date'): 'Ngày quét.', ('pii_finding', 'logger'): 'Tên logger của DU nơi lọt giá trị.',
    ('pii_finding', 'occurrences'): 'Số lần phát hiện trong ngày; không lưu giá trị.', ('pii_finding', 'consecutive_days'): 'Số ngày liên tiếp tái phạm.', ('detect_cursor', 'processed_until'): 'Cửa sổ đã xử lý tới thời điểm này.',
    ('shedlock', 'name'): 'Tên khóa tác vụ.', ('shedlock', 'lock_until'): 'Khóa có hiệu lực tới.', ('shedlock', 'locked_at'): 'Thời điểm lấy khóa.', ('shedlock', 'locked_by'): 'Bản sao đang giữ khóa.',
    ('outbox', 'occurred_at'): 'Thời điểm phát sinh sự kiện.',
}
NHOM = {
    'ph13_audit': ('3.1', 'Nhóm kiểm toán (schema `ph13_audit`)',
                   'Mười bốn bảng của module `audit`: chuỗi băm và bản ghi chỉ-thêm, neo và nơi công bố, lô WORM, xác minh, xuất bằng chứng, '
                   'đối chiếu số lượng, vòng đời phân vùng, kho cách ly và bảng kỹ thuật. Mọi bảng có `tenant_id` và `FORCE ROW LEVEL SECURITY`, '
                   'riêng `audit_signing_key` dùng mẫu S (mọi tenant đọc khóa công khai nền tảng).'),
    'ph13_obs': ('3.2', 'Nhóm quan sát (schema `ph13_obs`)',
                 'Mười chín bảng của module `observability`: cấu hình tenant, luật và runbook, cảnh báo và vòng đời xử lý, thông báo và lịch trực, '
                 'luật phát hiện và cảnh báo an ninh, SIEM, dashboard, kiểm tra tổng hợp và các bảng kỹ thuật. Không bảng nào chứa số liệu quan sát '
                 'hay bí mật; mọi bảng có `tenant_id` và `FORCE ROW LEVEL SECURITY`.'),
}

def derive(t, col):
    """Ghi chú rút từ CHECK: tập giá trị, mẫu regex, khoảng, kiểu JSON."""
    ex = []
    for c2 in t['cons']:
        if c2['kind'] != 'CHECK':
            continue
        d = c2['def']
        m = re.search(r"\b%s IN \(([^)]*)\)" % col, d)
        if m:
            vals = [v.strip().strip("'") for v in m.group(1).split(',')]
            ex.append('Giá trị: ' + ', '.join('`%s`' % v for v in vals) + '.')
        m = re.search(r"\b%s ~ '([^']*)'" % col, d)
        if m and col not in ('tenant_id',):
            ex.append('Mẫu `%s`.' % m.group(1))
        m = re.search(r"\b%s BETWEEN (\d+) AND (\d+)" % col, d) or re.search(r"char_length\(btrim\(%s\)\) BETWEEN (\d+) AND (\d+)" % col, d)
        if m:
            ex.append('Từ %s đến %s%s.' % (m.group(1), m.group(2), ' ký tự' if 'char_length' in d else ''))
        if re.search(r"jsonb_typeof\(%s\) = 'object'" % col, d):
            ex.append('JSON object.')
        if re.search(r"jsonb_typeof\(%s\) = 'array'" % col, d):
            ex.append('JSON array.')
    return ' '.join(dict.fromkeys(ex))


out = []
cur_schema, k = None, 0
for t in D['tables']:
    s, name = t['schema'], t['name']
    if s != cur_schema:
        cur_schema, k = s, 0
        num, title, intro = NHOM[s]
        out.append(f'### {num}. {title}\n')
        out.append(intro + '\n')
    k += 1
    out.append(f"#### {NHOM[s][0]}.{k}. `{name}`\n")
    if (s, name) in D['tcomment']:
        out.append(D['tcomment'][(s, name)] + '\n')
    out.append('| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |')
    out.append('|---|---|---|---|---|')
    for c in t['cols']:
        note = D['ccomment'].get((s, name, c['name']), STD.get(c['name'], PER.get((name, c['name']), GENERIC.get(c['name'], ''))))
        if c['name'] not in STD:
            dv = derive(t, c['name'])
            if dv and dv not in note:
                note = (note + ' ' + dv).strip()
        note = note.replace('|', '\\|')
        if c['generated']:
            default = f"sinh: `{c['generated']}`"
        else:
            default = ('`' + c['default'] + '`') if c['default'] else ''
        out.append(f"| `{c['name']}` | `{c['type']}` | {'x' if c['notnull'] else ''} | {default} | {note} |")
    out.append('')
    out.append(f"{': Cột của bảng `' + s + '.' + name + '`'}\n")
sys.stdout.write('\n'.join(out))
