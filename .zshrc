

# Path to your oh-my-zsh installation.
export ZSH="/Users/ersanisik/.oh-my-zsh"

ZSH_THEME="eastwood"

local color00='#282c34'
local color01='#353b45'
local color02='#3e4451'
local color03='#545862'
local color04='#565c64'
local color05='#abb2bf'
local color06='#b6bdca'
local color07='#c8ccd4'
local color08='#e06c75'
local color09='#d19a66'
local color0A='#e5c07b'
local color0B='#98c379'
local color0C='#56b6c2'
local color0D='#61afef'
local color0E='#c678dd'
local color0F='#be5046'

export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS"\
" --color=bg+:$color01,bg:$color00,spinner:$color0C,hl:$color0D"\
" --color=fg:$color04,header:$color0D,info:$color0A,pointer:$color0C"\
" --color=marker:$color0C,fg+:$color06,prompt:$color0A,hl+:$color0D"

plugins=(git zsh-z zsh-autosuggestions zsh-syntax-highlighting zsh-fzf-history-search web-search jsontools history zsh-shift-select)

source $ZSH/oh-my-zsh.sh
export PATH=/opt/homebrew/bin:$PATH
export NOTES_DIR=~/obsidian-vault
  
eval "$(starship init zsh)"

# ALIAS
alias ersvi="NVIM_APPNAME=ErsVi nvim"
alias dc=docker-compose  
alias vim="nvim"
alias vi="nvim"
alias v="nvim"
alias vf="nvim ."
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
alias dlbranch='git branch --merged | grep -v "\*" | grep -v "test" grep -v "master" | grep -v "main" | grep -v "release" | grep -v "dev" | xargs -n 1 git branch -d'
alias fzfv="fzf --print0 | xargs -0 -o nvim"
alias fzfc="fzf --preview 'cat {}'"
alias pr='php /Users/ersanisik/bitbucket-pull-request.php'
alias loghubFN='loghub-cli search -P 28'
#alias notes="cd $NOTES_DIR && nvim ."
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
