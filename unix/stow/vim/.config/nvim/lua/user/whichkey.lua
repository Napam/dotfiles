local which_key = require("which-key")
local mappings = {
    w = { "<cmd>wa<cr>", "Save all" },
    q = { "<cmd>q<cr>", "Quit buffer" },
    e = { "<cmd>NvimTreeToggle<cr>", "File explorer" },
    c = { "<cmd>bd<cr>", "Close buffer" },
    g = { "<cmd>LazyGit<cr>", "LazyGit" },
    f = {
        name = "Find",
        f = { "<cmd>Telescope find_files<cr>", "Find files" },
        g = { "<cmd>Telescope live_grep<cr>", "Find in files" },
        b = { "<cmd>Telescope buffers<cr>", "Find buffers" }
    },
    r = { "<cmd>Telescope oldfiles<cr>", "Recent files" },
    h = { "<cmd>noh<cr>", "Remove highlights" }
}

which_key.setup()
which_key.register(mappings, { prefix = "<leader>" })
