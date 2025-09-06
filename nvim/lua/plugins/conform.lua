return {
    "stevearc/conform.nvim",
    opts = {
        formatters_by_ft = {
            java = { "clang-format" },
            go = { "gofumpt", "golines", "goimports" },
            c = { "clang-format" },
            zig = { "zls" },
            javascript = { "prettier" },
            json = { "prettier" },
            html = { "prettier" },
            css = { "prettier" },
            javascriptreact = { "prettier" },
            terraform = { "tfmt" }
        },
        formatters = {
            clang_format = {
                prepend_args = { "--fallback-style=LLVM" }
            },
            tfmt = {
                command = "terraform",
                args = { "fmt", "-" },
                stdin = true,
            }
        },
        format_on_save = {
            timeout_ms = 500,
            lsp_format = "fallback",
        }
    }
}
