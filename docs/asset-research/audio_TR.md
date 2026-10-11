# Aset Araştırması — audio: SFX, ortam sesi & müzik (TR)

Kategori: kart/masa foley'leri, UI sesleri, ortam döngüleri, yaratık/boss tekli sesleri, kazanma/kaybetme stinger'ları ve müzik planı. Karanlık mum ışıklı masa ses sahnesi. Hedef: Godot 4.x ses bus'ları.

## Gereksinimler
| Sınıf | Örnekler | Kaynak planı |
|---|---|---|
| Kart foley | çekme, dağıtma, kaydırma, çevirme, masaya vurma | Kenney casino-audio |
| Çip/pot | şıkırtı, desteleme, itme, saçılma | Kenney casino-audio |
| Zar/mühür | yuvarlanma, kemik tıkırtısı | Kenney casino-audio |
| UI | hover tıkı, onay, hata, sayfa çevirme | Kenney interface-sounds |
| Ortam | mum odası tonu, rüzgâr, ateş çıtırtısı | Freesound CC0 (sonra; API anahtarı gerek) veya üretilmiş noise döngüsü |
| Kurban/VFX | whoosh, çözülme, vıcık | Kenney impact'a yakın seçkiler + sentez katmanlama |
| Boss/yaratık | hırlama, fısıltı, çan | Freesound/CC sonra veya sentez — boşluk olarak işaretli |
| Stinger | kazanma, kaybetme, perde artışı | özel/sentez |
| Müzik | masa döngüsü, gerilim katmanları, boss temaları | özgün besteleme — lisanslı parçalar reddedildi (aşağıda) |

## Karşılaştırılan kaynaklar
| Kaynak | Lisans | Karar |
|---|---|---|
| **Kenney audio paketleri** | CC0 | ✅ casino-audio + interface-sounds indi |
| **Freesound.org** | dosya başına CC0 / CC-BY / CC-BY-NC | ⚠ dosya başına lisans filtresiyle kullanılabilir (sadece CC0); hesap gerekir — ertelendi |
| BBC Sound Effects | RemArc (ticari değil) | ❌ reddedildi — ticari kullanım dışarıda |
| OpenGameArt | GPL/CC-SA riski | ❌ reddedildi |
| Kevin MacLeod (incompetech) | CC-BY 3.0 | ⚠ sadece yedek — atıf yükü var |
| Unity/Unreal audio | mağaza lisansı | ❌ |

## İndirilenler
`assets_external/audio/kenney/casino-audio/` — 59 dosya: kart foley, çipler, zarlar (`License.txt` CC0).
`assets_external/audio/kenney/interface-sounds/` — 104 dosya: UI tık/onay/hata/çan (`License.txt` CC0).
İki paket de orijinal zip'leriyle birlikte (~4MB toplam).

## Boşluklar
- **Ortam yatağı** (mum odası tonu, uzak rüzgâr) — en iyi kaynak: Freesound CC0 parçaları veya üretilmiş noise/gürültü döngüsü; freesound hesabı olan sonraki oturum gerekir.
- **Müzik** — bilinçli karar: özgün katmanlı beste (düşük drone + seyrek piyano/celesta + perde seviyesine göre gerilim stem'leri). Lisans + ruh hâli uyan paket bulunamadı; besteleme veya sipariş önerilir.
- **Ses/fısıltı efektleri** — kayıt veya sentez; temiz CC0 fısıltı paketi bulunamadı.

## Entegrasyon planı (Godot 4.x)
1. Ses bus'ları: `Master > Music, Ambience, SFX, UI` — casino→SFX, interface→UI.
2. `AudioManager` autoload: havuzlanmış AudioStreamPlayer3D (masada konumsal) + AudioStreamPlayer (UI/2D); tekrarlarda ±%5 pitch rastgeleliği makineli tüfek hissini kırar.
3. Eşleme: kart çekme→`cardX.ogg`, oynama→`cardPlaceX`, çipler→`chipLayX`, perde artışı→çan+bas stinger.
4. Ortam: Ambience bus'ta her şeyin altında −18dB kesintisiz döngü; müzik kabarmalarında duck.
5. Format: gelen .ogg/.wav korunur; paket sadece wav ise boyut için ogg'ye çevrilir.
6. Test: 100 rastgele tetikle SFX bus'ta clipping kontrolü; ducking ve masa kamerasına göre konumsal düşüş doğrulaması.

## Riskler
- Kenney SFX'leri temiz/oyunsu — okült sahneye oturtmak için EQ/reverb gerekir (mix turu planda).
- Müzik en büyük kaynaksız kalem — lisans yükümlü parça seçmek yerine açıkça işaretlendi.
