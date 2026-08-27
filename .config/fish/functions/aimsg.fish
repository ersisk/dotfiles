function __aimsg_base --description "HEAD'e en yakin entegrasyon dalinin merge-base'i"
    set -l cands
    set -l oh (git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null)
    test -n "$oh"; and set -a cands $oh
    set -a cands origin/release-candidate origin/main origin/master origin/develop main master

    set -l seen
    set -l best_mb ""
    set -l best_n 0
    for ref in $cands
        contains -- $ref $seen; and continue
        set -a seen $ref
        git rev-parse -q --verify "$ref^{commit}" >/dev/null 2>&1; or continue
        # HEAD bu dala girmisse branch'e ozgu is kalmamistir: base uretme
        git merge-base --is-ancestor HEAD $ref 2>/dev/null; and return 1
        set -l mb (git merge-base $ref HEAD 2>/dev/null)
        test -n "$mb"; or continue
        set -l n (git rev-list --count $mb..HEAD 2>/dev/null)
        test -n "$n"; and test $n -gt 0; or continue
        if test $best_n -eq 0 -o $n -lt $best_n
            set best_n $n
            set best_mb $mb
        end
    end
    test -n "$best_mb"; and echo $best_mb
end

# Diff'i modele verip aday commit mesajlarini alir. Jira anahtari branch adindan
# regex'le cikarilir, modele sorulmaz: diff gurultusunden anahtar uydurmasin.
#
# Iki arka uc, girdileri de farkli — olculdu:
#   ollama (qwen3): baglam satirlari atilmis diff'te 2-3s, tam diff'te 45s
#   claude (haiku): tam diff'te 14-16s, kalite belirgin daha iyi
# O yuzden yerel olan sadece degisen satirlari gorur, uzak olan tam diff'i.
function __aimsg_generate --argument-names diff_file branch backend
    set -l ai $AI_ONESHOT
    test -z "$ai"; and set ai ~/.config/bin/ai-oneshot
    set -l max $AIMSG_MAX_LINES
    test -z "$max"; and set max 2000

    set -l prompt "Below is a git diff. Propose 3 candidate commit message subjects.

Rules:
- One candidate per line, exactly 3 lines, nothing else.
- Each line: <type>: <subject>
- type: feat|fix|refactor|perf|test|docs|chore|build|ci|style|revert
- subject: English, lowercase, imperative, no trailing period, at most 60 characters.
- The three must differ in what they emphasise, not be rewordings of each other.
- No numbering, no bullets, no quotes, no code fences, no explanation, no body.

Diff:"

    set -l raw
    if test "$backend" = claude
        set raw (begin
            printf '%s\n' $prompt
            head -n $max -- $diff_file
            test (wc -l < $diff_file) -gt $max; and echo "[diff truncated at $max lines]"
        end | env AI_ONESHOT_BACKEND=claude $ai 2>/dev/null | string trim | string match -v '')
    else
        # Baglam satirlari (bosluk ile baslayanlar) atilir: yerel modelde prefill
        # maliyetin tamami, konu basligi icin de degisen satirlar yetiyor.
        set raw (begin
            printf '%s\n' $prompt
            rg -N '^(diff --git |@@|[+-])' -- $diff_file | head -150
        end | env AI_ONESHOT_BACKEND=ollama $ai 2>/dev/null | string trim | string match -v '')
    end

    # Model yine de numaralandirir ya da tirnaklarsa temizle.
    set -l key (string match -r '[A-Z]{2,10}-[0-9]+' -- (string upper -- $branch))
    for line in $raw
        set -l c (string replace -r '^\s*(?:[0-9]+[.)]|[-*])\s*' '' -- $line \
            | string trim | string trim -c '"' | string trim -c '`')
        test -n "$c"; or continue
        # Scope'u burada ekliyoruz: repo konvansiyonu <type>(<KEY>): <subject>.
        if test -n "$key"; and string match -qr '^[a-z]+(\([^)]*\))?: ' -- $c
            set -l type (string replace -r '^([a-z]+).*' '$1' -- $c)
            set -l subj (string replace -r '^[a-z]+(\([^)]*\))?:\s*' '' -- $c)
            echo "$type($key): $subj"
        else
            echo $c
        end
    end
end

