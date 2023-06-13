lvim.plugins = {
  { "sainnhe/sonokai" },
  { "iamcco/markdown-preview.nvim", build = "cd app && npm install", init = function() vim.g.mkdp_filetypes = { "markdown" } end, ft = { "markdown" } },
  { "weirongxu/plantuml-previewer.vim" },
  { "tyru/open-browser.vim" },
  { "aklt/plantuml-syntax" },
  { "ThePrimeagen/harpoon" },
  { "simrat39/rust-tools.nvim" }
}
