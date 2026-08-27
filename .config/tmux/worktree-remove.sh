#!/usr/bin/env bash
# worktree-remove — worktree-panel'den secilen worktree'yi onay alarak siler.
#
# Panelde ctrl-d ile cagrilir. Panelin "temizlenebilir" isaretine guvenmez,
# guvenlik kontrollerini silme aninda yeniden yapar (panel verisi cache'li olabilir).
# git worktree remove kullanilir; --force ASLA gecilmez, git'in kendi korumasi kalir.

set -uo pipefail

target="${1:-}"
[[ -n "$target" && -d "$target" ]] && exit_ok=1 || { echo "Gecersiz worktree yolu."; sleep 2; exit 1; }

branch=$(git -C "$target" rev-parse --abbrev-ref HEAD 2>/dev/null)
name=$(basename "$target")

# Ana worktree silinemez (git "is a main working tree" der); en basta ele
main_wt=$(git -C "$target" worktree list --porcelain 2>/dev/null | rg '^worktree ' | head -1 | cut -d' ' -f2)
if [[ "$target" == "$main_wt" ]]; then
  printf 'RED: bu repo'"'"'nun ana calisma agaci, silinemez.\n'
  sleep 3; exit 1
fi

# --- Guvenlik kontrolleri: her biri silmeyi engeller ---
if [[ "$branch" == "HEAD" ]]; then
  printf 'RED: detached HEAD (%s)\nHangi dalda oldugu belirsiz, elle kontrol et.\n' "$name"
  sleep 3; exit 1
fi

dirty=$(git -C "$target" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
if (( dirty > 0 )); then
  printf 'RED: %s icinde %s dosya commit edilmemis.\nOnce commit'"'"'le veya stash'"'"'le.\n' "$branch" "$dirty"
  sleep 3; exit 1
fi

unpushed=$(git -C "$target" rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)
if [[ "$unpushed" =~ ^[0-9]+$ ]] && (( unpushed > 0 )); then
  printf 'RED: %s icinde %s commit push edilmemis.\n' "$branch" "$unpushed"
  sleep 3; exit 1
fi

pr_state=$(gh pr list --head "$branch" --state all --limit 1 --json state --jq '.[0].state' 2>/dev/null)
if [[ "$pr_state" != "MERGED" ]]; then
  printf 'RED: %s icin merged PR yok (durum: %s).\nIsi bitmemis olabilir.\n' "$branch" "${pr_state:-PR yok}"
  sleep 3; exit 1
fi

# --- Onay ---
printf '\n  %s\n  PR merged, calisma agaci temiz, her sey push edilmis.\n\n' "$branch"
printf '  Bu worktree silinsin mi? (e/h) '
read -rsn1 answer; printf '\n\n'
[[ "$answer" == "e" || "$answer" == "E" ]] || { echo "  Iptal edildi."; sleep 1; exit 0; }

# Panel PR durumlarini cache'liyor; silme sonrasi liste yenilenince guncel olsun.
# Cache repo basina ayri dosyada (bkz worktree-panel.py cache_path) — anahtar
# git-common-dir'in sha1'i, cunku tek paylasilan dosya ayni adli dallari olan
# repolarin PR durumunu karistiriyordu.
wt_ident=$(git -C "$target" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
wt_hash=$(printf '%s' "$wt_ident" | shasum | cut -c1-12)
rm -f "${TMPDIR:-/tmp}/worktree-panel-pr-${wt_hash}.json" 2>/dev/null

if git -C "$target" worktree remove "$target" 2>/dev/null \
   || git -C "$(git -C "$target" rev-parse --path-format=absolute --git-common-dir 2>/dev/null | xargs dirname)" worktree remove "$target" 2>/dev/null; then
  echo "  Silindi: $name"
else
  echo "  Silinemedi - git reddetti. Elle kontrol et:"
  echo "    git worktree remove '$target'"
fi
sleep 2
