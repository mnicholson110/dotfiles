return {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
        defaults = {
            vimgrep_arguments = {
                "rg",
                "--color=never",
                "--no-heading",
                "--with-filename",
                "--line-number",
                "--column",
                "--smart-case",
                "--hidden",
                "--glob",
                "!.git/*",
            },
        },
        pickers = {
            find_files = {
                hidden = true,
                find_command = { "rg", "--files", "--hidden", "--follow", "--glob", "!.git/*" },
            },
            buffers = {
                initial_mode = "normal",
            }
        },
    }
}
