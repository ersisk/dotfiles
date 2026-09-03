#!/usr/bin/env bash
# Title + unread count from newsboat's cache.db; via a copy, since the cache may be locked.
db=~/.newsboat/cache.db
tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
cp "$db" "$tmp" 2>/dev/null || { cat ~/.newsboat/urls; exit 0; }

while read -r url tag; do
  [ -z "$url" ] && continue
  case "$url" in \#*) continue;; esac
  tag=${tag//\"/}; tag=${tag#ALL/}
  # tab separator: titles contain spaces, do not let read split on them
  IFS=$'\t' read -r title unread < <(sqlite3 -separator $'\t' "$tmp" \
    "SELECT COALESCE(NULLIF(f.title,''),'?'), COUNT(CASE WHEN i.unread=1 THEN 1 END)
     FROM rss_feed f LEFT JOIN rss_item i ON i.feedurl=f.rssurl
     WHERE f.rssurl='$url' GROUP BY f.rssurl;" 2>/dev/null)
  [ -z "$title" ] && { title="(no cache)"; unread=0; }
  if [ "${unread:-0}" -gt 0 ]; then
    printf '  \033[33m%3s\033[0m  \033[1m%-26.26s\033[0m \033[90m%s\033[0m\n' "$unread" "$title" "$tag"
  else
    printf '  \033[90m%3s  %-26.26s %s\033[0m\n' "·" "$title" "$tag"
  fi
done < ~/.newsboat/urls
