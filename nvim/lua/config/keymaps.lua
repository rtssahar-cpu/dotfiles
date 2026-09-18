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

-- Space + g + p : 通常プッシュ（初回作成にも対応）
vim.keymap.set("n", "<leader>gp", function()
  if check_git() then vim.cmd("!git push -u origin HEAD") end
end, { desc = "Git Push (初回対応)" })

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

-- Space + g + t : Gitツリー（ページャーを無効化して表示）
vim.keymap.set("n", "<leader>gt", function()
  if check_git() then vim.cmd("!git --no-pager log --graph --all --oneline --decorate") end
end, { desc = "Git Tree" })

-- Space + g + g : Lazygit（現在のcwdで開く）
-- LazyVim標準の<leader>ggはcwdを無視してgit rootに固定されるため上書き。
-- Neo-treeの「.」で変更したcwdをそのまま使うようにする。
vim.keymap.set("n", "<leader>gg", function()
  Snacks.lazygit({ cwd = vim.fn.getcwd() })
end, { desc = "Lazygit (cwd)" })
