local terminal = "com.superlogical.terminal"

-- pwd comes back as a file:// URL when the shell reports it via OSC 7.
local function pane_cwd(block_id)
  local r = rex.block.call(terminal, "pwd", { block_id = block_id })
  local pwd = r and r.pwd
  if not pwd or pwd == "" then return nil end
  pwd = pwd:gsub("^file://[^/]*", "")
  return (pwd:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end))
end

-- Mirrors the kitty -> tmux new-window keys; Rex execs the command directly,
-- so fish functions and aliases (ccr, kcr, cldy) go through fish -c.
local function tab_action(key, name, title, command)
  rex.action{
    name = name,
    title = title,
    run = function(ctx)
      local opts = { command = command, cwd = pane_cwd(ctx.block_id) }
      local _, err = rex.session.new_window{
        layout = rex.layout.block{ flavor = terminal .. ".shell", options = opts },
      }
      if err then error(err, 0) end
    end,
  }
  rex.bind(key, name)
end

tab_action("cmd+a", "claude_tab", "New Claude Tab", { "claude" })
tab_action("cmd+shift+d", "claude_resume_tab", "Resume Claude Session", { "fish", "-c", "ccr --here" })
tab_action("cmd+shift+z", "claude_yolo_tab", "New Claude Yolo Tab", { "fish", "-c", "cldy" })
tab_action("ctrl+cmd+k", "kilo_tab", "New Kilo Tab", { "kilo" })
tab_action("cmd+shift+k", "kilo_resume_tab", "Resume Kilo Session", { "fish", "-c", "kcr --here" })
tab_action("cmd+g", "lazygit_tab", "LazyGit", { "lazygit" })
tab_action("cmd+shift+g", "gh_dash_tab", "GH Dash", { "gh", "dash" })
tab_action("cmd+e", "editor_tab", "Editor", { "nvim", "+GoToFile" })
tab_action("cmd+shift+e", "editor_diff_tab", "Editor Diff", { "nvim", "+CodeDiffSolo" })
