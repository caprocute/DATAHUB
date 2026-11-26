#!/usr/bin/env python3
"""Sinh bộ bảy tập tài liệu cho một phân hệ bằng Claude Agent SDK (chạy trên runner GitHub Actions).

Mỗi tập là một phiên agent riêng (quy tắc tối ưu token số 3): FRS → UC → SDD → CSDL → API → màn hình
→ test case, rồi một phiên rà chéo. Sau mỗi phiên: chạy kiem_tra_ma.py, commit, push nhánh để chạy lại
được từ chỗ dừng. Chi phí từng phiên ghi vào build/so-lieu-token/agent/PH{nn}.json.

Dùng: python3 datahub-docs/build/agent/sinh_phan_he.py --ph 02 [--tap frs,uc] [--model claude-sonnet-5-5]
      [--model-ra-soat claude-sonnet-5-5] [--ngan-sach-usd 25] [--nhanh <tên nhánh để push>]
Khóa API đọc từ biến môi trường ANTHROPIC_API_KEY (secret của Actions). Script không in khóa.
"""
from __future__ import annotations

import argparse
import asyncio
import json
import os
import pathlib
import re
import subprocess
import sys
import time

from claude_agent_sdk import AssistantMessage, ClaudeAgentOptions, ResultMessage, TextBlock, ToolUseBlock, query

GOC = pathlib.Path(__file__).resolve().parents[3]          # gốc repo
DOCS = GOC / "datahub-docs"
CHI_PHI_DIR = DOCS / "build/so-lieu-token/agent"

# Phân hệ được phép sinh. PH-04, 05, 07, 10, 19 đã có bộ (hoặc đang có luồng khác làm).
PHAN_HE = {
    "01": ("Kết nạp hệ thống thông tin", "ket-nap-httt"),
    "02": ("Danh mục dịch vụ", "danh-muc-dich-vu"),
    "03": ("Cổng API", "cong-api"),
    "06": ("Dữ liệu chủ", "du-lieu-chu"),
    "08": ("Chất lượng dữ liệu", "chat-luong-du-lieu"),
    "09": ("Quyền riêng tư", "quyen-rieng-tu"),
    "11": ("Quy trình liên thông", "quy-trinh-lien-thong"),
    "12": ("Định danh và phân quyền", "dinh-danh-phan-quyen"),
    "13": ("Giám sát và kiểm toán", "giam-sat-kiem-toan"),
    "14": ("Kết nối quốc gia", "ket-noi-quoc-gia"),
    "15": ("Cổng nhà phát triển", "cong-nha-phat-trien"),
    "16": ("Báo cáo chỉ tiêu", "bao-cao-chi-tieu"),
    "17": ("Trợ lý AI", "tro-ly-ai"),
    "18": ("Vận hành và xử lý lỗi", "van-hanh-xu-ly-loi"),
    "20": ("Quản trị tenant", "quan-tri-tenant"),
}

