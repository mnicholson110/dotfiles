return {
    "neovim/nvim-lspconfig",

    dependencies = { "williamboman/mason.nvim", "williamboman/mason-lspconfig" },

    config = function()
        require("mason").setup()
        require("mason-lspconfig").setup({
            ensure_installed = { "clangd", "rust_analyzer", "pylsp", "gopls", "lua_ls", "jdtls" },
        })
        require("mason-lspconfig").setup_handlers {
            ["lua_ls"] = function()
                require("lspconfig").lua_ls.setup({
                    settings = {
                        Lua = {
                            diagnostics = { globals = { "vim" } }
                        }
                    }
                })
            end
        }
    end,
}
