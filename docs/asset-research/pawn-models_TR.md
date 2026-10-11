# Aset Araştırması — pawn-models: masa taşları & işaretler (TR)

Kategori: çuha üzerinde kartları temsil eden fiziksel 3D parçalar — piyonlar (Piyon), putlar (Put), mühürler (Mühür jetonları), yaratık işaretleri ve süs objeleri. Şart: küçük okunaklı siluetler, okült görünüm, animasyonlu (nefes salınımı, belirme/yok olma, saldırı hamlesi), Godot 4.x.

## Gereksinimler
| Parça sınıfı | Adet | Spec | Kaynak planı |
|---|---|---|---|
| Temel piyonlar (kart gövdeleri) | ~6 arketip siluet | 5–15cm duran, belirgin hatlar | chess_set parçaları (şah/vezir/fil/at/kale/piyon → kart arketipleri) |
| Put/boss parçaları | 3–5 | daha büyük, heybetli | marble_bust, gothic_statue, horse_statue |
| Yaratık piyonları | haşere/yoldaş tipleri | küçük | street_rat, concrete_cat_statue |
| Mühür/çip jetonları | istiflenebilir işaretler | yassı silindir/para | özel basit mesh'ler (trivial) |
| Süs objeleri | maske vb. | masa dekorasyonu | old_gas_mask vb. |

## Karşılaştırılan kaynaklar
| Kaynak | Lisans | Format | Karar |
|---|---|---|---|
| **Poly Haven** | CC0 | glTF + PBR | ✅ 6 ürün indi — chess_set neredeyse hazır piyon ailesi (6 siluet) |
| **Quaternius MegaKits** | CC0 (%60–70 ücretsiz) | glTF/FBX, Godot-hazır | ✅ en iyi ikinci tur — stilize yaratıklar, iskeletler, canavarlar (henüz indirilmedi: paket büyük, ihtiyaca göre seç) |
| **KayKit** (Skeletons/Adventurers) | CC0 | GLB | ✅ çizgi oranlı figürinler, animasyonlu rig'ler — yaratık piyon adayı |
| Sketchfab CC | CC0/CC-BY | değişken | ⚠ okült figürinler var ama ürün başına lisans kontrolü şart |
| OpenGameArt | GPL/CC-SA riski | değişken | ❌ |

## İndirilenler (`assets_external/pawn-models/polyhaven/`, 6 ürün, ~18MB, hepsi CC0)
- `chess_set` — 32 parça + tahta: altı arketip silueti hazır (piyon→Söz/köylü kartları, kale→Çuha savunucuları, at→saldırganlar, fil→mühür kullanıcıları, vezir→elit, şah→boss vekili). Gerçekçi mermer görünüm mum ışıklı masaya uyuyor.
- `marble_bust_01`, `horse_statue_01`, `concrete_cat_statue`, `old_gas_mask`, `street_rat` — putlar, yoldaşlar, okült süsler.
- Çapraz ref: env-table paketindeki `gothic_statue` büyük put olarak da çalışır.

## Boşluklar
- **Kafatası/kemik piyonlar** — Poly Haven'da yok; çözüm Quaternius Fantasy/Skeleton paketleri (CC0).
- **Kuzgun/keçi parçaları** — Sketchfab CC veya Quaternius; sonraki tura işaretli.
- **Mühür jetonları** — işaret decal'lı (card-art ikonları) özel yassı silindirler — basit özel mesh, indirme gerekmez.

## Entegrasyon planı (Godot 4.x)
1. glTF'yi `res://models/pawns/` içine aktar; satranç parçalarını tek tek sahnelere ayır (piyon/kale/at/fil/vezir/şah) — her biri tek mesh, paylaşımlı mermer malzeme.
2. ~8–14cm dünya yüksekliğine ölçekle; tabanı çuha düzlemine oturt (Y=0).
3. Animasyonlar kod temelli — nefes ölçeği (1±0.02), belirme = çuhadan yükselme + toz patlaması (Kenney partikül), saldırı = şerit hedefine hamle tween'i, ölüm = devrilme + dissolve shader (anim-vfx raporu).
4. Seçim/hover: emissive rim shader + hafif kaldırma.
5. Performans: masada ≤10 parça, her biri <3k üçgen — bütçe kolay; sadece 2–3 ana ışıkta gölge aç.
6. Test: savaş kamerası mesafesinde siluet okunabilirliği (UI'sız parça tanıma), belirme/ölüm hissi 300–500ms spec'e karşı, çuhada z-fighting yok.

## Riskler
- Gerçekçi mermer satranç seti vs stilize okült tema — tint/kan/mum shader turlarıyla birleştirilecek.
- chess_set tahta mesh'i dahil — kullanılmayacak; sadece parçalar.
- Yaratık piyon çeşitliliği hâlâ zayıf — içerik kilidinden önce Quaternius/KayKit turu önerilir.
