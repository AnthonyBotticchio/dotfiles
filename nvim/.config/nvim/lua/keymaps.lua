vim.keymap.set("n", "<leader>p", '"+p')
vim.keymap.set("n", "<leader>P", '"+P')
vim.keymap.set("v", "<leader>y", '"+y')
vim.keymap.set("v", "<leader>d", '"+d')

vim.keymap.set("n", "<C-_>", "gcc", {
    remap = true,
    silent = true,
    desc = "Toggle comment",
})

-- Telescope
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })

vim.keymap.set("n", "<F3>", "<cmd>LspClangdSwitchSourceHeader<CR>", {
    silent = true,
    desc = "Switch source/header",
})

vim.keymap.set("n", "<F2>", vim.lsp.buf.definition, {
    silent = true,
    desc = "Go to definition",
})
