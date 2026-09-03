function nvi --wraps neovide --description 'Neovide: file picker in a directory, open a file directly'
    set -l target $argv[1]
    test -n "$target"; or set target .

    # cwd is not inherited (a tty-less launch falls back to $HOME), so cd is passed to nvim explicitly.
    # Files must stay positional: neovide appends '-p' afterwards, so a file after '--' never lands in a tab.
    if test -d "$target"
        set -l dir (path resolve -- $target)
        neovide +GoToFile -- --cmd "cd "(string replace -a ' ' '\ ' -- $dir) &
    else
        neovide (path resolve -- $argv) -- --cmd "cd "(string replace -a ' ' '\ ' -- $PWD) &
    end
    disown
end
