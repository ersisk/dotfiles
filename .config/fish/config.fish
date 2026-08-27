#
# ███████╗██╗███████╗██╗  ██╗
# ██╔════╝██║██╔════╝██║  ██║
# █████╗  ██║███████╗███████║
# ██╔══╝  ██║╚════██║██╔══██║
# ██║     ██║███████║██║  ██║
# ╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝
# A smart and user-friendly command line
# https://fishshell.com/
# cSpell:words shellcode pkgx direnv
# Add Homebrew to PATH
if test -d /opt/homebrew/bin
    eval (/opt/homebrew/bin/brew shellenv)
end
starship init fish | source # https://starship.rs/
zoxide init fish | source # 'ajeetdsouza/zoxide'
fzf --fish | source
fnm --log-level quiet env --use-on-cd | source # "Schniz/fnm"
direnv hook fish | source # https://direnv.net/
fx --comp fish | source # https://fx.wtf/
# --disable-up-arrow: yukari ok fish'in kendi history'sinde kalsin, sadece ctrl-r atuin'e gitsin.
atuin init fish --disable-up-arrow | source # https://atuin.sh/
# atuin 18.19 bos satir basinda '?' ile dogal dil (AI) moduna giriyor; sync kapali kurulumda istemiyoruz.
bind -e '?' 2>/dev/null
set -g direnv_fish_mode eval_on_arrow # trigger direnv at prompt, and on every arrow-based directory change (default)

set -U fish_greeting # disable fish greeting


set -U fish_key_bindings fish_vi_key_bindings
set -Ux CLOUDSDK_PYTHON (which python3.13)
set -Ux OBSIDIAN_VAULT "~/obsidian-vault"
set -gx OLLAMA_ORIGINS "*"
set -Ux BAT_THEME "Kanagawa" # 'sharkdp/bat' cat clone
set -Ux EDITOR nvim # 'neovim/neovim' text editor
set -Ux FZF_DEFAULT_COMMAND "fd -H -E '.git'"
set -Ux EZA_CONFIG_DIR "~/.config/eza/"
# Kanagawa Wave; ton degerleri claude-tmux-notify ve tmux status bar ile ayni.
set -gx FZF_DEFAULT_OPTS (printf '%s ' \
    '--layout=reverse' \
    '--info=hidden' \
    '--ansi' \
    '--pointer=👉' \
    '--gutter=" "' \
    '--color=bg+:-1' \
    '--color=bg:-1' \
    '--color=fg:#dcd7ba' \
    '--color=fg+:#c8c093' \
    '--color=current-bg:-1' \
    '--color=current-fg:#7e9cd8' \
    '--color=gutter:-1' \
    '--color=header:#957fb8' \
    '--color=header-bg:-1' \
    '--color=header-border:#6a9589' \
    '--color=hl:#e6c384' \
    '--color=hl+:#ffa066' \
    '--color=info:#727169' \
    '--color=input-border:#e6c384' \
    '--color=list-border:#7e9cd8' \
    '--color=marker:#98bb6c' \
    '--color=pointer:#7e9cd8' \
    '--color=preview-border:#6a9589' \
    '--color=prompt:#98bb6c' \
    '--color=spinner:#ff9e3b' | string collect)

# TODO: fix colors of nvimpager
# set -Ux PAGER "~/.local/bin/nvimpager" # 'lucc/nvimpager'
set -Ux PAGER nvimpager

# golang - https://golang.google.cn/
set -Ux GOPATH (go env GOPATH)
fish_add_path $GOPATH/bin
fish_add_path $HOME/.rustup/toolchains/nightly-aarch64-apple-darwin/bin

fish_add_path $HOME/.config/bin # my custom scripts
fish_add_path $HOME/.cargo/bin
fish_add_path $HOME/Library/Python/3.9/bin

set copilot_cli_path (which copilot)

set -l foreground DCD7BA normal
set -l selection 2D4F67 brcyan
set -l comment 727169 brblack
set -l red C34043 red
set -l orange FF9E64 brred
set -l yellow C0A36E yellow
set -l green 76946A green
set -l purple 957FB8 magenta
set -l cyan 7AA89F cyan
set -l pink D27E99 brmagenta

# Syntax Highlighting Colors
set -g fish_color_normal $foreground
set -g fish_color_command $cyan
set -g fish_color_keyword $pink
set -g fish_color_quote $yellow
set -g fish_color_redirection $foreground
set -g fish_color_end $orange
set -g fish_color_error $red
set -g fish_color_param $purple
set -g fish_color_comment $comment
set -g fish_color_selection --background=$selection
set -g fish_color_search_match --background=$selection
set -g fish_color_operator $green
set -g fish_color_escape $pink
set -g fish_color_autosuggestion $comment

# Completion Pager Colors
set -g fish_pager_color_progress $comment
set -g fish_pager_color_prefix $cyan
set -g fish_pager_color_completion $foreground
set -g fish_pager_color_description $comment


#Aliases
alias ls="eza -a --icons --color --no-user --group-directories-first"
alias ll="eza -al --icons --color --group-directories-first"
alias la="eza -a --icons --color --group-directories-first"
alias vim="nvim"
alias vi="nvim"
alias vf="nvim +GoToFile"
alias vdf="nvim +CodeDiffSolo"
alias vp="NVIM_APPNAME=nvim-lite nvim"
alias shs="sesh_start"
alias dc="docker compose"
alias fzfe="fzf --print0 | xargs -0 -o nvim"
alias fzflg="fd -I -e log | gum filter --limit 1 --no-sort --fuzzy --placeholder 'Pick a Log' --height 50 --prompt='⚡' | xargs -r -o tail -f | hl -P"
alias fzfp="fzf --print0 | xargs -0 -o bat"
alias fzfssh="find ~/ssh -type f -name '*.sh' | fzf --print0 | xargs -0 -o bash"
alias cldy "claude --dangerously-skip-permissions"
alias lgs="log_search"
alias gbc="gbcleaner"
alias br="jira-to-branch"
alias ai="ai-oneshot"
alias dnv="diffnav"
alias sduck="s -p duckduckgo"
alias wt='git worktree'
alias sq="sesh connect lsq"
alias lzd="sesh connect lzd"

# The next line updates PATH for the Google Cloud SDK.
if test -f $HOME/google-cloud-sdk/path.fish.inc; source $HOME/google-cloud-sdk/path.fish.inc; end
