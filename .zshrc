

# Path to your oh-my-zsh installation.
export ZSH="/Users/ersanisik/.oh-my-zsh"

ZSH_THEME="eastwood"
export FZF_DEFAULT_OPTS='--color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9 --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9 --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6 --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4'

plugins=(git zsh-z zsh-autosuggestions zsh-syntax-highlighting web-search jsontools history zsh-shift-select)

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
alias acFn="aws ec2 describe-instances --filters 'Name=tag-value,Values=GetLocation' --query 'Reservations[*].Instances[*].{Name:Tags[?Key==\`Name\`]|[0].Value,IpAddress:PublicIpAddress,Status:State.Name,InstanceId:InstanceId,LaunchTime:LaunchTime}' --region us-east-1 --output table --profile ersan"
alias acSh="aws ec2 describe-instances --filters 'Name=tag-value,Values=$1' --query 'Reservations[*].Instances[*].{Name:Tags[?Key==\`Name\`]|[0].Value,IpAddress:PublicIpAddress,Status:State.Name,InstanceId:InstanceId,LaunchTime:LaunchTime}' --region us-east-1 --output table --profile ersan"
alias acCon="aws ssm start-session --region us-east-1 --profile ersan --target $1"
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
