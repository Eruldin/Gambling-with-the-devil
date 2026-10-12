# Devam Kılavuzu — kaldığın yerden buradan oku

Bu dosya, oturum çökerse yeni bir Devin oturumunun projeyi kaldığı yerden
sürdürmesi için yazılmıştır. Kullanıcının ana dili Türkçe; ona Türkçe cevap ver.

## Proje
Gambling with the Devil (Şeytanla Kumar) — Inscryption tarzı karanlık 3B
roguelike deckbuilder. Godot 4.7.2, GDScript. Tasarım: `docs/design/GAME_DESIGN_TR.md`
(EN eşi `GAME_DESIGN_EN.md`). Tüm içerik TR+EN çift dildir (`i18n/gwd.tr.po` + `gwd.en.po`).

## Çalıştırma & test
- Godot: `C:\Users\Administrator\godot\Godot_v4.7.2-stable_win64_console.exe`
- Parse kontrolü: `--headless --check-only --script res://scripts/battle.gd`
- Asset import: `--headless --path . --import`
- Otomatik tur probe'u (her değişiklikten sonra ZORUNLU):
  `GWD_AUTO=1 GWD_WIN=1 <godot> --path . > /tmp/gwd_x.log 2>&1 &` → ~75 sn bekle →
  `grep -icE "script error|Invalid call|Failed to load"` → 0 olmalı.
- İş bitince Godot'u öldür: `taskkill //F //IM Godot_v4.7.2-stable_win64_console.exe`

## Git akışı
main'e doğrudan itmeyiz: `git checkout -b devin/<slug>` → değişiklik →
probe temiz → commit → push → `git_create_pr` → `git_update_pr_base` ile
base'i "main" yap → squash-merge (`git merge --squash <branch>` → commit →
push origin main → remote+local branch sil). Kullanıcı tüm merge/deploy
izinlerini vermiştir; sorma.

## Mevcut durum (main'de canlı)
- **Savaş katmanı tam**: perdeler/ante, pot+fiziksel çip yığını, yükseltme(B),
  Soul Draw, Son Bahis(Y/N), Blöf Çağırma(C), tell'ler, mulligan(M),
  3 oyuncu trick'i (Tefeci/Öşrü/Ustura), reposition, 5 koz, ~20 mühür,
  2 effigy, zar/şans sistemi, arka sıra + Menzil, eşzamanlı çatışma+Keskin.
- **İniş (§18) tam**: 12+ kapı tipi (Fısıltı/Çark/Sözleşme/Defter/Ayna/
  Fırın/Tahnitçi/Günah Çıkarma/Geçiş/Emanet/Pit/Günah), kalıcı run state,
  escalation, kor ekonomisi, ganimetler, kırıcı kartlar, run mezar taşı.
- **Azrail**: 5 eksen psikoloji (%70 run-taşıma), 2 perde taunt, kapı lafları,
  hile oynuyor (trick'leri çözüyor), öfkelenince kart yakar/kural değiştirir,
  saygı kazanınca dürüstleşir.
- **7 günah boss'u** ayrı kurallı; **Çukur masası** (derin kapı) kuralları
  düşürür, kozlarını aynalayır.
- **Ev Kuralları (§7.1)**: her masada 6 kural setinden biri.
- **Kart seti**: 42 kart (35 piyon + 7 trick), her id'nin
  özel gravürü var (`assets_external/card-art/gwd/face_*.png`).
  Son eklenenler (#79-90): bargainer, mist_page, dissector, thurifer,
  bondsman, alms_sister, graveworm, night_collector, weeping_idol,
  dust_scribe, pallbearer, drowned_bellman, strongbox, moth_oracle +
  trick'ler salt_circle, grave_candle, cold_iron, ash_offering.
- **Sanat**: film bloom+kromatik sapma+hüzme postfx, sinematik açılış,
  vuruş kamerası, prosedürel drone müzik, gerçek tekir kedi, mumlar/fırtına.

## Kalan iş (öncelik sırası)
1. Kart setini ~190'a genişlet: her yeni kart = `card_def.gd` satırı +
   `face_*.png` (aşağıdaki tarifle üret) + i18n isim+desc. Parti parti ilerle.
2. Azrail olayları derinliği: eksenlere bağlı daha fazla özel laf/müdahale.
3. ~~Harita düğümleri fiziksel kapı~~ — yapıldı (#86): kapılar masada
   dik levha olarak yükselir; `GWD_DOORS=1` debug flag ile event
   fazına direkt atlanıp görsel kontrol yapılabilir.
4. Ses katmanını zenginleştir (gerçek SFX dosyaları Kenney paketinde var).
5. Boss arc'ları: günahların 3-perdelik yapısı §18.3'e göre derinleştirilebilir.
6. UI/UX: el tutma hissi, vuruş kareografisi, Türkçe tipografi kontrolü.

## Kart yüzü üretim tarifi (generate_image)
"Medieval occult woodcut tarot card face on aged sepia parchment, heavy black
ink linework with hatching: <özne>. Muted ink-wash tones <tek vurgu rengi>.
Tarot card composition, symmetrical border of thin ink filigree, no text, no
letters, dark elegant Inscryption-style occult illustration." →
`assets_external/card-art/gwd/face_<id>.png` kaydet → `--import` → kart def'te
face_file olarak bağla.

## Kullanıcı notları
- Türkçe konuş, jargon yok; her teslimde indirme linki + 2-3 adım kurulum.
- "İşini bitirmeden durma", "sürekli tur tur ilerleme" — engellemeden çalış,
  tur sonunda kısa rapor. Merge/test izinleri verilmiş.
- Test isterse `testing_agent` kullan (kayıt + rapor).
