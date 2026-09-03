function __aimsg_base --description "merge-base of the integration branch closest to HEAD"
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
        # If HEAD is already on this branch there is no branch-specific work left: produce no base
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

# Feeds the diff to the model and gets candidate commit messages back. The Jira
# key is pulled from the branch name by regex, never asked of the model, so it
# cannot invent one out of diff noise.
#
# Two backends, and their inputs differ too — measured:
#   ollama (qwen3): 2-3s on a diff with context lines stripped, 45s on the full diff
#   claude (haiku): 14-16s on the full diff, markedly better quality
# Hence the local one sees only changed lines, the remote one the full diff.
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
        # Context lines (those starting with a space) are dropped: prefill is the
        # whole cost for the local model, and changed lines are enough for a subject.
        set raw (begin
            printf '%s\n' $prompt
            rg -N '^(diff --git |@@|[+-])' -- $diff_file | head -150
        end | env AI_ONESHOT_BACKEND=ollama $ai 2>/dev/null | string trim | string match -v '')
    end

    # Clean up if the model numbers or quotes them anyway.
    set -l key (string match -r '[A-Z]{2,10}-[0-9]+' -- (string upper -- $branch))
    for line in $raw
        set -l c (string replace -r '^\s*(?:[0-9]+[.)]|[-*])\s*' '' -- $line \
            | string trim | string trim -c '"' | string trim -c '`')
        test -n "$c"; or continue
        # Scope is added here: the repo convention is <type>(<KEY>): <subject>.
        if test -n "$key"; and string match -qr '^[a-z]+(\([^)]*\))?: ' -- $c
            set -l type (string replace -r '^([a-z]+).*' '$1' -- $c)
            set -l subj (string replace -r '^[a-z]+(\([^)]*\))?:\s*' '' -- $c)
            echo "$type($key): $subj"
        else
            echo $c
        end
    end
end

function aimsg --description 'generate a commit message from the git diff, copy the pick to the clipboard'
    # This is how fzf's reload calls back in: print the candidates, exit.
    if test "$argv[1]" = --_gen
        __aimsg_generate $argv[2] $argv[3] $argv[4]
        return 0
    end

    if contains -- -h $argv; or contains -- --help $argv
        set_color normal
        echo "aimsg — generate a commit message from the git diff"
        echo
        set_color -o; echo "USAGE"; set_color normal
        echo "  aimsg [-c|--commit]"
        echo
        set_color -o; echo "FLOW"; set_color normal
        echo "  1. a diff is picked (unstaged, else staged, else untracked)"
        echo "     if none: the committed diff against the branch base (worktree flow)"
        echo "  2. ai-oneshot produces three candidates; the scope comes from the Jira key in the branch name"
        echo "  3. the candidates are listed with fzf, the one you pick goes to the clipboard"
        echo
        set_color -o; echo "OPTIONS"; set_color normal
        echo "  -c, --commit     git commit straight away with the chosen message"
        echo "  -h, --help       this help"
        echo
        set_color -o; echo "ENVIRONMENT"; set_color normal
        echo "  AI_ONESHOT       path to ai-oneshot (model choice lives there)"
        echo "  AIMSG_MAX_LINES  line limit on the diff sent to the model (default: 2000)"
        return 0
    end

    set -l do_commit 0
    for a in $argv
        switch $a
            case -c --commit; set do_commit 1
        end
    end

    # Untracked files are part of the change too, so they are made visible with -N
    # BEFORE the diff. This used to happen only when the unstaged diff was EMPTY;
    # with both modified and new files present (the common case) the new ones fell
    # away silently and the message told half the story.
    set -l marked (git ls-files --others --exclude-standard)
    test (count $marked) -gt 0; and git add -N -- $marked 2>/dev/null

    set -l diff_output (git --no-pager diff)
    test -z "$diff_output"; and set diff_output (git --no-pager diff --cached)

    # In the worktree flow the work is already committed and the tree stays clean.
    # Then diff the branch against its base: the merge-base of the candidate ref
    # closest to HEAD (master/release-candidate/upstream, depending on the repo).
    set -l from_range 0
    if test -z "$diff_output"
        set -l base (__aimsg_base)
        if test -n "$base"
            set diff_output (git --no-pager diff $base HEAD)
            if test -n "$diff_output"
                set from_range 1
                echo "source: committed diff — base "(string sub -l 8 -- $base)", "(git rev-list --count $base..HEAD)" commits, "(count $diff_output)" lines"
            end
        end
    end

    if test -z "$diff_output"
        test (count $marked) -gt 0; and git reset -q -- $marked 2>/dev/null
        echo "aimsg: no diff — enter" >&2
        isatty stdin; and read -P 'enter...' -n 1 -l __aimsg_key
        return 1
    end
    test (count $marked) -gt 0; and git reset -q -- $marked 2>/dev/null

    set -l branch (git symbolic-ref --short HEAD 2>/dev/null)
    # symbolic-ref returns empty in a detached worktree
    test -z "$branch"; and set branch (git rev-parse --short HEAD 2>/dev/null)

    set -l tmp (mktemp)
    printf '%s\n' $diff_output > $tmp

    # The list is filled inside fzf: the model can take 2-14 seconds and the popup
    # sat empty for all of it. Local model first (~2-3s); if you dislike the result,
    # ctrl-r regenerates with claude (~14s, markedly better).
    # --no-config: loading config.fish adds ~250ms to the subshell.
    set -l self (string escape -- (status filename))
    set -l a_tmp (string escape -- $tmp)
    set -l a_br (string escape -- $branch)
    set -l gen_local "fish --no-config -c "(string escape -- "source $self; aimsg --_gen $a_tmp $a_br ollama")" 2>/dev/null"
    set -l gen_remote "fish --no-config -c "(string escape -- "source $self; aimsg --_gen $a_tmp $a_br claude")" 2>/dev/null"

    set -l pick (fzf \
        --height 40% --reverse --border rounded \
        --border-label ' commit message ' --prompt '󰊢 ' \
        --header '⧗ local model is generating…' --header-first \
        --bind "start:reload($gen_local)" \
        --bind "load:change-header(⏎ pick · ctrl-r regenerate with claude)" \
        --bind "ctrl-r:change-header(⧗ claude is generating… ~14s)+reload($gen_remote)" \
        --color 'fg:#DCD7BA,bg:-1,hl:#7E9CD8,fg+:#C8C093,bg+:#2D4F67,prompt:#98BB6C,pointer:#98BB6C,header:italic:#957FB8,border:#54546D' </dev/null)
    rm -f $tmp
    test -z "$pick"; and return 0

    printf '%s' $pick | pbcopy
    if test $do_commit -eq 1 -a $from_range -eq 1
        echo "clipboard: $pick"
        echo "nothing to commit (the message came from the committed diff) — amend: git commit --amend -m ..." >&2
    else if test $do_commit -eq 1
        if test (count (git --no-pager diff --cached --name-only)) -gt 0
            git commit -m "$pick"
        else
            git commit -a -m "$pick"
        end
    else
        echo "clipboard: $pick"
        if isatty stdin
            read -P 'enter to close...' -n 1 -l __aimsg_key 2>/dev/null
        end
    end
end
