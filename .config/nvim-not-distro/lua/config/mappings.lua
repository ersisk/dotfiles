local M = {}
function M.is_available(plugin)
  local lazy_config_avail, lazy_config = pcall(require, "lazy.core.config")
  return lazy_config_avail and lazy_config.spec.plugins[plugin] ~= nil
end

function M.empty_map_table()
  local maps = {}
  for _, mode in ipairs({ "", "n", "v", "x", "s", "o", "!", "i", "l", "c", "t" }) do
    maps[mode] = {}
  end
  if vim.fn.has("nvim-0.10.0") == 1 then
    for _, abbr_mode in ipairs({ "ia", "ca", "!a" }) do
      maps[abbr_mode] = {}
    end
  end
  return maps
end

function M.set_mappings(map_table, base)
  -- iterate over the first keys for each mode
  base = base or {}
  for mode, maps in pairs(map_table) do
    -- iterate over each keybinding set in the current mode
    for keymap, options in pairs(maps) do
      -- build the options for the command accordingly
      if options then
        local cmd = options
        local keymap_opts = base
        if type(options) == "table" then
          cmd = options[1]
          keymap_opts = vim.tbl_deep_extend("force", keymap_opts, options)
          keymap_opts[1] = nil
        end
        if not cmd or keymap_opts.name then -- if which-key mapping, queue it
          if not keymap_opts.name then
            keymap_opts.name = keymap_opts.desc
          end
          if not M.which_key_queue then
            M.which_key_queue = {}
          end
          if not M.which_key_queue[mode] then
            M.which_key_queue[mode] = {}
          end
          M.which_key_queue[mode][keymap] = keymap_opts
        else -- if not which-key mapping, set it
          vim.keymap.set(mode, keymap, cmd, keymap_opts)
        end
      end
    end
  end
  if package.loaded["which-key"] then
    M.which_key_register()
  end -- if which-key is loaded already, register
end

local maps = M.empty_map_table()

local sections = {
  f = { desc = "Find" },
  p = { desc = "Packages" },
  l = { desc = "LSP" },
  u = { desc = "UI/UX" },
  b = { desc = "Buffers" },
  bs = { desc = "Sort Buffers" },
  d = { desc = "Debugger" },
  g = { desc = "Git" },
  S = { desc = "Session" },
  t = { desc = "Terminal" },
}

-- Normal --
-- Standard Operations
maps.n["j"] = { "v:count == 0 ? 'gj' : 'j'", expr = true, desc = "Move cursor down" }
maps.n["k"] = { "v:count == 0 ? 'gk' : 'k'", expr = true, desc = "Move cursor up" }
maps.n["<leader>w"] = { "<cmd>w<cr>", desc = "Save" }
maps.n["<leader>q"] = { "<cmd>confirm q<cr>", desc = "Quit" }
maps.n["<leader>Q"] = { "<cmd>confirm qall<cr>", desc = "Quit all" }
maps.n["<leader>n"] = { "<cmd>enew<cr>", desc = "New File" }
maps.n["<C-s>"] = { "<cmd>w!<cr>", desc = "Force write" }
maps.n["<C-q>"] = { "<cmd>qa!<cr>", desc = "Force quit" }
maps.n["|"] = { "<cmd>vsplit<cr>", desc = "Vertical Split" }
maps.n["\\"] = { "<cmd>split<cr>", desc = "Horizontal Split" }
-- TODO: Remove when dropping support for <Neovim v0.10
-- if not vim.ui.open then
-- 	maps.n["gx"] = { utils.system_open, desc = "Open the file under cursor with system app" }
-- end

