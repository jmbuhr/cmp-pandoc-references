local source = {}
local refs = require 'cmp-pandoc-references.references'

update_local_bib = require 'cmp-pandoc-references.update-local-bib'
-- Add command here to call the function on demand
vim.cmd("command! UpdateLocalBib lua update_local_bib.update_local_bib_file()")

source.new = function()
	return setmetatable({}, {__index = source})
end

-- Add another filetype if needed
source.is_available = function()
	return vim.o.filetype == 'pandoc' or vim.o.filetype == 'markdown' or vim.o.filetype == 'rmd' or vim.o.filetype == 'quarto'
end

source.get_keyword_pattern = function()
	return '[@][^[:blank:]]*'
end

source.complete = function(self, request, callback)
  local lines = vim.api.nvim_buf_get_lines(self.bufnr or 0, 0, -1, false)
  local entries = refs.get_entries(lines)

  if entries then
    self.items = entries
    callback(self.items)
  end
end

-- Add command here to call the function on demand
vim.cmd("command! UpdateLocalBib lua update_local_bib.update_local_bib_file")

return source

