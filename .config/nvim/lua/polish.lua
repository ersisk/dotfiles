
-- This will run last in the setup process.
-- This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

vim.cmd [[command! -nargs=0 GoToCommand :lua Snacks.picker.command_history()]]
vim.cmd [[command! -nargs=0 GoToFile :lua Snacks.picker.files({ hidden = true, ignored = true })]]
vim.cmd [[command! -nargs=0 GoToSymbol :lua Snacks.picker.lsp_symbols()]]
vim.cmd [[command! -nargs=0 GoToBuffer :lua Snacks.picker.buffers()]]
vim.cmd [[command! -nargs=0 Grep :lua Snacks.picker.grep()]]
vim.cmd [[command! -nargs=0 SmartGoTo :lua Snacks.picker.smart()]]
vim.api.nvim_create_user_command("FormatDisable", function(args)
  if args.bang then
    -- FormatDisable! will disable formatting just for this buffer
    vim.b.disable_autoformat = true
  else
    vim.g.disable_autoformat = true
  end
end, {
  desc = "Disable autoformat-on-save",
  bang = true,
})
vim.api.nvim_create_user_command("FormatEnable", function()
  vim.b.disable_autoformat = false
  vim.g.disable_autoformat = false
end, {
  desc = "Re-enable autoformat-on-save",
})
