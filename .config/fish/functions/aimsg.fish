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

function aimsg --description 'Raycast AI ile commit mesajı üret, seçeneği clipboard'"'"'a al'
    if contains -- -h $argv; or contains -- --help $argv
        set_color normal
        echo "aimsg — git diff'ten Raycast AI ile commit mesajı üret"
        echo
        set_color -o; echo "KULLANIM"; set_color normal
        echo "  aimsg [-c|--commit] [-n|--no-wait]"
        echo
        set_color -o; echo "AKIŞ"; set_color normal
        echo "  1. diff clipboard'a kopyalanır (unstaged, yoksa staged, yoksa untracked)"
        echo "     hiçbiri yoksa: branch'in base'ine göre commit'li diff (worktree akışı)"
        echo "  2. Raycast AI commit-generator açılır"
        echo "  3. Raycast'te Copy'ye bas — çıktı clipboard'a düşer"
        echo "  4. burada OPTION'lar fzf ile listelenir, seçtiğin clipboard'a gider"
        echo
        set_color -o; echo "SEÇENEKLER"; set_color normal
        echo "  -c, --commit     seçilen mesajla doğrudan git commit yap"
        echo "  -n, --no-wait    Raycast'i aç, seçim bekleme (eski davranış)"
        echo "  -h, --help       bu yardım"
        return 0
    end

    set -l do_commit 0
    set -l no_wait 0
    for a in $argv
        switch $a
            case -c --commit; set do_commit 1
            case -n --no-wait; set no_wait 1
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
    printf '%s\n' $diff_output | pbcopy
    test (count $marked) -gt 0; and git reset -q -- $marked 2>/dev/null

    set -l branch (git symbolic-ref --short HEAD 2>/dev/null)
    # detached worktree'de symbolic-ref bos doner
    test -z "$branch"; and set branch (git rev-parse --short HEAD 2>/dev/null)
    open -g "raycast://ai-commands/commit-generator?arguments={\"branch\":\"$branch\"}"

    test $no_wait -eq 1; and return 0

    # Raycast'in çıktısı clipboard'a düşene kadar bekle: diff gitmiş, OPTION gelmiş olmalı.
    # Beklerken Raycast'in terminale yazdığı metin ekranda görünmesin.
    isatty stdin; and stty -echo 2>/dev/null
    echo -n "Raycast'te Copy'ye bas... "
    set -l raw ""
    for i in (seq 60)
        sleep 1
        set raw (pbpaste 2>/dev/null | string collect)
        # Raycast bazen OPTION listesi, bazen tek mesaj döndürüyor: ikisini de kabul et.
        # Kendi kopyaladığımız diff'i çıktı sanmamak için 'diff --git' hariç tutulur.
        if test -n "$raw"; and not string match -q '*diff --git*' -- "$raw"
            break
        end
        set raw ""
    end
    if test -z "$raw"
        isatty stdin; and stty echo 2>/dev/null
        echo "zaman aşımı: clipboard'da OPTION yok — enter" >&2
        isatty stdin; and read -P 'enter...' -n 1 -l __aimsg_key
        return 1
    end
    isatty stdin; and stty echo 2>/dev/null
    echo "alındı."

    # Raycast'in Paste'i metni terminale yazar; buffer'da kalırsa fzf'in arama
    # alanına düşüyor. termios TCIFLUSH ile kernel seviyesinde temizle
    # (macOS stty'de flush yok, fish read'de timeout yok).
    if isatty stdin
        python3 -c 'import termios,sys; termios.tcflush(sys.stdin.fileno(), termios.TCIFLUSH)' 2>/dev/null
    end

    # OPTION N: satırlarını ayır, altındaki metni al
    set -l opts (printf '%s\n' $raw | awk '/^[[:space:]]*OPTION[[:space:]]*[0-9]+:/{n=1; next} n && NF {print; n=0}')
    # OPTION formatı yoksa boş olmayan satırları seçenek say (tek mesaj hali)
    if test (count $opts) -eq 0
        set opts (printf '%s\n' $raw | string trim | string match -v '')
    end
    if test (count $opts) -eq 0
        echo "aimsg: OPTION ayrıştırılamadı — enter" >&2
        isatty stdin; and read -P 'enter...' -n 1 -l __aimsg_key
        return 1
    end

    set -l pick (printf '%s\n' $opts | fzf \
        --height 30% --reverse --border rounded \
        --border-label ' commit mesajı ' --prompt '󰊢 ' \
        --color 'fg:#DCD7BA,bg:-1,hl:#7E9CD8,fg+:#C8C093,bg+:#2D4F67,prompt:#98BB6C,pointer:#98BB6C,border:#54546D')
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
