if false then return end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- This will run last in the setup process and is a good place to configure
-- things like custom filetypes. This just pure lua so anything that doesn't
-- fit in the normal config locations above can go here
vim.cmd [[command! -nargs=0 GoToCommand :Telescope commands]]
vim.cmd [[command! -nargs=0 GoToFile :Telescope find_files hidden=true no_ignore=true]]
vim.cmd [[command! -nargs=0 GoToSymbol :Telescope lsp_document_symbols]]
vim.cmd [[command! -nargs=0 Grep :Telescope live_grep]]
vim.cmd [[command! -nargs=0 SmartGoTo :Telescope smart_goto]]
vim.cmd [[command! -nargs=0 GoToBuffer :Telescope buffers]]
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