-- Plugin Manager
maps.n["<leader>p"] = sections.p
maps.n["<leader>pi"] = {
  function()
    require("lazy").install()
  end,
  desc = "Plugins Install",
}
maps.n["<leader>ps"] = {
  function()
    require("lazy").home()
  end,
  desc = "Plugins Status",
}
maps.n["<leader>pS"] = {
  function()
    require("lazy").sync()
  end,
  desc = "Plugins Sync",
}
maps.n["<leader>pu"] = {
  function()
    require("lazy").check()
  end,
  desc = "Plugins Check Updates",
}
maps.n["<leader>pU"] = {
  function()
    require("lazy").update()
  end,
  desc = "Plugins Update",
}

-- Manage Buffers
maps.n["<leader>c"] = {
  function()
    require("config.buffer").close()
  end,
  desc = "Close buffer",
}
maps.n["<leader>bq"] = {
  desc = "Find and Close",
  function()
    local action_state = require('telescope.actions.state')
    local actions = require('telescope.actions')
    require 'telescope.builtin'.buffers {
      attach_mappings = function(prompt_bufnr, map)
        local delete_buf = function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          vim.api.nvim_buf_delete(selection.bufnr, { force = true })
        end

        map('i', '<c-u>', delete_buf)

        return true
      end
    }
  end,
}
maps.n["<leader>C"] = {
  function()
    require("config.buffer").close(0, true)
  end,
  desc = "Force close buffer",
}
maps.n["]b"] = {
  function()
    require("config.buffer").nav(vim.v.count > 0 and vim.v.count or 1)
  end,
  desc = "Next buffer",
}
maps.n["[b"] = {
  function()
    require("config.buffer").nav(-(vim.v.count > 0 and vim.v.count or 1))
  end,
  desc = "Previous buffer",
}
maps.n[">b"] = {
  function()
    require("config.buffer").move(vim.v.count > 0 and vim.v.count or 1)
  end,
  desc = "Move buffer tab right",
}
maps.n["<b"] = {
  function()
    require("config.buffer").move(-(vim.v.count > 0 and vim.v.count or 1))
  end,
  desc = "Move buffer tab left",
}

maps.n["<leader>b"] = sections.b
maps.n["<leader>bc"] = {
  function()
    require("config.buffer").close_all(true)
  end,
  desc = "Close all buffers except current",
}
maps.n["<leader>bC"] = {
  function()
    require("config.buffer").close_all()
  end,
  desc = "Close all buffers",
}
maps.n["<leader>bl"] = {
  function()
    require("config.buffer").close_left()
  end,
  desc = "Close all buffers to the left",
}
maps.n["<leader>bp"] = {
  function()
    require("config.buffer").prev()
  end,
  desc = "Previous buffer",
}
maps.n["<leader>br"] = {
  function()
    require("config.buffer").close_right()
  end,
  desc = "Close all buffers to the right",
}
maps.n["<leader>bs"] = sections.bs
maps.n["<leader>bse"] = {
  function()
    require("config.buffer").sort("extension")
  end,
  desc = "By extension",
}
maps.n["<leader>bsr"] = {
  function()
    require("config.buffer").sort("unique_path")
  end,
  desc = "By relative path",
}
maps.n["<leader>bsp"] = {
  function()
    require("config.buffer").sort("full_path")
  end,
  desc = "By full path",
}
maps.n["<leader>bsi"] = {
  function()
    require("config.buffer").sort("bufnr")
  end,
  desc = "By buffer number",
}
maps.n["<leader>bsm"] = {
  function()
    require("config.buffer").sort("modified")
  end,
  desc = "By modification",
}

-- Navigate tabs
maps.n["]t"] = {
  function()
    vim.cmd.tabnext()
  end,
  desc = "Next tab",
}
maps.n["[t"] = {
  function()
    vim.cmd.tabprevious()
  end,
  desc = "Previous tab",
}

