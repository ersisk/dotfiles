function aipr --description 'branch diff'"'"'inden PR iskeleti üret (başlık + olgusal değişiklik listesi)'
    if contains -- -h $argv; or contains -- --help $argv
        set_color normal
        echo "aipr — PR iskeleti üret"
        echo
        set_color -o; echo "KULLANIM"; set_color normal
        echo "  aipr [-c|--create]"
        echo
        set_color -o; echo "NE ÜRETİR"; set_color normal
        echo "  başlık   <type>(<KEY>): <konu>  — KEY branch adından, konu modelden"
        echo "  Jira     KEY'den deterministik link"
        echo "  Çözüm    diff'ten olgusal değişiklik listesi"
        echo "  Sorun    BOŞ bırakılır — sebep diff'te yok, modele uydurtulmaz"
        echo
        set_color -o; echo "SEÇENEKLER"; set_color normal
        echo "  -c, --create   gh pr create ile aç (editörde açılır, gövde ön dolu)"
        echo "  -h, --help     bu yardım"
        return 0
    end

    # __aimsg_base paylasilan: base secimi iki yerde ayri durmasin. Fish dosya adiyla
    # autoload ettigi icin aimsg.fish'i acikca yuklemek gerekiyor.
    functions -q __aimsg_base; or source (dirname (status filename))/aimsg.fish

    git rev-parse --git-dir >/dev/null 2>&1; or begin
        echo "aipr: git deposu değil" >&2; return 1
    end

    set -l base (__aimsg_base)
    test -n "$base"; or begin
        echo "aipr: base bulunamadı — HEAD entegrasyon dalına girmiş olabilir" >&2; return 1
    end

    set -l diff (git --no-pager diff $base HEAD)
    test -n "$diff"; or begin
        echo "aipr: $base..HEAD boş" >&2; return 1
    end

    set -l branch (git symbolic-ref --short HEAD 2>/dev/null)
    set -l key (string match -r '[A-Z]{2,10}-[0-9]+' -- (string upper -- $branch))

    set -l tmp (mktemp); printf '%s\n' $diff > $tmp
    set -l ai $AI_ONESHOT; test -z "$ai"; and set ai ~/.config/bin/ai-oneshot
    set -l max $AIMSG_MAX_LINES; test -z "$max"; and set max 2000

    echo -n "iskele üretiliyor… " >&2
    set -l out (begin
        echo "Below is a git diff for one pull request. Output exactly two sections and nothing else:

SUBJECT: <type>: <one line, English, lowercase, imperative, max 60 chars>
CHANGES:
- <factual bullet, what the diff does, English, max 100 chars>
- <...at most 6 bullets, most significant first>

Describe only what the diff shows. Do not speculate about motive, impact or testing.
No markdown headings, no code fences, no extra commentary."
        head -n $max -- $tmp
    end | env AI_ONESHOT_BACKEND=claude $ai 2>/dev/null)
    rm -f $tmp
    echo "tamam." >&2

    set -l subject (printf '%s\n' $out | rg -m1 '^SUBJECT:' | string replace -r '^SUBJECT:\s*' '')
    set -l changes (printf '%s\n' $out | sed -n '/^CHANGES:/,$p' | tail -n +2 | string match -r '^\s*-.*')
    test -n "$subject"; or set subject "chore: update"
    test (count $changes) -gt 0; or set changes "- (diff'ten çıkarılamadı)"

    set -l title $subject
    if test -n "$key"; and string match -qr '^[a-z]+: ' -- $subject
        set title (string replace -r '^([a-z]+): ' "\$1($key): " -- $subject)
    end

    # Fish komut ikamesi ciktiyi satirlara boler; govde tek deger kalmazsa
    # cevredeki string birlesmesi kartezyen carpim yapip sablonu her madde icin
    # tekrarliyor. Once liste kurulur, sonra string collect ile tek parca yapilir.
    set -l lines "## Sorun" "" \
        "<!-- Neden bu değişiklik gerekti? Diff'te yok, sen yazacaksın. -->" "" \
        "## Çözüm" ""
    set -a lines $changes
    set -a lines "" "## Test" "" "<!-- Nasıl doğrulandı? -->"
    test -n "$key"; and set -a lines "" "Jira: https://pozitim.atlassian.net/browse/$key"
    set -l body (string join -- \n $lines | string collect)

    if contains -- -c $argv; or contains -- --create $argv
        gh pr create --base (string replace -r '^.*/' '' -- (git rev-parse --abbrev-ref $base 2>/dev/null; or echo dev)) \
            --title "$title" --body "$body" --draft --web
        return $status
    end

    printf '%s\n\n%s\n' "$title" "$body"
    printf '%s\n\n%s\n' "$title" "$body" | pbcopy
    echo >&2; echo "(clipboard'a kopyalandı; açmak için: aipr -c)" >&2
end
