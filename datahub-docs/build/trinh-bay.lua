-- Bộ lọc pandoc trình bày bản .docx theo quy chuẩn hồ sơ thiết kế (khuôn K-TRINH-BAY).
-- Việc làm:
--  1. Trang bìa và trang "Thông tin tài liệu" (thông tin chung, lịch sử phiên bản, ký duyệt)
--     dựng từ khối metadata; mục "Lịch sử phiên bản" ở cuối nguồn được chuyển lên đầu.
--  2. Bỏ tiêu đề cấp 1 của nguồn (đã có ở bìa), nâng các cấp còn lại lên một bậc.
--  3. Đánh số "Bảng n." và "Hình n."; bảng, sơ đồ chưa có chú thích lấy tên mục chứa nó.
--  4. Khối `::: dac-ta` và bảng "Trường | Nội dung" thành bảng đặc tả hai cột; các bước
--     "1. … 2. …" và ngoại lệ ngăn bằng "·" trong ô được tách thành danh sách.
--  5. Khối ```mermaid thành ảnh PNG bằng mmdc (nếu có), kèm chú thích hình.
--  6. Độ rộng cột bảng theo lượng chữ của từng cột.
-- Trang mục lục được chèn ở vị trí dấu [[MUC-LUC]]; hau_xu_ly.py chuyển mục lục của pandoc vào đó.

local stringify = pandoc.utils.stringify
local outdir = os.getenv("DH_MERMAID_OUT") or "build/out/mermaid"
local has_mmdc = os.execute("command -v mmdc >/dev/null 2>&1")
local puppeteer = os.getenv("DH_PUPPETEER_CFG") or "build/puppeteer.json"
local mermaid_cfg = os.getenv("DH_MERMAID_CFG") or "build/mermaid-config.json"

local so_bang, so_hinh = 0, 0
local muc_hien_tai = ""      -- tên mục gần nhất (đã bỏ số thứ tự)
local dem_trong_muc = { bang = 0, hinh = 0 }

------------------------------------------------------------------ tiện ích
local function para_style(style, inlines)
  return pandoc.Div({ pandoc.Para(inlines) }, { ["custom-style"] = style })
end
local function txt(s) return pandoc.Inlines(pandoc.Str(s)) end
local function page_break()
  return pandoc.RawBlock("openxml", '<w:p><w:r><w:br w:type="page"/></w:r></w:p>')
end
local function meta_str(m, k, default)
  local v = m[k]
  if v == nil then return default end
  local s = stringify(v)
  if s == "" then return default end
  return s
end
local function cell(blocks) return blocks end
local function bo_so_muc(s)
  -- "4.3. Máy trạng thái kết nối" -> "Máy trạng thái kết nối"; "FR-05-004 · Tạo" giữ nguyên
  s = s:gsub("^[%d%.]+%s+", "")
  s = s:gsub("^Nhóm%s+%a+%s+·%s+", "")
  return s
end

------------------------------------------------------------------ bảng đơn giản
local function bang_don(header, rows, widths, caption_inlines)
  local aligns, ws = {}, {}
  for i = 1, #widths do aligns[i] = pandoc.AlignDefault; ws[i] = widths[i] end
  local h = {}
  if header then for i, t in ipairs(header) do h[i] = { pandoc.Plain({ pandoc.Strong(txt(t)) }) } end end
  local r = {}
  for i, row in ipairs(rows) do
    r[i] = {}
    for j, c in ipairs(row) do
      if type(c) == "string" then r[i][j] = { pandoc.Plain(txt(c)) } else r[i][j] = c end
    end
  end
  local st = pandoc.SimpleTable(caption_inlines or {}, aligns, ws, h, r)
  return pandoc.utils.from_simple_table(st)
end

------------------------------------------------------------------ độ rộng cột
local function do_rong(tbl)
  local n = #tbl.colspecs
  if n < 2 then return end
  local tong, dai = {}, {}
  for i = 1, n do tong[i], dai[i] = 0, 0 end
  local function dem(row)
    for i, c in ipairs(row.cells) do
      if i <= n then
        local l = utf8.len(stringify(c.contents)) or #stringify(c.contents)
        tong[i] = tong[i] + math.min(l, 400)
        if l > dai[i] then dai[i] = l end
      end
    end
  end
  for _, row in ipairs(tbl.head.rows) do dem(row) end
  local so_dong = 0
  for _, body in ipairs(tbl.bodies) do
    for _, row in ipairs(body.body) do dem(row); so_dong = so_dong + 1 end
  end
  local w, s = {}, 0
  for i = 1, n do
    local tb = tong[i] / math.max(so_dong + 1, 1)
    w[i] = math.max(math.min(math.sqrt(tb) * 1.6 + math.sqrt(dai[i]) * 0.6, 40), 3.5)
    s = s + w[i]
  end
  for i = 1, n do tbl.colspecs[i][2] = w[i] / s end
end

------------------------------------------------------------------ tách bước, ngoại lệ trong ô
local function tach_buoc(inlines)
  -- tìm Str "1." ở đầu và các Str "k." đứng sau Space, tăng dần
  local ds, cur, ky_vong = {}, nil, 1
  if #inlines < 2 or inlines[1].t ~= "Str" or inlines[1].text ~= "1." then return nil end
  for i, el in ipairs(inlines) do
    local la_so = el.t == "Str" and el.text == (tostring(ky_vong) .. ".")
      and (i == 1 or inlines[i - 1].t == "Space")
    if la_so then
      cur = pandoc.Inlines({}); table.insert(ds, cur); ky_vong = ky_vong + 1
    elseif cur then
      if not (#cur == 0 and el.t == "Space") then cur:insert(el) end
    end
  end
  if #ds < 2 then return nil end
  local items = {}
  for _, it in ipairs(ds) do
    while #it > 0 and it[#it].t == "Space" do it:remove(#it) end
    table.insert(items, { pandoc.Plain(it) })
  end
  return pandoc.OrderedList(items)
end

local function tach_cham(inlines)
  -- "A: x · B: y" -> danh sách gạch đầu dòng
  local ds, cur = {}, pandoc.Inlines({})
  local co = false
  for i, el in ipairs(inlines) do
    if el.t == "Str" and el.text == "·" and i > 1 and inlines[i - 1].t == "Space" then
      table.insert(ds, cur); cur = pandoc.Inlines({}); co = true
    elseif not (#cur == 0 and el.t == "Space") then
      cur:insert(el)
    end
  end
  table.insert(ds, cur)
  if not co or #ds < 2 then return nil end
  local items = {}
  for _, it in ipairs(ds) do
    while #it > 0 and it[#it].t == "Space" do it:remove(#it) end
    if #it > 0 then table.insert(items, { pandoc.Plain(it) }) end
  end
  return pandoc.BulletList(items)
end

local function lam_dep_o(blocks)
  if #blocks ~= 1 or (blocks[1].t ~= "Plain" and blocks[1].t ~= "Para") then return blocks end
  local inl = blocks[1].content
  local l = tach_buoc(inl)
  if l then return { l } end
  l = tach_cham(inl)
  if l then return { l } end
  return blocks
end

------------------------------------------------------------------ bảng đặc tả
local function nhan(label)
  return { pandoc.Div({ pandoc.Plain({ pandoc.Strong(txt(label)) }) }, { ["custom-style"] = "Nhãn đặc tả" }) }
end

local function bang_dac_ta(cap)
  -- cap: danh sách {nhãn, blocks}
  local rows = {}
  for i, c in ipairs(cap) do rows[i] = { nhan(c[1]), c[2] } end
  local t = bang_don(nil, rows, { 0.24, 0.76 })
  return t
end

local function la_bang_truong_noi_dung(tbl)
  if #tbl.colspecs ~= 2 or #tbl.head.rows ~= 1 then return false end
  local h = tbl.head.rows[1].cells
  return stringify(h[1].contents) == "Trường" and stringify(h[2].contents) == "Nội dung"
end

local function chuyen_bang_truong(tbl)
  local cap = {}
  for _, body in ipairs(tbl.bodies) do
    for _, row in ipairs(body.body) do
      local c = row.cells
      table.insert(cap, { stringify(c[1].contents), lam_dep_o(c[2].contents) })
    end
  end
  return bang_dac_ta(cap)
end

local function div_dac_ta(div)
  local cap, cur = {}, nil
  for _, b in ipairs(div.content) do
    local mo = false
    if (b.t == "Para" or b.t == "Plain") and #b.content > 0 and b.content[1].t == "Strong" then
      local lab = stringify(b.content[1])
      if lab:match("[%.:]$") then
        lab = lab:gsub("[%.:]$", "")
        local rest = pandoc.Inlines({})
        for i = 2, #b.content do rest:insert(b.content[i]) end
        while #rest > 0 and (rest[1].t == "Space" or rest[1].t == "SoftBreak") do rest:remove(1) end
        cur = { lab, {} }
        table.insert(cap, cur)
        if #rest > 0 then table.insert(cur[2], pandoc.Para(rest)) end
        mo = true
      end
    end
    if not mo then
      if cur == nil then cur = { "", {} }; table.insert(cap, cur) end
      table.insert(cur[2], b)
    end
  end
  for _, c in ipairs(cap) do
    if #c[2] == 1 and c[2][1].t == "Para" then c[2] = { pandoc.Plain(c[2][1].content) } end
  end
  return bang_dac_ta(cap)
end

------------------------------------------------------------------ chú thích
local function chu_thich(loai, ten)
  local so
  if loai == "Bảng" then so_bang = so_bang + 1; so = so_bang else so_hinh = so_hinh + 1; so = so_hinh end
  local inl = pandoc.Inlines({ pandoc.Strong(txt(loai .. " " .. so .. ".")), pandoc.Space() })
  inl:extend(ten)
  return para_style(loai == "Bảng" and "Chú thích bảng" or "Chú thích hình", inl)
end

local function ten_mac_dinh(loai)
  local key = loai == "Bảng" and "bang" or "hinh"
  dem_trong_muc[key] = dem_trong_muc[key] + 1
  local t = muc_hien_tai ~= "" and muc_hien_tai or "Không tên"
  if dem_trong_muc[key] > 1 then t = t .. " (" .. dem_trong_muc[key] .. ")" end
  return txt(t)
end

------------------------------------------------------------------ mermaid
local function png_size(path)
  local f = io.open(path, "rb"); if not f then return nil end
  local d = f:read(24); f:close()
  if not d or #d < 24 then return nil end
  local function be(s) local a, b, c, e = s:byte(1, 4); return ((a * 256 + b) * 256 + c) * 256 + e end
  return be(d:sub(17, 20)), be(d:sub(21, 24))
end

local function mermaid(el)
  if not has_mmdc then return nil end
  os.execute("mkdir -p " .. outdir)
  local base = outdir .. "/" .. pandoc.utils.sha1(el.text)
  local src, png = base .. ".mmd", base .. ".png"
  local fp = io.open(png, "rb")
  if fp then fp:close() else
    local f = io.open(src, "w"); f:write(el.text); f:close()
    local cfg = io.open(mermaid_cfg, "r") and ("-c " .. mermaid_cfg) or ""
    local ok = os.execute(string.format(
      "mmdc -q -i %q -o %q -b white -s 2 -w 1400 %s -p %q >/dev/null 2>&1", src, png, cfg, puppeteer))
    if not ok then io.stderr:write("! Không vẽ được sơ đồ Mermaid (" .. src .. "), giữ khối mã\n"); return nil end
  end
  local w, h = png_size(png)
  local attr = {}
  if w then
    local cm = math.min(w / 2 / 96 * 2.54, 16.0)
    local cm_h = h / w * cm
    if cm_h > 21 then cm = cm * 21 / cm_h end
    attr = { width = string.format("%.1fcm", cm) }
  end
  local cap = el.attributes["caption"] and txt(el.attributes["caption"]) or ten_mac_dinh("Hình")
  return { para_style("Hình", { pandoc.Image({}, png, "", attr) }), chu_thich("Hình", cap) }
end

------------------------------------------------------------------ bìa và thông tin tài liệu
local function lay_lich_su(blocks)
  -- tìm mục "Lịch sử phiên bản" (cấp 2) và rút bảng của nó ra
  local out, lich_su, bo = {}, nil, false
  for _, b in ipairs(blocks) do
    if b.t == "Header" then
      if b.level <= 2 and stringify(b.content):match("^Lịch sử phiên bản") then bo = true
      elseif b.level <= 2 then bo = false end
    end
    if bo then
      if b.t == "Table" and not lich_su then lich_su = b end
    else
      table.insert(out, b)
    end
  end
  return out, lich_su
end

local function trang_bia(m)
  local ma = meta_str(m, "ma_tai_lieu", "")
  local ten = meta_str(m, "ten", meta_str(m, "title", ""))
  local b = {}
  table.insert(b, para_style("Bìa cơ quan", txt(meta_str(m, "co_quan", "CHỦ ĐẦU TƯ: ………………………………"))))
  table.insert(b, para_style("Bìa dự án", txt(meta_str(m, "du_an",
    "Dự án Xây dựng Nền tảng tích hợp, chia sẻ dữ liệu cấp tỉnh thế hệ mới (Datahub)"))))
  table.insert(b, para_style("Bìa loại", txt(meta_str(m, "loai_tai_lieu", "HỒ SƠ THIẾT KẾ HỆ THỐNG DATAHUB"))))
  table.insert(b, para_style("Bìa tiêu đề", txt(ten)))
  table.insert(b, para_style("Bìa mã", txt("Mã tài liệu: " .. ma)))
  local tom = meta_str(m, "mo_ta", nil)
  if tom then table.insert(b, para_style("Bìa mô tả", txt(tom))) end
  local rows = {
    { "Mã tài liệu", ma },
    { "Phiên bản", meta_str(m, "phien_ban", "0.1") },
    { "Trạng thái", meta_str(m, "trang_thai", "Dự thảo") },
    { "Ngày", meta_str(m, "ngay", "") },
    { "Đơn vị soạn thảo", meta_str(m, "don_vi_soan_thao", "Nhóm thiết kế Datahub") },
    { "Người đọc", meta_str(m, "nguoi_doc", "") },
  }
  local lq = meta_str(m, "tai_lieu_lien_quan", nil)
  if lq then table.insert(rows, { "Tài liệu liên quan", lq }) end
  local r2 = {}
  for i, r in ipairs(rows) do r2[i] = { nhan(r[1]), { pandoc.Plain(txt(r[2])) } } end
  table.insert(b, para_style("Bìa khoảng", txt(" ")))
  table.insert(b, bang_don(nil, r2, { 0.28, 0.72 }))
  table.insert(b, para_style("Bìa nơi ngày", txt(meta_str(m, "noi_ban_hanh", "Tháng " ..
    (meta_str(m, "ngay", ""):match("^%d+%-(%d+)") or "") .. "/" .. (meta_str(m, "ngay", ""):match("^(%d+)") or "")))))
  table.insert(b, page_break())
  return b
end

local function trang_thong_tin(m, lich_su_bang)
  local b = {}
  table.insert(b, para_style("Tiêu đề phụ lục đầu", txt("THÔNG TIN TÀI LIỆU")))
  table.insert(b, para_style("Tiêu đề nhỏ", txt("Lịch sử phiên bản")))
  if lich_su_bang then
    lich_su_bang.caption = { long = {}, short = nil }
    do_rong(lich_su_bang)
    table.insert(b, lich_su_bang)
  else
    table.insert(b, bang_don({ "Phiên bản", "Ngày", "Người thực hiện", "Nội dung thay đổi" },
      { { meta_str(m, "phien_ban", "0.1"), meta_str(m, "ngay", ""), "", "Bản đầu" } }, { 0.12, 0.16, 0.22, 0.5 }))
  end
  table.insert(b, para_style("Tiêu đề nhỏ", txt("Ký duyệt")))
  local kd = {}
  if m.ky_duyet and #m.ky_duyet > 0 then
    for _, k in ipairs(m.ky_duyet) do
      table.insert(kd, { stringify(k.vai_tro or ""), stringify(k.ho_ten or ""), stringify(k.chuc_vu or ""), "", "" })
    end
  else
    kd = { { "Soạn thảo", "", "", "", "" }, { "Kiểm tra", "", "", "", "" }, { "Phê duyệt", "", "", "", "" } }
  end
  table.insert(b, bang_don({ "Vai trò", "Họ và tên", "Chức vụ, đơn vị", "Chữ ký", "Ngày" }, kd,
    { 0.16, 0.24, 0.26, 0.18, 0.16 }))
  table.insert(b, para_style("Tiêu đề nhỏ", txt("Phân phối")))
  table.insert(b, bang_don({ "Nơi nhận", "Mục đích" }, {
    { "Hội đồng thẩm định", "Thẩm định thiết kế" },
    { "Chủ đầu tư, đơn vị chủ quản", "Phê duyệt, lưu hồ sơ" },
    { "Nhóm phát triển, kiểm thử, vận hành", "Hiện thực, kiểm thử, vận hành" },
  }, { 0.45, 0.55 }))
  table.insert(b, page_break())
  table.insert(b, para_style("Tiêu đề phụ lục đầu", txt("MỤC LỤC")))
  table.insert(b, pandoc.Para(txt("[[MUC-LUC]]")))
  table.insert(b, page_break())
  return b
end

------------------------------------------------------------------ duyệt tài liệu
function Pandoc(doc)
  local m = doc.meta
  local blocks, lich_su = lay_lich_su(doc.blocks)
  local out = {}
  for _, b in ipairs(trang_bia(m)) do table.insert(out, b) end
  for _, b in ipairs(trang_thong_tin(m, lich_su)) do table.insert(out, b) end

  local function xu_ly(list)
    local res = {}
    local i = 1
    while i <= #list do
      local b = list[i]
      if b.t == "Header" then
        if b.level == 1 then
          b = nil  -- tiêu đề tài liệu đã có ở bìa
        else
          b.level = b.level - 1
          muc_hien_tai = bo_so_muc(stringify(b.content))
          dem_trong_muc = { bang = 0, hinh = 0 }
        end
        if b then table.insert(res, b) end
      elseif b.t == "Div" and b.classes:includes("dac-ta") then
        table.insert(res, div_dac_ta(b))
      elseif b.t == "Div" then
        b.content = xu_ly(b.content); table.insert(res, b)
      elseif b.t == "CodeBlock" and b.classes:includes("mermaid") then
        local r = mermaid(b)
        if r then for _, x in ipairs(r) do table.insert(res, x) end else table.insert(res, b) end
      elseif b.t == "Table" then
        if la_bang_truong_noi_dung(b) then
          table.insert(res, chuyen_bang_truong(b))
        else
          local cap = b.caption.long and #b.caption.long > 0 and stringify(b.caption.long) ~= ""
          local ten = cap and b.caption.long[1].content or ten_mac_dinh("Bảng")
          b.caption = { long = {}, short = nil }
          do_rong(b)
          for _, body in ipairs(b.bodies) do
            for _, row in ipairs(body.body) do
              for _, c in ipairs(row.cells) do c.contents = lam_dep_o(c.contents) end
            end
          end
          table.insert(res, chu_thich("Bảng", ten))
          table.insert(res, b)
        end
      elseif b.t == "Para" and #b.content == 1 and b.content[1].t == "Image" then
        local img = b.content[1]
        local ten = #img.caption > 0 and img.caption or ten_mac_dinh("Hình")
        if not img.attributes.width then img.attributes.width = "16cm" end
        img.caption = {}
        table.insert(res, para_style("Hình", { img }))
        table.insert(res, chu_thich("Hình", ten))
      elseif b.t == "Figure" then
        local img = nil
        pandoc.walk_block(b, { Image = function(x) img = img or x end })
        local ten = stringify(b.caption.long) ~= "" and b.caption.long[1].content or ten_mac_dinh("Hình")
        if img then
          if not img.attributes.width then img.attributes.width = "16cm" end
          img.caption = {}
          table.insert(res, para_style("Hình", { img }))
        end
        table.insert(res, chu_thich("Hình", ten))
      else
        table.insert(res, b)
      end
      i = i + 1
    end
    return res
  end

  for _, b in ipairs(xu_ly(blocks)) do table.insert(out, b) end
  doc.blocks = out
  -- không để pandoc tự in khối tiêu đề
  doc.meta.title = nil; doc.meta.subtitle = nil; doc.meta.author = nil; doc.meta.date = nil
  return doc
end
