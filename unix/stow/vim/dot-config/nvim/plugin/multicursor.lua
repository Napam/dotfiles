require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/jake-stewart/multicursor.nvim" },
  })

  local mc = require("multicursor-nvim")
  mc.setup()

  local set = vim.keymap.set

  set({ "n", "v" }, "<up>", function() mc.addCursor("k") end)
  set({ "n", "v" }, "<down>", function() mc.addCursor("j") end)
  set({ "n", "v" }, "<c-n>", function() mc.addCursor("*") end)
  set({ "n", "v" }, "<c-s>", function() mc.skipCursor("*") end)
  set({ "n", "v" }, "<left>", mc.nextCursor)
  set({ "n", "v" }, "<right>", mc.prevCursor)
  set({ "n", "v" }, "<c-x>", mc.deleteCursor)
  set("n", "<c-leftmouse>", mc.handleMouse)

  -- Layer mappings only apply when multiple cursors exist (overlap-safe).
  mc.addKeymapLayer(function(layerSet)
    layerSet({ "n", "x" }, "<left>", mc.prevCursor)
    layerSet({ "n", "x" }, "<right>", mc.nextCursor)
    layerSet({ "n", "x" }, "<leader>x", mc.deleteCursor)
    layerSet("n", "<esc>", function()
      if not mc.cursorsEnabled() then
        mc.enableCursors()
      else
        mc.clearCursors()
      end
    end)
  end)

  set("n", "<leader>a", mc.alignCursors)
  set("v", "s", mc.splitCursors)
  set("v", "I", mc.insertVisual)
  set("v", "A", mc.appendVisual)
  set("v", "M", mc.matchCursors)
  set("v", "<leader>t", function() mc.transposeCursors(1) end)
  set("v", "<leader>T", function() mc.transposeCursors(-1) end)

  local hl = vim.api.nvim_set_hl
  hl(0, "MultiCursorCursor", { reverse = true })
  hl(0, "MultiCursorVisual", { link = "Visual" })
  hl(0, "MultiCursorSign", { link = "SignColumn" })
  hl(0, "MultiCursorMatchPreview", { link = "Search" })
  hl(0, "MultiCursorDisabledCursor", { reverse = true })
  hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
  hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })
end)
