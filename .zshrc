# Path to your oh-my-zsh installation.
plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-fzf-history-search web-search)
export ZSH="/Users/ersanisik/.oh-my-zsh"
ZSH_WEB_SEARCH_ENGINES=(
    ddc "https://duckduckgo.com/?q=DuckDuckGo%20AI%20Chat&ia=chat&duckai=1&atb=v452-1"
    grok "https://grok.com?q="
)
source $ZSH/oh-my-zsh.sh

# Starship 
eval "$(starship init zsh)"

#zoxide
eval "$(zoxide init zsh)"

# FZF
eval "$(fzf --zsh)"
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git "
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS='--height 100% --layout=reverse
--color=bg:-1,bg+:#2A2A37,fg:-1,fg+:#FFA066,hl:#a398bf,hl+:#ac7085
--color=header:#b8805e,info:#5f8a9b,pointer:#526994
--color=marker:#526994,prompt:#b35560,spinner:#5f8a9b  --pointer="👉"'
export FZF_CTRL_T_OPTS="--preview 'bat --color=always -n --line-range :500 {}'"
export FZF_TMUX_OPTS=" -p90%,80% --layout=reverse --height 100% --color=bg:#1F1F28,fg:#C8C093,border:#565c64 --border=rounded"
#Editor
export EDITOR="nvim"
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#54546D'
export STARSHIP_JOBS_COUNT="4"
export PATH=/opt/homebrew/bin:$PATH
export NOTES_DIR=~/obsidian-vault
export EZA_CONFIG_DIR=~/.config/eza/

# ALIAS
alias al-list="print -rl -- ${(k)aliases} | fzf"

#Docker
alias docker-compose="docker compose"
alias dc=docker-compose  
alias dce="docker-compose exec"
alias dcu-dev="docker-compose -f docker-compose-dev.yml  up -d"
alias d-node10="docker run -it --rm -v "$PWD":/usr/src/app -w /usr/src/app node:10"
#Docker Projects Based
alias dtelcoexec='docker exec -it docker-getcontactv2-1 bash'
alias dteliup="docker compose -f docker/docker-compose.yml up -d"
alias dteliexec='docker exec -it teli-php'
alias dteliphp='docker exec -it teli-php php bin/console'
alias dtelipest='docker exec -it teli-php ./vendor/bin/pest'
#Kubernetes
alias k="kubectl"
alias kgp="kubectl get pods"
alias kgpn="kubectl get pods -n "
alias keti="kubectl exec -it "
#NVIM
alias vi="nvim"
alias vf="nvim +GoToFile"
alias vim="nvim"
alias nvide="open -a Neovide.app"
alias rssn="newsboat -r"

alias ll='eza -al --icons=always --color=always --group-directories-first'
alias ls='eza --long --icons=always --color=always --no-user'

alias yz='yazi'

alias lg='lazygit'
alias lsql='lazysql'

alias fzn="fzf --print0 | xargs -0 -o nvim"
alias fzp="fzf --style full \
    --preview 'fzf-preview.sh {}' --bind 'focus:transform-header:file --brief {}'"

alias bb='/Users/ersanisik/bin/bb'
alias logse='/Users/ersanisik/bin/log_search.sh'
alias sesh_start='/Users/ersanisik/bin/sesh_start'
alias shs='/Users/ersanisik/bin/sesh_start'
alias hygg='/Users/ersanisik/.cargo/bin/hygg'
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
. "$HOME/.local/bin/env"
bindkey -r '\ec'

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/opt/homebrew/share/google-cloud-sdk/path.zsh.inc' ]; then . '/opt/homebrew/share/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc' ]; then . '/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc'; fi
export PATH=$PATH:$HOME/.local/bin

# Added by Antigravity
export PATH="/Users/ersanisik/.antigravity/antigravity/bin:$PATH"

fpath+=~/.zfunc; autoload -Uz compinit; compinit

zstyle ':completion:*' menu select
