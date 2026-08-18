function ccr --description 'Claude Code oturumunu fzf ile seçip resume et'
    set -l projects_dir "$HOME/.claude/projects"

    # >>> İstemediğin oturumları buradan ele. cwd/proje yolu bu regex'i içerirse atlanır.
    # Tamamen kapatmak istersen: set -l ccr_exclude ''
    set -l ccr_exclude 'observer'

    for dep in fzf jq claude
        type -q $dep; or begin; echo "ccr: '$dep' bulunamadı" >&2; return 1; end
    end
    test -d $projects_dir; or begin; echo "ccr: oturum yok ($projects_dir)" >&2; return 1; end

    if contains -- --help $argv
        set_color normal
        echo "ccr — Claude Code oturumunu fzf ile seçip resume et"
        echo
        set_color -o; echo "KULLANIM"; set_color normal
        echo "  ccr [--here|-h] [dizin] [arama]"
        echo
        set_color -o; echo "SEÇENEKLER"; set_color normal
        echo "  --here, -h       sadece bulunduğun dizinin oturumları"
        echo "  <dizin>          sadece o dizinin oturumları (var olan bir yol)"
        echo "  <arama>          fzf ön-sorgusu (dizin olmayan argümanlar)"
        echo "  --help           bu yardım"
        echo
        set_color -o; echo "LİSTE"; set_color normal
        echo "  zaman · proje · [mesaj] · ⎇ branch · ilk mesaj özeti"
        echo "  en yeni 150 oturum, yeniden eskiye"
        echo
        set_color -o; echo "ÖRNEKLER"; set_color normal
        echo "  ccr                          # tüm oturumlar"
        echo "  ccr --here                   # bu dizindekiler"
        echo "  ccr ~/workspace/dotfiles     # o dizindekiler"
        echo "  ccr sesh                     # 'sesh' ön-sorgusuyla aç"
        echo
        if test -n "$ccr_exclude"
            set_color -o; echo -n "Elenen yollar: "; set_color normal; echo "$ccr_exclude"
        end
        return 0
    end

    # --here / -h : sadece bulunduğun dizinin oturumları
    # var olan bir dizin argümanı: sadece o dizinin oturumları | kalanlar fzf ön-sorgusu
    set -l here 0
    set -l path_filter ""
    set -l query ""
    for a in $argv
        switch $a
            case --here -h; set here 1
            case '*'
                if test -d "$a"
                    set path_filter (realpath -- "$a")
                else
                    set query "$query $a"
                end
        end
    end
    set query (string trim -- $query)

    # Kanagawa (wave) hex paleti — truecolor sabit renkler
    set -l c_date  '\033[38;2;114;113;105m'    # fujiGray
    set -l c_proj  '\033[1;38;2;126;156;216m'  # crystalBlue, bold
    set -l c_msg   '\033[38;2;220;215;186m'    # fujiWhite
    set -l c_br    '\033[38;2;149;127;184m'    # oniViolet
    set -l c_today '\033[1;38;2;152;187;108m'  # springGreen, bold
    set -l c_off   '\033[0m'

    # Preview: sadece metinli user/assistant mesajlarını girintili, ayraçlı göster. {4} = jsonl yolu.
    # jq'yu fzf preview subshell'ine gömerek geçir (fonksiyon-local export oraya taşınmaz).
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

    set -l now (date +%s)
    # stat tek çağrıda: "mtime\tpath", en yeni 150 oturum
    set -l rows (stat -f '%m	%N' $projects_dir/*/*.jsonl 2>/dev/null)
    test (count $rows) -gt 0; or begin; echo "ccr: oturum dosyası yok" >&2; return 1; end

    set -l top (printf '%s\n' $rows | sort -rn | head -n 150)
    set -l files
    set -l mtimes
    for row in $top
        set -l parts (string split \t -- $row)
        set -a mtimes $parts[1]
        set -a files $parts[2]
    end

    # cwd ve gitBranch düz string; rg ile parse'sız çekilir (~30ms).
    # Tüm dosyaları jq'ya vermek 95MB JSON parse ediyordu (~850ms).
    # İlk kullanıcı mesajı için yalnızca "type":"user" satırları jq'ya gider (0.7MB).
    set -l tmpf (mktemp)
    rg --with-filename -m1 -o '"cwd":"[^"]*"' $files 2>/dev/null \
        | sed 's/:"cwd":"/	C	/; s/"$//' >$tmpf
    rg --with-filename -m1 -o '"gitBranch":"[^"]*"' $files 2>/dev/null \
        | sed 's/:"gitBranch":"/	B	/; s/"$//' >>$tmpf
    # isMeta alanı yalnızca meta satırlarda bulunur; gerçek mesajlarda hiç yok.
    rg --with-filename '"type":"user"' $files 2>/dev/null \
        | sed 's/^\([^:]*\):/\1	/' \
        | jq -Rr 'split("	") as $p | ($p[1:]|join("	")) as $l
            | ($l|fromjson? // {}) as $j
            | select(($j.isMeta // false) | not)
            | select(($j.isSidechain // false) | not)
            | ($j.message.content? // "")
            | (if type=="string" then . else ([.[]?|select(.type=="text")|.text]|join(" ")) end) as $c
            | select($c != null and $c != "" and ($c|test("^<")|not))
            | $p[0] + "	F	" + ($c|gsub("[	
]";" ")|.[0:60])' \
        | awk -F'	' '!seen[$1]++' >>$tmpf

    # Alanları dosya başına tek satıra topla: path, mtime, cwd, branch, first
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
        set -l sid (string replace -r '\.jsonl$' '' (basename $f))
        test -n "$mtime"; or continue

        test -z "$first"; and continue                                              # sidechain/boş oturum
        test -n "$ccr_exclude"; and string match -qr -- "$ccr_exclude" "$cwd"; and continue

        # Göreli zaman
        set -l age (math "$now - $mtime")
        set -l when
        if test $age -lt 86400; and test (date -r $mtime '+%j') = (date '+%j')
            set when (printf '%s%s%s' $c_today (date -r $mtime '+%H:%M') $c_off)
        else if test $age -lt 172800
            set when (printf '%sdün %s%s' $c_date (date -r $mtime '+%H:%M') $c_off)
        else if test $age -lt 604800
            set when (printf '%s%dg önce%s' $c_date (math "floor($age / 86400)") $c_off)
        else
            set when (printf '%s%s%s' $c_date (date -r $mtime '+%m-%d') $c_off)
        end

        # Proje adı: 20 karaktere akıllı kısalt (kesme yerine … ekle)
        set -l proj (basename "$cwd")
        if test (string length -- $proj) -gt 20
            set proj (string sub -l 19 -- $proj)…
        end

        # Branch: 18 karaktere kısalt; yoksa boş göster
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
    test (count $lines) -gt 0; or begin; echo "ccr: eşleşen oturum yok" >&2; return 1; end

    # Dizin filtresi (--here / path arg). Eşleşen oturum yoksa tüm listeye düş.
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

    set -l header (printf '%b  %-20s  %s   %s%b' $c_date 'PROJE' 'BRANCH' 'ÖZET' $c_off)

    set -l sel (printf '%s\n' $lines | fzf \
        --ansi \
        --delimiter \t --with-nth 1 --query "$query" \
        --height 90% --reverse --border rounded \
        --prompt '  resume ❯ ' \
        --pointer '▶' --marker '✓' \
        --info inline \
        --header "$header" --header-first \
        --color 'fg:#DCD7BA,bg:-1,hl:#7E9CD8,fg+:#C8C093,bg+:#2D4F67,hl+:#7FB4CA,prompt:#98BB6C,pointer:#98BB6C,marker:#98BB6C,info:#727169,header:italic:#957FB8,border:#54546D,gutter:-1' \
        --preview "tail -n 1500 {4} | jq -rs '$preview_jq'" \
        --preview-window 'right:55%:wrap:border-left')
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
end
