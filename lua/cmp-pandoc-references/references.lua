local cmp = require("cmp")

--- @type lsp.CompletionItem[]
local entries = {}
local M = {}
local last_log_time = 0
local LOG_THRESHOLD = 900 -- seconds (15 minutes)

-- (Crudely) Locates the bibliography
local function locate_bib(lines)
	for _, line in ipairs(lines) do
		local location = string.match(line, [[bibliography:[ "']*([%w./%-\]+)["' ]*]])
		if location then
			return location
		end
	end
	-- no bib locally defined
	-- test for quarto project-wide definition
	local fname = vim.api.nvim_buf_get_name(0)
	local root = require("lspconfig.util").root_pattern("_quarto.yml")(fname)
	if root then
		local file = root .. "/_quarto.yml"
		for line in io.lines(file) do
			local location = string.match(line, "bibliography: (%g+)")
			if location then
				return location
			end
		end
	end
end

local function sanitize_path(path)
	-- Sanitize the path: remove quotes and trim whitespace
	-- This duplicates some functionality from locate_quarto_bib
	path = path:gsub('^%s*["]?(.-)["\']?%s*$', "%1")
	-- Convert escaped spaces to regular spaces
	path = path:gsub("\\ ", " ")
	-- Unescape backslashes
	path = path:gsub('\\([/"])', "%1")
	return path
end

-- Determine if we should log a message
local function should_log()
	local current_time = os.time()
	if current_time - last_log_time >= LOG_THRESHOLD then
		last_log_time = current_time
		return true
	end
	return false
end

--- Resolves bibliography file path from string or function
--- @param lines table The lines of the current buffer to parse
--- @return string|nil Absolute path to bibliography file or nil if not found
local function get_bib_path(lines)
	-- locate bib reference as before
	local initial_bib = locate_bib(lines)
	-- return nil and log if bib not specified
	if not initial_bib then
		if should_log() then
			vim.notify(
				"cmp-pandoc-references: No bibliography file specification found in document",
				vim.log.levels.DEBUG
			)
		end
		return nil
	end
	-- Sanitize and expand the path
	local sanitized_path = sanitize_path(initial_bib)
	-- Try direct, sanitized, path first
	local direct_path = vim.fn.expand(sanitized_path)
	if vim.fn.filereadable(direct_path) == 1 then
		return vim.fn.fnamemodify(direct_path, ":p")
	end
	-- Try relative to buffer directory
	local buf_dir = vim.fn.expand("%:p:h")
	local full_path = buf_dir .. "/" .. sanitized_path
	full_path = vim.fn.expand(full_path)
	if vim.fn.filereadable(full_path) == 1 then
		return vim.fn.fnamemodify(full_path, ":p")
	end
	-- If we get here, no readable file was found
	if should_log() then
		vim.notify(
			string.format(
				"cmp-pandoc-references: Bibliography file not found. Tried:\n- %s\n- %s",
				direct_path,
				full_path
			),
			vim.log.levels.WARN
		)
	end
	return nil
end

-- Remove newline & excessive whitespace
local function clean(text)
	if text then
		text = text:gsub("\n", " ")
		return text:gsub("%s%s+", " ")
	else
		return text
	end
end

-- Parses the .bib file, formatting the completion item
-- Adapted from http://rgieseke.github.io/ta-bibtex/
local function parse_bib(filename)
	local file = io.open(filename, "rb")
	if file == nil then
		if should_log() then
			vim.notify(string.format("Unable to open bibliography file at: %s", filename), vim.log.levels.WARN)
		end
		return
	end
	local bibentries = file:read("*all")
	file:close()
	for bibentry in bibentries:gmatch("@.-\n}\n") do
		local entry = {}

		local title = clean(bibentry:match('title%s*=%s*["{]*(.-)["}],?')) or ""
		local author = clean(bibentry:match('author%s*=%s*["{]*(.-)["}],?')) or ""
		local year = bibentry:match('year%s*=%s*["{]?(%d+)["}]?,?') or ""

		local doc = { "**" .. title .. "**", "", "*" .. author .. "*", year }

		--- @type lsp.CompletionItem
		local entry = {
			label = "@" .. bibentry:match("@%w+{(.-),"),
			kind = cmp.lsp.CompletionItemKind.Reference,
			insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
			documentation = {
				kind = cmp.lsp.MarkupKind.Markdown,
				value = table.concat(doc, "\n"),
			},
		}

		table.insert(entries, entry)
		::continue::
	end
end

-- Parses the references in the current file, formatting for completion
local function parse_ref(lines)
	local words = table.concat(lines, "\n")
	for ref in words:gmatch("{#(%a+[:%-][%w_-]+)") do
		local entry = {}
		entry.label = "@" .. ref
		entry.kind = cmp.lsp.CompletionItemKind.Reference
		table.insert(entries, entry)
	end
	for ref in words:gmatch("#| label: (%a+[:%-][%w_-]+)") do
		local entry = {}
		entry.label = "@" .. ref
		entry.kind = cmp.lsp.CompletionItemKind.Reference
		table.insert(entries, entry)
	end
end

-- Returns the entries as a table, clearing entries beforehand
function M.get_entries(lines)
	local location = get_bib_path(lines)
	entries = {}

	entries = {}

	if location and vim.fn.filereadable(location) == 1 then
		parse_bib(location)
	end
	parse_ref(lines)

	return entries
end

return M