# tập: (tệp chính, khuôn, tệp mẫu PH-05, việc riêng)
TAP = {
    "frs": ("02-yeu-cau/frs/D02-03-PH{nn}-frs-{slug}.md", "K-FRS.md",
            "02-yeu-cau/frs/D02-03-PH05-frs-bo-dieu-hop.md",
            "Viết FRS: mọi FR dạng khối `::: dac-ta` 17 mục; NFR, BR; ma trận truy vết LGC → FR phủ HẾT các hàng "
            "hệ cũ của phân hệ trong D00-03 phần A và mọi FR cũ của docs/07-srs (bảng ánh xạ mã cũ → mã mới). "
            "Mục tiêu đo được, kiến trúc khái quát, sơ đồ Mermaid nhóm chức năng và trình tự."),
    "uc": ("02-yeu-cau/use-case/D02-04-PH{nn}-use-case-{slug}.md", "K-UC.md",
           "02-yeu-cau/use-case/D02-04-PH05-use-case-bo-dieu-hop.md",
           "Viết UC: mỗi UC khối 15 mục, sơ đồ use case tổng (Mermaid), truy vết UC ↔ FR. Đọc FRS của phân hệ "
           "này ở bảng danh sách FR (không đọc lại toàn văn)."),
    "sdd": ("03-thiet-ke/sdd/D03-02-PH{nn}-sdd-{slug}.md", "K-SDD.md",
            "03-thiet-ke/sdd/D03-02-PH05-sdd-bo-dieu-hop.md",
            "Viết SDD: thành phần (khối 10 mục), package `vn.datahub.{du}.{module}`, sơ đồ thành phần và trình tự "
            "cho các luồng chính, trạng thái, xử lý lỗi, cấu hình, khả năng mở rộng, ATTT (tham chiếu SEC-*)."),
    "csdl": ("03-thiet-ke/csdl/D03-03-PH{nn}-csdl-{slug}.md", "K-CSDL.md",
             "03-thiet-ke/csdl/D03-03-PH05-csdl-bo-dieu-hop.md",
             "Viết DDL PostgreSQL chạy được ở `03-thiet-ke/csdl/ph{nn}/ddl/ph{nn}_*.sql` (schema `ph{nn}_{ngắn}`, cột "
             "ngữ cảnh bắt buộc, RLS theo tenant), bài kiểm cô lập tenant ở `csdl/ph{nn}/test/`, rồi chạy thử bằng "
             "`psql \"$DH_PG_URL\" -v ON_ERROR_STOP=1 -f …` (biến DH_PG_URL có sẵn nếu runner có PostgreSQL). "
             "Đặc tả mỗi bảng khối 10 mục sinh từ DDL bằng công cụ `csdl/ph{nn}/tools/them_dac_ta_bang.py` "
             "(chép và chỉnh từ `csdl/ph19/tools/them_dac_ta_bang.py`). ERD Mermaid."),
    "api": ("03-thiet-ke/api/D03-04-PH{nn}-api-{slug}.md", "K-API.md",
            "03-thiet-ke/api/D03-04-PH05-api-bo-dieu-hop.md",
            "Viết `03-thiet-ke/api/ph{nn}/openapi-*.yaml` (OpenAPI 3.1, lỗi RFC 9457) và `asyncapi-*.yaml` "
            "(AsyncAPI 3.0) — có thể sinh bằng script như `api/ph05/tools/` — rồi sinh đặc tả endpoint bằng "
            "`python3 datahub-docs/build/tools/sinh_dac_ta_api.py`. Kiểm tra YAML nạp được, mọi API-, EVT-, ERR- "
            "định nghĩa đủ."),
    "mh": ("03-thiet-ke/uiux/D03-06-PH{nn}-man-hinh-{slug}.md", "K-MH.md",
           "03-thiet-ke/uiux/D03-06-PH05-man-hinh-bo-dieu-hop.md",
           "Viết màn hình: bảng đặc tả đầu mỗi màn, route, mẫu PTN, thành phần CMP và token đúng tên chuẩn "
           "D03-05 (không tự đặt), trạng thái, thông báo theo mã ERR, phím tắt, truy cập WCAG 2.2 AA. "
           "Sinh ảnh hi-fi mỗi màn: `03-thiet-ke/uiux/ph{nn}/hifi/gen_hifi.py` (chép cách làm của "
           "`uiux/ph19/hifi/`, dùng lại `hifi.css`) và chụp bằng `node shot.js` (Playwright có sẵn), nhúng PNG vào tập."),
    "tc": ("05-kiem-thu/test-case/D05-02-PH{nn}-test-case.md", "K-TC.md",
           "05-kiem-thu/test-case/D05-02-PH05-test-case.md",
           "Viết test case: kịch bản TS, mỗi ca một khối, phủ mọi FR/UC/API/UI và các ERR; UAT tương đương hệ cũ. "
           "Chép công cụ `05-kiem-thu/test-case/ph05/tools/` sang `ph{nn}/tools/` rồi cấp số TC, sinh ma trận, "
           "xlsx, Gherkin."),
    "ra-soat": (None, None, None,
                "Rà chéo cả bảy tập của phân hệ một lượt: mã dẫn chiếu hai chiều (FR ↔ UC ↔ API ↔ UI ↔ TC), mục bắt "
                "buộc theo khuôn, chú thích bảng và hình, câu thông báo khớp mã ERR, sơ đồ Mermaid hợp lệ (không `;` "
                "trong thông điệp sequence). Sửa trực tiếp lỗi tìm thấy; điều không tự sửa được ghi thành câu hỏi mở "
                "hoặc mục \"Đề nghị đồng bộ\"."),
}
THU_TU = ["frs", "uc", "sdd", "csdl", "api", "mh", "tc", "ra-soat"]

