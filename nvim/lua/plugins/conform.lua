return {
    "stevearc/conform.nvim",
    opts = {
        formatters_by_ft = {
            java = { "google-java-format" },
            go = { "gofumpt", "golines", "goimport" },
            c = { "clang-format" }
        },
        format_on_save = {
            timeout_ms = 500,
            lsp_format = "fallback",
        }
    }
}
