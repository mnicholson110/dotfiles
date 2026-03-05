vim.keymap.set("n", "<leader>a", vim.cmd.Oil)
vim.keymap.set("v", "<C-j>", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "<C-k>", ":m '<-2<CR>gv=gv")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>")
vim.keymap.set("n", "<leader>t", ":term<CR>")
vim.keymap.set("n", "<C-up>", "<C-w>+")
vim.keymap.set("n", "<C-down>", "<C-w>-")
vim.keymap.set("n", "<C-left>", "<C-w><")
vim.keymap.set("n", "<C-right>", "<C-w>>")


local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>h", builtin.find_files, {})
vim.keymap.set("n", "<leader>j", builtin.live_grep, {})
vim.keymap.set("n", "<leader>k", builtin.buffers, {})
vim.keymap.set("n", "<leader>l", builtin.help_tags, {})

vim.filetype.add({
    extension = {
        h = "c",
    },
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = "oil",
    callback = function()
        vim.keymap.set("n", "<leader>.", require("oil").toggle_hidden, { buffer = true, desc = "Toggle hidden files" })
    end,
})

--Macros

--Indent current line by 1 tab, then move to next line
vim.fn.setreg('t', '^i	j')
