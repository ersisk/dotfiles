# Path to your oh-my-zsh installation.
plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-fzf-history-search web-search)
export ZSH="/Users/ersanisik/.oh-my-zsh"

source $ZSH/oh-my-zsh.sh

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
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"
export FZF_DEFAULT_OPTS='--height 50% --layout=default
  --color fg:#6f737b,bg:#21252d
  --color bg+:#adc896,fg+:#282c34,hl:#abb2bf,hl+:#1e222a,gutter:#282c34
  --color pointer:#adc896,info:#abb2bf,border:#565c64
  --border'
export FZF_CTRL_T_OPTS="--preview 'bat --color=always -n --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --icons=always --tree --color=always {} | head -200'"
export FZF_TMUX_OPTS=" -p90%,70% "

#Editor
export EDITOR="nvim"


export PATH=/opt/homebrew/bin:$PATH
export NOTES_DIR=~/obsidian-vault
export EZA_CONFIG_DIR=~/.config/eza/

alias al-list="print -rl -- ${(k)aliases} | fzf"
# ALIAS
alias dbang="gobang"

#Docker
alias docker-compose="docker compose"
alias dc=docker-compose  
alias dce="docker-compose exec app"
alias dcu-dev="docker-compose -f docker-compose-dev.yml  up -d"
alias d-node10="docker run -it --rm -v "$PWD":/usr/src/app -w /usr/src/app node:10"

#NVIM
alias nv="nvim"
alias nvp="nvim ."
alias nvf="nvim +GoToFile"
alias vi="nvim"
alias vim="nvim"

alias ll='eza -al --icons=always --group-directories-first'
alias ls='eza --no-filesize --long --icons=always --color=always --no-user'

alias lg='lazygit'

alias merged-b='/Users/ersanisik/bin/merged-branches_macos'
alias merged-dlb='git branch --merged | grep -v "\*" | grep -v "test" | grep -v "master" | grep -v "main" | grep -v "release" | grep -v "dev" | xargs -n 1 git branch -d'

alias fzf-nv="fzf --print0 | xargs -0 -o nvim"
alias fzf-f="fzf --style full \
    --preview 'fzf-preview.sh {}' --bind 'focus:transform-header:file --brief {}'"

alias bb='/Users/ersanisik/bin/bb'
alias prm='/Users/ersanisik/bin/pr.sh'
alias prc='/Users/ersanisik/bin/pr-create.sh'

alias aws-ssh='/Users/ersanisik/bin/aws-ssh'
alias aws-con="find ~/ssh -type f -name '*.sh' | fzf --print0 | xargs -0 -o bash"

alias loghub='loghub-cli'

alias notes=" find ~/obsidian-vault | fzf --print0 | xargs -0 -o nvim"
alias notesdaily='nvim $NOTES_DIR/Journals\(Günlük\)/$(date +"%Y-%m-%d.md")'


alias tail-json="tail -f xargs -0 | sed  \
    -e 's/\(.*INFO.*\)/\x1B[32m\1\x1B[39m/' \
    -e 's/\(.*ERROR.*\)/\x1B[31m\1\x1B[39m/'" 

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

bindkey '^[[a' up-history

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

# Added by Windsurf
export PATH="/Users/ersanisik/.codeium/windsurf/bin:$PATH"
