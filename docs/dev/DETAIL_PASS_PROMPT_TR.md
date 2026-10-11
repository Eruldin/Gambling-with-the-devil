# Detay Turu İş Promptu — "vow" seviyesi
*(Avenox ilkesi: modelin bilemeyeceği şeyleri yaz — hedef, sebep, sınır, bitiş kriteri, tekrarlanan hata. Talimat değil, karar verme bilgisi.)*

## Hedef
Oyuncu ekrana baktığında tek kelime söylesin: "vow". Bunun için üç şey şart:
1. **Şeytan dünyaya ait hissetsin** — hareketleri ağır, amaçlı, sebepli.
2. **Masa gerçek malzeme hissetsin** — dokulu ahşap, dokulu keçe, ışık tutan yüzey.
3. **Karton detay yok** — hiçbir şey "iki kırmızı nokta" gibi ucuz okumasın.

## Sınır (asla geçme)
- Kafası imleci TAKİP ETMEZ. Göz yalnızca oyun olaylarına (watch) döner; boştayken ileriye, oyuncuya bakar.
- Rastgele seğirme/snap/sallanma YOK. Boşta sadece nefes (çok hafif) + göz kırpma (nadir).
- Parlayan göz orb'ları ve halo quad'ları YOK — modelin kendi yüz dokusu + kukuleta içi ışık yüzü okutur. Göz parlaması artık yüz ışığının ani güçlenmesidir.
- Model texture'larını düz renkle EZME — karartma = albedo_color çarpanı, albedo_texture/normal/ARM korunur.
- Hareket hep yavaş ve ağır: kafa dönüşü ~0.4 sn+, tween'ler cubic, hız çarpanları < 1.
- lerp ağırlıkları clamp'li (NaN dersi).

## Bitiş kriteri
- AUTO tur + SHOT render: 0 script hatası, 0 `is_finite`.
- Karede: göz orb'u yok, masa ahşap damarı okunuyor, keçe bez dokulu, iblis sabit dururken "yaşıyor" (nefes + anim), olay anında tek anlamlı kafa hareketi.

## Tekrarlanan hatalar (bu oturumdaki şikayetler)
1. Rastgele hisseden hareket → sebep: imleç takibi + snap twitch + sürekli sway üst üste biniyor. Çözüm: cursor-track silindi, twitch silindi, sway nefese indirildi.
2. "İki kırmızı nokta saçma" → sebep: emissive orb + additive halo quad, yüzden bağımsız yüzüyor. Çözüm: komple silindi.
3. "Masa düzgün texture'lı değil" → sebep: material_override düz renk, GLB'nin 1k diffuse/normal/ARM'ını eziyor. Çözüm: texture koruyup tint'le; keçeye üretilmiş bez dokusu.