-- Alpha
-- if is_available("alpha-nvim") then
-- 	maps.n["<leader>h"] = {
-- 		function()
-- 			local wins = vim.api.nvim_tabpage_list_wins(0)
-- 			if #wins > 1 and vim.api.nvim_get_option_value("filetype", { win = wins[1] }) == "neo-tree" then
-- 				vim.fn.win_gotoid(wins[2]) -- go to non-neo-tree window to toggle alpha
-- 			end
-- 			require("alpha").start(false, require("alpha").default_config)
-- 		end,
-- 		desc = "Home Screen",
-- 	}
-- end
--
-- Comment
-- if is_available("Comment.nvim") then
-- 	maps.n["<leader>/"] = {
-- 		function()
-- 			require("Comment.api").toggle.linewise.count(vim.v.count > 0 and vim.v.count or 1)
-- 		end,
-- 		desc = "Toggle comment line",
-- 	}
-- 	maps.v["<leader>/"] = {
-- 		"<esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<cr>",
-- 		desc = "Toggle comment for selection",
-- 	}
-- end

-- GitSigns
-- if is_available("gitsigns.nvim") then
-- 	maps.n["<leader>g"] = sections.g
-- 	maps.n["]g"] = {
-- 		function()
-- 			require("gitsigns").next_hunk()
-- 		end,
-- 		desc = "Next Git hunk",
-- 	}
-- 	maps.n["[g"] = {
-- 		function()
-- 			require("gitsigns").prev_hunk()
-- 		end,
-- 		desc = "Previous Git hunk",
-- 	}
-- 	maps.n["<leader>gl"] = {
-- 		function()
-- 			require("gitsigns").blame_line()
-- 		end,
-- 		desc = "View Git blame",
-- 	}
-- 	maps.n["<leader>gL"] = {
-- 		function()
-- 			require("gitsigns").blame_line({ full = true })
-- 		end,
-- 		desc = "View full Git blame",
-- 	}
-- 	maps.n["<leader>gp"] = {
-- 		function()
-- 			require("gitsigns").preview_hunk()
-- 		end,
-- 		desc = "Preview Git hunk",
-- 	}
-- 	maps.n["<leader>gh"] = {
-- 		function()
-- 			require("gitsigns").reset_hunk()
-- 		end,
-- 		desc = "Reset Git hunk",
-- 	}
-- 	maps.n["<leader>gr"] = {
-- 		function()
-- 			require("gitsigns").reset_buffer()
-- 		end,
-- 		desc = "Reset Git buffer",
-- 	}
-- 	maps.n["<leader>gs"] = {
-- 		function()
-- 			require("gitsigns").stage_hunk()
-- 		end,
-- 		desc = "Stage Git hunk",
-- 	}
-- 	maps.n["<leader>gS"] = {
-- 		function()
-- 			require("gitsigns").stage_buffer()
-- 		end,
-- 		desc = "Stage Git buffer",
-- 	}
-- 	maps.n["<leader>gu"] = {
-- 		function()
-- 			require("gitsigns").undo_stage_hunk()
-- 		end,
-- 		desc = "Unstage Git hunk",
-- 	}
-- 	maps.n["<leader>gd"] = {
-- 		function()
-- 			require("gitsigns").diffthis()
-- 		end,
-- 		desc = "View Git diff",
-- 	}
-- end

-- NeoTree
maps.n["<leader>e"] = { "<cmd>Neotree toggle<cr>", desc = "Toggle Explorer" }
maps.n["<leader>o"] = {
  function()
    if vim.bo.filetype == "neo-tree" then
      vim.cmd.wincmd("p")
    else
      vim.cmd.Neotree("focus")
    end
  end,
  desc = "Toggle Explorer Focus",
}

