"""Mở bản .docx bằng LibreOffice (không giao diện), cập nhật mục lục và số trang, xuất PDF.
Bản PDF dùng để xem trước và gửi kèm hồ sơ. Số trang của từng mục được ghi ra <vào.docx>.so-trang.txt
để hau_xu_ly.py --so-trang điền sẵn vào mục lục của bản .docx.
Dùng: python3 build/cap_nhat_muc_luc.py <vào.docx> <ra.pdf>
Cần LibreOffice và mô-đun uno của Python hệ thống (/usr/bin/python3)."""
import os
import subprocess
import sys
import time

if "uno" not in sys.modules:
    try:
        import uno  # noqa: F401
    except ImportError:
        os.execv("/usr/bin/python3", ["/usr/bin/python3", *sys.argv])

import uno  # noqa: E402
from com.sun.star.beans import PropertyValue  # noqa: E402


def prop(name, value):
    p = PropertyValue()
    p.Name, p.Value = name, value
    return p


def main():
    src, pdf = os.path.abspath(sys.argv[1]), os.path.abspath(sys.argv[2])
    port = 2002 + os.getpid() % 1000
    proc = subprocess.Popen(["soffice", "--headless", "--invisible", "--nologo", "--norestore",
                             f"-env:UserInstallation=file:///tmp/lo-dh-{port}",
                             f"--accept=socket,host=127.0.0.1,port={port};urp;"],
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        local = uno.getComponentContext()
        resolver = local.ServiceManager.createInstanceWithContext("com.sun.star.bridge.UnoUrlResolver", local)
        ctx = None
        for _ in range(60):
            try:
                ctx = resolver.resolve(f"uno:socket,host=127.0.0.1,port={port};urp;StarOffice.ComponentContext")
                break
            except Exception:
                time.sleep(0.5)
        if ctx is None:
            raise SystemExit("Không kết nối được LibreOffice")
        desktop = ctx.ServiceManager.createInstanceWithContext("com.sun.star.frame.Desktop", ctx)
        doc = desktop.loadComponentFromURL(uno.systemPathToFileUrl(src), "_blank", 0, (prop("Hidden", True),))
        idx = doc.getDocumentIndexes()
        for _ in range(2):  # lần hai để số trang ổn định sau khi mục lục dài ra
            for i in range(idx.getCount()):
                idx.getByIndex(i).update()
            doc.refresh()
        doc.storeToURL(uno.systemPathToFileUrl(pdf), (prop("FilterName", "writer_pdf_Export"),))
        # ghi số trang của từng mục để hau_xu_ly.py điền vào mục lục của bản .docx
        if idx.getCount():
            with open(src + ".so-trang.txt", "w", encoding="utf-8") as f:
                f.write(idx.getByIndex(0).getAnchor().getString())
        doc.close(True)
    finally:
        proc.terminate()


if __name__ == "__main__":
    main()
