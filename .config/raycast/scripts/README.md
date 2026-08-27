# Raycast Script Commands

Raycast Settings → Extensions → Script Commands → **Add Directory** →
`~/.config/raycast/scripts`. Stow bu dizini kurar, Raycast dosyaları yerinde
okur; AI Command'lerin aksine bunlar gerçekten versiyonlanıyor.

| Komut | Hotkey | Ne yapar |
| --- | --- | --- |
| Jump to Claude | `⌃⌥J` | Dikkat bekleyen Claude oturumuna kitty'yi kaldırıp atlar |
| Claude Sessions | `⌃⌥K` | Çalışan tüm oturumları, en acili başta listeler |
| Screen OCR | `⌃⌥O` | Ekran bölgesi seç, metni panoya kopyala (macOS Vision) |
| Sesh Session | `⌃⌥S` | kitty'yi kaldır ve eşleşen sesh oturumuna geç |

`⌃⌥` bloğu bilerek seçildi: aerospace `⌥`'ü, kitty `⌘`'i doldurmuş durumda,
`⌃⌥` ise tamamen boş — Raycast script'leri için çakışmasız bir isim alanı.

## Bu dizinde script yazarken

- **`#!/bin/bash`**, `#!/usr/bin/env bash` değil. Raycast script'leri kısıtlı bir
  PATH ile başlatıyor, `env` oradan brew'un bash 5'ini bulamaz ve macOS'un
  3.2'sine düşersin. 3.2'yi hedefle: `mapfile` ve associative array yok.
- **PATH'i elle kur.** Aynı sebeple `tmux`, `git`, `jq` görünmez; her script
  başında `PATH="/opt/homebrew/bin:/usr/bin:/bin:..."` var.
- **Paylaşılan okuyucu burada değil.** Claude oturum durumunu ayrıştıran kod
  `~/.local/share/claude-menubar/claude-state.sh`'te — sözleşmeyi tanımlayan
  uygulamanın yanında, `claude-next.sh` de aynı dosyayı source ediyor.

## Claude oturum durumu

Commit mesajı buradan kaldırıldı: `aimsg` (`⌘+b`) aynı işi Raycast'e hiç
uğramadan yapıyor — üç aday, fzf seçimi, `ctrl-r` ile claude, scope branch
adındaki Jira key'inden. Bu dizindeki hiçbir komut artık Raycast AI'ya bağlı değil.

`screen-ocr.sh`, `jira-to-branch`'in kullandığı Vision sarmalayıcısını çağırır;
`huzef44/screenocr` extension'ına artık gerek yok. `sesh.sh` de atlamayı
`claude-jump`'a devrediyor — aerospace yarışı orada çözülü, ikinci kez çözülmesin.

`claude-jump.sh` ve `claude-sessions.sh`, `~/.local/state/claude-menubar/sessions`
altındaki tek satırlık JSON'ları okur — kontratı ana README'de yazılı. Atlama işini
kendileri yapmaz, `~/.local/bin/claude-jump`'a devrederler: tmux dışından
`switch-client` açık bir client ister, o script zaten bunun için var.

Okuyucu tek: `~/.local/share/claude-menubar/claude-state.sh`. Eskiden tmux
tarafı kendi kopyasını taşıyordu, "tuş basımında dosya source etme" gerekçesiyle;
ölçüldü, fark yok (boş bash 2.2 ms, source'lu 2.0 ms) ve kopya kaldırıldı.

`claude-jump.sh` de prefix + j gibi sadece `waiting`, `done-bg`, `done`
oturumlarına gider ve aynı sırayla döner: art arda basınca ilerler, aynı pane'e
kilitlenmez. `working` oturumlarına gitmez — cevaplanacak bir şey yok.
