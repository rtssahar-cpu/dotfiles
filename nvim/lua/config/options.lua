-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
-- 追加: LazyVimの自動ルート判定よりも、カレントディレクトリ(CWD)を絶対的に優先する
vim.g.root_spec = { "cwd" }
