local terminal = "com.superlogical.terminal"

-- pwd comes back as a file:// URL when the shell reports it via OSC 7.
local function pane_cwd(block_id)
  local r = rex.block.call(terminal, "pwd", { block_id = block_id })
  local pwd = r and r.pwd
  if not pwd or pwd == "" then return nil end
  pwd = pwd:gsub("^file://[^/]*", "")
  return (pwd:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end))
end

rex.action{
  name = "claude_tab",
  title = "New Claude Tab",
  run = function(ctx)
    local opts = { command = { "claude" }, cwd = pane_cwd(ctx.block_id) }
    local _, err = rex.session.new_window{
      layout = rex.layout.block{ flavor = terminal .. ".shell", options = opts },
    }
    if err then error(err, 0) end
  end,
}

rex.bind("cmd+a", "claude_tab")
