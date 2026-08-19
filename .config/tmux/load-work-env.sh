#!/usr/bin/env bash
# load-work-env — is yollarini tmux'un global ortamina aktarir.
#
# work-paths.fish repoda tutulmaz (.gitignore); tmux server fish'in ortamini
# miras almadigi icin degiskenler burada okunup tmux setenv ile aktarilir.
# Dosya yoksa sessizce cikar - repoyu klonlayan baskasinda kirilma olmaz.

set -uo pipefail

src=~/.config/fish/conf.d/work-paths.fish
[[ -r "$src" ]] || exit 0

# fish'i kaynak gostererek degerleri cozdur: $WORK_ROOT gibi ic referanslar da genisler
command -v fish >/dev/null || exit 0
while IFS='=' read -r key val; do
  [[ -n "$key" && -n "$val" ]] || continue
  tmux setenv -g "$key" "$val" 2>/dev/null
done < <(fish -c "source $src; for v in (set -n -x); string match -qr '^WORK_' \$v; and echo \$v=(eval echo \\\$\$v); end" 2>/dev/null)
