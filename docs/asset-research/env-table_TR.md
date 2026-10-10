# Aset Araştırması — env-table: 3D masa sahnesi & ortam (TR)

Kategori: **Gambling with the Devil** için 3D savaş masası ve ortamı — ağır oymalı masa, mumlar, okült objeler, in/salon odası. Görsel hedef: mum ışıklı Inscryption tarzı sahnenin özgün yorumu; gerçek 3D mesh'ler, animasyonlu, ticari-indie kalitesi. Hedef motor: Godot 4.x (GLB/glTF tercihli).

## Gereksinim analizi
| İhtiyaç | Spec | Format | Bütçe |
|---|---|---|---|
| Ana masa | ağır ahşap, tek mesh, ~1–2m | GLB/glTF + PBR | <20k üçgen |
| Mum/ışıklar | birkaç varyant, alev shader animasyonu için ayrı | glTF | düşük |
| Objeler | kitap, sandık, testi, kase, ayna, hançer, saat, kasa, fıçı | glTF | <5k üçgen/adet |
| Oda kabuğu | duvar/zemin/kapı/fon | kitbash parçaları veya özel geo | — |
| Dokular | ahşap/çuha/metal/mum PBR | 1–2k jpg/ktx2 | tileable |
| HDRI | karanlık iç mekân ortam | .hdr 1–2k | sadece aydınlatma |

## Karşılaştırılan kaynaklar
| Kaynak | Lisans | Format | Karar |
|---|---|---|---|
| **Poly Haven** | CC0 | glTF/FBX/blend + PBR | ✅ birincil — doğrulanmış CC0, açık API, yüksek kalite |
| **Quaternius Fantasy Props MegaKit** | CC0 (%60–70 ücretsiz) | glTF/FBX/OBJ; Godot-hazır sürüm | ✅ ortaçağ objeleri için güçlü (kafatasları, iksirler, kitaplar, sandıklar, mumlar) — ücretsiz katman yeterli |
| **ambientCG** | CC0 | PBR doku setleri | ✅ ahşap/çuha/deri/mum kaplamalar |
| **KayKit** | CC0 | GLB | ✅ zar/çip objeleri |
| Sketchfab (CC0/CC-BY) | karışık | değişken | ⚠ ürün başına lisans kontrolü şart — sadece başka yerde bulunmayan ana parçalar için (oymalı masa, terazi, kum saati) |
| OpenGameArt | karışık (GPL riski) | değişken | ❌ lisans mayın tarlası — prodüksiyonda kaçın |
| Unreal/Unity market | paket bazlı | motor kilitli | ⚠ paket başına "başka motorlarda kullanım" maddesi kontrol et |

## İndirilen seçkiler (`assets_external/env-table/polyhaven/`, 20 model, ~55MB, hepsi CC0)
Mum & ışık: `brass_candleholders`, `wooden_candlestick`, `wooden_lantern_01`, `lantern_chandelier_01`.
Mobilya: `WoodenTable_02` (ana masa), `ArmChair_01`, `WoodenChair_01`, `wooden_bookshelf_worn`, `GothicCabinet_01`.
Obje: `book_encyclopedia_set_01`, `treasure_chest`, `ornate_mirror_01`, `gothic_statue`, `jug_01`, `wooden_bowl_01`, `wine_bottles_01`, `Barrel_01`, `wooden_crate_01`, `vintage_grandfather_clock_01`, `ornate_medieval_dagger`.
Ürün başına lisans kaydı: `assets_external/env-table/LICENSES.md`.

## Hâlâ gerekenler (sonraki taramalar / özel iş için boşluklar)
- **Terazi** (imza obje — muhtemelen özel ya da Sketchfab CC parçası; ürün başına lisans kontrolü)
- **Kafatası/kemik yığınları** — Quaternius Fantasy Props MegaKit / Sketchfab CC0
- **Kum saati, tüy kalem+mürekkep hokkası, çip desteleri, zarlar** — KayKit zar (CC0); çipler = basit özel silindirler
- **Oda kabuğu** — `large_castle_door` (PH) mevcut; duvar/zemin en iyisi tileable ambientCG dokuları + modüler geo ile
- **Çuha masa yüzeyi** — ambientCG kumaş dokusuyla masa üstü kaplama
- **HDRI** — Poly Haven HDRI'larından karanlık iç mekân seçilecek (henüz indirilmedi; polyhaven.com/hdris'te "dark"/"candle" ara)

## Entegrasyon planı (Godot 4.x)
1. `.gltf` dosyasını (`.bin` + `textures/` kardeşleriyle) `res://models/env/` içine sürükle — Godot glTF'yi yerel içe aktarır; 1k dokuları koru, sadece ana masada 2k'ya çık.
2. Ortak `wood_pbr`/`metal_pbr` malzeme değişim turu planla — draw-call gruplaması için her modelin kendi malzemesi yerine paylaşımlı malzemeler.
3. Mumlar: hazır alev sprite'ını gizle; `flame` malzemesini özel titreme shader'ı (vertex salınımı + emissive nabız) + grup başına PointLight3D (max ~4 aktif gölge) ile sür.
4. Masa çuhası: kumaş dokulu (ambientCG `fabric`/`felt`) overlay quad, hafif yeşil-siyah ton.
5. Performans: statik objeler → sadece etkileşimli olanlarda `StaticBody3D`+trimesh/convex; occlusion culling açık; hedef <1M üçgen, gruplama sonrası <150 draw call.
6. Test: test sahnesinde yükle, kamera gezdir, tek sıcak PointLight + düşük ambient altında (WorldEnvironment ambient_light_energy ~0.05) malzeme doğruluğunu kontrol et, hedef çözünürlükte 60fps doğrula.

## Riskler
- PH modelleri archviz kalitesi (1k–20k üçgen) — toplam sahne bütçesine dikkat; gerekirse sadece ana parçaları decimate et.
- `.gltf` + harici dokular: içe aktarımda klasör yapısını bozma.
- Sketchfab boşluk doldurmaları: CC0 tercih; CC-BY kullanılırsa → atıf dosyası zorunlu.

## Sonraki adım
`pawn-models`, `card-art`, `anim-vfx`, `audio`, `ui-fonts` kategorileri SWE-2 kapasitesi açıldığında işçi oturumlarına sıraya alındı.
