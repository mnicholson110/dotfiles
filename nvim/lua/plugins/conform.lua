return {
    "stevearc/conform.nvim",
    opts = {
        formatters_by_ft = {
            java = { "google-java-format" },
            go = { "gofumpt", "golines", "goimports" },
            c = { "clang-format" },
            zig = { "zls" },
        },
        formatters = {
            clang_format = {
                prepend_args = { "--fallback-style=LLVM" }
            }
        },
        format_on_save = {
            timeout_ms = 500,
            lsp_format = "fallback",
        }
    }
}
