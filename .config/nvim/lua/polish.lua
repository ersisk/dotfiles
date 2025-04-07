-- This will run last in the setup process and is a good place to configure
-- things like custom filetypes. This just pure lua so anything that doesn't
-- fit in the normal config locations above can go here
-- vim.cmd [[command! -nargs=0 GoToCommand :Telescope commands]]
-- vim.cmd [[command! -nargs=0 GoToFile :Telescope find_files hidden=true no_ignore=true]]
-- vim.cmd [[command! -nargs=0 GoToSymbol :Telescope lsp_document_symbols]]
-- vim.cmd [[command! -nargs=0 Grep :Telescope live_grep]]
-- vim.cmd [[command! -nargs=0 SmartGoTo :Telescope smart_goto]]
-- vim.cmd [[command! -nargs=0 GoToBuffer :Telescope buffers]]
vim.cmd [[command! -nargs=0 GoToCommand :lua Snacks.picker.command_history()]]
vim.cmd [[command! -nargs=0 GoToFile :lua Snacks.picker.files({ hidden = true, ignored = true })]]
vim.cmd [[command! -nargs=0 GoToSymbol :lua Snacks.picker.lsp_symbols()]]
vim.cmd [[command! -nargs=0 GoToBuffer :lua Snacks.picker.buffers()]]
vim.cmd [[command! -nargs=0 Grep :lua Snacks.picker.grep()]]
vim.cmd [[command! -nargs=0 SmartGoTo :lua Snacks.picker.smart()]]
-- Set up custom filetypes
-- vim.filetype.add {
--   extension = {
--     foo = "fooscript",
--   },
--   filename = {
--     ["Foofile"] = "fooscript",
--   },
--   pattern = {
--     ["~/%.config/foo/.*"] = "fooscript",
--   },
-- }
