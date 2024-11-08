# Path to your oh-my-zsh installation.
export ZSH="/Users/ersanisik/.oh-my-zsh"

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

ZSH_THEME="eastwood"

export FZF_DEFAULT_OPTS='
  --color fg:#6f737b,bg:#21252d
  --color bg+:#adc896,fg+:#282c34,hl:#abb2bf,hl+:#1e222a,gutter:#282c34
  --color pointer:#adc896,info:#abb2bf,border:#565c64
  --border'

plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-fzf-history-search web-search jsontools history zsh-shift-select wd)

source $ZSH/oh-my-zsh.sh
export PATH=/opt/homebrew/bin:$PATH
export NOTES_DIR=~/obsidian-vault
  
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
eval "$(fzf --zsh)"

# ALIAS
alias docker-compose="docker compose"
alias dc=docker-compose  
alias dceapp="docker-compose exec app"
alias dcuplo="docker-compose -f docker-compose-local.yml up -d"
alias dcupdev="docker-compose -f docker-compose-dev.yml  up -d"

alias evi="NVIM_APPNAME=envim nvim"
alias lvi="NVIM_APPNAME=lnvim nvim"
alias dbvi='NVIM_APPNAME=envim nvim -c "Dbee"'
alias vim="nvim"
alias nv="nvim"
alias vi="nvim"

alias ld='eza -lD'
alias lf='eza -lf --color=always | grep -v /'
alias lh='eza -dl .* --group-directories-first'
alias ll='eza -al --group-directories-first'
alias ls='eza --icons=always --color=always --sort=size | grep -v /'
alias lt='eza -al --sort=modified'
alias la='eza -a --icons=always --color=always'

alias d-node10="docker run -it --rm -v "$PWD":/usr/src/app -w /usr/src/app node:10"
alias c='clear'
alias e=exit
alias lg='lazygit'

alias dlb='git branch --merged | grep -v "\*" | grep -v "test" | grep -v "master" | grep -v "main" | grep -v "release" | grep -v "dev" | xargs -n 1 git branch -d'

alias fzfnv="fzf --print0 | xargs -0 -o nvim"
alias fzfc="fzf --preview 'cat {}'"

alias bb='/Users/ersanisik/bin/bb'
alias prm='/Users/ersanisik/bin/pr.sh'
alias prc='/Users/ersanisik/bin/pr-create.sh'

alias aws-ssh='/Users/ersanisik/bin/aws-ssh'
alias aws-con="find ~/ssh -type f -name '*.sh' | fzf --print0 | xargs -0 -o bash"

alias loghubFN='loghub-cli search -P 28'
alias loghub='loghub-cli'

alias notes=" find ~/obsidian-vault | fzf --print0 | xargs -0 -o nvim"
alias nn='nv $NOTES_DIR/'
alias notesn='vim $NOTES_DIR/$(date +"%Y%m%d%H%M.md")'

alias taco="tail -f xargs -0 | sed  \
    -e 's/\(.*INFO.*\)/\x1B[32m\1\x1B[39m/' \
    -e 's/\(.*ERROR.*\)/\x1B[31m\1\x1B[39m/'" 

# Tmux
# Attaches tmux to a session (example: ta portal)
alias ta='tmux attach -t'
# Creates a new session
alias tn='tmux new-session -s '
# Kill session
alias tk='tmux kill-session -t '
# Lists all ongoing sessions
alias tl='tmux list-sessions'
# Detach from session
alias td='tmux detach'
# Tmux Clear pane
alias tc='clear; tmux clear-history; clear'

export EDITOR="nvim"
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

