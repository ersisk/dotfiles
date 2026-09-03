#!/usr/bin/env bash
# load-work-env — carries the work paths into tmux's global environment.
#
# work-paths.fish is not kept in the repo (.gitignore); the tmux server does not
# inherit fish's environment, so the variables are read here and passed on with
# tmux setenv. With no file it exits quietly - nothing breaks for someone else
# cloning the repo.

set -uo pipefail

src=~/.config/fish/conf.d/work-paths.fish
[[ -r "$src" ]] || exit 0

# resolve the values by sourcing fish: inner references like $WORK_ROOT expand too
command -v fish >/dev/null || exit 0
while IFS='=' read -r key val; do
  [[ -n "$key" && -n "$val" ]] || continue
  tmux setenv -g "$key" "$val" 2>/dev/null
done < <(fish -c "source $src; for v in (set -n -x); string match -qr '^WORK_' \$v; and echo \$v=(eval echo \\\$\$v); end" 2>/dev/null)
