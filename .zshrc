# Path to your oh-my-zsh installation.
plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-fzf-history-search web-search)
export ZSH="/Users/ersanisik/.oh-my-zsh"

source $ZSH/oh-my-zsh.sh

# Starship 
eval "$(starship init zsh)"

#sesh
function sesh-sessions() {
  {
    exec </dev/tty
    exec <&1
    local session
    session=$(sesh list | fzf --height 40% --reverse --border-label ' sesh ' --border --prompt '⚡  ')
    zle reset-prompt > /dev/null 2>&1 || true
    [[ -z "$session" ]] && return
    sesh connect $session
  }
}

zle     -N             sesh-sessions
bindkey -M emacs '\es' sesh-sessions
bindkey -M vicmd '\es' sesh-sessions
bindkey -M viins '\es' sesh-sessions

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

# Setup fzf previews
export FZF_CTRL_T_OPTS="--preview 'bat --color=always -n --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --icons=always --tree --color=always {} | head -200'"

# fzf preview for tmux
export FZF_TMUX_OPTS=" -p90%,70% "

#Editor
export EDITOR="nvim"


export PATH=/opt/homebrew/bin:$PATH
export NOTES_DIR=~/obsidian-vault
export EZA_CONFIG_DIR=~/.config/eza/


# ALIAS
alias dbang="gobang"
alias docker-compose="docker compose"
alias dc=docker-compose  
alias dceapp="docker-compose exec app"
alias dcuplo="docker-compose -f docker-compose-local.yml up -d"
alias dcupdev="docker-compose -f docker-compose-dev.yml  up -d"

alias vim="nvim"
alias nv="nvim"
alias vi="nvim"


alias ll='eza -al --icons=always --group-directories-first'
alias ls='eza --no-filesize --long --icons=always --color=always --no-user'

alias d-node10="docker run -it --rm -v "$PWD":/usr/src/app -w /usr/src/app node:10"
alias c='clear'
alias e=exit
alias lg='lazygit'

alias dlb='git branch --merged | grep -v "\*" | grep -v "test" | grep -v "master" | grep -v "main" | grep -v "release" | grep -v "dev" | xargs -n 1 git branch -d'

alias fzfnv="fzf --print0 | xargs -0 -o nvim"

alias bb='/Users/ersanisik/bin/bb'
alias prm='/Users/ersanisik/bin/pr.sh'
alias prc='/Users/ersanisik/bin/pr-create.sh'
alias bb-dev='bb pipeline custom "$(git symbolic-ref --short HEAD)" "dev-check"'

alias aws-ssh='/Users/ersanisik/bin/aws-ssh'
alias aws-con="find ~/ssh -type f -name '*.sh' | fzf --print0 | xargs -0 -o bash"

alias loghubFN='loghub-cli search -P 28'
alias loghub='loghub-cli'

alias notes=" find ~/obsidian-vault | fzf --print0 | xargs -0 -o nvim"
alias notesnv='nv $NOTES_DIR/'
alias notesn='vim $NOTES_DIR/$(date +"%Y%m%d%H%M.md")'

alias taco="tail -f xargs -0 | sed  \
    -e 's/\(.*INFO.*\)/\x1B[32m\1\x1B[39m/' \
    -e 's/\(.*ERROR.*\)/\x1B[31m\1\x1B[39m/'" 

# Tmux
# Attaches tmux to a session (example: ta portal)
alias ta='tmux attach -t'
alias tn='tmux new-session -s '
alias tk='tmux kill-session -t '
alias tl='tmux list-sessions'
alias td='tmux detach'
alias tc='clear; tmux clear-history; clear'
alias ts='sesh connect $(sesh list | fzf)'

alias copilot="gh copilot explain"

bindkey '^P' up-history
bindkey '^N' down-history

bindkey '^[[a' up-history

eb-status-getlocation() {
    export AWS_PAGER=""
    aws elasticbeanstalk describe-environments \
        --region us-east-1 | jq -c '.Environments[] | select( .EnvironmentName | contains("GetLocation") ) | {EnvironmentName: .EnvironmentName, HealthStatus: .HealthStatus, VersionLabel: .VersionLabel}' \
        | jq
}

eb-status-desk-360-v2() {
    export AWS_PAGER=""
    aws elasticbeanstalk describe-environments \
        --region eu-central-1 | jq -c '.Environments[] | select( .EnvironmentName | contains("Desk360v2") and (contains("WebSite") | not) ) | {EnvironmentName: .EnvironmentName, HealthStatus: .HealthStatus, VersionLabel: .VersionLabel}' \
        | jq
}

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
