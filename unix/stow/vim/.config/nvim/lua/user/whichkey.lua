local which_key = require("which-key")
local mappings = {
    c = { "<cmd>bd<cr>", "Close buffer" },
    C = { "<cmd>edit ~/.config/nvim/init.lua<cr>", "Open config" },
    e = { "<cmd>NvimTreeToggle<cr>", "File explorer" },
    f = {
        name = "Find",
        f = { "<cmd>Telescope find_files<cr>", "Find files" },
        g = { "<cmd>Telescope live_grep<cr>", "Find in files" },
        b = { "<cmd>Telescope buffers<cr>", "Find buffers" }
    },
    g = {
        name = "Git",
        g = { "<cmd>LazyGit<cr>", "Git client" },
        r = { "<cmd>Gitsigns reset_hunk<cr>", "Reset hunk" },
    },
    h = { "<cmd>noh<cr>", "Remove highlights" },
    l = {
        name = "LSP",
        f = { "<cmd>LspZeroFormat<cr>", "Format" }
    },
    q = { "<cmd>q!<cr>", "Quit buffer" },
    r = { "<cmd>Telescope oldfiles<cr>", "Recent files" },
    u = { "<cmd>UndotreeToggle<cr>", "Undo history" },
    w = { "<cmd>w<cr>", "Save" },
    W = { "<cmd>wa<cr>", "Save all" },
}

which_key.setup()
which_key.register(mappings, { prefix = "<leader>" })
