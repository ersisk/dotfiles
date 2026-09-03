function gcb --description 'jira-to-branch ile branch adı üret, seçilen base üzerinden aç'
    if contains -- -h $argv; or contains -- --help $argv
        set_color normal
        echo "gcb — Jira başlığından branch üret (jira-to-branch) ve checkout et"
        echo
        set_color -o; echo "KULLANIM"; set_color normal
        echo "  gcb [base] [-k|--key <KEY>] [-n|--name <ad>] [-d|--dry-run]"
        echo
        set_color -o; echo "AKIŞ"; set_color normal
        echo "  1. jira-to-branch çalışır: anahtar (-k yoksa ekrandan OCR ile) →"
        echo "     başlık jira-cli ile API'den → branch adı"
        echo "  2. base branch seçilir (parametre yoksa fzf ile)"
        echo "  3. git fetch + git checkout -b <ad> origin/<base>"
        echo
        set_color -o; echo "SEÇENEKLER"; set_color normal
        echo "  base             base branch; kısmi ad da eşleşir (rc → release-candidate)"
        echo "  -k, --key <KEY>  Jira anahtarı; OCR atlanır, başlık API'den gelir"
        echo "  -n, --name <ad>  jira-to-branch'i hiç çağırma, adı doğrudan ver"
        echo "  -d, --dry-run    sadece ne yapacağını yaz, checkout etme"
        echo "  -h, --help       bu yardım"
        echo
        set_color -o; echo "ÖRNEKLER"; set_color normal
        echo "  gcb                              # base'i fzf ile seç"
        echo "  gcb release-candidate            # doğrudan base ver"
        echo "  gcb rc                           # kısaltma"
        echo "  gcb rc -k GD-1140                # ekrana bakmadan"
        echo "  gcb rc -n feature/GD-1-deneme    # jira-to-branch olmadan"
        echo "  gcb -d                           # kuru çalıştır"
        return 0
    end

    git rev-parse --git-dir >/dev/null 2>&1; or begin
        echo "gcb: git deposu değil" >&2
        return 1
    end

    set -l dry 0
    set -l name ""
    set -l key ""
    set -l base_arg ""
    set -l i 1
    while test $i -le (count $argv)
        switch $argv[$i]
            case -d --dry-run; set dry 1
            case -k --key
                set i (math $i + 1)
                set key $argv[$i]
            case -n --name
                set i (math $i + 1)
                set name $argv[$i]
            case '*'
                test -z "$base_arg"; and set base_arg $argv[$i]
        end
        set i (math $i + 1)
    end

    # -n jira-to-branch'i hic cagirmiyor, -k ona verilecek argument: ikisi birlikte
    # verilirse -k sessizce yok sayilirdi.
    if test -n "$name"; and test -n "$key"
        echo "gcb: -n ve -k birlikte kullanılmaz" >&2
        return 1
    end

    # Uzak base adaylarını topla; kısmi eşleşmeye izin ver (rc -> release-candidate)
    git fetch --quiet 2>/dev/null
    set -l cands (git branch -r 2>/dev/null | string trim | string replace -r '^origin/' '' \
        | string match -v -r '^HEAD' | sort -u)
    test (count $cands) -eq 0; and begin
        echo "gcb: uzak branch bulunamadı" >&2
        return 1
    end

    set -l base ""
    if test -n "$base_arg"
        # tam eşleşme önce, sonra kısmi
        if contains -- $base_arg $cands
            set base $base_arg
        else
            set -l hits (printf '%s\n' $cands | fzf --filter=$base_arg 2>/dev/null)
            switch (count $hits)
                case 0
                    echo "gcb: '$base_arg' hiçbir branch'e uymuyor" >&2
                    return 1
                case 1
                    set base $hits[1]
                case '*'
                    set base (printf '%s\n' $hits | fzf --height 30% --reverse \
                        --border rounded --border-label ' base branch ' --prompt '⎇ ' \
                        --query $base_arg)
            end
        end
    else
        # Sık kullanılanları başa al, kalanları arkasına
        set -l pref
        for b in release-candidate develop dev main master test
            contains -- $b $cands; and set -a pref $b
        end
        set -l rest
        for b in $cands
            contains -- $b $pref; or set -a rest $b
        end
        set base (printf '%s\n' $pref $rest | fzf --height 40% --reverse \
            --border rounded --border-label ' base branch ' --prompt '⎇ ')
    end
    test -z "$base"; and return 0

    # Branch adı: -n ile verilmediyse jira-to-branch üretir, stdout'tan okunur.
    # Boru eklersen $status boruyu izler, jira-to-branch'i değil — hatası yutulur.
    if test -z "$name"
        set -l jtb ~/.config/bin/jira-to-branch
        test -x $jtb; or begin
            echo "gcb: $jtb bulunamadı (-n ile ad verebilirsin)" >&2
            return 1
        end
        set -l jtb_args
        test -n "$key"; and set jtb_args -k $key
        set name ($jtb $jtb_args)
        or return 1
    end

    if test -z "$name"
        echo "gcb: branch adı boş" >&2
        return 1
    end
    # Tek satır, boşluksuz olmalı
    set name (printf '%s' $name | head -1 | string replace -a ' ' '-')

    if git show-ref --verify --quiet "refs/heads/$name"
        echo "gcb: '$name' zaten var" >&2
        return 1
    end

    echo "  base:   origin/$base"
    echo "  branch: $name"
    if test $dry -eq 1
        echo "  (dry-run, checkout yapılmadı)"
        return 0
    end
    git checkout -b $name --no-track "origin/$base"
end
