# Aset Araştırması — card-art: kart görselleri, çerçeveler, ikonlar (TR)

Kategori: kart çerçevesi/şablonu, kart arkası, suit ikonları (Kılıç, Kupa, Tılsım, Göz), mühür işaretleri, istatistik pip'leri, nadirlik uygulamaları — artı kart illüstrasyonu için üretim hattı. Kullanıcı kısıtı: kartlar canlı dokulu gerçek 3D mesh'ler (viewport art), düz sprite değil; her şey animasyonlu.

## Gereksinimler
| Öğe | Spec | Kaynak planı |
|---|---|---|
| Kart çerçevesi | yıpranmış parşömen/deri, 4 suit renk versiyonu, foil uyumlu | quad mesh üstü özel doku; yerleşim için Kenney referans |
| Kart arkası | tek okült tasarım | özel (illüstrasyon hattına bak) |
| Suit ikonları | 4 farklı işaret, 16px'te okunur | game-icons.net CC-BY veya özel vektör |
| Mühür işaretleri | ~20 rune benzeri marka | game-icons.net rune'ları veya özel |
| İstatistik pip/ikonları | saldırı/can/bedel şekilleri | Kenney boardgame-pack PNG + özel |
| Nadirlik uygulamaları | tint/foil varyantları | shader temelli (anim-vfx raporu) |
| İllüstrasyon | ~150+ kart görseli, tutarlı karanlık stil | AI-taban + insan rötuşu, veya sipariş — karar gerekli |

## Karşılaştırılan kaynaklar
| Kaynak | Lisans | Karar |
|---|---|---|
| **Kenney boardgame-pack** | CC0 | ✅ indi — pip, çip, zar, kart arkası prototipleme için |
| **game-icons.net** | CC-BY 3.0 | ✅ en iyi ikon sözlüğü (silahlar, kupalar, gözler, rune'lar); ATTRIBUTION.md gerekir |
| OpenGameArt | GPL/CC-SA riski | ❌ |
| itch.io kart şablonları | karışık/ücretli | ⚠ ürün başına kontrol; zaten çoğu fazla jenerik |
| DeviantArt/ArtStation kazıma | lisanssız | ❌ asla — lisans bilinmiyor |

## İndirilenler
`assets_external/card-art/kenney/boardgame-pack/` — 534 PNG, 25 vektör, spritesheet'ler (`license.txt` CC0). Kart öğelerini prototiplemek ve yerleşim referansı için; final görseller özel olacak.

## İllüstrasyon hattı (karar noktası)
Kart yüzleri ~150+ tutarlı karanlık-okült illüstrasyon istiyor. Seçenekler:
1. **AI destekli**: SDXL/Flux taban üretim → tutarlılık için insan rötuşu (hızlı; stil LoRA + seçki emeği ister).
2. **Sipariş**: ~10-15 ana görsel sipariş, gerisi türetilmiş/şablonlu (yavaş, en yüksek kalite).
3. **Hibrit (önerilen)**: AI taban (doku/kompozisyon) → yoğun rötuş + ortak palet/grading turu → tek tip çerçeve kalan tutarsızlığı örter.
Lisans notu: AI görselleri çoğu ülkede telif taşımaz — süreci yine de belgele; sanatçı-adı prompt'larından kaçın (stil/IP riski).

## Entegrasyon planı (Godot 4.x)
1. Kart = MeshInstance3D (bevel'lı quad) + ön/arka malzeme; görsel, CardViewport sahnesini render eden ViewportTexture ile (çerçeve PNG + görsel + yerelleşmiş metin) — tasarım gereği animasyonlu/foil görsel sağlar.
2. Katmanlar: `arka | çerçeve | illüstrasyon | suit+mühür decal | metin (ui-fonts seti) | foil shader`.
3. i18n: metin katmanları `tr()` anahtarlarıyla — görseli yeniden dışa aktarmadan TR/EN değişimi.
4. Suit ikonları SVG→PNG 4 boyutta; mühürler ayrı decal malzeme — parlayıp nabız atabilsin diye.
5. Performans: viewport bütçesi — sadece görünen kartlar canlı render (≤12), diğerleri baked snapshot.
6. Test: kol mesafesi kamerasında okunabilirlik (isim+istatistik), TR metin sığması (uzun kelimeler), farklı ışık açılarında foil.

## Riskler
- Viewport dokulu kartlar kare bütçesinin en ağır kalemi — canlı viewport'u sınırla, gerisini bake et.
- 4 suit + mühürler arası ikon tutarlılığı — tek kaynak (game-icons veya tek sanatçı) önerilir.
- Görsel hattı kararsız → kart-art üretimini bloke eder; kullanıcı kararına işaretlendi.
