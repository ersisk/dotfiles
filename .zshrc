

# Path to your oh-my-zsh installation.
export ZSH="/Users/ersanisik/.oh-my-zsh"

ZSH_THEME="eastwood"

export FZF_DEFAULT_OPTS='
  --color fg:#6f737b,bg:#21252d
  --color bg+:#adc896,fg+:#282c34,hl:#abb2bf,hl+:#1e222a,gutter:#282c34
  --color pointer:#adc896,info:#abb2bf,border:#565c64
  --border'

plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-fzf-history-search web-search jsontools history zsh-shift-select)

source $ZSH/oh-my-zsh.sh
export PATH=/opt/homebrew/bin:$PATH
export NOTES_DIR=~/obsidian-vault
  
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"

# ALIAS
alias dc=docker-compose  
alias pdup="docker-compose -f docker-compose-local.yml up -d"
alias ddup="docker-compose -f docker-compose-dev.yml  up -d"

alias ev="NVIM_APPNAME=ErsVi nvim"
alias dbv="NVIM_APPNAME=ErsVi nvim -c 'DBUI'"
alias vim="nvim"
alias vi="nvim"
alias v="nvim"

alias l='lsd -lah'
alias ls=lsd

alias d-node10="docker run -it --rm -v "$PWD":/usr/src/app -w /usr/src/app node:10"
alias c='clear'
alias e=exit
alias lg='lazygit'

alias dlb='git branch --merged | grep -v "\*" | grep -v "test" | grep -v "master" | grep -v "main" | grep -v "release" | grep -v "dev" | xargs -n 1 git branch -d'

alias fzfv="fzf --print0 | xargs -0 -o nvim"
alias fzfc="fzf --preview 'cat {}'"

alias pr='php /Users/ersanisik/bitbucket-pull-request.php'
alias loghubFN='loghub-cli search -P 28'
alias notes=" find ~/obsidian-vault | fzf --print0 | xargs -0 -o nvim"
alias notesn='vim $NOTES_DIR/$(date +"%Y%m%d%H%M.md")'

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

source /Users/ersanisik/.config/broot/launcher/bash/br
