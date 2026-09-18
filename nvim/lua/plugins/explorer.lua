-- <leader>e が開くのは neo-tree ではなく Snacks Explorer。
-- 隠しファイル(dotfiles)と .gitignore されたファイルは別々のトグル(H / I)で、
-- どちらもデフォルトで表示するようにする。
return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        explorer = {
          hidden = true,
          ignored = true,
        },
      },
    },
  },
}
