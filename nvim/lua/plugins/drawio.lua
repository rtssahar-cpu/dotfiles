-- *.drawio を開くと PNG に変換して snacks.image で表示する。
-- 変換には draw.io デスクトップ版の CLI を使う（ヘッドレス環境なので xvfb-run 経由）。
-- 画像の転送は kitty graphics protocol（WezTerm 対応、SSH 越しでも可）。
--
-- バッファ内のキー:
--   r  再変換して再表示（別の場所で編集した後など）
--   ]p / [p  次 / 前のページ
--   X  XML として開き直す（元に戻すときは :e）

local M = {}

---@param buf integer
---@param lines string[]
local function set_text(buf, lines)
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].modified = false
end

---@param src string
---@param page integer 0 始まり
local function cache_path(src, page)
  local stat = vim.uv.fs_stat(src)
  local key = vim.fn.sha256(src .. ":" .. (stat and stat.mtime.sec or 0) .. ":" .. page)
  local dir = vim.fn.stdpath("cache") .. "/drawio"
  vim.fn.mkdir(dir, "p")
  return dir .. "/" .. key:sub(1, 16) .. ".png"
end

---@param buf integer
---@param force? boolean キャッシュを無視して再変換
function M.render(buf, force)
  local src = vim.api.nvim_buf_get_name(buf)
  local page = vim.b[buf].drawio_page or 0
  local out = cache_path(src, page)

  local function show()
    if vim.api.nvim_buf_is_valid(buf) then
      Snacks.image.buf.attach(buf, { src = out })
    end
  end

  if not force and vim.uv.fs_stat(out) then
    return show()
  end

  if vim.fn.executable("drawio") == 0 then
    return set_text(buf, { "drawio コマンドが見つかりません。setup.sh で draw.io をインストールしてください。" })
  end

  set_text(buf, { ("Rendering %s (page %d) ..."):format(vim.fn.fnamemodify(src, ":t"), page + 1) })
  local cmd = { "drawio", "--no-sandbox", "--disable-gpu", "-x", "-f", "png", "-s", "2" }
  -- draw.io v27.0.2 以降の --page-index は 1 始まり
  vim.list_extend(cmd, { "--page-index", tostring(page + 1), "-o", out, src })
  if vim.fn.executable("xvfb-run") == 1 then
    cmd = vim.list_extend({ "xvfb-run", "-a" }, cmd)
  end

  vim.system(cmd, { text = true }, function(res)
    vim.schedule(function()
      if res.code ~= 0 or not vim.uv.fs_stat(out) then
        local msg = vim.trim((res.stderr or "") .. "\n" .. (res.stdout or ""))
        set_text(buf, vim.list_extend({ "draw.io の変換に失敗しました:" }, vim.split(msg, "\n")))
        return
      end
      show()
    end)
  end)
end

---@param buf integer
---@param delta integer
function M.page(buf, delta)
  local page = math.max(0, (vim.b[buf].drawio_page or 0) + delta)
  vim.b[buf].drawio_page = page
  M.render(buf)
end

---@param buf integer
function M.open_xml(buf)
  local lines = vim.fn.readfile(vim.api.nvim_buf_get_name(buf))
  Snacks.image.placement.clean(buf)
  -- 編集時に r などが通常の動作をするよう、画像用のキーを外す
  for _, lhs in ipairs({ "r", "]p", "[p", "X" }) do
    pcall(vim.keymap.del, "n", lhs, { buffer = buf })
  end
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modified = false
  vim.bo[buf].filetype = "xml"
  vim.b[buf].drawio_xml = true
end

function M.setup()
  local group = vim.api.nvim_create_augroup("drawio_preview", { clear = true })

  vim.api.nvim_create_autocmd("BufReadCmd", {
    group = group,
    pattern = "*.drawio",
    callback = function(e)
      local buf = e.buf
      vim.b[buf].drawio_xml = false
      vim.bo[buf].swapfile = false
      vim.bo[buf].buftype = "acwrite"
      local map = function(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, { buffer = buf, desc = desc })
      end
      map("r", function() M.render(buf, true) end, "draw.io: re-render")
      map("]p", function() M.page(buf, 1) end, "draw.io: next page")
      map("[p", function() M.page(buf, -1) end, "draw.io: prev page")
      map("X", function() M.open_xml(buf) end, "draw.io: open as XML")
      M.render(buf)
    end,
  })

  -- 画像表示中は保存しない。XML モードのときだけ書き戻す。
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    group = group,
    pattern = "*.drawio",
    callback = function(e)
      if vim.b[e.buf].drawio_xml then
        vim.fn.writefile(vim.api.nvim_buf_get_lines(e.buf, 0, -1, false), e.file)
      end
      vim.bo[e.buf].modified = false
    end,
  })
end

return {
  {
    "folke/snacks.nvim",
    opts = {
      image = { enabled = true },
    },
    init = function()
      M.setup()
    end,
  },
}
