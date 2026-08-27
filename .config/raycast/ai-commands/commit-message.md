# Commit Message

Girdi clipboard'dan gelir: `git diff --staged | pbcopy`

- Alias: `cm`
- Model: Gemini 3.5 Flash Lite
- Creativity: None
- Output: Copy to Clipboard

```prompt
Aşağıdaki git diff için tek bir Conventional Commits mesajı üret.

Kurallar:
- Sadece commit mesajını döndür; açıklama, tırnak veya kod bloğu ekleme.
- Format: <type>(<scope>): <subject>
- type: feat|fix|refactor|perf|test|docs|chore|build|ci
- subject İngilizce, küçük harfle başlar, emir kipi, nokta yok, 72 karakteri geçmez.
- scope'u ancak diff tek bir modüle dokunuyorsa ekle.
- Diff birden fazla ilgisiz değişiklik içeriyorsa en baskın olanı seç.
- Gövde ekleme.

Diff:
{clipboard}
```
