function nvi --wraps neovide --description 'Neovide: dizinde dosya seçici, dosyayı doğrudan aç'
    set -l target $argv[1]
    test -n "$target"; or set target .

    # cwd devralınmıyor (tty'siz başlatmada $HOME'a düşüyor), o yüzden nvim'e cd açıkça geçiliyor.
    # Dosyalar positional kalmalı: neovide '-p'yi sonradan eklediği için '--' sonrasındaki dosya tab'a atanmıyor.
    if test -d "$target"
        set -l dir (path resolve -- $target)
        neovide +GoToFile -- --cmd "cd "(string replace -a ' ' '\ ' -- $dir) &
    else
        neovide (path resolve -- $argv) -- --cmd "cd "(string replace -a ' ' '\ ' -- $PWD) &
    end
    disown
end
