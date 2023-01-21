local M = {}

M.sessions = {
  sessions_path = vim.fn.stdpath("data") .. "/sessions/",
  sessions_variable = "session",
}

M.autoload = false
M.autosave = true
M.autoswitch = {
  enable = false,
  exclude_ft = { "fugitive", "alpha", "NvimTree", "fzf", "qf" },
}

M.theme = "dropdown"
M.post_hook = nil

return M