HE_THONG = """Bạn là kỹ sư viết tài liệu thiết kế cho dự án Datahub (LGSP thế hệ mới, đa tenant, cấp tỉnh). Bạn làm việc
không có người giám sát trên một runner CI; không ai trả lời câu hỏi. Viết tiếng Việt chuẩn, có dấu.

Quy tắc bắt buộc:
1. Chỉ tạo và sửa tệp của phân hệ PH-{nn} trong `datahub-docs/` (tập của phân hệ và thư mục `ph{nn}/` đi kèm).
   KHÔNG sửa tài liệu dùng chung (D00-*, D02-08, D03-01, README, khuôn, build/tools, kiem_tra_ngoai_le.txt) và
   KHÔNG đụng các phân hệ khác: các luồng khác chạy song song. Việc cần sửa ở tài liệu chung ghi vào mục
   "Đề nghị đồng bộ" cuối tập. Không tạo ADR mới (đề xuất ADR thì ghi ở "Đề nghị đồng bộ").
2. Đọc sổ tra cứu gọn `datahub-docs/00-chung/D00-04-so-tra-cuu-gon.md` và khuôn
   `datahub-docs/00-chung/khuon/K-TRINH-BAY.md` trước tiên. Chỉ mở tài liệu gốc (SRS, SAD, ADR, D03-07…) ở đúng mục
   cần, theo bảng "Mở khi cần" của D00-04. Mẫu thật là bộ PH-05: chỉ đọc những mục cần đối chiếu, dùng Grep/
   Read có offset thay vì đọc toàn văn tệp lớn.
3. Dùng đúng mã đã chốt (SEC-*, PERM-*, ROLE-*, CMP-*, token, PTN-*, Z0…Z7, ADR) — tra bằng Grep. Mã mới của
   phân hệ lấy theo dải ở D00-04 §3. Thiếu số liệu thật thì dùng giả định ghi rõ "giả định" kèm cơ sở; không để
   "TBD" ngoài mục Câu hỏi mở (mã Q{nn}-.. theo dải của tập).
4. Ghi tệp theo chương (mỗi lần Write/Edit một chương trọn vẹn), không nối từng đoạn nhỏ.
5. Trước khi kết thúc chạy `python3 datahub-docs/build/tools/kiem_tra_ma.py` và sửa hết lỗi MỚI do tệp của bạn
   gây ra (mã trùng, mã thiếu, liên kết hỏng).
6. Không in, không đọc, không ghi biến môi trường hay khóa bí mật. Không dùng git (script ngoài lo commit).
7. Chất lượng ngang bộ PH-05/PH-19: đủ mục bắt buộc, độ sâu đủ để kỹ sư vào làm ngay và hội đồng thẩm định đọc được.
Kết thúc bằng một đoạn tóm tắt ngắn: tệp đã viết, số mã chính (FR/UC/API/UI/TC…), câu hỏi mở đã thêm.
"""


def sh(*args: str, check: bool = True) -> subprocess.CompletedProcess:
    return subprocess.run(args, cwd=GOC, check=check, text=True, capture_output=True)


def doc_chi_phi(nn: str) -> dict:
    p = CHI_PHI_DIR / f"PH{nn}.json"
    return json.loads(p.read_text()) if p.exists() else {"phan_he": f"PH-{nn}", "phien": []}


def ghi_chi_phi(nn: str, d: dict) -> None:
    CHI_PHI_DIR.mkdir(parents=True, exist_ok=True)
    d["tong_usd"] = round(sum(p["chi_phi_usd"] for p in d["phien"]), 4)
    (CHI_PHI_DIR / f"PH{nn}.json").write_text(json.dumps(d, ensure_ascii=False, indent=2) + "\n")


def tom_tat(dong: str) -> None:
    print(dong, flush=True)
    s = os.environ.get("GITHUB_STEP_SUMMARY")
    if s:
        with open(s, "a") as f:
            f.write(dong + "\n")


