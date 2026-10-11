# Master Prompt — Gambling with the Devil
*(Avenox direktiflerine göre: hedef + neden + sınır + bitiş + tekrarlanan hatalar. Gerisini modele bırak.)*

## HEDEF
"Gambling with the Devil"ı Inscryption kalitesinde, mum ışığında tek başına ürküten bir 3D kart oyunu yap — ucuz kopya değil, kendi ayakta duran bir estetik.

## NEDEN
Oyuncu masada gerçek bir iblisle kumar oynadığını hissetsin: nefes alan, hamleyi okuyan, beslenen bir rakip; yaşayan bir oda; elimde hissedilen kartlar.

## SINIRLAR — asla aşma
- Masa/kart/sahne GÖRSEL ÜSTÜNE editlenmez — her şey gerçek 3D model + animasyon.
- Hiçbir şey animasyonsuz durmaz.
- Sadece CC0/OFL asset — her indirilen `assets_external/*/LICENSES.md`'ye yazılır.
- Görünür metin TR+EN.
- main'e squash-merge; PR base'ini main'e çevirmeyi unutma.

## TEKRARLANAN HATALARIM — tekrar etme
- `lerpf(a,b,delta*K)` ağırlığını clampsiz bırakma — `minf(delta*K,1.0)` (NaN gözler).
- Windows Python'da `open(...,'w')` mutlaka `encoding='utf-8'`.
- Yeni GLB/PNG/WAV'den önce `--import` çalıştır.
- `npx` değil `npx.cmd`.

## BİTTİ SAY
Tur uçtan uca oynanabilir; konsol 0 hata; her yeni nesne lisanslı + animasyonlu; render referansa yakın.
