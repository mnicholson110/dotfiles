return {
    "neovim/nvim-lspconfig",
    config = function()
        local cmp_ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
        if cmp_ok then
            vim.lsp.config("*", {
                capabilities = cmp_lsp.default_capabilities(),
            })
        end

        local servers = {
            {
                name = "clangd",
                bin = "clangd",
            },
            {
                name = "gopls",
                bin = "gopls",
            },
            {
                name = "rust_analyzer",
                bin = "rust-analyzer",
            },
        }

        for _, server in ipairs(servers) do
            if vim.fn.executable(server.bin) == 1 then
                local config = {
                    cmd = { server.bin },
                }

                if server.settings then
                    config.settings = server.settings
                end

                vim.lsp.config(server.name, config)
                vim.lsp.enable(server.name)
            end
        end
    end,
}