def loi_bi_mat() -> bool:
    """Chặn commit nếu diff có dạng khóa Anthropic."""
    diff = sh("git", "diff", "--cached", check=False).stdout
    return bool(re.search(r"sk-ant-[A-Za-z0-9_-]{10,}", diff))


def commit_push(nn: str, tap: str, nhanh: str | None) -> None:
    sh("git", "add", "-A", "datahub-docs")
    if loi_bi_mat():
        sh("git", "reset", "-q")
        raise SystemExit("! Diff có chuỗi giống khóa API, dừng không commit.")
    if sh("git", "diff", "--cached", "--quiet", check=False).returncode == 0:
        return
    ten, _ = PHAN_HE[nn]
    sh("git", "commit", "-q", "-m", f"PH-{nn} {ten}: tập {tap} (sinh bằng Agent SDK trên Actions)")
    if nhanh:
        for i in range(4):
            if sh("git", "push", "-q", "origin", f"HEAD:{nhanh}", check=False).returncode == 0:
                return
            time.sleep(2 ** (i + 1))
        raise SystemExit("! Push thất bại 4 lần.")


def loi_nhac(nn: str, tap: str) -> str:
    ten, slug = PHAN_HE[nn]
    tep, khuon, mau, viec = TAP[tap]
    da_co = [THU_TU[i] for i in range(THU_TU.index(tap))]
    tep_truoc = [f"datahub-docs/{TAP[t][0].format(nn=nn, slug=slug)}" for t in da_co if TAP[t][0]]
    srs_cu = sorted(GOC.glob(f"docs/07-srs/SRS-PH-{nn}-*.md"))
    p = [f"Phân hệ: PH-{nn} {ten}. Phiên này: tập `{tap}`."]
    if tep:
        p.append(f"Tệp chính cần viết: `datahub-docs/{tep.format(nn=nn, slug=slug)}` (metadata, tiêu đề, "
                 f"tóm tắt cho hội đồng thẩm định, câu hỏi mở, lịch sử phiên bản bản 0.1 ngày hôm nay).")
        p.append(f"Khuôn: `datahub-docs/00-chung/khuon/{khuon}` và `K-TRINH-BAY.md`. "
                 f"Mẫu đối chiếu: `datahub-docs/{mau}`.")
    p.append("Việc: " + viec.replace("{nn}", nn))
    p.append("Nếu tệp chính đã có (lần chạy trước dừng giữa chừng), đọc mục lục của nó và viết tiếp phần còn thiếu, "
             "không viết lại từ đầu.")
    if tep_truoc:
        p.append("Các tập đã viết của phân hệ (chỉ đọc bảng tổng hợp, danh sách mã): " + ", ".join(f"`{t}`" for t in tep_truoc))
    p.append("Nguồn nghiệp vụ: SRS hệ thống `datahub-docs/02-yeu-cau/D02-02-srs.md` (mục của PH-" + nn + "), "
             "SAD `datahub-docs/03-thiet-ke/D03-01-sad.md` §4, kiểm kê hệ cũ D00-03 phần A (Grep `PH-" + nn + "`), "
             "D02-08 (quyền PERM-" + nn + "), BRD `datahub-docs/02-yeu-cau/brd/` nếu có"
             + (", SRS cũ của repo: " + ", ".join(f"`{s.relative_to(GOC)}`" for s in srs_cu) if srs_cu else "")
             + ". Tài liệu hệ cũ chi tiết (nếu cần) ở `docs/`.")
    return "\n\n".join(p)


