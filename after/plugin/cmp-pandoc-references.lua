-- Check if cmp is installed before attempting to use it
-- We might only be the source for blink.cmp
local ok, cmp = pcall(require, 'cmp')
if ok then
  cmp.register_source('pandoc_references', require('cmp-pandoc-references').new())
end
