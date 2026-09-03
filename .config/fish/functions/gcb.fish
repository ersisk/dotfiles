function gcb --description 'generate a branch name with jira-to-branch, open it off the chosen base'
    if contains -- -h $argv; or contains -- --help $argv
        set_color normal
        echo "gcb — build a branch from a Jira title (jira-to-branch) and check it out"
        echo
        set_color -o; echo "USAGE"; set_color normal
        echo "  gcb [base] [-k|--key <KEY>] [-n|--name <name>] [-d|--dry-run]"
        echo
        set_color -o; echo "FLOW"; set_color normal
        echo "  1. jira-to-branch runs: key (via screen OCR unless -k) →"
        echo "     title from the API via jira-cli → branch name"
        echo "  2. base branch is picked (with fzf unless given as a parameter)"
        echo "  3. git fetch + git checkout -b <ad> origin/<base>"
        echo
        set_color -o; echo "OPTIONS"; set_color normal
        echo "  base             base branch; a partial name matches too (rc → release-candidate)"
        echo "  -k, --key <KEY>  Jira key; OCR is skipped, the title comes from the API"
        echo "  -n, --name <name>  skip jira-to-branch entirely, give the name directly"
        echo "  -d, --dry-run    only print what it would do, do not check out"
        echo "  -h, --help       this help"
        echo
        set_color -o; echo "EXAMPLES"; set_color normal
        echo "  gcb                              # pick the base with fzf"
        echo "  gcb release-candidate            # give the base directly"
        echo "  gcb rc                           # abbreviation"
        echo "  gcb rc -k GD-1140                # without looking at the screen"
        echo "  gcb rc -n feature/GD-1-trial     # without jira-to-branch"
        echo "  gcb -d                           # dry run"
        return 0
    end

    git rev-parse --git-dir >/dev/null 2>&1; or begin
        echo "gcb: not a git repository" >&2
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

    # -n never calls jira-to-branch, while -k is an argument for it: given both,
    # -k would be silently ignored.
    if test -n "$name"; and test -n "$key"
        echo "gcb: -n and -k cannot be combined" >&2
        return 1
    end

    # Collect remote base candidates; allow partial matches (rc -> release-candidate)
    git fetch --quiet 2>/dev/null
    set -l cands (git branch -r 2>/dev/null | string trim | string replace -r '^origin/' '' \
        | string match -v -r '^HEAD' | sort -u)
    test (count $cands) -eq 0; and begin
        echo "gcb: no remote branch found" >&2
        return 1
    end

    set -l base ""
    if test -n "$base_arg"
        # exact match first, then partial
        if contains -- $base_arg $cands
            set base $base_arg
        else
            set -l hits (printf '%s\n' $cands | fzf --filter=$base_arg 2>/dev/null)
            switch (count $hits)
                case 0
                    echo "gcb: '$base_arg' matches no branch" >&2
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
        # Put the common ones first, the rest after
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

    # Branch name: unless given with -n, jira-to-branch produces it on stdout.
    # Add a pipe and $status follows the pipe, not jira-to-branch — its error is swallowed.
    if test -z "$name"
        set -l jtb ~/.config/bin/jira-to-branch
        test -x $jtb; or begin
            echo "gcb: $jtb not found (you can pass a name with -n)" >&2
            return 1
        end
        set -l jtb_args
        test -n "$key"; and set jtb_args -k $key
        set name ($jtb $jtb_args)
        or return 1
    end

    if test -z "$name"
        echo "gcb: branch name is empty" >&2
        return 1
    end
    # Must be a single line with no spaces
    set name (printf '%s' $name | head -1 | string replace -a ' ' '-')

    if git show-ref --verify --quiet "refs/heads/$name"
        echo "gcb: '$name' already exists" >&2
        return 1
    end

    echo "  base:   origin/$base"
    echo "  branch: $name"
    if test $dry -eq 1
        echo "  (dry-run, nothing checked out)"
        return 0
    end
    git checkout -b $name --no-track "origin/$base"
end
