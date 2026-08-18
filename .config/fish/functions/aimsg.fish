function aimsg --description 'Raycast AI ile commit mesajı üret, seçeneği clipboard'"'"'a al'
    if contains -- -h $argv; or contains -- --help $argv
        set_color normal
        echo "aimsg — git diff'ten Raycast AI ile commit mesajı üret"
        echo
        set_color -o; echo "KULLANIM"; set_color normal
        echo "  aimsg [-c|--commit] [-n|--no-wait]"
        echo
        set_color -o; echo "AKIŞ"; set_color normal
        echo "  1. diff clipboard'a kopyalanır (unstaged, yoksa staged)"
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

    if test -z "$diff_output"
        test (count $marked) -gt 0; and git reset -q -- $marked 2>/dev/null
        echo "aimsg: diff yok — enter" >&2
        isatty stdin; and read -P 'enter...' -n 1 -l __aimsg_key
        return 1
    end
    printf '%s\n' $diff_output | pbcopy
    test (count $marked) -gt 0; and git reset -q -- $marked 2>/dev/null

    set -l branch (git symbolic-ref --short HEAD 2>/dev/null)
    open -g "raycast://ai-commands/commit-generator?arguments={\"branch\":\"$branch\"}"

    test $no_wait -eq 1; and return 0

    # Raycast'in çıktısı clipboard'a düşene kadar bekle: diff gitmiş, OPTION gelmiş olmalı.
    echo -n "Raycast'te Copy'ye bas... "
    set -l raw ""
    for i in (seq 60)
        sleep 1
        set raw (pbpaste 2>/dev/null | string collect)
        string match -qr 'OPTION\s*[0-9]' -- "$raw"; and break
        set raw ""
    end
    if test -z "$raw"
        echo "zaman aşımı: clipboard'da OPTION yok — enter" >&2
        isatty stdin; and read -P 'enter...' -n 1 -l __aimsg_key
        return 1
    end
    echo "alındı."

    # Raycast'in Paste'i metni terminale yazmış olabilir; buffer'da kalırsa
    # fzf'in arama alanına düşüyor (macOS stty'de flush yok). Enter ile tüket.
    if isatty stdin
        read -P 'seçim için enter... ' -l __aimsg_drain
    end

    # OPTION N: satırlarını ayır, altındaki metni al
    set -l opts (printf '%s\n' $raw | awk '/^[[:space:]]*OPTION[[:space:]]*[0-9]+:/{n=1; next} n && NF {print; n=0}')
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
    if test $do_commit -eq 1
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
