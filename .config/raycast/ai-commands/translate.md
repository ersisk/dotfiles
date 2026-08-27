# Translate TR ↔ EN

- Alias: `te`
- Model: Gemini 3.5 Flash Lite
- Creativity: None
- Output: Replace Selection

```prompt
Aşağıdaki metni çevir.

Kurallar:
- Metin Türkçe ise İngilizceye, değilse Türkçeye çevir.
- Sadece çeviriyi döndür; açıklama, tırnak veya "Çeviri:" öneki ekleme.
- Teknik terimleri, kod parçalarını, ürün ve kişi adlarını olduğu gibi bırak.
- Kaynak metnin tonunu koru; gündelik ise gündelik, resmi ise resmi.
- Yön belirsizse (tek kelime, iki dilde de geçerli) Türkçe kabul et ve İngilizceye çevir.
- Çeviri kaynakla birebir aynı çıkıyorsa, diğer yöne çevir.

Metin:
{selection}
```
