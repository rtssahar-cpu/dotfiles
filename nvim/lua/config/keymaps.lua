-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- ターミナル入力中からでも直接他のウィンドウへ移動する
vim.keymap.set("t", "<C-h>", "<cmd>wincmd h<cr>", { desc = "Go to Left Window" })
vim.keymap.set("t", "<C-j>", "<cmd>wincmd j<cr>", { desc = "Go to Lower Window" })
vim.keymap.set("t", "<C-k>", "<cmd>wincmd k<cr>", { desc = "Go to Upper Window" })
vim.keymap.set("t", "<C-l>", "<cmd>wincmd l<cr>", { desc = "Go to Right Window" })

-- Space + c + p で相対パスをクリップボードにコピー
vim.keymap.set("n", "<leader>cp", function()
  local path = vim.fn.expand("%")
  vim.fn.setreg("+", path)
  vim.notify('Copied: ' .. path)
end, { desc = "ファイルの相対パスをコピー" })

-- Space + c + Shift + p (cP) で絶対パスをクリップボードにコピー
vim.keymap.set("n", "<leader>cP", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  vim.notify('Copied: ' .. path)
end, { desc = "ファイルの絶対パスをコピー" })

-- ==========================================
-- Gitコマンド用の拡張設定
-- ==========================================

-- Gitリポジトリか判定するヘルパー関数
local function check_git()
  vim.fn.system("git rev-parse --is-inside-work-tree 2>/dev/null")
  if vim.v.shell_error ~= 0 then
    vim.notify("ここはGit管理下のディレクトリではありません", vim.log.levels.ERROR)
    return false
  end
  return true
end

-- <leader>g にはこのファイルで定義したショートカットのみを候補として表示したいので、
-- LazyVim / gitsigns がデフォルトで <leader>g 配下に登録するキーマップを先に削除する。
local default_git_keymaps = {
  { "n", "<leader>gg" },
  { "n", "<leader>gG" },
  { "n", "<leader>gL" },
  { "n", "<leader>gb" },
  { "n", "<leader>gf" },
  { "n", "<leader>gl" },
  { "n", "<leader>gB" },
  { "x", "<leader>gB" },
  { "n", "<leader>gY" },
  { "x", "<leader>gY" },
  { "n", "<leader>gd" },
  { "n", "<leader>gD" },
  { "n", "<leader>gi" },
  { "n", "<leader>gI" },
  { "n", "<leader>ghs" },
  { "x", "<leader>ghs" },
  { "n", "<leader>ghr" },
  { "x", "<leader>ghr" },
  { "n", "<leader>ghS" },
  { "n", "<leader>ghu" },
  { "n", "<leader>ghR" },
  { "n", "<leader>ghp" },
  { "n", "<leader>ghb" },
  { "n", "<leader>ghB" },
  { "n", "<leader>ghd" },
  { "n", "<leader>ghD" },
}
for _, k in ipairs(default_git_keymaps) do
  pcall(vim.keymap.del, k[1], k[2])
end

-- Space + g + A : 全てステージ
vim.keymap.set("n", "<leader>gA", function()
  if check_git() then vim.cmd("!git add .") end
end, { desc = "Git Add All" })

-- Space + g + C : メッセージ付きコミット
vim.keymap.set("n", "<leader>gC", function()
  if not check_git() then return end
  local msg = vim.fn.input("Commit message: ")
  if msg ~= "" then
    vim.cmd("!git commit -m '" .. msg .. "'")
    vim.notify("Committed: " .. msg)
  end
end, { desc = "Git Commit" })

-- Space + g + p : 通常プッシュ
-- -u は初回以降も無害（毎回 upstream を(再)設定するだけ）なので、常時これでOK
vim.keymap.set("n", "<leader>gp", function()
  if check_git() then vim.cmd("!git push -u origin HEAD") end
end, { desc = "Git Push" })

-- Space + g + P : 安全な強制プッシュ
vim.keymap.set("n", "<leader>gP", function()
  if check_git() then vim.cmd("!git push origin HEAD --force-with-lease --force-if-includes") end
end, { desc = "Git Push Force Safe" })

