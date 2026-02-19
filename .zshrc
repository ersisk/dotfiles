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

# EXPORTS
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git "
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS='--height 100% --layout=reverse
--color=bg:-1,bg+:#2A2A37,fg:-1,fg+:#FFA066,hl:#a398bf,hl+:#ac7085
--color=header:#b8805e,info:#5f8a9b,pointer:#526994
--color=marker:#526994,prompt:#b35560,spinner:#5f8a9b  --pointer="👉"'
export FZF_CTRL_T_OPTS="--preview 'bat --color=always -n --line-range :500 {}'"
export FZF_TMUX_OPTS=" -p90%,80% --layout=reverse --height 100% --color=bg:#1F1F28,fg:#C8C093,border:#565c64 --border=rounded"
export EDITOR="nvim"
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#54546D'
export STARSHIP_JOBS_COUNT="4"
export PATH=/opt/homebrew/bin:$PATH
export NOTES_DIR=~/obsidian-vault
export EZA_CONFIG_DIR=~/.config/eza/

# ALIAS
alias al-list="print -rl -- ${(k)aliases} | fzf"

#Docker
alias dc="docker compose"  

# Kubectl exec + fzf
fzfke() {
  local ns="$1"
  local container="$2"

  # If namespace is not provided, select it using fzf
  if [ -z "$ns" ]; then
    ns=$(kubectl get namespaces --no-headers | fzf --height 20% --reverse --header="Select Namespace:" | awk '{print $1}')
  fi

  # Exit if no namespace is selected
  if [ -z "$ns" ]; then
    echo "Error: Namespace not specified."
    return 1
  fi

  # Select pod from the specified namespace
  local pod=$(kubectl get pods -n "$ns" --no-headers | fzf --height 40% --reverse --header="Select Pod ($ns):" | awk '{print $1}')

  # If a pod is selected, construct and run the exec command
  if [ -n "$pod" ]; then
    local exec_cmd="kubectl exec -it $pod -n $ns"
    
    # If a second argument is provided, use it as the container name (-c)
    if [ -n "$container" ]; then
      echo "Connecting to: $ns / $pod (Container: $container)"
      exec_cmd="$exec_cmd -c $container"
    else
      echo "Connecting to: $ns / $pod"
    fi

    # Execute the command, try /bin/bash first, fallback to /bin/sh
    eval "$exec_cmd -- /bin/bash" || eval "$exec_cmd -- /bin/sh"
  else
    echo "No pod selected."
  fi
}

#NVIM
alias vi="nvim"
alias vf="nvim +GoToFile"
alias vl="NVIM_APPNAME=nvim-lazy nvim"
alias vim="nvim"
alias nvide="open -a Neovide.app"

#EZA
alias ll='eza -al --icons --color --group-directories-first'
alias ls='eza --icons --color --no-user --group-directories-first -a'

#FZF
alias fzfn="fzf --print0 | xargs -0 -o nvim"
alias fzfp="fzf --style full \
    --preview 'fzf-preview.sh {}' --bind 'focus:transform-header:file --brief {}'"

# Custom Scripts
alias bb='/Users/ersanisik/bin/bb'
alias startdaily='/Users/ersanisik/bin/daily-monster'
alias selo='/Users/ersanisik/bin/log_search.sh'
alias sesh_start='/Users/ersanisik/bin/sesh_start'
alias shs='/Users/ersanisik/bin/sesh_start'
alias hygg='/Users/ersanisik/.cargo/bin/hygg'
alias aws-ssh='/Users/ersanisik/bin/aws-ssh'
alias aws-con="find ~/ssh -type f -name '*.sh' | fzf --print0 | xargs -0 -o bash"
alias merged-b='/Users/ersanisik/bin/merged-branches_macos'
alias merged-dlb='git branch --merged | grep -v "\*" | grep -v "test" | grep -v "master" | grep -v "main"| grep -v "stage" | grep -v "release" | grep -v "dev" | xargs -n 1 git branch -d'
alias loghub='loghub-cli'

# Obsidian Notes
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

. "$HOME/.local/bin/env"
bindkey -r '\ec'

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/opt/homebrew/share/google-cloud-sdk/path.zsh.inc' ]; then . '/opt/homebrew/share/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc' ]; then . '/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc'; fi
export PATH=$PATH:$HOME/.local/bin

fpath+=~/.zfunc; autoload -Uz compinit; compinit

zstyle ':completion:*' menu select

# bun completions
[ -s "/Users/ersanisik/.bun/_bun" ] && source "/Users/ersanisik/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

# Added by Antigravity
export PATH="/Users/ersanisik/.antigravity/antigravity/bin:$PATH"

## [Completion]
## Completion scripts setup. Remove the following line to uninstall
[[ -f /Users/ersanisik/.dart-cli-completion/zsh-config.zsh ]] && . /Users/ersanisik/.dart-cli-completion/zsh-config.zsh || true
## [/Completion]

