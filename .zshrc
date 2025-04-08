# Path to your oh-my-zsh installation.
plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-fzf-history-search web-search)
export ZSH="/Users/ersanisik/.oh-my-zsh"

source $ZSH/oh-my-zsh.sh

ZSH_WEB_SEARCH_ENGINES=(
    ddc "https://duckduckgo.com/?q=DuckDuckGo%20AI%20Chat&ia=chat&duckai=1&atb=v452-1"
    grok "https://grok.com?q="
)
# Starship 
eval "$(starship init zsh)"

#sesh
function ts() {
  {
    exec </dev/tty
    exec <&1
    local session
    session=$(sesh list -i --hide-duplicates | gum filter --limit 1 --no-sort --fuzzy --placeholder 'Pick a sesh' --height 50 --prompt='⚡')
    zle reset-prompt > /dev/null 2>&1 || true
    [[ -z "$session" ]] && return
    sesh connect $session
  }
}

zle     -N             ts
bindkey -M emacs '\es' ts
bindkey -M vicmd '\es' ts
bindkey -M viins '\es' ts

#zoxide
eval "$(zoxide init zsh)"

# FZF
eval "$(fzf --zsh)"
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git "
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS='--height 100% --layout=reverse
  --color fg:#6f737b,bg:#21252d
  --color bg+:#adc896,fg+:#282c34,hl:#abb2bf,hl+:#1e222a,gutter:#282c34
  --color pointer:#adc896,info:#abb2bf,border:#565c64
  --border=rounded
  --pointer="👉"'
export FZF_CTRL_T_OPTS="--preview 'bat --color=always -n --line-range :500 {}'"
export FZF_TMUX_OPTS=" -p90%,80% --layout=reverse --height 100% --color=bg:#21252d,fg:#6f737b,border:#565c64 --border=rounded"
#Editor
export EDITOR="nvim"


export PATH=/opt/homebrew/bin:$PATH
export NOTES_DIR=~/obsidian-vault
export EZA_CONFIG_DIR=~/.config/eza/

# ALIAS
alias al-list="print -rl -- ${(k)aliases} | fzf"

#Docker
alias docker-compose="docker compose"
alias dc=docker-compose  
alias dce="docker-compose exec app"
alias dcu-dev="docker-compose -f docker-compose-dev.yml  up -d"
alias d-node10="docker run -it --rm -v "$PWD":/usr/src/app -w /usr/src/app node:10"

#NVIM
alias envim="NVIM_APPNAME=envim nvim"
alias evi="NVIM_APPNAME=envim nvim"
alias evf="NVIM_APPNAME=envim nvim +GoToFile"
alias vi="nvim"
alias vf="nvim +GoToFile"
alias vim="nvim"
alias nvide="open -a Neovide.app"
alias rssn="newsboat -r"

alias ll='eza -al --icons=always --color=always --group-directories-first'
alias ls='eza --long --icons=always --color=always --no-user'

alias lg='lazygit'
alias lsql='lazysql'

alias fzn="fzf --print0 | xargs -0 -o nvim"
alias fzp="fzf --style full \
    --preview 'fzf-preview.sh {}' --bind 'focus:transform-header:file --brief {}'"

alias bb='/Users/ersanisik/bin/bb'
alias sesh_start='/Users/ersanisik/bin/sesh_start'
alias aws-ssh='/Users/ersanisik/bin/aws-ssh'
alias aws-con="find ~/ssh -type f -name '*.sh' | fzf --print0 | xargs -0 -o bash"
alias merged-b='/Users/ersanisik/bin/merged-branches_macos'
alias merged-dlb='git branch --merged | grep -v "\*" | grep -v "test" | grep -v "master" | grep -v "main" | grep -v "release" | grep -v "dev" | xargs -n 1 git branch -d'

alias loghub='loghub-cli'

alias notes=" find ~/obsidian-vault | fzf --print0 | xargs -0 -o nvim"
alias notesdaily='nvim $NOTES_DIR/Journals\(Günlük\)/$(date +"%Y-%m-%d.md")'

# Tmux
# Attaches tmux to a session (example: ta portal)
alias ta='tmux attach -t'
alias tn='tmux new-session -s '
alias tk='tmux kill-session -t '
alias tl='tmux list-sessions'
alias td='tmux detach'
alias th='tmux new-session -d -c ~/ -s home'
alias tc='clear; tmux clear-history; clear'

alias copilot="gh copilot explain"

bindkey '^P' up-history
bindkey '^N' down-history

dev-check() {
    if git branch -avvv 2>&1 | grep -q ': ahead '; then
        echo "You have unpushed commits. Are you sure you want to continue? (y/n)"
        read -r response
        if [ "$response" != "y" ]; then
            echo "Aborting."
            return 1
        fi
    fi

    if ! git diff-index --quiet HEAD --; then
        echo "You have uncommitted changes. Are you sure you want to continue? (y/n)"
        read -r response
        if [ "$response" != "y" ]; then
            echo "Aborting."
            return 1
        fi
    fi

    local response=$(bb pipeline custom "$(git symbolic-ref --short HEAD)" "dev-check" | xargs)
    local pipelineId=$(echo ${response##*/} | sed 's/\x1b\[[0-9;]*m//g' | tr -d '[:space:]')

    echo "$response"
    bb pipeline wait "$pipelineId"
}

export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#55403f'

. "$HOME/.local/bin/env"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
bindkey -r '\ec'