-- Session Manager
-- if is_available("neovim-session-manager") then
-- 	maps.n["<leader>S"] = sections.S
-- 	maps.n["<leader>Sl"] = { "<cmd>SessionManager! load_last_session<cr>", desc = "Load last session" }
-- 	maps.n["<leader>Ss"] = { "<cmd>SessionManager! save_current_session<cr>", desc = "Save this session" }
-- 	maps.n["<leader>Sd"] = { "<cmd>SessionManager! delete_session<cr>", desc = "Delete session" }
-- 	maps.n["<leader>Sf"] = { "<cmd>SessionManager! load_session<cr>", desc = "Search sessions" }
-- 	maps.n["<leader>S."] =
-- 		{ "<cmd>SessionManager! load_current_dir_session<cr>", desc = "Load current directory session" }
-- end
-- if is_available("resession.nvim") then
-- 	maps.n["<leader>S"] = sections.S
-- 	maps.n["<leader>Sl"] = {
-- 		function()
-- 			require("resession").load("Last Session")
-- 		end,
-- 		desc = "Load last session",
-- 	}
-- 	maps.n["<leader>Ss"] = {
-- 		function()
-- 			require("resession").save()
-- 		end,
-- 		desc = "Save this session",
-- 	}
-- 	maps.n["<leader>St"] = {
-- 		function()
-- 			require("resession").save_tab()
-- 		end,
-- 		desc = "Save this tab's session",
-- 	}
-- 	maps.n["<leader>Sd"] = {
-- 		function()
-- 			require("resession").delete()
-- 		end,
-- 		desc = "Delete a session",
-- 	}
-- 	maps.n["<leader>Sf"] = {
-- 		function()
-- 			require("resession").load()
-- 		end,
-- 		desc = "Load a session",
-- 	}
-- 	maps.n["<leader>S."] = {
-- 		function()
-- 			require("resession").load(vim.fn.getcwd(), { dir = "dirsession" })
-- 		end,
-- 		desc = "Load current directory session",
-- 	}
-- end

-- Package Manager
maps.n["<leader>pm"] = { "<cmd>Mason<cr>", desc = "Mason Installer" }
maps.n["<leader>pM"] = { "<cmd>MasonUpdateAll<cr>", desc = "Mason Update" }

-- Smart Splits
-- if is_available("smart-splits.nvim") then
-- 	maps.n["<C-h>"] = {
-- 		function()
-- 			require("smart-splits").move_cursor_left()
-- 		end,
-- 		desc = "Move to left split",
-- 	}
-- 	maps.n["<C-j>"] = {
-- 		function()
-- 			require("smart-splits").move_cursor_down()
-- 		end,
-- 		desc = "Move to below split",
-- 	}
-- 	maps.n["<C-k>"] = {
-- 		function()
-- 			require("smart-splits").move_cursor_up()
-- 		end,
-- 		desc = "Move to above split",
-- 	}
-- 	maps.n["<C-l>"] = {
-- 		function()
-- 			require("smart-splits").move_cursor_right()
-- 		end,
-- 		desc = "Move to right split",
-- 	}
-- 	maps.n["<C-Up>"] = {
-- 		function()
-- 			require("smart-splits").resize_up()
-- 		end,
-- 		desc = "Resize split up",
-- 	}
-- 	maps.n["<C-Down>"] = {
-- 		function()
-- 			require("smart-splits").resize_down()
-- 		end,
-- 		desc = "Resize split down",
-- 	}
-- 	maps.n["<C-Left>"] = {
-- 		function()
-- 			require("smart-splits").resize_left()
-- 		end,
-- 		desc = "Resize split left",
-- 	}
-- 	maps.n["<C-Right>"] = {
-- 		function()
-- 			require("smart-splits").resize_right()
-- 		end,
-- 		desc = "Resize split right",
-- 	}
-- else
-- 	maps.n["<C-h>"] = { "<C-w>h", desc = "Move to left split" }
-- 	maps.n["<C-j>"] = { "<C-w>j", desc = "Move to below split" }
-- 	maps.n["<C-k>"] = { "<C-w>k", desc = "Move to above split" }
-- 	maps.n["<C-l>"] = { "<C-w>l", desc = "Move to right split" }
-- 	maps.n["<C-Up>"] = { "<cmd>resize -2<CR>", desc = "Resize split up" }
-- 	maps.n["<C-Down>"] = { "<cmd>resize +2<CR>", desc = "Resize split down" }
-- 	maps.n["<C-Left>"] = { "<cmd>vertical resize -2<CR>", desc = "Resize split left" }
-- 	maps.n["<C-Right>"] = { "<cmd>vertical resize +2<CR>", desc = "Resize split right" }
-- end

