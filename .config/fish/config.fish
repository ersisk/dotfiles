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
# Inlined `brew shellenv fish` output: saves a ~10ms subprocess per shell. Re-diff after major brew upgrades.
if test -d /opt/homebrew/bin
    set -gx HOMEBREW_PREFIX /opt/homebrew
    set -gx HOMEBREW_CELLAR /opt/homebrew/Cellar
    set -gx HOMEBREW_REPOSITORY /opt/homebrew
    fish_add_path --global --move --path /opt/homebrew/bin /opt/homebrew/sbin
    if test -n "$MANPATH"; set -gx MANPATH (string replace --regex '^:*(.*?):*$' ':$1' -- "$MANPATH"); end
    if not set -q INFOPATH; set INFOPATH ''; end; set -gx INFOPATH /opt/homebrew/share/info $INFOPATH
end
# Each init is a 3-12ms subprocess per shell. Their output is deterministic, so cache it keyed on
# the resolved binary (a versioned Cellar path, so an upgrade invalidates it) plus the arguments.
function __cached_init --argument-names name
    set -l bin (command -s $name); or return
    set -l key "# "(path resolve $bin)" $argv[2..]"
    set -l cache (set -q XDG_CACHE_HOME; and echo $XDG_CACHE_HOME; or echo $HOME/.cache)/fish-init/$name.fish
    set -l first
    test -r $cache; and read first <$cache
    if test "$first" != "$key"
        mkdir -p (path dirname $cache)
        begin
            echo $key
            command $argv
        end >$cache
    end
    source $cache
end
__cached_init starship init fish --print-full-init # https://starship.rs/
__cached_init zoxide init fish # 'ajeetdsouza/zoxide'
__cached_init fzf --fish
# Not cached: the output names a per-shell multishell path.
fnm --log-level quiet env --use-on-cd | source # "Schniz/fnm"
# Homebrew's vendor_conf.d/direnv.fish already hooks it before this file runs; a second hook cost ~4ms.
functions -q __direnv_export_eval; or direnv hook fish | source # https://direnv.net/
__cached_init fx --comp fish # https://fx.wtf/
# --disable-up-arrow: keep the up arrow on fish's own history, send only ctrl-r to atuin.
__cached_init atuin init fish --disable-up-arrow # https://atuin.sh/
functions -e __cached_init
# atuin 18.19 enters natural-language (AI) mode on '?' at the start of an empty line; not wanted on a sync-off setup.
bind -e '?' 2>/dev/null
set -g direnv_fish_mode eval_on_arrow # trigger direnv at prompt, and on every arrow-based directory change (default)

set -U fish_greeting # disable fish greeting


set -U fish_key_bindings fish_vi_key_bindings
set -gx CLOUDSDK_PYTHON /opt/homebrew/bin/python3.14
set -gx OBSIDIAN_VAULT $HOME/obsidian-vault
set -gx OLLAMA_ORIGINS "*"
set -gx BAT_THEME "Kanagawa" # 'sharkdp/bat' cat clone
set -gx EDITOR nvim # 'neovim/neovim' text editor
set -gx FZF_DEFAULT_COMMAND "fd -H -E '.git'"
set -gx EZA_CONFIG_DIR $HOME/.config/eza/
# Kanagawa Wave; the tone values match agent-tmux-notify and the tmux status bar.
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
set -gx PAGER nvimpager

# golang - https://golang.google.cn/
set -q GOPATH; or set -Ux GOPATH (go env GOPATH)
fish_add_path $GOPATH/bin
fish_add_path $HOME/.rustup/toolchains/nightly-aarch64-apple-darwin/bin

fish_add_path $HOME/.config/bin # my custom scripts
fish_add_path $HOME/.cargo/bin

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
alias gclean="gbcleaner"
alias br="jira-to-branch"
alias ai="ai-oneshot"
alias dnv="diffnav"
alias sduck="s -p duckduckgo"
alias wt='git worktree'
alias sq="sesh connect lsq"
alias lzd="sesh connect lzd"

# Google Cloud SDK: path.fish.inc only prepends bin/, but its two `builtin cd`s fire the zoxide hook on every shell.
if test -d $HOME/google-cloud-sdk/bin; fish_add_path --global --path $HOME/google-cloud-sdk/bin; end

# kilo
fish_add_path /Users/ersanisik/.kilo/bin

# Added by Antigravity IDE
fish_add_path /Users/ersanisik/.antigravity-ide/antigravity-ide/bin
