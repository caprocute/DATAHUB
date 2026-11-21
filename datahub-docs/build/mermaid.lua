-- Chuyển khối ```mermaid thành ảnh PNG bằng mmdc (@mermaid-js/mermaid-cli) nếu có.
-- Không có mmdc thì giữ nguyên khối mã để không làm hỏng bản xuất.
local outdir = os.getenv("DH_MERMAID_OUT") or "build/out/mermaid"
local has_mmdc = os.execute("command -v mmdc >/dev/null 2>&1")
local n = 0
function CodeBlock(el)
  if not el.classes:includes("mermaid") or not has_mmdc then return nil end
  n = n + 1
  local base = outdir .. "/" .. pandoc.utils.sha1(el.text)
  local src, png = base .. ".mmd", base .. ".png"
  local f = io.open(src, "w"); f:write(el.text); f:close()
  local ok = os.execute(string.format(
    "mmdc -q -i %q -o %q -b white -w 1600 -p build/puppeteer.json >/dev/null 2>&1", src, png))
  if not ok then return nil end
  return pandoc.Para({pandoc.Image({}, png)})
end