async def chay_tap(nn: str, tap: str, model: str, ngan_sach: float, effort: str) -> dict:
    opts = ClaudeAgentOptions(
        system_prompt={"type": "preset", "preset": "claude_code", "append": HE_THONG.replace("{nn}", nn)},
        allowed_tools=["Read", "Write", "Edit", "Glob", "Grep", "Bash", "TodoWrite"],
        disallowed_tools=["WebFetch", "WebSearch", "Task", "Agent"],
        permission_mode="bypassPermissions",
        setting_sources=[],
        cwd=str(GOC),
        model=model,
        effort=effort,
        max_turns=400,
        max_budget_usd=ngan_sach,
    )
    bat_dau = time.time()
    kq: ResultMessage | None = None
    async for m in query(prompt=loi_nhac(nn, tap), options=opts):
        if isinstance(m, AssistantMessage):
            for b in m.content:
                if isinstance(b, ToolUseBlock):
                    arg = b.input.get("file_path") or b.input.get("pattern") or str(b.input.get("command", ""))[:120]
                    print(f"  · {b.name} {arg}", flush=True)
        elif isinstance(m, ResultMessage):
            kq = m
    u = (kq.usage or {}) if kq else {}
    return {
        "tap": tap, "model": model, "effort": effort,
        "chi_phi_usd": round(kq.total_cost_usd or 0, 4) if kq else 0,
        "so_luot": kq.num_turns if kq else 0,
        "phut": round((time.time() - bat_dau) / 60, 1),
        "ket_thuc": kq.subtype if kq else "khong-co-ket-qua",
        "token": {k: u.get(k) for k in ("input_tokens", "output_tokens", "cache_read_input_tokens",
                                         "cache_creation_input_tokens")},
        "tom_tat": (kq.result or "")[-1500:] if kq else "",
    }


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--ph", required=True)
    ap.add_argument("--tap", default=",".join(THU_TU))
    ap.add_argument("--model", default="claude-sonnet-5-5")
    ap.add_argument("--model-ra-soat", default="claude-sonnet-5-5")
    ap.add_argument("--effort", default="high")
    ap.add_argument("--ngan-sach-usd", type=float, default=25.0, help="trần chi phí cho cả phân hệ")
    ap.add_argument("--nhanh", default=None)
    a = ap.parse_args()
    nn = a.ph.zfill(2)
    if nn not in PHAN_HE:
        raise SystemExit(f"! PH-{nn} không nằm trong danh sách được sinh (đã có bộ hoặc luồng khác đang làm).")
    if not os.environ.get("ANTHROPIC_API_KEY"):
        raise SystemExit("! Thiếu ANTHROPIC_API_KEY.")

    cp = doc_chi_phi(nn)
    xong = {p["tap"] for p in cp["phien"] if p["ket_thuc"] == "success"}
    tom_tat(f"### PH-{nn} {PHAN_HE[nn][0]}\n")
    tom_tat("| Tập | Model | Chi phí US$ | Lượt | Phút | Kết thúc |\n|---|---|---|---|---|---|")
    for tap in [t for t in THU_TU if t in a.tap.split(",")]:
        if tap in xong:
            tom_tat(f"| {tap} | — | — | — | — | đã xong trước đó |")
            continue
        da_tieu = sum(p["chi_phi_usd"] for p in cp["phien"])
        con = a.ngan_sach_usd - da_tieu
        if con < 1:
            tom_tat(f"| {tap} | — | — | — | — | dừng: hết ngân sách ({da_tieu:.2f}/{a.ngan_sach_usd}) |")
            break
        model = a.model_ra_soat if tap == "ra-soat" else a.model
        print(f"== PH-{nn} tập {tap} ({model}, còn {con:.2f} US$)", flush=True)
        r = asyncio.run(chay_tap(nn, tap, model, con, a.effort))
        km = sh("python3", "datahub-docs/build/tools/kiem_tra_ma.py", check=False)
        r["kiem_tra_ma"] = (km.stdout.strip().splitlines() or [""])[-3:]
        cp["phien"].append(r)
        ghi_chi_phi(nn, cp)
        commit_push(nn, tap, a.nhanh)
        tom_tat(f"| {tap} | {model} | {r['chi_phi_usd']:.2f} | {r['so_luot']} | {r['phut']} | {r['ket_thuc']} |")
        if r["ket_thuc"] != "success":
            tom_tat(f"\nDừng ở tập {tap}: {r['ket_thuc']}. Chạy lại workflow để tiếp tục từ tập này.")
            break
    tom_tat(f"\n**Tổng PH-{nn}: {cp.get('tong_usd', 0):.2f} US$**\n")
    km = sh("python3", "datahub-docs/build/tools/kiem_tra_ma.py", check=False)
    print(km.stdout[-2000:])
    sys.exit(0)


if __name__ == "__main__":
    main()
