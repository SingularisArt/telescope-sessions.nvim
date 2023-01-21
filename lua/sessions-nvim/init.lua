local M = {}

local utils = require("sessions-nvim.utils")
local config = require("sessions-nvim.config")

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local sorters = require("telescope.sorters")
local previewers = require("telescope.previewers")
local themes = require("telescope.themes")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local user_config = {}

M.setup = function(user_opts)
  user_config = vim.tbl_deep_extend("force", config, user_opts or {})

  if user_config.autoload and vim.fn.argc() == 0 then
    M.autoload()
  end

  if user_config.autoload and vim.fn.argc() == 0 then
    M.autoload()
  end

  if user_config.autosave then
    local autosave_session = vim.api.nvim_create_augroup("AutosaveSession", {})
    vim.api.nvim_clear_autocmds({ group = autosave_session })
    vim.api.nvim_create_autocmd("VimLeave", {
      group = autosave_session,
      desc = "📌 save session on VimLeave",
      callback = function()
        M.autosave()
      end,
    })
  end
end

M.new = function()
  if vim.fn.finddir(user_config.sessions.sessions_path) == "" then
    print("sessions_path does not exist.")
    return
  end

  local function create_session(name)
    if next(vim.fs.find(name, { path = user_config.sessions.sessions_path })) == nil then
      vim.cmd.mksession({ args = { user_config.sessions.sessions_path .. name } })
      vim.g[user_config.sessions.sessions_variable] = vim.fs.basename(name)
      print("Saved in: " .. user_config.sessions.sessions_path .. name)
    else
      print("Session already exists.")
    end
  end

  if user_config.dressing then
    vim.ui.input({ prompt = "Session name: " }, function(name)
      if name ~= "" then
        create_session(name)
      end
    end)
  else
    local name = vim.fn.input("Session name: ")
    create_session(name)
  end
end

M.list = function()
  local sessions = utils.sessions(user_config.sessions.sessions_path)

  local opts = {
    sorting_strategy = "ascending",
    sorter = sorters.get_generic_fuzzy_sorter({}),
    prompt_title = "Sessions",

    attach_mappings = function(prompt_bufnr, map)
      map("i", "<CR>", M.load)
      map("i", "<C-d>", M.delete)
      return true
    end,

    finder = finders.new_table({
      results = sessions,
      entry_maker = function(item)
        return {
          value = item,
          ordinal = item,
          display = item,
        }
      end,
    }),

    previewer = previewers.new_buffer_previewer({
      title = "Files",
      define_preview = function(self, entry, _)
        local session = entry.value
        local files = utils.session_files(user_config.sessions.sessions_path .. session)

        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, files)
      end,
    }),
  }

  local picker_theme = themes["get_" .. user_config.theme]()
  return pickers.new(picker_theme, opts):find()
end

M.status = function()
  local cur_session = vim.g[user_config.sessions.sessions_variable]
  return cur_session ~= nil and cur_session or nil
end

M.update = function()
  local cur_session = vim.g[user_config.sessions.sessions_variable]
  if cur_session ~= nil then
    local confirm = vim.fn.confirm("Overwrite session?", "&Yes\n&No", 2)
    if confirm ~= 1 then
      return
    end

    vim.cmd.mksession({ args = { user_config.sessions.sessions_path .. cur_session }, bang = true })
    print("Updated session: " .. cur_session .. ".")
  else
    print("No session loaded.")
  end
end

M.load = function(prompt_bufnr)
  local selected = action_state.get_selected_entry()
  local session = user_config.sessions.sessions_path .. selected["display"]

  actions.close(prompt_bufnr)
  vim.cmd.source(session)
  vim.g[user_config.sessions.sessions_variable] = vim.fs.basename(session)
end

M.delete = function(prompt_bufnr)
  actions.move_selection_next(prompt_bufnr)

  local selected = action_state.get_selected_entry()
  local session = user_config.sessions.sessions_path .. selected["display"]

  os.remove(session)
  print("Deleted " .. session .. ".")
  if vim.g[user_config.sessions.sessions_variable] == vim.fs.basename(session) then
    vim.g[user_config.sessions.sessions_variable] = nil
  end
end

M.autosave = function()
  local cur_session = vim.g[user_config.sessions.sessions_variable]
  if cur_session ~= nil then
    vim.cmd.mksession({ args = { user_config.sessions.sessions_path .. cur_session }, bang = true })
  end
end

M.autoswitch = function()
  vim.cmd.write()
  M.autosave()
  vim.cmd.bufdo("e")
  local buf_list = vim.tbl_filter(function(buf)
    return vim.api.nvim_buf_is_valid(buf)
        and vim.api.nvim_buf_get_option(buf, "buflisted")
        and vim.api.nvim_buf_get_option(buf, "modifiable")
        and not utils.is_in_list(vim.api.nvim_buf_get_option(buf, "filetype"), config.autoswitch.exclude_ft)
  end, vim.api.nvim_list_bufs())
  for _, buf in pairs(buf_list) do
    vim.cmd("bd " .. buf)
  end
end

M.autoload = function()
  local session = utils.session_in_cwd(user_config.sessions.sessions_path)
  if session ~= nil then
    vim.cmd.source(user_config.sessions.sessions_path .. session)
    vim.g[user_config.sessions.sessions_variable] = vim.fs.basename(session)
  end
end

return M