-- SymbolsOutline
-- if is_available("aerial.nvim") then
-- 	maps.n["<leader>l"] = sections.l
-- 	maps.n["<leader>lS"] = {
-- 		function()
-- 			require("aerial").toggle()
-- 		end,
-- 		desc = "Symbols outline",
-- 	}
-- end

-- Telescope
maps.n["<leader>f"] = sections.f
maps.n["<leader>g"] = sections.g
maps.n["<leader>gb"] = {
  function()
    require("telescope.builtin").git_branches({ use_file_path = true })
  end,
  desc = "Git branches",
}
maps.n["<leader>gc"] = {
  function()
    require("telescope.builtin").git_commits({ use_file_path = true })
  end,
  desc = "Git commits (repository)",
}
maps.n["<leader>gC"] = {
  function()
    require("telescope.builtin").git_bcommits({ use_file_path = true })
  end,
  desc = "Git commits (current file)",
}
maps.n["<leader>gt"] = {
  function()
    require("telescope.builtin").git_status({ use_file_path = true })
  end,
  desc = "Git status",
}
maps.n["<leader>f<CR>"] = {
  function()
    require("telescope.builtin").resume()
  end,
  desc = "Resume previous search",
}
maps.n["<leader>f'"] = {
  function()
    require("telescope.builtin").marks()
  end,
  desc = "Find marks",
}
maps.n["<leader>f/"] = {
  function()
    require("telescope.builtin").current_buffer_fuzzy_find()
  end,
  desc = "Find words in current buffer",
}

maps.n["<leader>fb"] = {
  function()
    require("telescope.builtin").buffers()
  end,
  desc = "Find buffers",
}
maps.n["<leader>fc"] = {
  function()
    require("telescope.builtin").grep_string()
  end,
  desc = "Find word under cursor",
}
maps.n["<leader>fC"] = {
  function()
    require("telescope.builtin").commands()
  end,
  desc = "Find commands",
}
maps.n["<leader>ff"] = {
  function()
    require("telescope.builtin").find_files()
  end,
  desc = "Find files",
}
maps.n["<leader>fF"] = {
  function()
    require("telescope.builtin").find_files({ hidden = true, no_ignore = true })
  end,
  desc = "Find all files",
}
maps.n["<leader>fh"] = {
  function()
    require("telescope.builtin").help_tags()
  end,
  desc = "Find help",
}
maps.n["<leader>fk"] = {
  function()
    require("telescope.builtin").keymaps()
  end,
  desc = "Find keymaps",
}
maps.n["<leader>fm"] = {
  function()
    require("telescope.builtin").man_pages()
  end,
  desc = "Find man",
}
maps.n["<leader>fn"] = {
  function()
    require("telescope").extensions.notify.notify()
  end,
  desc = "Find notifications",
}
maps.n["<leader>fo"] = {
  function()
    require("telescope.builtin").oldfiles()
  end,
  desc = "Find history",
}
maps.n["<leader>fr"] = {
  function()
    require("telescope.builtin").registers()
  end,
  desc = "Find registers",
}
maps.n["<leader>ft"] = {
  function()
    require("telescope.builtin").colorscheme({ enable_preview = true })
  end,
  desc = "Find themes",
}
maps.n["<leader>fw"] = {
  function()
    require("telescope.builtin").live_grep()
  end,
  desc = "Find words",
}
maps.n["<leader>fW"] = {
  function()
    require("telescope.builtin").live_grep({
      additional_args = function(args)
        return vim.list_extend(args, { "--hidden", "--no-ignore" })
      end,
    })
  end,
  desc = "Find words in all files",
}
maps.n["<leader>l"] = sections.l
maps.n["<leader>ls"] = {
  function()
    local aerial_avail, _ = pcall(require, "aerial")
    if aerial_avail then
      require("telescope").extensions.aerial.aerial()
    else
      require("telescope.builtin").lsp_document_symbols()
    end
  end,
  desc = "Search symbols",
}
maps.n["<leader>lf"] = {
  function()
    vim.lsp.buf.format()
  end,
  desc = "Format Buffer",
}

