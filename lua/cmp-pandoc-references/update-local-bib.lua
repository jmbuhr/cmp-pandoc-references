
local M = {}

-- Function to extract unique citation keys from the buffer
local function extract_citation_keys(file_path)
    local citation_keys = {}
    for line in io.lines(file_path) do
        for key in line:gmatch('@[%w_]+[^][ ;,.]+') do
            if not (key:match('^@fig%-') or key:match('^@tbl%-')) then
                citation_keys[key] = true
            end
        end
    end
    local keys = {}
    for key in pairs(citation_keys) do
        table.insert(keys, key)
    end
    table.sort(keys)
    return keys
end

-- Function to check if references.bib file exists and create it if it doesn't
local function check_references_file(file_path)
    if not io.open(file_path, "r") then
        io.open(file_path, "w"):close()
    end
end

-- Function to check if a citation key is present in references.bib
local function is_citation_key_present(citation_key, references_file)
    local file = io.open(references_file, "r")
    if not file then
        return false
    end
    local content = file:read("*all")
    file:close()
    return content:match("{" .. citation_key:sub(2) .. ",") ~= nil
end

-- Function to copy a specific BibTeX entry to the local references.bib file
local function insert_reference_from_global_bib(key, global_bib, local_bib)
    local global_file = io.open(global_bib, "r")
    if not global_file then
        print("Error: Global BibTeX file not found: " .. global_bib)
        return
    end
    local local_file = io.open(local_bib, "a")
    if not local_file then
        print("Error: Unable to write to local references file: " .. local_bib)
        global_file:close()
        return
    end

    local copying = false
    for line in global_file:lines() do
        if line:find("{" .. key:sub(2) .. ",") then
            copying = true
        end
        if copying then
            local_file:write(line .. "\n")
        end
        if line == "}" then
            copying = false
        end
    end

    global_file:close()
    local_file:write("\n")
    local_file:close()
    print("Copied entry with key " .. key .. " to " .. local_bib)
end

-- Define function to update local .bib file
function M.update_local_bib_file(specific_key, global_bib_file)
    -- Set default arguments if not provided
    global_bib_file = global_bib_file or vim.g.global_bib_file -- Default to globally defined bib file

    -- Read buffer content into a string
    local buffer_content = table.concat(vim.fn.getline(1, "$"), "\n")

    local citation_keys
    if specific_key then
        citation_keys = {specific_key}  -- Use the specific_key if provided
    else
        citation_keys = extract_citation_keys(buffer_content)
    end

    -- set local bib file to references.bib if no bibliography key set in yaml
    local output_bib_file = vim.fn.expand("%:p:h") .. "/references.bib" -- Current buffer's directory + references.bib

    -- Check if "bibliography:" key is present in the yaml header
    local yaml_header = buffer_content:match("^%-%-%-%s*(.-)\n%-%-%-")
    local bibliography_key = yaml_header and yaml_header:match("bibliography:%s*(%S+)")
    if bibliography_key then
        output_bib_file = vim.fn.expand("%:p:h") .. "/" .. bibliography_key
    end

    check_references_file(output_bib_file)

    for _, key in ipairs(citation_keys) do
        if not is_citation_key_present(key, output_bib_file) then
            print("Copying reference for key: " .. key)
            insert_reference_from_global_bib(key, global_bib_file, output_bib_file)
        else
            print("Reference for key: " .. key .. " already present. Skipping.")
        end
    end

    print("References insertion complete.")
end

return M
