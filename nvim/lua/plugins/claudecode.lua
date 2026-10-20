return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  opts = {
    terminal = {
      provider = "snacks",
      snacks_win_opts = {
        position = "right",
        width = 80,
      },
    },
  },
  keys = {
    { "<leader>a", nil, desc = "AI/Claude Code" },
    {
      "<leader>ac",
      function()
        Snacks.terminal.toggle("claude", {
          win = {
            position = "right",
            width = 80,
          },
        })
      end,
      desc = "Toggle Claude (right panel)",
    },
    { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
    { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
    { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
    { "<leader>as", mode = "v", "<cmd>ClaudeCodeSend<cr>", desc = "Send selection to Claude" },
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
  },
}
