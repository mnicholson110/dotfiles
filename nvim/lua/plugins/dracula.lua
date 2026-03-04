return {
    "Mofiqul/dracula.nvim",
    lazy = false,
    priority = 1000,
    config = function()
        vim.cmd([[colorscheme dracula-soft]])
        vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#6b7089" })
    end,
}
