return {
  "jake-stewart/multicursor.nvim",
  branch = "main",
  config = function()
    local mc = require("multicursor-nvim")
    mc.setup()

    local set = vim.keymap.set

    -- Add cursors above/below the main cursor.
    set({ "n", "v" }, "<up>", function()
      mc.addCursor("k")
    end)
    set({ "n", "v" }, "<down>", function()
      mc.addCursor("j")
    end)

    -- Add a cursor and jump to the next word under cursor.
    set({ "n", "v" }, "<c-n>", function()
      mc.addCursor("*")
    end)

    -- Jump to the next word under cursor but do not add a cursor.
    set({ "n", "v" }, "<c-s>", function()
      mc.skipCursor("*")
    end)

    -- Rotate the main cursor.
    set({ "n", "v" }, "<left>", mc.nextCursor)
    set({ "n", "v" }, "<right>", mc.prevCursor)

    -- Delete the main cursor.
    set({ "n", "v" }, "<leader>x", mc.deleteCursor)

    -- Add and remove cursors with control + left click.
    set("n", "<c-leftmouse>", mc.handleMouse)


    -- Mappings defined in a keymap layer only apply when there are
    -- multiple cursors. This lets you have overlapping mappings.
    mc.addKeymapLayer(function(layerSet)
      -- Select a different cursor as the main one.
      layerSet({ "n", "x" }, "<left>", mc.prevCursor)
      layerSet({ "n", "x" }, "<right>", mc.nextCursor)

      -- Delete the main cursor.
      layerSet({ "n", "x" }, "<leader>x", mc.deleteCursor)

      -- Enable and clear cursors using escape.
      layerSet("n", "<esc>", function()
        if not mc.cursorsEnabled() then
          mc.enableCursors()
        else
          mc.clearCursors()
        end
      end)
    end)

    -- Align cursor columns.
    set("n", "<leader>a", mc.alignCursors)

    -- Split visual selections by regex.
    set("v", "s", mc.splitCursors)

    -- Append/insert for each line of visual selections.
    set("v", "I", mc.insertVisual)
    set("v", "A", mc.appendVisual)

    -- match new cursors within visual selections by regex.
    set("v", "M", mc.matchCursors)

    -- Rotate visual selection contents.
    set("v", "<leader>t", function()
      mc.transposeCursors(1)
    end)
    set("v", "<leader>T", function()
      mc.transposeCursors(-1)
    end)

    -- -- Customize how cursors look.
    -- vim.api.nvim_set_hl(0, "MultiCursorCursor", { link = "Cursor" })
    -- vim.api.nvim_set_hl(0, "MultiCursorVisual", { link = "Visual" })
    -- vim.api.nvim_set_hl(0, "MultiCursorDisabledCursor", { link = "Visual" })
    -- vim.api.nvim_set_hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
    -- Customize how cursors look.
    local hl = vim.api.nvim_set_hl
    hl(0, "MultiCursorCursor", { reverse = true })
    hl(0, "MultiCursorVisual", { link = "Visual" })
    hl(0, "MultiCursorSign", { link = "SignColumn" })
    hl(0, "MultiCursorMatchPreview", { link = "Search" })
    hl(0, "MultiCursorDisabledCursor", { reverse = true })
    hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
    hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })
  end
}