-- Terminal
-- if is_available("toggleterm.nvim") then
-- 	maps.n["<leader>t"] = sections.t
-- 	if vim.fn.executable("lazygit") == 1 then
-- 		maps.n["<leader>g"] = sections.g
-- 		maps.n["<leader>gg"] = {
-- 			function()
-- 				local flags = worktree and (" --work-tree=%s --git-dir=%s"):format(worktree.toplevel, worktree.gitdir)
-- 					or ""
-- 				utils.toggle_term_cmd("lazygit " .. flags)
-- 			end,
-- 			desc = "ToggleTerm lazygit",
-- 		}
-- 		maps.n["<leader>tl"] = maps.n["<leader>gg"]
-- 	end
-- 	if vim.fn.executable("node") == 1 then
-- 		maps.n["<leader>tn"] = {
-- 			function()
-- 				utils.toggle_term_cmd("node")
-- 			end,
-- 			desc = "ToggleTerm node",
-- 		}
-- 	end
-- 	if vim.fn.executable("gdu") == 1 then
-- 		maps.n["<leader>tu"] = {
-- 			function()
-- 				utils.toggle_term_cmd("gdu")
-- 			end,
-- 			desc = "ToggleTerm gdu",
-- 		}
-- 	end
-- 	if vim.fn.executable("btm") == 1 then
-- 		maps.n["<leader>tt"] = {
-- 			function()
-- 				utils.toggle_term_cmd("btm")
-- 			end,
-- 			desc = "ToggleTerm btm",
-- 		}
-- 	end
-- 	local python = vim.fn.executable("python") == 1 and "python" or vim.fn.executable("python3") == 1 and "python3"
-- 	if python then
-- 		maps.n["<leader>tp"] = {
-- 			function()
-- 				utils.toggle_term_cmd(python)
-- 			end,
-- 			desc = "ToggleTerm python",
-- 		}
-- 	end
-- 	maps.n["<leader>tf"] = { "<cmd>ToggleTerm direction=float<cr>", desc = "ToggleTerm float" }
-- 	maps.n["<leader>th"] = { "<cmd>ToggleTerm size=10 direction=horizontal<cr>", desc = "ToggleTerm horizontal split" }
-- 	maps.n["<leader>tv"] = { "<cmd>ToggleTerm size=80 direction=vertical<cr>", desc = "ToggleTerm vertical split" }
-- 	maps.n["<F7>"] = { "<cmd>ToggleTerm<cr>", desc = "Toggle terminal" }
-- 	maps.t["<F7>"] = maps.n["<F7>"]
-- 	maps.n["<C-'>"] = maps.n["<F7>"] -- requires terminal that supports binding <C-'>
-- 	maps.t["<C-'>"] = maps.n["<F7>"] -- requires terminal that supports binding <C-'>
-- end

