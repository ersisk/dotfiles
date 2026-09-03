function aipr --description 'build a PR skeleton from the branch diff (title + factual change list)'
    if contains -- -h $argv; or contains -- --help $argv
        set_color normal
        echo "aipr — build a PR skeleton"
        echo
        set_color -o; echo "USAGE"; set_color normal
        echo "  aipr [-c|--create]"
        echo
        set_color -o; echo "WHAT IT PRODUCES"; set_color normal
        echo "  title     <type>(<KEY>): <subject>  — KEY from the branch name, subject from the model"
        echo "  Jira      deterministic link from the KEY"
        echo "  Solution  factual change list from the diff"
        echo "  Problem   left EMPTY — the reason is not in the diff, the model will not invent it"
        echo
        set_color -o; echo "OPTIONS"; set_color normal
        echo "  -c, --create   open it with gh pr create (opens in the editor, body pre-filled)"
        echo "  -h, --help     this help"
        return 0
    end

    # __aimsg_base is shared so base selection does not live in two places. Fish
    # autoloads by file name, so aimsg.fish has to be sourced explicitly.
    functions -q __aimsg_base; or source (dirname (status filename))/aimsg.fish

    git rev-parse --git-dir >/dev/null 2>&1; or begin
        echo "aipr: not a git repository" >&2; return 1
    end

    set -l base (__aimsg_base)
    test -n "$base"; or begin
        echo "aipr: no base found — HEAD may already be on the integration branch" >&2; return 1
    end

    set -l diff (git --no-pager diff $base HEAD)
    test -n "$diff"; or begin
        echo "aipr: $base..HEAD is empty" >&2; return 1
    end

    set -l branch (git symbolic-ref --short HEAD 2>/dev/null)
    set -l key (string match -r '[A-Z]{2,10}-[0-9]+' -- (string upper -- $branch))

    set -l tmp (mktemp); printf '%s\n' $diff > $tmp
    set -l ai $AI_ONESHOT; test -z "$ai"; and set ai ~/.config/bin/ai-oneshot
    set -l max $AIMSG_MAX_LINES; test -z "$max"; and set max 2000

    echo -n "building skeleton… " >&2
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
    echo "done." >&2

    set -l subject (printf '%s\n' $out | rg -m1 '^SUBJECT:' | string replace -r '^SUBJECT:\s*' '')
    set -l changes (printf '%s\n' $out | sed -n '/^CHANGES:/,$p' | tail -n +2 | string match -r '^\s*-.*')
    test -n "$subject"; or set subject "chore: update"
    test (count $changes) -gt 0; or set changes "- (could not be derived from the diff)"

    set -l title $subject
    if test -n "$key"; and string match -qr '^[a-z]+: ' -- $subject
        set title (string replace -r '^([a-z]+): ' "\$1($key): " -- $subject)
    end

    # Fish command substitution splits output into lines; unless the body stays a
    # single value the surrounding string concatenation goes cartesian and repeats
    # the template per bullet. Build the list first, then collapse it with string collect.
    set -l lines "## Problem" "" \
        "<!-- Why was this change needed? Not in the diff, you write it. -->" "" \
        "## Solution" ""
    set -a lines $changes
    set -a lines "" "## Test" "" "<!-- How was it verified? -->"
    test -n "$key"; and set -a lines "" "Jira: https://pozitim.atlassian.net/browse/$key"
    set -l body (string join -- \n $lines | string collect)

    if contains -- -c $argv; or contains -- --create $argv
        gh pr create --base (string replace -r '^.*/' '' -- (git rev-parse --abbrev-ref $base 2>/dev/null; or echo dev)) \
            --title "$title" --body "$body" --draft --web
        return $status
    end

    printf '%s\n\n%s\n' "$title" "$body"
    printf '%s\n\n%s\n' "$title" "$body" | pbcopy
    echo >&2; echo "(copied to the clipboard; to open it: aipr -c)" >&2
end
