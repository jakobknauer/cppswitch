local function split_extension(path)
    dir, filename = path:match "^(.*[%/])([^%/]*)$"
    fileroot, ext = filename:match "^(.+)%.([^%.]+)$"
    if fileroot == nil then
        fileroot = filename
        ext = ""
    end
    return dir, fileroot, ext
end

local function split_directory_into_parts(dir)
    local parts = {}
    while true do
        local part, rest = dir:match "^[%/]?([^%/]*)%/(.*)$"
        if part ~= nil then
            table.insert(parts, part)
            dir = rest
        else
            part = dir:match "^(.*)%/$"
            table.insert(parts, part)
            return parts
        end
    end
end

local function concat_path(parts)
    local dir = "/"
    for i = 1, #parts do dir = dir .. parts[i] .. "/" end
    return dir
end

local function array_find_last(array, item)
    local index = nil
    for i = 1, #array do if array[i] == item then index = i end end
    return index
end

local function array_contains(array, item)
    local index = nil
    for i = 1, #array do if array[i] == item then return true end end
    return false
end

local function get_twin_dir(dir, directory_to_replace, directory_replacement)
    local parts = split_directory_into_parts(dir)
    local last_index = array_find_last(parts, directory_to_replace)
    if last_index ~= nil then
        parts[last_index] = directory_replacement
        twin_dir = concat_path(parts)
        return twin_dir
    end
    return nil
end

local function create_goto_function(all_extensions_var, preferred_extension_var,
                                    directory_to_replace_var,
                                    directory_replacement_var)
    return function()
        -- Obtain config values
        local all_extensions = vim.g[all_extensions_var]
        local preferred_extension = vim.g[preferred_extension_var]
        local directory_to_replace = vim.g[directory_to_replace_var]
        local directory_replacement = vim.g[directory_replacement_var]
        local search_dirs = vim.g.cppswitch_search_dirs
        local creation_dir = vim.g.cppswitch_creation_dir

        -- Get current directory path
        local path = vim.api.nvim_buf_get_name(0)
        local dir, root, _ = split_extension(path)

        -- Determine directories to search
        local actual_search_dirs = {}
        for i = 1, #search_dirs do
            local search_dir = search_dirs[i]
            if search_dir == "same" then
                table.insert(actual_search_dirs, dir)
            elseif search_dir == "twin" then
                local twin_dir = get_twin_dir(dir, directory_to_replace,
                                              directory_replacement)
                if twin_dir ~= nil then
                    table.insert(actual_search_dirs, twin_dir)
                end
            end
        end

        -- Search in directories
        for i = 1, #actual_search_dirs do
            local actual_search_dir = actual_search_dirs[i]

            for j = 1, #all_extensions do
                local extension = all_extensions[j]

                local candidate = actual_search_dir .. root .. "." .. extension
                if vim.fn.filereadable(candidate) == 1 then
                    vim.cmd("edit " .. candidate)
                    return
                end

            end
        end

        -- Determine directory to create file
        local actual_creation_dir = ""
        if creation_dir == "same" then
            actual_creation_dir = dir
        elseif creation_dir == "twin" then
            actual_creation_dir = get_twin_dir(dir, directory_to_replace,
                                               directory_replacement)
        end

        -- Create directory
        os.execute("mkdir -p " .. actual_creation_dir)

        -- Create file
        local file_to_create = actual_creation_dir .. root .. "." ..
                                   preferred_extension
        vim.cmd("edit " .. file_to_create)
    end
end

local function switch()
    local path = vim.api.nvim_buf_get_name(0)
    local _, _, ext = split_extension(path)

    header_extensions = vim.g.cppswitch_header_extensions
    impl_extensions = vim.g.cppswitch_impl_extensions

    if array_contains(header_extensions, ext) then
        vim.cmd("CppswitchGotoImpl")
    elseif array_contains(impl_extensions, ext) then
        vim.cmd("CppswitchGotoHeader")
    end
end

local function setup()

    vim.g.cppswitch_header_extensions = {"h", "hpp", "hh", "h++", "hxx", "H"}
    vim.g.cppswitch_preferred_header_extension = "h"
    vim.g.cppswitch_header_dir = "include"

    vim.g.cppswitch_impl_extensions = {"c", "cpp", "cc", "c++", "cxx", "C"}
    vim.g.cppswitch_preferred_impl_extension = "cpp"
    vim.g.cppswitch_impl_dir = "src"

    vim.g.cppswitch_search_dirs = {"same", "twin"}
    vim.g.cppswitch_creation_dir = "same" -- "same" or "twin"

    vim.api.nvim_create_user_command("CppswitchGotoHeader",
                                     create_goto_function(
                                         "cppswitch_header_extensions",
                                         "cppswitch_preferred_header_extension",
                                         "cppswitch_impl_dir",
                                         "cppswitch_header_dir"), {})

    vim.api.nvim_create_user_command("CppswitchGotoImpl",
                                     create_goto_function(
                                         "cppswitch_impl_extensions",
                                         "cppswitch_preferred_impl_extension",
                                         "cppswitch_header_dir",
                                         "cppswitch_impl_dir"), {})

    vim.api.nvim_create_user_command("CppswitchSwitch", switch, {})

end

return {setup = setup}
