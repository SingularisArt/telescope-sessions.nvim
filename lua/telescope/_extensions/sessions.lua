local has_telescope, telescope = pcall(require, "telescope")
local sessions = require("sessions-nvim")

if not has_telescope then
  error("This plugins requires nvim-telescope/telescope.nvim")
end

return telescope.register_extension({
  setup = function(ext_config)
    sessions.setup(ext_config)
  end,

  exports = {
    new = sessions.new,
    list = sessions.list,
    update = sessions.update,
  },
})
