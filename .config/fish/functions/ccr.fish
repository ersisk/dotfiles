function ccr --description 'pick a Claude Code session with fzf and resume it'
    set -l projects_dir "$HOME/.claude/projects"

    # >>> Filter out sessions you do not want here. A cwd/project path matching this regex is skipped.
    # To turn it off entirely: set -l ccr_exclude ''
    set -l ccr_exclude 'observer'

    for dep in fzf jq claude
        type -q $dep; or begin; echo "ccr: '$dep' not found" >&2; return 1; end
    end
    test -d $projects_dir; or begin; echo "ccr: no sessions ($projects_dir)" >&2; return 1; end

    if contains -- --help $argv
        set_color normal
        echo "ccr — pick a Claude Code session with fzf and resume it"
        echo
        set_color -o; echo "USAGE"; set_color normal
        echo "  ccr [--here|-h] [dir] [search]"
        echo
        set_color -o; echo "OPTIONS"; set_color normal
        echo "  --here, -h       only sessions from the current directory"
        echo "  <dir>            only sessions from that directory (an existing path)"
        echo "  <search>         fzf pre-query (arguments that are not directories)"
        echo "  --help           this help"
        echo
        set_color -o; echo "LIST"; set_color normal
        echo "  time · project · [message] · ⎇ branch · summary of the first message"
        echo "  the 150 newest sessions, newest first"
        echo
        set_color -o; echo "EXAMPLES"; set_color normal
        echo "  ccr                          # all sessions"
        echo "  ccr --here                   # the ones in this directory"
        echo "  ccr ~/workspace/dotfiles     # the ones in that directory"
        echo "  ccr sesh                     # open with 'sesh' as the pre-query"
        echo
        if test -n "$ccr_exclude"
            set_color -o; echo -n "Filtered paths: "; set_color normal; echo "$ccr_exclude"
        end
        return 0
    end

    # --here / -h : only sessions from the current directory
    # an existing directory argument: only that directory's sessions | the rest become the fzf pre-query
    set -l here 0
    set -l list_mode 0
    set -l path_filter ""
    set -l query ""
    for a in $argv
        switch $a
            case --here -h; set here 1
            case --_list; set list_mode 1
            case '*'
                if test -d "$a"
                    set path_filter (realpath -- "$a")
                else
                    set query "$query $a"
                end
        end
    end
    set query (string trim -- $query)

    # Kanagawa (wave) hex palette — truecolor literals
    set -l c_date  '\033[38;2;114;113;105m'    # fujiGray
    set -l c_proj  '\033[1;38;2;126;156;216m'  # crystalBlue, bold
    set -l c_msg   '\033[38;2;220;215;186m'    # fujiWhite
    set -l c_br    '\033[38;2;149;127;184m'    # oniViolet
    set -l c_today '\033[1;38;2;152;187;108m'  # springGreen, bold
    set -l c_off   '\033[0m'

    # Preview: show only user/assistant messages that carry text, indented and separated. {4} = jsonl path.
    # jq is inlined into the fzf preview subshell (a function-local export does not reach it).
    set -l preview_jq '
      def clr($c): "["+$c+"m";
      def body:
        if type=="string" then .
        else ([.[]? | select(.type=="text") | .text] | join("\n")) end;
      [.[]
        | select(.type=="user" or .type=="assistant")
        | select((.isMeta // false) | not)
        | select((.isSidechain // false) | not)
        | {r: .type, t: (.message.content | body)}
        | select(.t != null)
        | .t |= (gsub("\n{3,}"; "\n\n") | gsub("[ \t]+$"; "") | gsub("^[[:space:]]+"; ""))
        | select((.t | gsub("[[:space:]]"; "")) != "")
        | select((.t | test("^<command")) | not)]
      | .[-8:]
      | reverse
      | map(
          (if .r=="user" then clr("38;2;149;127;184")+"▶ user"+clr("0")
           else clr("38;2;126;156;216")+"● claude"+clr("0") end) as $hdr
          | (.t | if length > 500 then .[0:500]+" …" else . end) as $txt
          | $hdr + "\n" + ($txt | gsub("\n"; "\n  ") | "  " + .))
      | join("\n" + clr("38;2;84;84;109") + ("─" * 32) + clr("0") + "\n")'

    # If there is no session file at all, exit without opening fzf.
    set -l rows (stat -f '%m	%N' $projects_dir/*/*.jsonl 2>/dev/null)
    test (count $rows) -gt 0; or begin; echo "ccr: no session files" >&2; return 1; end

    # In interactive mode the list is computed in fzf's start:reload; running the
    # scan below a second time here wasted ~470ms.
    if test $list_mode -eq 0
        set -l header (printf '%b  %-20s  %s   %s%b' $c_date 'PROJECT' 'BRANCH' 'SUMMARY' $c_off)

        # The list is filled inside fzf: the scan takes ~1s and the window sat empty
        # for all of it, with no sign the key had registered.
        # --no-config: loading config.fish adds ~250ms to the subshell; sourcing the
        # function directly is enough (PATH already comes from the environment).
        set -l list_args --_list
        test $here -eq 1; and set -a list_args --here
        test -n "$path_filter"; and set -a list_args "$path_filter"
        set -l inner "source "(string escape -- (status filename))"; ccr "(string join -- ' ' (string escape -- $list_args))
        set -l load "fish --no-config -c "(string escape -- $inner)" 2>/dev/null"

        set -l sel (fzf \
            --ansi \
            --delimiter \t --with-nth 1 --query "$query" \
            --height 90% --reverse --border rounded \
            --prompt '  resume ❯ ' \
            --pointer '▶' --marker '✓' \
            --info inline \
            --header '⧗ scanning…' --header-first \
            --bind "start:reload($load)" \
            --bind "load:change-header($header)" \
            --color 'fg:#DCD7BA,bg:-1,hl:#7E9CD8,fg+:#C8C093,bg+:#2D4F67,hl+:#7FB4CA,prompt:#98BB6C,pointer:#98BB6C,marker:#98BB6C,info:#727169,header:italic:#957FB8,border:#54546D,gutter:-1' \
            --preview "tail -n 1500 {4} | jq -rs '$preview_jq'" \
            --preview-window 'right:55%:wrap:border-left' </dev/null)
        test -n "$sel"; or return 0

        set -l p (string split \t -- $sel)
        set -l sid $p[2]
        set -l cwd $p[3]

        if test -d "$cwd"; and test "$cwd" != "$PWD"
            pushd "$cwd" >/dev/null
            claude --resume $sid
            popd >/dev/null
        else
            claude --resume $sid
        end
        return 0
    end

    # --- everything below is --_list only (the fzf reload subshell) ---
    set -l now (date +%s)
    # Midnight epoch once: otherwise two `date` forks per row.
    set -l midnight (date -j -f '%H:%M:%S' '00:00:00' '+%s')

    set -l top (printf '%s\n' $rows | sort -rn | head -n 150)
    set -l files
    set -l mtimes
    for row in $top
        set -l parts (string split \t -- $row)
        set -a mtimes $parts[1]
        set -a files $parts[2]
    end

    # cwd and gitBranch are plain strings; rg pulls them without parsing (~30ms).
    # Handing every file to jq parsed 95MB of JSON (~850ms).
    # For the first user message only "type":"user" lines go to jq (0.7MB).
    set -l tmpf (mktemp)
    rg --with-filename -m1 -o '"cwd":"[^"]*"' $files 2>/dev/null \
        | sed 's/:"cwd":"/	C	/; s/"$//' >$tmpf
    rg --with-filename -m1 -o '"gitBranch":"[^"]*"' $files 2>/dev/null \
        | sed 's/:"gitBranch":"/	B	/; s/"$//' >>$tmpf
    # The isMeta field only appears on meta lines; real messages never carry it.
    rg --with-filename '"type":"user"' $files 2>/dev/null \
        | sed 's/^\([^:]*\):/\1	/' \
        | jq -Rr 'split("	") as $p | ($p[1:]|join("	")) as $l
            | ($l|fromjson? // {}) as $j
            | select(($j.isMeta // false) | not)
            | select(($j.isSidechain // false) | not)
            | ($j.message.content? // "")
            | (if type=="string" then . else ([.[]?|select(.type=="text")|.text]|join(" ")) end) as $c
            | select($c != null and $c != "" and ($c|test("^<")|not))
            | $p[0] + "	F	" + ($c|.[0:60]|gsub("[	
]";" "))' \
        | awk -F'	' '!seen[$1]++' >>$tmpf

    # Collapse the fields into one row per file: path, mtime, cwd, branch, first
    set -l mtf (mktemp)
    for idx in (seq (count $files))
        printf '%s	M	%s
' $files[$idx] $mtimes[$idx] >>$mtf
    end
    set -l all_info (cat $tmpf $mtf | awk -F'	' -v OFS='	' '
        {v[$1"|"$2] = $3; if (!($1 in seen)) { seen[$1]=1; order[++n]=$1 }}
        END {
            for (i = 1; i <= n; i++) {
                f = order[i]
                print f, v[f"|M"], v[f"|C"], v[f"|B"], v[f"|F"]
            }
        }')
    rm -f $tmpf $mtf

    set -l lines
    for row in $all_info
        set -l ip (string split \t -- $row)
        set -l f $ip[1]
        set -l mtime $ip[2]
        set -l cwd $ip[3]
        set -l branch $ip[4]
        set -l first $ip[5]
        set -l sid (string replace -r '^.*/(.*)\.jsonl$' '$1' -- $f)
        test -n "$mtime"; or continue

        test -z "$first"; and continue                                              # sidechain/empty session
        test -n "$ccr_exclude"; and string match -qr -- "$ccr_exclude" "$cwd"; and continue

        # Relative time
        set -l age (math "$now - $mtime")
        set -l when
        if test $mtime -ge $midnight
            set when (printf '%s%s%s' $c_today (date -r $mtime '+%H:%M') $c_off)
        else if test $age -lt 172800
            set when (printf '%syst %s%s' $c_date (date -r $mtime '+%H:%M') $c_off)
        else if test $age -lt 604800
            set when (printf '%s%dd ago%s' $c_date (math "floor($age / 86400)") $c_off)
        else
            set when (printf '%s%s%s' $c_date (date -r $mtime '+%m-%d') $c_off)
        end

        # Project name: shorten to 20 characters gracefully (append … instead of cutting)
        set -l proj (basename "$cwd")
        if test (string length -- $proj) -gt 20
            set proj (string sub -l 19 -- $proj)…
        end

        # Branch: shorten to 18 characters; show nothing when absent
        set -l brdisp ""
        if test -n "$branch"; and test "$branch" != HEAD
            set -l b $branch
            test (string length -- $b) -gt 18; and set b (string sub -l 17 -- $b)…
            set brdisp (printf '%s ⎇ %s%s' $c_br $b $c_off)
        end


        set -l summ (string sub -l 60 -- "$first")
        set -l disp (printf '%b  %b%-20s%b%b  %b%s%b' \
            $when \
            $c_proj $proj $c_off \
            $brdisp \
            $c_msg $summ $c_off)
        set -a lines (printf '%s\t%s\t%s\t%s' $disp $sid $cwd $f)
    end
    test (count $lines) -gt 0; or begin; echo "ccr: no matching session" >&2; return 1; end

    # Directory filter (--here / path arg). With no match, fall back to the full list.
    set -l want ""
    test $here -eq 1; and set want "$PWD"
    test -n "$path_filter"; and set want "$path_filter"
    if test -n "$want"
        set -l filtered
        for l in $lines
            set -l lc (string split \t -- $l)[3]
            test "$lc" = "$want"; and set -a filtered $l
        end
        test (count $filtered) -gt 0; and set lines $filtered
    end

    printf '%s\n' $lines
    return 0
end
