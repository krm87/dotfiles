vim.o.number = true
-- Line numbers, then a separator before the text.
vim.o.statuscolumn = "%s%=%l %#LineNr#│ "
vim.o.cursorline = true
vim.o.cursorlineopt = "number"
vim.o.signcolumn = "auto"
vim.o.scrolloff = 5
vim.o.ignorecase = true
vim.o.smartcase = true

vim.pack.add({
  "https://github.com/projekt0n/github-nvim-theme",
  "https://github.com/nvim-treesitter/nvim-treesitter",
  "https://github.com/nvim-tree/nvim-web-devicons",
  "https://github.com/MeanderingProgrammer/render-markdown.nvim",
})

-- Match Ghostty's GitHub Light/Dark themes (see colors/github.lua). Neovim
-- asks the terminal for its background, so the scheme follows Ghostty's mode.
vim.cmd.colorscheme("github")

-- Tree-sitter syntax highlighting. Parsers are built on first start, which
-- needs the tree-sitter CLI and a C compiler.
require("nvim-treesitter").install({
  "bash",
  "c_sharp",
  "css",
  "diff",
  "dockerfile",
  "git_config",
  "gitcommit",
  "go",
  "gomod",
  "html",
  "javascript",
  "json",
  "lua",
  "make",
  "markdown",
  "python",
  "sql",
  "toml",
  "tsx",
  "typescript",
  "yaml",
})

vim.treesitter.language.register("bash", { "env", "zsh" })

vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    if pcall(vim.treesitter.start, args.buf) then
      vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

-- Render markdown in the buffer: headings, code blocks, tables, checkboxes.
-- The cursor line shows the raw text for editing. Icons come from Ghostty's
-- built-in Nerd Font symbols.
require("render-markdown").setup({
  -- Headings already have icons; keep the column left of the numbers empty.
  sign = { enabled = false },
})

-- Copy every yank to the system clipboard with OSC 52. The terminal does the
-- copying, so this works locally, over SSH and inside tmux (set-clipboard on).
-- Pasting stays inside Neovim; use the terminal's paste for clipboard contents.
local osc52_copy = require("vim.ui.clipboard.osc52").copy("+")

vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("osc52_yank", { clear = true }),
  callback = function()
    local event = vim.v.event
    if event.operator ~= "y" or not vim.tbl_contains({ "", "+", "*" }, event.regname) then
      return
    end
    local lines = vim.list_extend({}, event.regcontents)
    if event.regtype == "V" then
      table.insert(lines, "")
    end
    osc52_copy(lines)
  end,
})
