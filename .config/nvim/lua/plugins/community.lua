return {
  -- Add the community repository of plugin specifications
  "AstroNvim/astrocommunity",
  -- example of importing a plugin
  -- available plugins can be found at https://github.com/AstroNvim/astrocommunity
  { import = "astrocommunity.colorscheme.nordic-nvim" },
  { import = "astrocommunity.motion.leap-nvim" },
  { import = "astrocommunity.recipes.cache-colorscheme" },
  { import = "astrocommunity.motion.nvim-surround" },
  { import = "astrocommunity.pack.laravel" },
  { import = "astrocommunity.test.vim-test"}
  -- { import = "astrocommunity.debugging.nvim-dap-view" },
}
