# Aset Araştırması — anim-vfx: animasyon & görsel efektler (TR)

Kategori: hareket eden ya da parlayan her şey — kart hareketi (çekme/oynama/hover/saldırı/yok olma), masa efektleri (kurban, mühür tetikleri, çip transferleri, pot büyümesi), ortam efektleri (mum alevleri, duman, kor, toz, vinyet), geri bildirim (blöf çağrısı parlamaları, kazanma/kaybetme sekansları). Kullanıcı şartı: hiçbir şey statik olmayacak — "animasyonsuz iş yapmayacaksın". Hedef: Godot 4.x, 3D sahne + Control katmanları.

## Gereksinimler
| Efekt sınıfı | Teknik | Gereken aset |
|---|---|---|
| Kart oynama/çağırma | Tween + GPU partikül | flipbook sprite, parıltı/sihir çemberi decal |
| Kurban | partikül patlaması + dissolve shader | duman/kor sprite'ları, dissolve noise dokusu |
| Çip/pot hareketi | Tween zincirleri | yok (mesh animasyonu) |
| Mum alevi & duman | shader + flipbook sprite | alev/duman partikül sprite'ları |
| Ortam | GPUParticles3D | toz/kor sprite'ları, sis |
| Saldırı/hasar geri bildirimi | Tween + flaş shader | vuruş kıvılcımları, ekran sarsıntısı (kod) |
| Blöf/Çağrı/Telafuz açılımları | UI anim + ışık nabzı | sihir-çemberi rune sprite'ları |
| Kazanma/kaybetme, geçişler | sahne anim + partikül | konfeti-vs-kül sprite'ları |

## Karşılaştırılan kaynaklar
| Kaynak | Lisans | Format | Karar |
|---|---|---|---|
| **Kenney Particle Pack** | CC0 | 98 şeffaf PNG | ✅ indi — alev, duman, kıvılcım, sihir çemberleri, semboller |
| **Effekseer** | MIT | runtime + .efk efektleri | ✅ Godot eklentili parçacık aracı adayı — native GPUParticles3D ile karşılaştırılacak |
| **Godot VFX demo/kütüphaneleri** | çoğu MIT | shader kodu | ✅ dissolve/foil/holo kart shader'ları için referans — uyarlanır, toptan kopyalanmaz |
| itch.io VFX paketleri | karışık | sprite/flipbook | ⚠ ürün başına lisans kontrolü; ileride alev/kan flipbook için iyi |
| OpenGameArt | GPL/CC-SA riski | karışık | ❌ prodüksiyonda kaçın |
| Unity/Unreal VFX | mağaza lisansı | motor kilitli | ❌ |

## İndirilenler
`assets_external/anim-vfx/kenney/particle-pack/` — 98 şeffaf PNG sprite + siyah zeminli varyantlar + License.txt (CC0). Alev, duman, kıvılcım, yıldız, çember, sihir rune'u, iz, girdap ailelerini kapsıyor — GPUParticles3D sprite dokusu ve kart-efekti decal olarak kullanılabilir.

## Özel iş gerekenler (paketle çözülemez)
- **Kart malzeme shader'ları**: foil/holo, kurban-dissolve, mühür emissive parıltısı — özel canvas_item/spatial shader yazılacak (referans: godot-shaders.com, MIT parçacıklar).
- **Mum alevi**: prosedürel shader (vertex salınımı + emissive degrade); yedek olarak Kenney alev sprite'ı.
- **Fiziksel çip/kart hareketi**: Tween + AnimationPlayer — saf kod.
- **Ekran sarsıntısı/hitstop**: Camera3D kodu.
- **"Dağıtma" sekansı**: çok aşamalı animasyon (deste kayma → yerleştirme → çevirme) — kod temelli.

## Entegrasyon planı (Godot 4.x)
1. GPUParticles3D emitörleri kart/piyon sahne köklerine çocuk olarak; sprite dokuları particle-pack'ten (şeffaf set; siyah-zemin seti sadece `blend_add` malzemelerde).
2. Tek `VFXManager` autoload: spawn(isim, konum, parametre) → havuzlanmış emitörler; asla anlık partikül instance yok.
3. Shader kütüphanesi: `res://shaders/` — dissolve (noise + kenar emissive), foil (bakışa bağlı gökkuşağı), alev titremesi (vertex salınımı + scroll), kart-hover vurgusu.
4. Animasyon temposu: oyun-okunaklı vuruşlar (çekme 300ms, oynama 400ms, saldırı 250ms, yok olma 500ms) — ortam döngüleri paralel, girdiyi asla bloklamaz.
5. Performans: partikül bütçesi (max ~6 eşzamanlı emitör, ≤200 partikül), parıltılarda additive blend, ekran dışı emitörleri visibility_notifier ile kapat.
6. Test: kurban + saldırı sekanslarını kare kare 60fps hedefiyle incele; 50 efekt sonrası partikül sızıntısı olmadığını doğrula.

## Riskler
- Kenney sprite'ları jenerik — okült palete uydurmak için tint/shader turu gerekir (planda).
- Effekseer eklenti bağımlılığı ekler — GPUParticles3D prototipi sonrası karar.
- Aşırı animasyon riski — animasyon süreleri sınırlı ve atlanabilir olacak (tasarım dokümanı tempo bölümü).
