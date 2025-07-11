return {
    "neovim/nvim-lspconfig",

    dependencies = { "williamboman/mason.nvim", "williamboman/mason-lspconfig" },

    config = function()
        require("mason").setup()
        require("mason-lspconfig").setup({
            ensure_installed = { "clangd", "rust_analyzer", "pylsp", "gopls", "lua_ls", "jdtls" },
            automatic_enable = {
                exclude = { "clangd" }
            }
        })
        require("lspconfig").clangd.setup {
            init_options = {
                fallbackFlags = { '--std=c23' }
            },
        }
    end,
}
