-- lua/settings/telescope.lua

local telescope = require('telescope')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')

-- Custom function to send selected entries to the quickfix list
local function send_to_qflist(prompt_bufnr)
  local picker = action_state.get_current_picker(prompt_bufnr)
  local entries = picker:get_multi_selection()

  if vim.tbl_isempty(entries) then
    -- If no entries are selected, use the current entry
    actions.smart_send_to_qflist(prompt_bufnr)
  else
    local qf_entries = {}
    for _, entry in ipairs(entries) do
      table.insert(qf_entries, {
        bufnr = entry.bufnr,
        lnum = entry.lnum,
        col = entry.col,
        text = entry.text,
        filename = entry.filename,
      })
    end
    vim.fn.setqflist(qf_entries)
    vim.cmd('copen')
  end
  actions.close(prompt_bufnr)
end

-- Map the custom function in Telescope mappings
telescope.setup({
  defaults = {
    mappings = {
      i = {
        ["<C-q>"] = send_to_qflist,
      },
      n = {
        ["<C-q>"] = send_to_qflist,
      },
    },
  },
})
