function kcr --description 'pick a Kilo session with fzf and resume it'
    # Kilo is an opencode fork with the same sqlite schema; see ocr.fish for why the
    # database is queried directly instead of going through `kilo session list`.
    set -l db $KCR_DB
    if test -z "$db"
        set -l data $XDG_DATA_HOME
        test -z "$data"; and set data "$HOME/.local/share"
        set db "$data/kilo/kilo.db"
    end

    for dep in fzf jq sqlite3 kilo
        type -q $dep; or begin
            echo "kcr: '$dep' not found" >&2; return 1
        end
    end
    test -f "$db"; or begin
        echo "kcr: no session database ($db)" >&2; return 1
    end

    if contains -- --help $argv
        set_color normal
        echo "kcr — pick a Kilo session with fzf and resume it"
        echo
        set_color -o; echo "USAGE"; set_color normal
        echo "  kcr [--here|-h] [dir] [search]"
        echo
        set_color -o; echo "OPTIONS"; set_color normal
        echo "  --here, -h       only sessions from the current directory"
        echo "  <dir>            only sessions from that directory (an existing path)"
        echo "  <search>         fzf pre-query (arguments that are not directories)"
        echo "  --help           this help"
        echo
        set_color -o; echo "LIST"; set_color normal
        echo "  time · project · title"
        echo "  the 150 newest sessions, newest first; subagent sessions are left out"
        echo
        set_color -o; echo "EXAMPLES"; set_color normal
        echo "  kcr                          # all sessions"
        echo "  kcr --here                   # the ones in this directory"
        echo "  kcr ~/workspace/dotfiles     # the ones in that directory"
        echo "  kcr agents                   # open with 'agents' as the pre-query"
        echo
        set_color -o; echo "ENVIRONMENT"; set_color normal
        echo "  KCR_DB           path to kilo.db (default: \$XDG_DATA_HOME/kilo/kilo.db)"
        return 0
    end

    set -l here 0
    set -l path_filter ""
    set -l query ""
    for a in $argv
        switch $a
            case --here -h
                set here 1
            case '*'
                if test -d "$a"
                    set path_filter (realpath -- "$a")
                else
                    set query "$query $a"
                end
        end
    end
    set query (string trim -- $query)
    test $here -eq 1; and set path_filter "$PWD"

    # The directory filter is a prefix match, not equality: kilo records the
    # directory kilo was started in, so a session opened in a subdirectory of
    # the repo still belongs to it.
    set -l dir_clause ""
    if test -n "$path_filter"
        set dir_clause "AND (directory = '"(string replace --all "'" "''" -- $path_filter)"' OR directory LIKE '"(string replace --all "'" "''" -- $path_filter)"/%')"
    end

    # Kanagawa (wave) truecolor literals, assembled in SQL so the whole list is one
    # process: no fish loop, no `date` fork per row.
    set -l sql "
WITH s AS (
  SELECT id, directory, time_updated,
         replace(replace(substr(title, 1, 60), char(9), ' '), char(10), ' ') AS ttl,
         substr(directory, length(rtrim(directory, replace(directory, '/', ''))) + 1) AS proj,
         (strftime('%s', 'now') - time_updated / 1000) AS age
  FROM session
  WHERE parent_id IS NULL AND time_archived IS NULL
    AND EXISTS (SELECT 1 FROM part p WHERE p.session_id = session.id)
    $dir_clause
  ORDER BY time_updated DESC
  LIMIT 150
)
SELECT
  CASE
    WHEN date(time_updated / 1000, 'unixepoch', 'localtime') = date('now', 'localtime')
      THEN char(27) || '[1;38;2;152;187;108m' || strftime('%H:%M', time_updated / 1000, 'unixepoch', 'localtime')
    WHEN date(time_updated / 1000, 'unixepoch', 'localtime') = date('now', '-1 day', 'localtime')
      THEN char(27) || '[38;2;114;113;105myst ' || strftime('%H:%M', time_updated / 1000, 'unixepoch', 'localtime')
    WHEN age < 604800
      THEN char(27) || '[38;2;114;113;105m' || CAST(age / 86400 AS int) || 'd ago'
    ELSE char(27) || '[38;2;114;113;105m' || strftime('%m-%d', time_updated / 1000, 'unixepoch', 'localtime')
  END || char(27) || '[0m'
  || '  ' || char(27) || '[1;38;2;126;156;216m'
  || CASE WHEN length(proj) > 20 THEN substr(proj, 1, 19) || '…'
          ELSE substr(proj || '                    ', 1, 20) END
  || char(27) || '[0m  ' || char(27) || '[38;2;220;215;186m' || ttl || char(27) || '[0m'
  || char(9) || id || char(9) || directory
