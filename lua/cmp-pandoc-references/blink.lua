-- Docs: https://cmp.saghen.dev/development/source-boilerplate.html
--- @module 'blink.cmp'
--- @class blink.cmp.Source
local source = {}
local refs = require("cmp-pandoc-references.references")

function source.new(opts)
  local self = setmetatable({}, { __index = source })
  self.opts = opts
  return self
end

function source:enabled()
  return vim.o.filetype == "pandoc"
    or vim.o.filetype == "markdown"
    or vim.o.filetype == "rmd"
    or vim.o.filetype == "quarto"
end

function source:get_trigger_characters()
  return { "@" }
end

function source:get_completions(ctx, callback)
  local lines = vim.api.nvim_buf_get_lines(ctx.bufnr or 0, 0, -1, false)

  local blink = require("blink.cmp.types")
  local fields = {
    entry_kind = blink.CompletionItemKind.Reference,
    documentation_kind = "markdown",
  }
  local entries = refs.get_entries(lines, fields)

  --- @type lsp.CompletionItem[]
  local items = {}
  if entries then
    items = entries
  end

  callback({
    items = items,
    is_incomplete_backward = false,
    is_incomplete_forward = false,
  })
  return function() end
end

-- (Optional) Before accepting the item or showing documentation, blink.cmp will call this function
-- function source:resolve(item, callback)
--   item = vim.deepcopy(item)
--   callback(item)
-- end

-- Called immediately after applying the item's textEdit/insertText
function source:execute(ctx, item, callback, default_implementation)
  -- By default, your source must handle the execution of the item itself,
  -- but you may use the default implementation at any time
  default_implementation()

  -- The callback _MUST_ be called once
  callback()
end

return source
