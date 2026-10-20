return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  version = false, -- 常に最新を使用（"*" を指定しないこと）
  build = "bash ./build.sh", -- ビルド済みバイナリを取得（cargo 不要）
  opts = {
    provider = "claude",
    -- <leader>a は claudecode.nvim が使うため、avante は <leader>v に寄せる
    mappings = {
      ask = "<leader>va",
      new_ask = "<leader>vn",
      zen_mode = "<leader>vz",
      edit = "<leader>ve",
      refresh = "<leader>vr",
      focus = "<leader>vf",
      stop = "<leader>vS",
      toggle = {
        default = "<leader>vt",
        debug = "<leader>vd",
        selection = "<leader>vC",
        suggestion = "<leader>vs",
        repomap = "<leader>vR",
      },
      files = {
        add_current = "<leader>vc",
        add_all_buffers = "<leader>vB",
      },
      select_model = "<leader>v?",
      select_history = "<leader>vh",
      select_acp_model = "<leader>vM",
      select_acp_mode = "<leader>vm",
    },
  },
  keys = {
    { "<leader>v", nil, desc = "Avante" },
  },
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-tree/nvim-web-devicons",
    -- 最新版の avante が要求する依存（:Avante コマンドの解析に使用）
    { "ColinKennedy/mega.cmdparse", dependencies = { "ColinKennedy/mega.logging" } },
  },
}
