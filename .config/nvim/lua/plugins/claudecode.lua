local tmux_provider = (function()
  local pane_id = nil

  local function is_pane_alive()
    if not pane_id then return false end
    local result = vim.fn.system("tmux display-message -t " .. pane_id .. " -p '#{pane_id}' 2>/dev/null")
    return vim.v.shell_error == 0 and result:match "%S"
  end

  local function create_pane(cmd_string, env_table)
    local args = { "tmux", "split-window", "-h", "-l", "50%", "-P", "-F", "#{pane_id}" }
    if env_table then
      for k, v in pairs(env_table) do
        table.insert(args, "-e")
        table.insert(args, k .. "=" .. tostring(v))
      end
    end
    table.insert(args, cmd_string)
    local output = vim.fn.system(args)
    pane_id = output:match "%%(%d+)"
    if pane_id then pane_id = "%" .. pane_id end
  end

  local function kill_pane()
    if pane_id then
      vim.fn.system("tmux kill-pane -t " .. pane_id)
      pane_id = nil
    end
  end

  local function focus_pane()
    if pane_id then vim.fn.system("tmux select-pane -t " .. pane_id) end
  end

  return {
    setup = function() end,

    open = function(cmd_string, env_table, _, focus)
      if not is_pane_alive() then create_pane(cmd_string, env_table) end
      if focus ~= false then focus_pane() end
    end,

    close = function() kill_pane() end,

    simple_toggle = function(cmd_string, env_table)
      if is_pane_alive() then
        kill_pane()
      else
        create_pane(cmd_string, env_table)
      end
    end,

    focus_toggle = function(cmd_string, env_table)
      if is_pane_alive() then
        focus_pane()
      else
        create_pane(cmd_string, env_table)
        focus_pane()
      end
    end,

    get_active_bufnr = function() return nil end,

    is_available = function() return vim.env.TMUX ~= nil end,
  }
end)()

return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  opts = {
    terminal = {
      provider = vim.env.TMUX and tmux_provider or "snacks",
    },
    -- Diff Integration
    diff_opts = {
      layout = "vertical", -- "vertical" or "horizontal"
      open_in_new_tab = true,
      keep_terminal_focus = false, -- If true, moves focus back to terminal after diff opens
      hide_terminal_in_new_tab = true,
      -- on_new_file_reject = "keep_empty", -- "keep_empty" or "close_window"
    },
  },
  cmd = {
    "ClaudeCode",
    "ClaudeCodeFocus",
    "ClaudeCodeSend",
    "ClaudeCodeAdd",
    "ClaudeCodeDiffAccept",
    "ClaudeCodeDiffDeny",
    "ClaudeCodeSelectModel",
    "ClaudeCodeTreeAdd",
  },
  keys = {
    { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude Code" },
    { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude Code" },
    { "<leader>av", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
    { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
    { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
    { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
    {
      "<leader>as",
      "<cmd>ClaudeCodeTreeAdd<cr>",
      desc = "Add file",
      ft = { "oil", "netrw" },
    },
    -- Diff management
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
  },
}
