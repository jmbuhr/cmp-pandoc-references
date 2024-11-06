local Client = {}
local ms = vim.lsp.protocol.Methods
local refs = require 'cmp-pandoc-references.references'

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('blink.cmp').get_lsp_capabilities(capabilities)

local root_dir = function(_, bufnr)
  return vim.fs.root(bufnr or 0, {
    ".git",
    "_quarto.yml",
    "*.bib",
  })
end

Client.start = function()
  local client_id = vim.lsp.start({
    name = 'references',
    capabilities = capabilities,
    cmd = function(dispatchers)
      local members = {
        ---@param method string lsp request method. One of ms
        ---@param params table params passed from nvim with the request
        ---@param handler function function(err, response, ctx, conf)
        ---@param _notify_callback function notify_reply_callback function. Not currently used
        request = function(method, params, handler, _notify_callback)
          if method == ms.initialize then
            local completion_options = {
              triggerCharacters = { "\\@" },
              resolveProvider = true,
            }
            local initializeResult = {
              capabilities = {
                completionProvider = completion_options,
              },
              serverInfo = {
                name = "pandoc-references",
                version = "1.0.0",
              },
            }
            handler(nil, initializeResult)
            return
          end
          if method == ms.textDocument_completion then
            local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
            local entries = refs.get_entries(lines)
            local completionResult = {
              isComplete = true,
              items = {}
            }

            for _, entry in ipairs(entries) do
              local label = entry.label
              table.insert(completionResult.items, {
                data = {
                  position = params.position,
                  symbolLabel = "ref",
                  uri = params.textDocument.uri,
                },
                kind = 18,
                label = label
              })
            end

            handler(nil, completionResult)
          end
        end,
        notify = function(_, _) end,
        is_closing = function() end,
        terminate = function() end,
      }
      return members
    end,
    init_options = {},
    before_init = function(params, config) end,
    on_init = function(client, initialize_result) end,
    root_dir = root_dir(),
    on_exit = function(code, signal, client_id) end,
  })
  return client_id
end

return Client
