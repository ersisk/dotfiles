function fzfke --description 'fzf ile pod seç: shell aç, komut çalıştır (--) veya log oku (-l)'
    if contains -- -h $argv; or contains -- --help $argv
        set_color normal
        echo "fzfke — fzf ile pod seç, sonra shell aç / komut çalıştır / log oku"
        echo
        set_color -o; echo "KULLANIM"; set_color normal
        echo "  fzfke [-l] [-] [ns] [container] [query] [-- ...]"
        echo
        set_color -o; echo "MODLAR"; set_color normal
        echo "  (varsayılan)     interaktif shell aç (bash, yoksa sh)"
        echo "  -- <komut>       pod içinde tek komut çalıştır"
        echo "  -l, --logs       kubectl logs; -- <süre> ile süre (varsayılan 30m)"
        echo
        set_color -o; echo "SEÇENEKLER"; set_color normal
        echo "  -                son kullanılan pod'u tekrar kullan, fzf'i atla"
        echo "  ns               namespace; boşsa fzf ile seçilir"
        echo "  container        -c olarak geçer; boş bırakılabilir"
        echo "  query            pod listesinde fzf ön-sorgusu"
        echo "  -h, --help       bu yardım"
        echo
        set_color -o; echo "ÖRNEKLER"; set_color normal
        echo "  fzfke my-ns                                    # shell"
        echo "  fzfke my-ns my-container                       # container + shell"
        echo "  fzfke my-ns -- pwd                             # komut"
        echo "  fzfke my-ns my-container -- ls -la log/"
        echo "  fzfke my-ns -- bash -c 'env | grep -i DB'"
        echo "  fzfke -l my-ns my-container                    # son 30m log"
        echo "  fzfke -l my-ns my-container -- 15m             # son 15m log"
        echo "  fzfke - my-ns -- whoami                        # son pod'a komut"
        echo
        if set -q fzfke_last_pod
            set_color -o; echo -n "Son pod: "; set_color normal; echo $fzfke_last_pod
        end
        return 0
    end

    # '--' sonrası komut olarak çalışır; öncesi eski pozisyonel sıra: [ns] [container] [query]
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

    # -l / --logs: komut yerine logs modu. Kalan '--' argümanları --since'a gider.
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
        echo "fzfke: namespace seçilmedi" >&2
        return 1
    end

    # Son pod'u hatırla: aynı pod'a arka arkaya komut göndermek en sık durum.
    # '-' verilirse fzf atlanır, doğrudan o pod kullanılır.
    set -l pod
    if test $reuse -eq 1
        set pod $fzfke_last_pod
        test -z "$pod"; and begin
            echo "fzfke: hatırlanan pod yok" >&2
            return 1
        end
        # Pod hâlâ ayakta mı? Yeniden başladıysa hash değişir.
        if not kubectl get pod $pod -n $ns >/dev/null 2>&1
            echo "fzfke: $pod artık yok, seçim listesine düşülüyor" >&2
            set pod ""
        end
    end

    if test -z "$pod"
        set -l fzf_args --height 40% --reverse --header="Select Pod ($ns):"
        test -n "$query"; and set -a fzf_args --query $query
        set pod (kubectl get pods -n "$ns" --no-headers | fzf $fzf_args | awk '{print $1}')
    end

    if test -z "$pod"
        echo "fzfke: pod seçilmedi" >&2
        return 1
    end
    set -g fzfke_last_pod $pod

    set -l target -n $ns
    test -n "$container"; and set -a target -c $container

    if test $logs -eq 1
        # Süre: '--' sonrası ilk argüman, yoksa 30m
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
