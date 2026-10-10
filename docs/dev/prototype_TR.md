# Prototip — mum ışıklı 3D masa sahnesi (TR)

İlk oynanabilir görsel aşama: Inscryption tarzı mum ışıklı kart masası — tamamen önceki taramalarda bulunan lisanslı aset paketleriyle (Poly Haven CC0 + Kenney CC0) kuruldu. Godot 4.7.2, `gl_compatibility` render (bu VM'de güvenli; gerçek GPU'larda SSR/parlama için `forward_plus`'a geçilir).

## Çalıştırma
```
Godot_v4.7.2-stable_win64.exe --path .
# veya project.godot'u editörde açıp F5
```
Ekran görüntüsü probu: `GWD_SHOT=1 godot --path .` → `C:/Users/Administrator/gwd_shot.png` kaydedip çıkar.

## Sahnede neler var
- Ahşap masa + iki sıra beş şeritli koyu çuha tahtası (Çuha)
- Flipbook alevli 4 şamdan, titreyen omni ışıklar, yükselen duman + gölgeli ana ışık
- Sallanan avize feneri
- Koltuklar, kitaplık, gotik dolap, heykel, sarkaçlı saat, sandık, kasa, fener, masa objeleri (kitaplar, testi, kase, şişeler, hançer)
- Şeritlere yerleştirilmiş satranç piyonları (siyah şah/at/piyon vs beyaz piyon/fil)
- Kameraya dönük yelpaze 5 kartlık el (Kenney yüzleri) + 2 kapalı rakip kartı; dağıtma tween animasyonu
- Hover inceleme: kart kalkar, büyür ve izleyiciye eğilir (mouse raycast)
- Ruh çipi desteleri (silindir jetonlar)
- Çift dilli HUD altyapısı: `i18n/gwd.en.po` + `gwd.tr.po`, `tr()` ile (ui-fonts paketinden Cinzel)

## Animasyon kapsamı ("animasyonsuz iş yok" çıtası)
Kamera salınımı, alev flipbook + ışık titremesi, duman yükseliş/sönüm döngüsü, avize sallantısı, kart idle salınım + dağıtma + hover kaldırma/eğme. Piyon idle animleri savaş prototipiyle gelecek.

## Yapı
```
project.godot         — GL-compat render, ana sahne, i18n kayıtları
scenes/main.tscn      — kök Node3D
scripts/main.gd       — sahne kurulumu + kamera/HUD/hover/prob
scripts/game_card.gd  — kart mesh + dağıtma + hover anim
scripts/candle_flame.gd — alev flipbook + titreme + duman
scripts/sway.gd       — genel sallantı
i18n/gwd.{en,tr}.po   — çeviri anahtarları
```
Asetler `assets_external/` içinden doğrudan referanslanıyor (glTF yerel yüklenir; `--import` ile içe aktarıldı).

## Sonraki adımlar
- Savaş döngüsü: şeritler tasarım kurallarına bağlanacak (gizli yerleştirme, Perdeler, Blöf Çağırma)
- Kart yüzleri → ViewportTexture hattı (yerelleşmiş metin + foil shader)
- Piyon arketip seti → okült siluetler; kurban-dissolve shader
- Render: hedef donanımda bloom/SSAO için `forward_plus`'a geçiş

## Savaş dilimi (proto/battle-loop)
Tasarım döngüsü: iki taraf da Perde öder (1/2/3/5/8/13 çip), kartları **gizli** (kapalı) şeritlerine koyar; SPACE / AÇ hepsini çevirir, kartlar birim gibi dikilir ve her şerit karşısındakine vurur — önce birime, boş şeritte çipe hasar. Kan (tur başı 2) yerleştirme bedelidir; sağ tık kartı `kurban değeri` kadar kan için feda eder. Dosyalar: `battle.gd` (durum makinesi, düşman AI, HUD), `card_def.gd` (kart anatomisi + 10 kartlık başlangıç destesi), `game_card.gd` (seçim/parlama, yerleştirme/açma/hamle/flaş/ölüm/yanma). `GWD_AUTO=1` headless doğrulama için bir tur oynatır.
