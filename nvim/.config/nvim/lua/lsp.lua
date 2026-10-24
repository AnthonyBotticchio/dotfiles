vim.diagnostic.config({ virtual_text = true })

-- Use clangd from PATH; Mason manages the other servers in plugins.lua.
vim.lsp.config("clangd", {
    filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
})
vim.lsp.enable("clangd")

vim.lsp.config("cmake", {
    root_markers = {
        "CMakePresets.json", "CTestConfig.cmake", ".git", "build", "cmake",
        "CMakeLists.txt",
    },
})

local function complete(findstart, base)
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local before = vim.api.nvim_get_current_line():sub(1, col)
    if before:match("^%s*$") then
        return findstart == 1 and -3 or {}
    end
    return vim.lsp.omnifunc(findstart, base)
end

-- Suppress automatic suggestions on blank or whitespace-only input.
vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspCompletion", { clear = true }),
    callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client:supports_method("textDocument/completion") then
            vim.lsp.completion.enable(true, client.id, event.buf)
            vim.bo[event.buf].completefunc = "v:lua.require'lsp'.complete"
            vim.bo[event.buf].complete = "F"
            vim.bo[event.buf].autocomplete = true
        end
    end,
})

local clangd_filetypes = { c = true, cpp = true, objc = true, objcpp = true, cuda = true }

vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("FormatOnSave", { clear = true }),
    callback = function(event)
        local filetype = vim.bo[event.buf].filetype
        if filetype == "glsl" then
            local lines = vim.api.nvim_buf_get_lines(event.buf, 0, -1, false)
            local result = vim.system({
                "clang-format", "--style=file",
                "--assume-filename=" .. vim.api.nvim_buf_get_name(event.buf),
            }, { stdin = table.concat(lines, "\n") .. "\n", text = true }):wait(1000)
            if result.code ~= 0 then
                error(("GLSL formatting failed (exit %s): %s"):format(result.code, result.stderr or ""))
            end
            local formatted = vim.split(result.stdout, "\n", { plain = true })
            if formatted[#formatted] == "" then
                table.remove(formatted)
            end
            if not vim.deep_equal(lines, formatted) then
                local view = vim.fn.winsaveview()
                vim.api.nvim_buf_set_lines(event.buf, 0, -1, false, formatted)
                vim.fn.winrestview(view)
            end
        elseif clangd_filetypes[filetype] then
            local clients = vim.lsp.get_clients({
                bufnr = event.buf,
                name = "clangd",
                method = "textDocument/formatting",
            })
            if #clients > 0 then
                vim.lsp.buf.format({ bufnr = event.buf, name = "clangd", timeout_ms = 1000 })
            end
        end
    end,
})

return { complete = complete }