FROM s;
"

    # sqlite3 >= 3.50 prints control characters as ^[ unless escaping is turned off.
    set -l lines (sqlite3 -readonly -noheader -escape off "file:$db?mode=ro" "$sql" 2>/dev/null)
    if test (count $lines) -eq 0
        if test -n "$path_filter"
            echo "kcr: no session in $path_filter" >&2
        else
            echo "kcr: no session found" >&2
        end
        return 1
    end

    # Preview: the newest text parts of the picked session, newest first. {2} is the
    # session id and fzf quotes it, which is also what makes the SQL safe.
    set -l preview_sql "SELECT m.data AS msg, p.data AS part FROM part p JOIN message m ON m.id = p.message_id WHERE p.session_id = {2} ORDER BY p.time_created DESC LIMIT 40"
    set -l preview_jq '
      def clr($c): "["+$c+"m";
      [.[]
        | (.msg | fromjson) as $m
        | (.part | fromjson) as $p
        | select($p.type == "text")
        | {r: ($m.role // "assistant"), t: ($p.text // "")}
        | .t |= (gsub("\n{3,}"; "\n\n") | gsub("[ \t]+$"; "") | gsub("^[[:space:]]+"; ""))
        | select((.t | gsub("[[:space:]]"; "")) != "")]
      | .[0:8]
      | map(
          (if .r == "user" then clr("38;2;149;127;184")+"▶ user"+clr("0")
           else clr("38;2;126;156;216")+"● kilo"+clr("0") end) as $hdr
          | (.t | if length > 500 then .[0:500]+" …" else . end) as $txt
          | $hdr + "\n" + ($txt | gsub("\n"; "\n  ") | "  " + .))
      | join("\n" + clr("38;2;84;84;109") + ("─" * 32) + clr("0") + "\n")'

    set -l header (printf '\033[38;2;114;113;105m  %-20s  %s\033[0m' 'PROJECT' 'TITLE')

    set -l sel (printf '%s\n' $lines | fzf \
        --ansi \
        --delimiter \t --with-nth 1 --query "$query" \
        --height 90% --reverse --border rounded --border-label ' Kilo resume ' \
        --prompt '󱚝  resume ❯ ' \
        --pointer '▶' --marker '✓' \
        --info inline \
        --header "$header" --header-first \
        --color 'fg:#DCD7BA,bg:-1,hl:#7E9CD8,fg+:#C8C093,bg+:#2D4F67,hl+:#7FB4CA,prompt:#98BB6C,pointer:#98BB6C,marker:#98BB6C,info:#727169,header:italic:#957FB8,border:#54546D,gutter:-1' \
        --preview "sqlite3 -readonly -json \"file:$db?mode=ro\" \"$preview_sql\" | jq -r '$preview_jq'" \
        --preview-window 'right:55%:wrap:border-left')
    test -n "$sel"; or return 0

    set -l p (string split \t -- $sel)
    set -l sid $p[2]
    set -l cwd $p[3]

    if test -d "$cwd"; and test "$cwd" != "$PWD"
        pushd "$cwd" >/dev/null
        kilo --session $sid
        popd >/dev/null
    else
        kilo --session $sid
    end
end
