function fzfke --description 'pick a pod with fzf: open a shell, run a command (--) or read logs (-l)'
    if contains -- -h $argv; or contains -- --help $argv
        set_color normal
        echo "fzfke — pick a pod with fzf, then open a shell / run a command / read logs"
        echo
        set_color -o; echo "USAGE"; set_color normal
        echo "  fzfke [-l] [-] [ns] [container] [query] [-- ...]"
        echo
        set_color -o; echo "MODES"; set_color normal
        echo "  (default)        open an interactive shell (bash, else sh)"
        echo "  -- <command>     run a single command in the pod"
        echo "  -l, --logs       kubectl logs; -- <duration> sets the window (default 30m)"
        echo
        set_color -o; echo "OPTIONS"; set_color normal
        echo "  -                reuse the last pod, skip fzf"
        echo "  ns               namespace; picked with fzf when empty"
        echo "  container        passed as -c; can be left empty"
        echo "  query            fzf pre-query on the pod list"
        echo "  -h, --help       this help"
        echo
        set_color -o; echo "EXAMPLES"; set_color normal
        echo "  fzfke my-ns                                    # shell"
        echo "  fzfke my-ns my-container                       # container + shell"
        echo "  fzfke my-ns -- pwd                             # command"
        echo "  fzfke my-ns my-container -- ls -la log/"
        echo "  fzfke my-ns -- bash -c 'env | grep -i DB'"
        echo "  fzfke -l my-ns my-container                    # last 30m of logs"
        echo "  fzfke -l my-ns my-container -- 15m             # last 15m of logs"
        echo "  fzfke - my-ns -- whoami                        # command on the last pod"
        echo
        if set -q fzfke_last_pod
            set_color -o; echo -n "Last pod: "; set_color normal; echo $fzfke_last_pod
        end
        return 0
    end

    # Everything after '--' runs as the command; before it the old positional order: [ns] [container] [query]
    set -l cmd
    set -l pre
    set -l seen_sep 0
    for a in $argv
        if test $seen_sep -eq 1
            set -a cmd $a
        else if test "$a" = --
            set seen_sep 1
        else
            set -a pre $a
        end
    end

    # -l / --logs: logs mode instead of a command. Remaining '--' arguments go to --since.
    set -l logs 0
    set -l reuse 0
    set -l rest
    for a in $pre
        switch $a
            case -l --logs; set logs 1
            case -; set reuse 1
            case '*'; set -a rest $a
        end
    end

    set -l ns $rest[1]
    set -l container $rest[2]
    set -l query $rest[3]

    if test -z "$ns"
        set ns (kubectl get namespaces --no-headers | fzf --height 20% --reverse --header="Select Namespace:" | awk '{print $1}')
    end
    if test -z "$ns"
        echo "fzfke: no namespace selected" >&2
        return 1
    end

    # Remember the last pod: firing commands at the same pod back to back is the common case.
    # With '-' fzf is skipped and that pod is used directly.
    set -l pod
    if test $reuse -eq 1
        set pod $fzfke_last_pod
        test -z "$pod"; and begin
            echo "fzfke: no remembered pod" >&2
            return 1
        end
        # Is the pod still up? A restart changes the hash.
        if not kubectl get pod $pod -n $ns >/dev/null 2>&1
            echo "fzfke: $pod is gone, falling back to the picker" >&2
            set pod ""
        end
    end

    if test -z "$pod"
        set -l fzf_args --height 40% --reverse --header="Select Pod ($ns):"
        test -n "$query"; and set -a fzf_args --query $query
        set pod (kubectl get pods -n "$ns" --no-headers | fzf $fzf_args | awk '{print $1}')
    end

    if test -z "$pod"
        echo "fzfke: no pod selected" >&2
        return 1
    end
    set -g fzfke_last_pod $pod

    set -l target -n $ns
    test -n "$container"; and set -a target -c $container

    if test $logs -eq 1
        # Duration: the first argument after '--', else 30m
        set -l since 30m
        test (count $cmd) -gt 0; and set since $cmd[1]
        set -l label "logs: $ns / $pod"
        test -n "$container"; and set label "$label ($container)"
        echo $label >&2
        kubectl logs $pod $target --since=$since
    else if test (count $cmd) -gt 0
        kubectl exec $pod $target -- $cmd
    else
        set -l label "shell: $ns / $pod"
        test -n "$container"; and set label "$label ($container)"
        echo $label >&2
        kubectl exec -it $pod $target -- /bin/bash
        or kubectl exec -it $pod $target -- /bin/sh
    end
end
