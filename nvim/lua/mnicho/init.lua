require("mnicho.remap")
require("mnicho.set")
require("mnicho.packer")


require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = { "rust_analyzer", "pylsp", "gopls", "lua_ls" },
})

require("mason-lspconfig").setup_handlers {
  -- The first entry (without a key) will be the default handler
  -- and will be called for each installed server that doesn't have
  -- a dedicated handler.
  function (server_name) -- default handler (optional)
    require("lspconfig")[server_name].setup {}
  end,
  -- Next, you can provide a dedicated handler for specific servers.
  -- For example, a handler override for the `rust_analyzer`:
  ["jdtls"] = function ()
    require("lspconfig").jdtls.setup {
      cmd = { "jdtls" }
    }
  end,
  ["rust_analyzer"] = function ()
     require("rust-tools").setup()
  end,
  ["gopls"] = function ()
    require("lspconfig").gopls.setup({settings = {
                             gopls = {
                               gofumpt = true,
                             }}})
  end,
}
local cmp = require('cmp')

cmp.setup({
  snippet = {
    expand = function(args)
      vim.fn["vsnip#anonymous"](args.body)
    end,
  },
  window = {
    completion = cmp.config.window.bordered('rounded'),
    documentation = cmp.config.window.bordered('rounded'),
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-y>'] = cmp.mapping.confirm({ select = true }),
    ['<Tab>'] = nil,
    ['<S-Tab>'] = nil,
    ['<C-p>'] = cmp.mapping(cmp.mapping.select_prev_item(), { 'i', 'c' }),
    ['<C-n>'] = cmp.mapping(cmp.mapping.select_next_item(), { 'i', 'c' }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'vsnip' },
  }, {
    { name = 'buffer' },
  })
})

require('lualine').setup()

require('transparent').setup()

require('harpoon').setup({
    global_settings = {
        tabline = true,
        tabline_auto_open = true,
        tabline_position = 'top',
        tabline_prefix = ' ',
        tabline_suffix = ' ',
    },
})

vim.opt.cmdheight=0

vim.cmd [[autocmd BufWritePre *.go lua vim.lsp.buf.format()]]
vim.cmd [[autocmd TermOpen * setlocal nonumber norelativenumber]]