function aimsg --description 'git diff'"'"'ten commit mesajı üret, seçeneği clipboard'"'"'a al'
    # fzf'in reload'u kendini boyle cagirir: adaylari basar, cikar.
    if test "$argv[1]" = --_gen
        __aimsg_generate $argv[2] $argv[3] $argv[4]
        return 0
    end

    if contains -- -h $argv; or contains -- --help $argv
        set_color normal
        echo "aimsg — git diff'ten commit mesajı üret"
        echo
        set_color -o; echo "KULLANIM"; set_color normal
        echo "  aimsg [-c|--commit]"
        echo
        set_color -o; echo "AKIŞ"; set_color normal
        echo "  1. diff seçilir (unstaged, yoksa staged, yoksa untracked)"
        echo "     hiçbiri yoksa: branch'in base'ine göre commit'li diff (worktree akışı)"
        echo "  2. ai-oneshot üç aday üretir; scope branch adındaki Jira key'inden gelir"
        echo "  3. adaylar fzf ile listelenir, seçtiğin clipboard'a gider"
        echo
        set_color -o; echo "SEÇENEKLER"; set_color normal
        echo "  -c, --commit     seçilen mesajla doğrudan git commit yap"
        echo "  -h, --help       bu yardım"
        echo
        set_color -o; echo "ORTAM"; set_color normal
        echo "  AI_ONESHOT       ai-oneshot yolu (model seçimi orada)"
        echo "  AIMSG_MAX_LINES  modele giden diff satır sınırı (varsayılan: 2000)"
        return 0
    end

    set -l do_commit 0
    for a in $argv
        switch $a
            case -c --commit; set do_commit 1
        end
    end

    set -l diff_output (git --no-pager diff)
    test -z "$diff_output"; and set diff_output (git --no-pager diff --cached)

    set -l marked
    if test -z "$diff_output"
        set marked (git ls-files --others --exclude-standard)
        if test (count $marked) -gt 0
            git add -N -- $marked 2>/dev/null
            set diff_output (git --no-pager diff)
        end
    end

    # Worktree akisinda is zaten commit'lenmis oluyor, calisma agaci temiz kaliyor.
    # O durumda branch'i base'ine gore diff'le: base, HEAD'e en yakin aday ref'in
    # merge-base'i (repo'ya gore master/release-candidate/upstream degisiyor).
    set -l from_range 0
    if test -z "$diff_output"
        set -l base (__aimsg_base)
        if test -n "$base"
            set diff_output (git --no-pager diff $base HEAD)
            if test -n "$diff_output"
                set from_range 1
                echo "kaynak: commit'li diff — base "(string sub -l 8 -- $base)", "(git rev-list --count $base..HEAD)" commit, "(count $diff_output)" satır"
            end
        end
    end

    if test -z "$diff_output"
        test (count $marked) -gt 0; and git reset -q -- $marked 2>/dev/null
        echo "aimsg: diff yok — enter" >&2
        isatty stdin; and read -P 'enter...' -n 1 -l __aimsg_key
        return 1
    end
    test (count $marked) -gt 0; and git reset -q -- $marked 2>/dev/null

    set -l branch (git symbolic-ref --short HEAD 2>/dev/null)
    # detached worktree'de symbolic-ref bos doner
    test -z "$branch"; and set branch (git rev-parse --short HEAD 2>/dev/null)

    set -l tmp (mktemp)
    printf '%s\n' $diff_output > $tmp

    # Liste fzf icinde doldurulur: model 2-14 saniye surebiliyor ve o sure boyunca
    # popup bombos kaliyordu. Once yerel model (~2-3s), begenmezsen ctrl-r ile
    # claude yeniden uretir (~14s, belirgin daha iyi).
    # --no-config: config.fish yuklemek subshell'e ~250ms ekliyor.
    set -l self (string escape -- (status filename))
    set -l a_tmp (string escape -- $tmp)
    set -l a_br (string escape -- $branch)
    set -l gen_local "fish --no-config -c "(string escape -- "source $self; aimsg --_gen $a_tmp $a_br ollama")" 2>/dev/null"
    set -l gen_remote "fish --no-config -c "(string escape -- "source $self; aimsg --_gen $a_tmp $a_br claude")" 2>/dev/null"

    set -l pick (fzf \
        --height 40% --reverse --border rounded \
        --border-label ' commit mesajı ' --prompt '󰊢 ' \
        --header '⧗ yerel model üretiyor…' --header-first \
        --bind "start:reload($gen_local)" \
        --bind "load:change-header(⏎ seç · ctrl-r claude ile yeniden üret)" \
        --bind "ctrl-r:change-header(⧗ claude üretiyor… ~14s)+reload($gen_remote)" \
        --color 'fg:#DCD7BA,bg:-1,hl:#7E9CD8,fg+:#C8C093,bg+:#2D4F67,prompt:#98BB6C,pointer:#98BB6C,header:italic:#957FB8,border:#54546D' </dev/null)
    rm -f $tmp
    test -z "$pick"; and return 0

    printf '%s' $pick | pbcopy
    if test $do_commit -eq 1 -a $from_range -eq 1
        echo "clipboard: $pick"
        echo "commit edilecek değişiklik yok (mesaj commit'li diff'ten üretildi) — amend: git commit --amend -m ..." >&2
    else if test $do_commit -eq 1
        if test (count (git --no-pager diff --cached --name-only)) -gt 0
            git commit -m "$pick"
        else
            git commit -a -m "$pick"
        end
    else
        echo "clipboard: $pick"
        if isatty stdin
            read -P 'kapatmak için enter...' -n 1 -l __aimsg_key 2>/dev/null
        end
    end
end
