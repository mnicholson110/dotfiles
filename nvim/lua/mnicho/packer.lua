vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
  use('wbthomason/packer.nvim')

  use({
    'nvim-telescope/telescope.nvim', tag = '0.1.3',
    requires = { {'nvim-lua/plenary.nvim'} }
  })

  use({
    'Mofiqul/dracula.nvim',
     as = 'dracula',
     config = function()
       vim.cmd('colorscheme dracula')
     end,
  })

  use({'nvim-treesitter/nvim-treesitter',
      run = function()
        local ts_update = require('nvim-treesitter.install').update({with_sync = true})
        ts_update()
      end,}
  )
  use('theprimeagen/harpoon')
  use('github/copilot.vim')
  use({
    'williamboman/mason.nvim',
    'williamboman/mason-lspconfig.nvim',
    'neovim/nvim-lspconfig',
  })
  use({
    'hrsh7th/nvim-cmp',
    requires = {
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-vsnip',
      'hrsh7th/vim-vsnip',
    }
  })
  use('theprimeagen/vim-be-good')
  use('simrat39/rust-tools.nvim')

  use({
    'nvim-lualine/lualine.nvim',
    requires = {'nvim-tree/nvim-web-devicons', opt = true}
  })

  use('xiyaowong/transparent.nvim')


end)
