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
      actions = {
        -- "." (デフォルトの explorer_focus) を上書き。
        -- Snacks Explorerは元々 DirChanged を監視して自動で
        -- picker:set_cwd()+picker:find() を行う仕組みを持っているので、
        -- ここで自分でも set_cwd/find を呼ぶと二重に走ってしまい
        -- (Shift+Hでの隠しファイル表示が反映されない不具合の原因だった)、
        -- Vim本体のCWDを変えるだけにして反映は内部の仕組みに任せる。
        explorer_focus = function(picker)
          local dir = picker:dir()
          if not dir then
            return
          end
          vim.fn.chdir(dir)
          vim.notify("CWD => " .. dir, vim.log.levels.INFO, { title = "Explorer" })
        end,
      },
    },
  },
}
