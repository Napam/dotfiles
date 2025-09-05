return {
  "kndndrj/nvim-dbee",
  dependencies = {
    "MunifTanjim/nui.nvim",
  },
  build = function()
    -- Install tries to automatically detect the install method.
    -- if it fails, try calling it with one of these parameters:
    --    "curl", "wget", "bitsadmin", "go"
    require("dbee").install()
  end,
  config = function()
    local sources = {}
    local dbee_json = vim.fs.find("dbee.json", { upward = true })[1]

    if dbee_json then
      table.insert(
        sources, require("dbee.sources").FileSource:new(dbee_json)
      )
    end

    require("dbee").setup({sources = sources})
  end
}
