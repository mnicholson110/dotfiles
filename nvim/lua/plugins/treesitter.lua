return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
        local treesitter = require("nvim-treesitter")
        local languages = { "c", "java", "lua", "vim", "vimdoc", "go" }

        treesitter.setup()

        local installed = {}
        for _, lang in ipairs(treesitter.get_installed("parsers")) do
            installed[lang] = true
        end

        local missing = {}
        for _, lang in ipairs(languages) do
            if not installed[lang] then
                table.insert(missing, lang)
            end
        end

        if #missing > 0 then
            vim.schedule(function()
                treesitter.install(missing, { summary = true })
            end)
        end

        vim.api.nvim_create_autocmd("FileType", {
            pattern = languages,
            callback = function(args)
                vim.treesitter.start(args.buf)
                vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                vim.wo[vim.api.nvim_get_current_win()].foldexpr = "v:lua.vim.treesitter.foldexpr()"
                vim.wo[vim.api.nvim_get_current_win()].foldmethod = "expr"
            end,
        })
    end,
}
