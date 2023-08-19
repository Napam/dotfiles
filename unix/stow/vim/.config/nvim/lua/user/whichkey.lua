local which_key = require("which-key")
local mappings = {
    c = { "<cmd>bd<cr>", "Close buffer" },
    e = { "<cmd>NvimTreeToggle<cr>", "File explorer" },
    f = {
        name = "Find",
        f = { "<cmd>Telescope find_files<cr>", "Find files" },
        g = { "<cmd>Telescope live_grep<cr>", "Find in files" },
        b = { "<cmd>Telescope buffers<cr>", "Find buffers" }
    },
    g = { "<cmd>LazyGit<cr>", "Git client" },
    h = { "<cmd>noh<cr>", "Remove highlights" },
    q = { "<cmd>q<cr>", "Quit buffer" },
    r = { "<cmd>Telescope oldfiles<cr>", "Recent files" },
    u = { "<cmd>UndotreeToggle<cr>", "Undo history" },
    w = { "<cmd>wa<cr>", "Save all" },
}

which_key.setup()
which_key.register(mappings, { prefix = "<leader>" })
