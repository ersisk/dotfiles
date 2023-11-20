

# Path to your oh-my-zsh installation.
export ZSH="/Users/ersanisik/.oh-my-zsh"

ZSH_THEME="eastwood"
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
    --color=fg:#e5e9f0,bg:#3b4252,hl:#81a1c1
    --color=fg+:#e5e9f0,bg+:#3b4252,hl+:#81a1c1
    --color=info:#eacb8a,prompt:#bf6069,pointer:#b48dac
    --color=marker:#a3be8b,spinner:#b48dac,header:#a3be8b'

plugins=(git zsh-z zsh-autosuggestions zsh-syntax-highlighting zsh-fzf-history-search web-search jsontools history zsh-shift-select)

source $ZSH/oh-my-zsh.sh
export PATH=/opt/homebrew/bin:$PATH
export NOTES_DIR=~/obsidian-vault
  
eval "$(starship init zsh)"

# ALIAS
alias dc=docker-compose  
alias dc=docker-compose  
alias vim="nvim"
alias vi="nvim"
alias v="nvim"
alias nv="nvim"
alias l='lsd -lah'
alias ls=lsd
alias sl=lsd
alias c='clear'
alias lg='lazygit'
alias pdup="docker-compose -f docker-compose-local.yml up -d"
alias ddup="docker-compose -f docker-compose-dev.yml  up -d"
alias d-node10="docker run -it --rm -v "$PWD":/usr/src/app -w /usr/src/app node:10"
alias e=exit
alias deletelocalbranch='git branch --merged | grep -v "\*" | grep -v "test" grep -v "master" | grep -v "main" | grep -v "release" | grep -v "dev" | xargs -n 1 git branch -d'
alias fvi="fzf --print0 | xargs -0 -o nvim"
alias vf="nvim ."
alias pr='php /Users/ersanisik/bitbucket-pull-request.php'
alias lgcfn='loghub-cli search -P 28'
alias notes="cd $NOTES_DIR && nvim ."
alias zn='vim $NOTES_DIR/$(date +"%Y%m%d%H%M.md")'
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
source ~/.aws-fzf
