# Raycast AI Commands

Raycast AI Command'leri `raycast-enc.sqlite` içinde şifreli tutuyor; dışa aktarma
yok. Bu dizin o yüzden **kaynak metin arşivi**: buradaki prompt'lar elle
Raycast'e yapıştırılır, tersi otomatik değildir. Prompt'u Raycast tarafında
değiştirdiysen buradaki dosyayı da güncelle, yoksa arşiv yalan söyler.

Kurulum: Raycast → `Create AI Command` → başlığı dosya adından, prompt'u
```prompt``` bloğundan al, Model/Creativity/Output alanlarını dosyadaki gibi ayarla.

| Komut | Alias | Girdi | Prompt burada mı? |
| --- | --- | --- | --- |
| Explain Error | `ee` | `{selection}` | ✔ |
| Commit Message | `cm` | `{clipboard}` (`git diff --staged \| pbcopy`) | ✔ — ama `aimsg` daha iyisini yapıyor |
| Translate TR ↔ EN | `te` | `{selection}` | ✔ |

`jira-to-branch` eskiden buradan iki AI komutu (`parse-jira-title`,
`generate-branch`) ve `screenocr` extension'ını deeplink ile zincirliyordu.
Artık etmiyor: OCR'ı macOS Vision, çeviriyi `claude -p` yapıyor ve hiçbir şey
clipboard'dan geçmiyor. O üç Raycast komutunu silebilirsin, başka kullananı yok.

## Model seçimi

Katalog `defaults read com.raycast.macos raycastAI_modelInfo` içinde duruyor;
her modelin `intelligence` ve `speed` skoru ve `requires_better_ai` bayrağı var.
Seçimler oradan yapıldı, isme bakarak değil — "Pro" etiketi taşıyan bir model
Flash'tan daha akıllı olmak zorunda değil.

**Gemini 3.7 Flash** eklenti gerektirmeyen modeller arasında tek Pareto galibi:
intelligence 4, speed 5, vision + web search + reasoning effort. Raycast'in kendi
varsayılanı (GPT-5.6 Luna, intelligence 3 / speed 4) her iki eksende de altında.
`Gemini 3 Flash` ismine aldanma, o intelligence 2.

Mekanik işler (çeviri, commit mesajı, jira parse) **Gemini 3.5 Flash Lite**'a
gidiyor: intelligence 3, speed 5. Bu işlerde model zekası değil gecikme belirleyici,
özellikle `jira-to-branch` gibi clipboard polling'e bağlı zincirlerde.

`requires_better_ai` işaretli modeller (Claude Opus 5, GPT-5.6 Sol, Gemini 3.1 Pro)
Advanced AI eklentisi ister. Almaya değmez: Raycast burada kısa ve hızlı yüzey,
ağır düşünme zaten terminalde Claude Code'da yapılıyor.
