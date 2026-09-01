#!/usr/bin/env bash
# worktree-remove-all — temizlenebilir tum worktree'leri tek onayla siler.
#
# Panelde ctrl-alt-d ile cagrilir. Kriterleri KENDI BILMEZ: her worktree icin
# worktree-remove.sh'i WT_BATCH=1 ile cagirir. Kurallar tek yerde kalsin diye,
# yoksa panel/tek silme/toplu silme uc ayri dogruluk kaynagi olur.
#
# Silinemeyecek olan zaten reddedilir, o yuzden "hepsi" ile "temizlenebilir
# olanlar" ayni kume: secim isaretlemeye (Tab) gerek yok.
#
# PR durumu her worktree icin yeniden sorulur (gh, seri). Panel cache'ini
# kullanmiyoruz cunku silme aninda taze dogrulama bu tasarimin sarti.

set -uo pipefail

dir="${1:-}"
[[ -n "$dir" && -d "$dir" ]] || { echo "Gecersiz yol."; sleep 2; exit 1; }

REMOVE="$HOME/.config/tmux/worktree-remove.sh"
[[ -x "$REMOVE" ]] || { echo "worktree-remove.sh bulunamadi: $REMOVE"; sleep 2; exit 1; }

main_wt=$(git -C "$dir" worktree list --porcelain 2>/dev/null | rg '^worktree ' | head -1 | cut -d' ' -f2)

# Ana worktree listeden dusuruluyor: silinemez ve onay sayisini sisiriyor.
paths=()
while IFS= read -r line; do
  p="${line#worktree }"
  [[ "$p" == "$main_wt" ]] && continue
  paths+=("$p")
done < <(git -C "$dir" worktree list --porcelain 2>/dev/null | rg '^worktree ')

count=${#paths[@]}
(( count )) || { echo "  Ana worktree disinda worktree yok."; sleep 2; exit 0; }

printf '\n  %s worktree taranacak.\n' "$count"
printf '  Sadece PR'"'"'i merged, agaci temiz ve her seyi push edilmis olanlar silinir;\n'
printf '  digerleri sebebiyle birlikte atlanir.\n\n'
printf '  Devam edilsin mi? (e/h) '
read -rsn1 answer; printf '\n\n'
[[ "$answer" == "e" || "$answer" == "E" ]] || { echo "  Iptal edildi."; sleep 1; exit 0; }

removed=0
skipped=0
for p in "${paths[@]}"; do
  printf '  ── %s\n' "$(basename "$p")"
  if WT_BATCH=1 "$REMOVE" "$p"; then
    removed=$((removed + 1))
  else
    skipped=$((skipped + 1))
  fi
done

printf '\n  %s silindi, %s atlandi.\n\n' "$removed" "$skipped"
printf '  Kapatmak icin bir tusa bas.'
read -rsn1 _
