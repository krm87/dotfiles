-- GitHub Light/Dark Default, matching Ghostty. Neovim re-runs this scheme
-- when 'background' changes, so it follows the terminal's light/dark mode.
require("github-theme").load({
  theme = vim.o.background == "light" and "github_light_default" or "github_dark_default",
})
vim.g.colors_name = "github"
