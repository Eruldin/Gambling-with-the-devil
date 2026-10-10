# Aset Araştırması — ui-fonts: arayüz ve kart tipografisi (TR)

Kategori: arayüz, kart isimleri/kural metinleri, sayılar ve çift dilli (TR+EN) metin render'ı için fontlar. Karanlık okült estetik; Türkçe glif desteği (ğşıİçöü) zorunlu; kart üzerinde küçük puntoda okunabilir olmalı.

## Gereksinimler
| Rol | Stil | Kalınlık | Not |
|---|---|---|---|
| Kart adı / başlıklar | gravür serif, okült | 600–800 | sadece display |
| Kural / gövde metni | okunaklı serif | 400–600 | kartta 12–18px |
| UI iskeleti / menüler | zarif serif veya küçük büyük harf | 400–700 | butonlar, HUD |
| Sayılar (çip, HP, bedel) | tabular/mono | 400–800 | istatistik kaymamalı |
| Elyazması/olay metni | antik el baskısı | 400 + italik | hikâye panelleri |

## Karşılaştırılan kaynaklar
| Kaynak | Lisans | Karar |
|---|---|---|
| **Google Fonts** | OFL-1.1 (tüm fontlar) | ✅ birincil — ticari kullanım serbest, TTF, garantili Türkçe alt küme |
| Font Squirrel | font başına değişken | ⚠ kullanılabilir ama gereksiz — GF kataloğu seçkileri kapsıyor |
| itch.io font paketleri | karışık | ⚠ ürün başına kontrol; piksel font bu projeye zaten gerekmez |
| DaFont / 1001fonts | çoğu "kişisel kullanım" | ❌ lisans tuzağı — çoğu ticari kullanımı yasaklar |
| Adobe Fonts | aboneliğe bağlı | ❌ yeniden dağıtım yasak |

## İndirilen seçkiler (`assets_external/ui-fonts/`, 5 aile, OFL-1.1)
| Font | Rol | Neden |
|---|---|---|
| **Cinzel** | kart adları, başlıklar, boss unvanları | gravür Roma büyük harfleri — okült/ağırbaşlı, display |
| **Cormorant Garamond** | UI iskeleti, menü başlıkları | zarif yüksek kontrastlı serif, Cinzel ile uyumlu |
| **IM Fell English** | olay/elyazması metinleri, özel kart metni | gerçek 17. yy Fell tipi canlandırması — "eski kitap" sesi |
| **Alegreya** | kart gövde/kural metni | küçük puntoda uzun okuma için tasarlanmış; güçlü Türkçe glif |
| **JetBrains Mono** | çip sayıları, hasar rakamları, debug | tabular rakamlar — sabit istatistik okuması |

Eşleşme: Cinzel (başlık) + Alegreya (gövde) + JetBrains Mono (sayı) ana çalışma seti; Cormorant ve IM Fell vurgu/bağlam fontları.

## Boşluklar / notlar
- İleride imza için el yazısı "deal" fontu istenirse GF "Caveat"/"Kalam" (OFL) eklenebilir — indirilmedi (Türkçe okunabilirlik riski).
- İkon fontu ihtiyacı belli değil — muhtemelen özel SVG ikonlar (card-art taramasındaki ui başlığına bak).
- TR+EN doğrulandı: beş font da latin-ext alt kümesi içeriyor (GF örneğinde Türkçe glifler onaylı).

## Entegrasyon planı (Godot 4.x)
1. .ttf dosyalarını `res://fonts/` altına koy; `FontFile` kaynakları oluştur; Cinzel/Cormorant için **MSDF** içe aktarımını aç — her kart zoom'unda keskin.
2. Tema varsayılanları: gövde=Alegreya 16px, başlık=Cinzel, sayı=JetBrains Mono; etiket başına değil Control başına override.
3. i18n: tek font yığını TR+EN'i kapsıyor — dile özel font değişimi gerekmez; `tr()` anahtarları tasarıma uygun kalır.
4. Performans: fallback zinciri `Cinzel→Cormorant→sistem serif`; MSDF atlası aile başına ~4MB — kabul edilebilir.
5. Test: kartı 0.5×–2× zoom'da render et, Türkçe glifleri (Ğüşİıçö) kontrol et, koyu çuha zeminde kontrast (min 4.5:1), çip sayısı tween'lenirken rakam kararlılığı.

## Riskler
- IM Fell'in yıpranmış glifleri <14px'te kötü görünür — sadece büyük panellerde kullan.
- MSDF atlasları bellek ekler; MSDF'i 3 çalışma fontuyla sınırla.