if M.is_available("nvim-dap") then
  maps.n["<leader>d"] = sections.d
  maps.v["<leader>d"] = sections.d
  -- modified function keys found with `showkey -a` in the terminal to get key code
  -- run `nvim -V3log +quit` and search through the "Terminal info" in the `log` file for the correct keyname
  maps.n["<F5>"] = {
    function()
      require("dap").continue()
    end,
    desc = "Debugger: Start",
  }
  maps.n["<F17>"] = {
    function()
      require("dap").terminate()
    end,
    desc = "Debugger: Stop",
  }                   -- Shift+F5
  maps.n["<F21>"] = { -- Shift+F9
    function()
      vim.ui.input({ prompt = "Condition: " }, function(condition)
        if condition then
          require("dap").set_breakpoint(condition)
        end
      end)
    end,
    desc = "Debugger: Conditional Breakpoint",
  }
  maps.n["<F29>"] = {
    function()
      require("dap").restart_frame()
    end,
    desc = "Debugger: Restart",
  } -- Control+F5
  maps.n["<F6>"] = {
    function()
      require("dap").pause()
    end,
    desc = "Debugger: Pause",
  }
  maps.n["<F9>"] = {
    function()
      require("dap").toggle_breakpoint()
    end,
    desc = "Debugger: Toggle Breakpoint",
  }
  maps.n["<F10>"] = {
    function()
      require("dap").step_over()
    end,
    desc = "Debugger: Step Over",
  }
  maps.n["<F11>"] = {
    function()
      require("dap").step_into()
    end,
    desc = "Debugger: Step Into",
  }
  maps.n["<F23>"] = {
    function()
      require("dap").step_out()
    end,
    desc = "Debugger: Step Out",
  } -- Shift+F11
  maps.n["<leader>db"] = {
    function()
      require("dap").toggle_breakpoint()
    end,
    desc = "Toggle Breakpoint (F9)",
  }
  maps.n["<leader>dB"] = {
    function()
      require("dap").clear_breakpoints()
    end,
    desc = "Clear Breakpoints",
  }
  maps.n["<leader>dc"] = {
    function()
      require("dap").continue()
    end,
    desc = "Start/Continue (F5)",
  }
  maps.n["<leader>dC"] = {
    function()
      vim.ui.input({ prompt = "Condition: " }, function(condition)
        if condition then
          require("dap").set_breakpoint(condition)
        end
      end)
    end,
    desc = "Conditional Breakpoint (S-F9)",
  }
  maps.n["<leader>di"] = {
    function()
      require("dap").step_into()
    end,
    desc = "Step Into (F11)",
  }
  maps.n["<leader>do"] = {
    function()
      require("dap").step_over()
    end,
    desc = "Step Over (F10)",
  }
  maps.n["<leader>dO"] = {
    function()
      require("dap").step_out()
    end,
    desc = "Step Out (S-F11)",
  }
  maps.n["<leader>dq"] = {
    function()
      require("dap").close()
    end,
    desc = "Close Session",
  }
  maps.n["<leader>dQ"] = {
    function()
      require("dap").terminate()
    end,
    desc = "Terminate Session (S-F5)",
  }
  maps.n["<leader>dp"] = {
    function()
      require("dap").pause()
    end,
    desc = "Pause (F6)",
  }
  maps.n["<leader>dr"] = {
    function()
      require("dap").restart_frame()
    end,
    desc = "Restart (C-F5)",
  }
  maps.n["<leader>dR"] = {
    function()
      require("dap").repl.toggle()
    end,
    desc = "Toggle REPL",
  }
  maps.n["<leader>ds"] = {
    function()
      require("dap").run_to_cursor()
    end,
    desc = "Run To Cursor",
  }

  if M.is_available("nvim-dap-ui") then
    maps.n["<leader>dE"] = {
      function()
        vim.ui.input({ prompt = "Expression: " }, function(expr)
          if expr then
            require("dapui").eval(expr, { enter = true })
          end
        end)
      end,
      desc = "Evaluate Input",
    }
    maps.v["<leader>dE"] = {
      function()
        require("dapui").eval()
      end,
      desc = "Evaluate Input",
    }
    maps.n["<leader>du"] = {
      function()
        require("dapui").toggle()
      end,
      desc = "Toggle Debugger UI",
    }
    maps.n["<leader>dh"] = {
      function()
        require("dap.ui.widgets").hover()
      end,
      desc = "Debugger Hover",
    }
  end
end

