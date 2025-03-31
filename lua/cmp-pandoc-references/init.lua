local source = {}
local refs = require("cmp-pandoc-references.references")

source.new = function()
  return setmetatable({}, { __index = source })
end

-- Add another filetype if needed
source.is_available = function()
  return vim.o.filetype == "pandoc"
    or vim.o.filetype == "markdown"
    or vim.o.filetype == "rmd"
    or vim.o.filetype == "quarto"
end

source.get_keyword_pattern = function()
  return "[@][^[:blank:]]*"
end

source.complete = function(self, request, callback)
  local lines = vim.api.nvim_buf_get_lines(self.bufnr or 0, 0, -1, false)

  local cmp = require("cmp")
  local fields = {
    entry_kind = cmp.lsp.CompletionItemKind.Reference,
    documentation_kind = cmp.lsp.MarkupKind.Markdown,
  }
  local entries = refs.get_entries(lines, fields)

  if entries then
    self.items = entries
    callback(self.items)
  end
end

return source