-- Space + g + f : fixupコミット（ハッシュ入力待ち）
vim.keymap.set("n", "<leader>gf", function()
  if not check_git() then return end
  -- コマンドラインに途中まで自動入力して待機
  vim.fn.feedkeys(":!git commit --fixup ")
end, { desc = "Git Commit Fixup..." })

-- Space + g + r : autosquashリベース（ブランチ名入力待ち）
vim.keymap.set("n", "<leader>gr", function()
  if not check_git() then return end
  vim.fn.feedkeys(":!git rebase -i --autosquash ")
end, { desc = "Git Rebase Autosquash..." })

-- Space + g + t : Gitツリー
-- :! だと noice.nvim のメッセージ/コマンドラインUIと干渉して複数行出力が
-- 表示されないことがあるため、lazygitと同じフローティングターミナルで表示する。
-- auto_close はデフォルトtrueで、一瞬で終わるコマンドだと開いた直後に
-- 自動で閉じてしまう（何も起きていないように見える）ので明示的にfalseにする。
-- (q で閉じられる)
vim.keymap.set("n", "<leader>gt", function()
  if check_git() then
    Snacks.terminal(
      { "git", "--no-pager", "log", "--graph", "--all", "--oneline", "--decorate" },
      { cwd = vim.fn.getcwd(), interactive = false, auto_close = false }
    )
  end
end, { desc = "Git Tree" })

-- Space + g + c : 直前のコミットにメッセージ変更なしで追加（amend）
vim.keymap.set("n", "<leader>gc", function()
  if check_git() then vim.cmd("!git commit --amend --no-edit") end
end, { desc = "Git Commit Amend (No Edit)" })

-- Space + g + b : ブランチ一覧を表示（フローティングターミナル、qで閉じる）
-- auto_close=false: 一瞬で終わるコマンドで自動的に閉じてしまわないようにする
vim.keymap.set("n", "<leader>gb", function()
  if check_git() then
    Snacks.terminal(
      { "git", "--no-pager", "branch", "-vv" },
      { cwd = vim.fn.getcwd(), interactive = false, auto_close = false }
    )
  end
end, { desc = "Git Branch List" })

-- Space + g + s : 既存ブランチへ switch（一覧から選択）
vim.keymap.set("n", "<leader>gs", function()
  if not check_git() then return end
  local branches = vim.fn.systemlist("git branch --format='%(refname:short)'")
  if vim.v.shell_error ~= 0 or #branches == 0 then
    vim.notify("ブランチが見つかりませんでした", vim.log.levels.ERROR)
    return
  end
  vim.ui.select(branches, { prompt = "Switch to branch:" }, function(choice)
    if choice then
      vim.cmd("!git switch " .. vim.fn.shellescape(choice))
    end
  end)
end, { desc = "Git Switch Branch" })

-- Space + g + S : 新規ブランチを作成して switch
vim.keymap.set("n", "<leader>gS", function()
  if not check_git() then return end
  local name = vim.fn.input("New branch name: ")
  if name ~= "" then
    vim.cmd("!git switch -c " .. vim.fn.shellescape(name))
  end
end, { desc = "Git Switch -c (New Branch)" })

-- Space + g + z : スタッシュ
vim.keymap.set("n", "<leader>gz", function()
  if check_git() then vim.cmd("!git stash") end
end, { desc = "Git Stash" })

-- Space + g + Z : スタッシュポップ
vim.keymap.set("n", "<leader>gZ", function()
  if check_git() then vim.cmd("!git stash pop") end
end, { desc = "Git Stash Pop" })

-- Space + g + g : Lazygit（現在のcwdで開く）
-- LazyVim標準の<leader>ggはcwdを無視してgit rootに固定されるため上書き。
-- Neo-treeの「.」で変更したcwdをそのまま使うようにする。
vim.keymap.set("n", "<leader>gg", function()
  Snacks.lazygit({ cwd = vim.fn.getcwd() })
end, { desc = "Lazygit (cwd)" })