-- Improved Code Folding
-- if is_available("nvim-ufo") then
-- 	maps.n["zR"] = {
-- 		function()
-- 			require("ufo").openAllFolds()
-- 		end,
-- 		desc = "Open all folds",
-- 	}
-- 	maps.n["zM"] = {
-- 		function()
-- 			require("ufo").closeAllFolds()
-- 		end,
-- 		desc = "Close all folds",
-- 	}
-- 	maps.n["zr"] = {
-- 		function()
-- 			require("ufo").openFoldsExceptKinds()
-- 		end,
-- 		desc = "Fold less",
-- 	}
-- 	maps.n["zm"] = {
-- 		function()
-- 			require("ufo").closeFoldsWith()
-- 		end,
-- 		desc = "Fold more",
-- 	}
-- 	maps.n["zp"] = {
-- 		function()
-- 			require("ufo").peekFoldedLinesUnderCursor()
-- 		end,
-- 		desc = "Peek fold",
-- 	}
-- end

-- Stay in indent mode
maps.v["<S-Tab>"] = { "<gv", desc = "Unindent line" }
maps.v["<Tab>"] = { ">gv", desc = "Indent line" }

-- Improved Terminal Navigation
maps.t["<C-h>"] = { "<cmd>wincmd h<cr>", desc = "Terminal left window navigation" }
maps.t["<C-j>"] = { "<cmd>wincmd j<cr>", desc = "Terminal down window navigation" }
maps.t["<C-k>"] = { "<cmd>wincmd k<cr>", desc = "Terminal up window navigation" }
maps.t["<C-l>"] = { "<cmd>wincmd l<cr>", desc = "Terminal right window navigation" }

maps.n["<leader>u"] = sections.u
-- Custom menu for modification of the user experience
-- if is_available("nvim-autopairs") then
-- 	maps.n["<leader>ua"] = { ui.toggle_autopairs, desc = "Toggle autopairs" }
-- end
-- maps.n["<leader>ub"] = { ui.toggle_background, desc = "Toggle background" }
-- if is_available("nvim-cmp") then
-- 	maps.n["<leader>uc"] = { ui.toggle_cmp, desc = "Toggle autocompletion" }
-- end
-- if is_available("nvim-colorizer.lua") then
-- 	maps.n["<leader>uC"] = { "<cmd>ColorizerToggle<cr>", desc = "Toggle color highlight" }
-- end
-- maps.n["<leader>ud"] = { ui.toggle_diagnostics, desc = "Toggle diagnostics" }
-- maps.n["<leader>ug"] = { ui.toggle_signcolumn, desc = "Toggle signcolumn" }
-- maps.n["<leader>ui"] = { ui.set_indent, desc = "Change indent setting" }
-- maps.n["<leader>ul"] = { ui.toggle_statusline, desc = "Toggle statusline" }
-- maps.n["<leader>uL"] = { ui.toggle_codelens, desc = "Toggle CodeLens" }
-- maps.n["<leader>un"] = { ui.change_number, desc = "Change line numbering" }
-- maps.n["<leader>uN"] = { ui.toggle_ui_notifications, desc = "Toggle Notifications" }
-- maps.n["<leader>up"] = { ui.toggle_paste, desc = "Toggle paste mode" }
-- maps.n["<leader>us"] = { ui.toggle_spell, desc = "Toggle spellcheck" }
-- maps.n["<leader>uS"] = { ui.toggle_conceal, desc = "Toggle conceal" }
-- maps.n["<leader>ut"] = { ui.toggle_tabline, desc = "Toggle tabline" }
-- maps.n["<leader>uu"] = { ui.toggle_url_match, desc = "Toggle URL highlight" }
-- maps.n["<leader>uw"] = { ui.toggle_wrap, desc = "Toggle wrap" }
-- maps.n["<leader>uy"] = { ui.toggle_syntax, desc = "Toggle syntax highlighting (buffer)" }
-- maps.n["<leader>uh"] = { ui.toggle_foldcolumn, desc = "Toggle foldcolumn" }
--
M.set_mappings(maps)
return M
