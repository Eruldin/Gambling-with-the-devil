# ŞEYTANLA KUMAR (GAMBLING WITH THE DEVIL)
## Tam Oyun Çerçevesi — Tasarım Dokümanı (TR)

*Karanlık stratejik roguelike deste kurma oyunu. Mekanik odaklı tasarım.*
*Bu doküman sadece sistemleri tanımlar: hikâye, görsel yön veya anlatı yok. Her mekanik bir karar üretmek için var.*

---

# 1. TEMEL OYNANIŞ ÖZETİ

## Tek cümlelik oyun
Mum ışığında bir masada Şeytan'ın karşısına oturuyorsun ve ruhunun parçalarını — kelimenin gerçek anlamıyla — taktik bir kart düellosuna yatırıyorsun; masaya konan her kart bir bahis, her bahis gizli ve her zafer iki oyuncunun kendi kanıyla büyüttüğü bir pottan ödeniyor.

## Tasarım sütunları
1. **Her eylem bir bahistir.** Can havuzun = mana havuzun. Kart oynamak, blöfü görmek veya potu yükseltmek — hepsi düşmanın senden almaya çalıştığı aynı çipleri harcar.
2. **Gizli bilgi blöf doğurur.** Kartlar kapalı konur. Düşman bahse GİRDİĞİNİ ve NE KADAR yatırdığını görür — NE yatırdığını asla. Pokerin gerilimi taktik tahtasının içine taşınır.
3. **Gücün bir bedeli vardır.** Borç, yozlaşma, kurban, aşırı birleştirme. En güçlü hamleler kendi geleceğinden ödünç alır.
4. **Masa hatırlar.** Kartlar yaralanır, evrimleşir, defterine dövme gibi işlenir ve değişmiş geri döner. Kartlara bağlanmak, harcanabilir bir kaynaktır.
5. **Kasa (Ev) hep tırmandırır.** Sürekli yükselen ante (Perde/Blinds) her düelloyu bitirir. Oyalanmak matematiksel olarak imkânsız — sadece kararlı oyun hayatta kalır.

## İlhamlarından mekanik olarak farkı
- *Slay the Spire* mana kullanır; biz **birleşik can/mana potu** kullanıyoruz — her oyun acıtır.
- *Inscryption* açık tahtada kan kurbanı kullanır; biz **kapalı yerleştirme + ortak büyüyen pot** kullanıyoruz — savaşın kendisi kumardır.
- *Magic: The Gathering* instant'lara sahip; bizde **Tell, Görme (Call) ve Yükseltme (Raise)** var — gizli tahta üzerinde bilgi savaşı.
- *Poker* psikolojik bahse sahip; biz bahsi **gerçek, görünür ve tur boyunca kalıcı** yapıyoruz (Defter, Borç, Şeytan Kredisi).

## Oyuncu duygu hedefleri
- "Güçlü bir şey buldum" → organik keşfedilen graft/mutasyon komboları.
- "Bunu ben kurdum" → desteler tasarlanmaz, *inşa edilir* (birleştir/graft/dövme).
- "Bunu atlatmamalıydım" → pot yaralarla büyür; geri dönüşler en büyük ödemelerdir.
- "Önemli bir şeyi feda ettim" → kurban; bir slot, bir gelecek, bir dost gider.
- "Bir tur daha" → borçlar ve yozlaşmalar Defter aracılığıyla sonraki tura sızar.

---

# 2. TAM SAVAŞ KURALLARI

## 2.1 Savaş alanı — "Çuha" (The Felt)
Tam 3D fiziksel masa (motor/animasyon gereksinimleri §17'te).

```
                 DÜŞMAN RAFI (3 put/tılsım slotu)
        [A]   [A]   [A]   [A]   [A]        ← düşman ARKA sırası (5)
        [Ö]   [Ö]   [Ö]   [Ö]   [Ö]        ← düşman ÖN sırası (5)
   ─────────────────────────────────────────
                 POT (ortada)
   ─────────────────────────────────────────
        [Ö]   [Ö]   [Ö]   [Ö]   [Ö]        ← oyuncu ÖN sırası (5)
        [A]   [A]   [A]   [A]   [A]        ← oyuncu ARKA sırası (5)
                 OYUNCU RAFI (3 put slotu)
```

- **5 kulvar.** Her kulvar iki taraf için de bir ön + bir arka slotu eşler.
- **Ön sıra** — vurucular ve tutucular. Sadece ön sıradaki kartlar Çatışma (Clash) yapar.
- **Arka sıra** — destek piyonları ve korumalı kartlar. Arka sıradaki bir kart ancak kulvarının ön slotu boşsa veya saldıranın **Menzil (Reach)** mührü varsa hasar alır.
- **Raf (Mantel)** — her taraf için 3 ortak Put (Effigy) slotu; pasif motorlar. Çatışmaya girmezler ve çatışma ile hedeflenemezler; sadece özellikle rafı hedefleyen hileler/yetenekler dokunabilir.
- **Pot** — masanın ortasındaki gerçek çip yığını. Görünür, büyür ve ödüldür.

## 2.2 Savaş başlangıcı
- Oyuncu **Ruh Çipi = kalıcı can havuzu** ile girer (tur başında 40; savaşlar arasında taşınır).
- Düşman çip havuzu karşılaşma seviyesine göre (standart 25–40, Derin Masa 45–70, Boss mekaniğe göre değişir).
- Açılış: oyuncu 5 karta çeker, bir kez **yeniden dağıtma (mulligan)** hakkı vardır.
- Düşman Çuha'ya 0–2 kapalı kart önceden yerleştirir (silüet + bahis miktarı görünür).

## 2.3 Tur yapısı

### OYUNCU TURU
1. **Ante (Perdeler).** Güncel ante **iki** çip havuzundan da pota çekilir. Ante tırmanır (bkz. 2.6). Bu kıyamet saatidir.
2. **Çek.** 1 kart çek. Deste boşsa **Ruh Çekimi**: çekilen her kart hemen 2 çipe mal olur (ince desteler kanar).
3. **Bahis Aşaması** — istediğin sayıda eylemi istediğin sırada yap, sonra **"Gördüm" (Call)** de:
   - **Yerleştir:** bir kartı boş ön/arka slota kapalı koy (çip ve/veya et bedeli öde). Çip bedeli kulvara görünür bahis olarak dizilir — düşman bahsi görür, kartı görmez.
   - **Hile oyna:** anında çözülür, slot tutmaz.
   - **Kurban et:** kendi kartlarından birini (kapalı VEYA açık) feda et → Kurban Değeri kadar **Et** kazan; kart Yığın'a (mezarlık) gider. Kapalı kurban = sessiz pas.
   - **Yükselt (Raise):** turda bir kez, 1–5 ek çipi pota yatır. "yükselttiğinde" mühürlerini tetikler; ödülü büyütür; düşmanın planını sıkıştırır.
   - **Aktifleştir:** açık kartlardaki aktif yetenekleri kullan (bedeli yazdığı gibi).
   - **Blöfü Gör (Call the Bluff):** savaş başına bir kez: 2 çip öde, bir düşman kapalı kartını şimdi çevir. **Blöf** tipindeyse yok olur ve düşman 2 çip kaybeder. Gerçekse açık kalır (bilgi için ödedin).
   - **Konumlandır:** açık bir kartı ön↔arka arasında taşı veya başka bir kartla kulvar değiştir. Her kart savaşta bir kez konum değiştirir.
   - **Koz kullan:** tek kullanımlık hile eşyaları (bkz. kaynaklar), en fazla 3 taşınır.
4. **Açılış (Reveal).** Bu tur kapalı konan tüm kartlar aynı anda açılır. Açılışta tetiklenen mühürler soldan sağa, önce ön sonra arka sıra sırasıyla çalışır.
5. **Çatışma (Clash).** Ön sıradaki her piyonun kendi kulvarına vurur:
   - **Dolu kulvar** → karşılıklı hasar: iki kart da aynı anda birbirine Saldırı değeri kadar vurur. Yaralar kalıcıdır (Savunma yenilenmez). Saldıranın **Keskin (Sharp)** mührü varsa önce o vurur; öldürürse karşılık gelmez.
   - **Boş kulvar** → piyon Saldırı değerini düşmanın çip havuzuna vurur. Bu şekilde verilen her çip hasarı için **1 çip pota girer**.
   - **Menzil** mühürlü arka sıra piyonları karşı ön kartı (veya ön boşsa arka kartı) vurabilir.

### DÜŞMAN TURU — aynı yapıyla simetrik.
Düşmanın kapalı yerleştirmelerinde görünen: **bahis miktarı** ve bir **Tell** — küçük bir ipucu simgesi (maça işareti, duruş veya kart arkası). Tell'ler okunabilir, sahtesi yapılabilir (Blöf kartları bahis miktarında yalan söyler) veya susturulabilir.

### Tur biter. Perdeler programa göre yükselir.

## 2.4 Hasar ve Pot
- Çip hasarı (karşılıksız saldırılar, bazı hileler) kurbanın havuzundan birebir çip eksiltir **ve aynı miktar pota girer**.
- Piyon hasarı kartları yaralar; yaralar savaş boyunca kalıcıdır.
- **Pot ödüldür:** galip, potu → **Kor (Ember)** olarak 1:1 çevirir (üretim para birimi). Her iki tarafta ne kadar şiddet olduysa ödeme o kadar büyük.
- Sonuç: *yavaş yavaş kaybetmek, hâlâ kazanabileceğin bir potu besler.* Geri dönüş sadece hayatta kalmak değil — masadaki en büyük kazançtır.

## 2.5 Zafer, yenilgi ve Son Bahis
- **Zafer:** düşman çipleri 0'a iner → potu Kor olarak alırsın + node ödülleri.
- **Yenilgi:** çiplerin 0'a iner → tur başına bir kez **Son Bahis** tetiklenir: Şeytan seni 10 çiple oyuna geri almayı teklif eder. Bedel: **Borç +15** ve bir **Damga** (kalıcı tur laneti). Kabul et ve savaş; reddet ve tur biter.
- **Oyalanmak imkânsız:** Perdeler en pasif tahtada bile ~15–20 turda ölümü garantiler.

## 2.6 Perdeler (tırmanma programı)
| Turlar | Ante (taraf başına, turda) |
|---|---|
| 1–3 | 1 |
| 4–6 | 2 |
| 7–9 | 3 |
| 10–12 | 5 |
| 13–15 | 8 |
| 16+ | 13 (sonra +5/tur) |

İki taraf da öder — yani baskın bir düşman da senin ödül potuna kanıyor. Oyuncu ante programını masada yanan fiziksel bir mum olarak görür.

## 2.7 Zayıf deste neden güçlü desteyi yenebilir
- **Kapalı taahhüt** ucuz yemlerin düşman Görme'lerini boşa harcatmasını sağlar.
- **Pot** kimin büyük sayıları olduğunu değil, şiddeti kimin zamanladığını ödüllendirir.
- **Tell + Görme** bilgiyi satın alınabilen, sahtesi yapılabilen, çalınabilen bir kaynağa çevirir.
- **Kurban zamanlaması** kaybedilen tahtayı tek kararlı tura dönüştüren et üretir.
- **Yükseltmeler** kaybeden oyuncunun potu bilerek şişirmesini, sonra tek patlamayla geri çalmasını sağlar ("kısa desteli rest").

## 2.8 Geri dönüş mekanikleri (açık)
- Ödül olarak pot (yaraların ödülünü büyütür).
- Son Bahis (bir kerelik Şeytan kurtarması, korkunç koşullarla).
- Çaresizlik mühürleri ("çiplerin ≤ 10 iken …" kartları).
- Geri dönüş kolu olarak Borç — şimdi güç, sonra ödeme.

---

# 3. KART SİSTEMİ

## 3.1 Kart anatomisi
Her kart tam şablonu taşır:

| Alan | Anlamı |
|---|---|
| **İsim** | Kimlik. Sayılar değil, isimler. |
| **Tür** | Piyon / Hile / Put |
| **Bedel** | Çip (her zaman) ve/veya Et (büyük çağrılar) |
| **Saldırı** | Çatışma hasarı (saf destek için 0) |
| **Savunma** | Yara kapasitesi, savaşta kalıcı |
| **Yetenek** | Kartın metni — tetikler, aktifler |
| **Pasif** | Açıkken sürekli kural |
| **Mühür slotları** | 0–3 modüler yetenek slotu (graft'lanabilir) |
| **Sinerji etiketleri** | Maça (Tılsım/Kupa/Kılıç/Göz) + arketip bayrakları (Borç, Yavru, Saray, Şans, Kül) |
| **Kurban değeri** | Kurban edilince verilen Et |
| **Dönüşüm potansiyeli** | Birleştirme kademesi, mutasyon hattı, yozlaşma slotları |

### Kart türleri
- **Piyon** — ön veya arka sırayı tutar; Çatışır (ön) veya destekler (arka).
- **Hile** — anlık tek atış; oynanınca hemen çözülür. *Kalıcı* alt türü bir karta/kulvara yapışır.
- **Put (Effigy)** — raf slotunu tutar; pasif motor; çatışmaya dokunulamaz.

## 3.2 Dört maça (kimlik eksenleri)
- **Kılıç** — saldırganlık, yara baskısı, ölüm kartopu. Zayıflık: pot aşırı taahhüde kışkırtır.
- **Kupa** — kan, et, kurban, iyileşme. Zayıflık: kendi tahtasını tüketir.
- **Tılsım** — çipler, pot, borç, ekonomi. Zayıflık: açgözlülük sömürülebilir.
- **Göz** — bilgi, açılışlar, kopyalar, manipülasyon. Zayıflık: cılız istatistikler.

Arketip etiketleri maçaları keser: **Borç** (kredi sinerjileri), **Yavru** (ölüm-doğum), **Saray** (piyon güçlendirme), **Şans** (para/zar RNG), **Kül** (mezarlık döngüsü).

## 3.3 Mühürler — modüler yetenek dilbilgisi
Mühürler, mühür slotlarına graft'lanan işaretlerdir. Her mührün bir **karşı vektörü** vardır — hiçbir şey bedava değil.

### Saldırgan
| Mühür | Etki | Karşı vektör |
|---|---|---|
| Keskin | Çatışmada önce vurur; öldürme = karşılık yok | Koruma, yüksek Savunma duvarları |
| Delici | Fazla çatışma hasarı çiplere gider | Geniş tahtalar (fazla hasar hedefi yok) |
| Zehir | Yaralı kartlar tur başına +1 alır (3 kat) | Yaralıları kurban/dönüştür |
| Cellat | Halihazırda yaralı karta +3 Saldırı | Taze duvarlar |
| Azgın | Öldürme sonrası tekrar vurur (−2 Saldırı) | Ucuz yemlerle engelleme |
| Pusu | Arka sıraya doğrudan vurabilir | Raf/Çapa korumalı yerleşim |

### Savunma
| Mühür | Etki | Karşı vektör |
|---|---|---|
| Siper | Saldırıya uğrayınca karşılık verilemez | Boş kulvarlar onu atlatır |
| Mum Derisi | Her tur ilk yarayı yok sayar | Çoklu vuruş (Azgın, ek vuruşlar) |
| Diriliş | Ölümde ele döner (savaşta bir kez) | Sürgün/yakma etkileri |
| Koruma | Düşman hilelerine dokunulmaz | Ham çatışmalar |
| Çapa | Taşınamaz, değiştirilemez, yerinden edilemez | — (Örümcek/Takas'a bağışık) |

### Ekonomi
| Mühür | Etki | Karşı vektör |
|---|---|---|
| Adak | Oynanınca: +2 çip | Tahtayı yavaşlatır (savaşmayan tur) |
| Kabuk | Kurbanında +1 ekstra Et | Et ancak büyük çağrılar biriktirirsen işler |
| Tefeci | Açılışta: +2 çip, Borç +1 | Borç katlanır |
| Pot Oranı | Açılışta: pottaki her 5 için +1 çip | Küçük potlar |
| Yavru | Ölümde: 0/1 Kurtçuk doğar | Sürgün, Boşluklu Kral |

### Manipülasyon
| Mühür | Etki | Karşı vektör |
|---|---|---|
| Gözucu | Açılışta: bir düşman kapalı kartını gör | Blöf/sahte bahisler |
| Peçe | Görülemez (Call edilemez) | Hileler, sabır |
| Taklit | Açılışta: karşı kartın mühürlerini kopyala | Kendi karşı önlemlerini aynalar |
| Takas | Açılışta: rastgele bir müttefikle kulvar değiştirir | Çapalı müttefikler |
| Musallat | Ölümde: katilini lanetler (−1 Saldırı) | Sürgün, üzerinden azgınlık |

Gizli kombinasyonlar keşif katmanıdır: Yavru+Kabuk (kendini yenileyen yem), Adak+Diriliş (çip motoru), Taklit+Takas (çal ve kaç).

## 3.4 Açılış zamanlama katmanı
Kartlar üç durumda bulunur: **kapalı** → **açık** → **harcanmış** (tek atışlık piyonlar için).
- *Yerleştirilince* tetikler — kapalı (sessiz, gizli).
- *Açılışta* tetikler — çevrilme anı (dramatik vuruş).
- *Çatışmada* / *ölümde* — savaş vuruşları.
- Kapalı kartlar çoğu etkiye hedef olamaz — ama **kurban edilebilir** (sessiz pas) veya Görülebilir.

---

# 4. KAYNAK SİSTEMLERİ

Altı iç içe ekonomi. Her güçlü eylem en az birini harcar.

## 4.1 Ruh Çipi — *can = mana = bahis* (birincil)
- Tur boyunca kalıcı (başlangıç 40, iyileşme kıt).
- Harcanır: kart bedelleri, yükseltmeler, Görmeler, ruh çekimleri, bazı kozlar, dükkân fiyatları.
- Kazanılır: pot talepleri (Kor'a çevrilebilir), Adak tipi mühürler, nadir olaylar, Mola node'u.
- *Temel gerilim:* her tempo puanı kelimenin tam anlamıyla can puanıdır. Çiple saldırmak "ruhunu bahse koymaktır".

## 4.2 Et — kurban ekonomisi (savaş başına)
- Kart kurban ederek üretilir (her kartın Kurban Değeri 0–3).
- Savaş içinde biriktirilir; Et bedelli çağrılara harcanır (büyük piyonlar).
- Savaşla ölür — kullan ya da kaybet.

## 4.3 Pot — bahis ekonomisi (savaş başına)
- Besleyenler: çip hasarı, ante'ler, yükseltmeler, bazı mühürler.
- Galip tarafça talep edilir → Kor'a çevrilir.
- İkincil işlev: bazı kartlar pot büyüklüğüne göre çalışır (Pot Oranı, Defter Tayfası…).

## 4.4 Kor — üretim ekonomisi (kalıcı)
- Kaynak: pot talepleri, node ödülleri, Veznedar'a kart satışı.
- Harcama: Ocak/Veznedar'da birleştirme, graft, çıkarma, alışveriş, iyileşme.
- Çiplerin rol yaptığı "gerçek" tur para birimi.

## 4.5 Borç & Şeytan Kredisi — risk ekonomisi (kalıcı)
- **Borç al:** savaş ortasında veya node'lar arasında çip (Kredi düğmesi hep açık — "kasa kredi açar").
- Borç **faiz** işler: atladığın her Mola'da +1 Borç, her Çember sonunda +2. Ödenmemiş ≥ 15 → **Tahsildar olayları** haritada peşine düşer.
- Borç doğrudan öldürmez — son bossu güçlendirir (senedin onda) ve Mola iyileşmesini önce ona keser.
- *Tasarım amacı:* oyuncunun açgözlülüğü kendi zorluğunu kendi ayarlar. 0 borçlu tur "temiz"dir; 20 borçlu tur oyuncunun seçtiği bir bıçak kavgasıdır.

## 4.6 Kozlar — hile ekonomisi (kalıcı, tüketilebilir)
- Nadir tek kullanımlıklar (en fazla 3 taşınır): **Kol Kozu** (tüm kapalıları gör), **Soğuk Deste** (elini yeniden çek), **Aynalı Para** (herhangi bir atışı yeniden at), **İşaretli Kartlar** (düşman bu savaş Görme yapamaz), **Hileli Zar** (sonraki Şans atışın kazanır).
- Veznedar/Çark/olaylarda bulunur. Kasıtlı kural ihlalleri — yozlaşmış oldukları için kıt.

## 4.7 Şans — gizli meta-istatistik
- −3…+3 bandı; tüm iç RNG'yi eğer (Çark, Şans mühürleri, mutasyon, dükkân stoğu).
- Bazı olaylar/sunaklar yükseltir; açgözlü eylemler kanatır (Şeytan hileleri fark eder).
- Masada zar olarak **görünür** — Şeytan zarların hileli olduğunu gösterecek kadar adil oynar.

---

# 5. YÜKSELTME & DÖNÜŞÜM SİSTEMLERİ

Güç tehlike yaratmalı. Aşağıdaki her yol canını yakabilir.

## 5.1 Birleştirme — "Ocak"
- **Aynı maçalı iki kartı** tek karta kaynaştır: statlar = toplam −20%, mühürler = birleşim (slot tavanı = taban kartın slotu +1), kurban değeri = yüksek olanı.
- Bedel: kademeye göre Kor 15–40.
- **Birleştirme kademeleri:** K1–K2 güvenli. **K3+** kart **Aşırı Yüklü** olur — her savaşta **Çatlama** riski (rastgele bir mühür kalıcı kaybolur). Birleştirmeden önce uyarı görünür.
- Birleşmiş kart *yeni bir karttır* — tekrar birleştirilebilir (üssel risk, üssel ihtişam).

## 5.2 Graft — "Tahnitçi"
- A kartından mühür sök (A hayatta kalır ama **İskelet** olur — mühürsüz; ya da tam et iadesiyle tüketilir) → B kartının boş slotuna tak.
- Bedel: Kor + A'nın eti.
- İmza zanaatı: bir yem kartından *Yavru*'yu söküp kazanma koşuna tak.

## 5.3 Mutasyon — koşullu evrim
- Gizli eşikler kalıcı değişim tetikler: öldürmeler (Kasap hattı), hayatta kalma (Yara hattı), ölümler (Kül hattı), pot eşikleri (Hırs hattı).
- Mutasyon *kazanılır*, satın alınamaz — Ocak satmaz. 3 boss sağ çıkaran kartla 10 kurban yemiş kart farklı mutasyona uğrar.
- Kaos mutasyonu var (Çark/Şans Sunağı) — rastgele, sert, Şans'a ağırlıklı.

## 5.4 Yozlaşma — "Şeytan Dokunuşu"
- Antlaşma/Sunak olayı: bir **nimet** seç (+2 Saldırı, bedava mühür, −1 çip bedeli) ve bir **lanet** seç (tur başına 1 çip bakım; Borç +4; ölümde 3 çip kaybı; **Bağlı** — desteden çıkarılamaz).
- Yozlaşmış kartlar görünür şekilde damgalı — ve Krupiye finalde onları hatırlar.

## 5.5 Dövme — "Defter Bağı"
- Kartı tur defterine bağla: her boss sonrası kalıcı +1/+1 kazanır.
- Bağlanmanın bedeli: savaşta ölürse **Borç +2**. En sevdiğin kart rehine olur.

## 5.6 Oyuncu neden tereddüt eder
- Birleştirme değeri tek Çatlayabilen bedende yoğunlaştırır.
- Graft bir kartı öldürüp diğerini güçlendirir.
- Yozlaşma turu rehin alır.
- Dövme sevgiyi pahalı yapar.
- Yükseltme *slotları* sınırlı — seçilen her +1, başka yerde alınmayan +1'dir.

---

# 6. DESTE KURMA KURALLARI

## 6.1 Sayılar
- **Başlangıç destesi:** 10 kart — 4 küçük piyon, 3 hile, 2 yem/kurbanlık, 1 persona imza kartı.
- **Deste boyutu:** en az 10, en çok 30.
- **El:** savaş başında 5'e çek (bir mulligan), turda 1 çek, el sınırı 7.
- **Ruh Çekimi:** deste boş → zorunlu her çekim 2 çip kanatır.

## 6.2 Kurma fiilleri
| Eylem | Nerede | Bedel/risk |
|---|---|---|
| Kart al (3'ten 1 seç / Kor için Pas) | savaş sonrası ödül | Pas = ince deste değeri |
| Kart çıkar | Sunak / Veznedar hizmeti | kor veya et/mühür için kurban |
| Kopyala | Ayna olayları | nadir; kopya vergisine tabi |
| Birleştir / graft / yozlaştır / dövme | Ocak / olaylar | §5 |
| Deste kartını kurban et | Sunak node'u | kalıcı çıkarma → et/kor/mühür |
| Katla (sat) | Veznedar | kart → kor dönüşümü |

## 6.3 "Her şeyi al" karşıtı baskılar
- **Kopya vergisi:** aynı kartın 3.+ kopyası oynamak için +1 çip ("masa numaralarını öğrenir").
- **Ruh Çekimi yorgunluğu:** ince desteler tutarlı ama boş çekimlerde kanar.
- **Maça bağlılığı:** bazı güçlü kartlar destenin ≥40%'ının aynı maçada olmasını ister — sulandırmak onları bozar.
- **Yaralar kalıcı:** dev deste daha uzun öğütür; Perdeler öğütmeyi cezalandırır.
- **Pas iyidir:** kartı reddetmek gerçek bir ödüldür (+3 kor) — kısıtlılık bir stratejidir.

**Tasarım kuralı:** 12 kartlık bıçak gibi bileylenmiş bir deste, 28 kartlık yığını yenebilmeli — tutarlılık vs. dayanıklılık gerçek bir eksendir, acemi tuzağı değil.

## 6.4 Kart ödül sıklığı
- Standart Masa: 3'ten 1 seç (destenin maçalarına ağırlıklı, ~%65/25/10).
- Derin Masa: 3'ten 1 nadir-veya-üstü + mühür jetonu.
- Boss: bir Nimet seçimi (bkz. §8) + kart havuzu genişleme olayı.

---

# 7. ROGUELIKE YAPISI — "İNİŞ"

## 7.1 Harita
Üç **Çember**, her biri ~5 sütunlu, 2–4 dallı yollu node grafiği:

- **Çember I — Salon** (öğretici, hafif ev kuralları)
- **Çember II — Mahzen** (elit yoğun, ekonomi baskısı)
- **Çember III — Çukur** (her şey serbest; Şeytan rol yapmayı bırakır)

Node türleri:
| Node | Ne olur |
|---|---|
| **Masa** | Standart savaş (asılı **Ev Kuralı** ile) |
| **Derin Masa** | Elit savaş — yüksek bahis, çift pot, nadir ödüller |
| **Çukur Patronu** | Çember sonu bossu (kural bozucu, §8) |
| **Veznedar** | Dükkân: kartlar, kozlar, çıkarma, iyileşme — kor *veya* çip ile |
| **Ocak** | Birleştirme / graft / dövme hizmetleri |
| **Sunak** | Deste kartını kurban et → kor/et/mühür-söküm; ayrıca kartı çıkarır |
| **Çark** | Gerçek kumar: kor/çip yatır, çevir. İsteğe bağlı, Şans'a ağırlıklı |
| **Mola** | Çip iyileş, Borç öde veya **Dalavere** (az iyileş, kor kazan) |
| **Antlaşma** | Şeytan'ın teklif olayı — ısmarlama pazarlık (şimdi güç, sonra bedel) |
| **Fısıltı** | Gizli node — sadece harita kumarları veya Gözucu olaylarıyla açılır |

**Ev Kuralları** (her Masa öncesinde asılı — rota seçimiyle zehrini sen seçersin):
- *Mum Nöbeti* — kurban yasak
- *Açık Masa* — tüm kartlar açık konur
- *Geçiş Resmi* — her çekim 1 çipe mal olur
- *Sebt* — raf putları sessiz
- *Yüksek Bahis* — ante ×2, pot ödemesi ×2
- *Kan Bedeli* — yaralar savaşlar arasında kalıcı (sadece bu node)

## 7.2 Zorluk ölçeklemesi
- Düşman çip havuzları, statlar ve mühür yoğunluğu çember başına ölçeklenir (×1.0 / ×1.35 / ×1.7).
- Derin Masalar açgözlü yollarda daha sık — haritanın **risk/ödül okunabilirliği** bir beceridir: güvenli rotalar build'i aç bırakır.
- **Kişisel ölçekleme:** Borç ≥15, yol ortasında pusu kuran Tahsildar node'ları doğurur.
- **Uyarlanabilir şeytanlık (son oyun):** Çukur en çok oynadığın arketipi izler ve geç masalara karşı önlemler ağırlar — görünmez ama dürüst.

## 7.3 Turun duygusal ritmi
Erken: ucuz zaferler, küçük potlar — fiilleri öğretir.
Orta: ilk gerçek pazarlık — build'i tanımlayan bir graft veya ilk Borç.
Geç: her seçim kanar — pot devasa, ruhun ince, Perdeler çığlık atıyor.
Ölüm neredeyse her zaman yazılmış hissettirmeli: "Bedeli gördüm ve yine de ödedim."

---

# 8. BOSS FELSEFESİ

Boss'ların daha çok canı yok — **boss'lar masanın kurallarını değiştirir.** Her biri boss yüzü takmış farklı bir oyundur.

## 8.1 Boss kadrosu (Çember bossları havuzdan çekilir; çember başına iki alternatif turları farklılaştırır)

### Tahsildar (Çember I)
- **Benzersiz mekanik:** çip havuzu yok — **pot onun canı.** Onu aşırı ödemeye zorlayarak kazanırsın: her yükseltmeni karşılamak zorunda (balina; pas diyemez). Zafer = pot ≥ Hırs Eşiği (başlangıç 40) → batar ve her şeyi öder.
- **Baskı:** karşıladığı ante'ler büyür; önce senin çiplerin 0'a inerse normal yenilgi.
- **Karşı oyun:** erken karşılamalarını kışkırt, sonra aç bırak — *yükseltmenin* hasar olduğu tek savaş.

### Bahis Dul'u (Çember I alternatifi)
- **Benzersiz mekanik:** **destenin aynasını** oynar — kelimesi kelimesine senin listen.
- **Baskı:** ante ×2. Destenin kendi tavanı saattir.
- **Karşı oyun:** kendi cevabını taşıyan build'ler ödüllendirilir (kontrol > ham stat); zayıf kopyalar onun Görme'lerini blöfleyebilir.

### Krupiye (Çember II)
- **Benzersiz mekanik:** her 3 turda **masayı yeniden dağıtır** — oyundaki tüm kartlar destelere karışır, taze kapalı yerleştirmeler gelir.
- **Baskı:** saf anti-oyalanma; kurulum motorları asla bitmez.
- **Karşı oyun:** düşük taahhütlü patlama, Açılış tetikli kartlar, tekrar oynanmak isteyen kartlar (Adak motorları yeniden dağıtmayı sever).

### Boşluklu Kral (Çember II alternatifi)
- **Benzersiz mekanik:** **iki mezarlık da onun.** Ölen her kart (iki tarafın da) onun tahtasında −1/−1 ile dirilir.
- **Baskı:** kurbanların onun ordusunu silahlandırır — Kupa/Yavru build'lerini özellikle cezalandırır.
- **Karşı oyun:** sürgün/yakma etkileri ("küller diz çökmez"), az-ölümlü tahtalar veya ona yem besleyip alanı yakmak.

### Krupiye / Şeytan (Final — Çember III)
- **Benzersiz mekanik:** **turunun tarihini** oynar. Her yozlaşmış kart ona hizmet eder; Borcun onun başlangıç çipleri olur; Ev Kuralları en çok kullandığın arketibe karşı seçilir (faz başına yeniden atılır).
- **Baskı:** üç faz (Salon kuralları → Mahzen kuralları → kuralları tamamen bırakır: *görünür şekilde hile yapar* — Kozların sana aynalanarak döndüğü tek savaş).
- **Karşı oyun:** tur hijyeni karşılığını verir — düşük borç, az yozlaşma, çeşitli arketipler onu güçsüz kılar. Temiz oyuncu bir ölümlüyle; tefeci oyuncu bir tanrıyla karşılaşır.

## 8.2 Ortak boss kuralları
- Her boss kural değişikliğini masada fiziksel bir fikstür olarak asar (kuralı savaştan önce hep görürsün).
- Her boss ödül ekranında belirtilmiş bir karşı-eksen taşır ("kasa tell'lerini gösterir").
- Hiçbir boss stat-kontrolü olamaz: sayılarla tek başına yenilebiliyorsa tasarım başarısızdır.

---

# 9. ÖRNEK KARTLAR

Başlangıç havuzu örneği (statlar temsili, denge playtest'te belirlenecek):

| İsim | Tür | Bedel | Sal/Sav | Mühürler | Metin | Maça/Etiket |
|---|---|---|---|---|---|---|
| Adak İblisi | Piyon | 1 çip | 1/2 | Adak | Oynanınca: +2 çip | Kılıç / Borç |
| Küllü Güve | Piyon | 0 | 0/1 | — | Ölümde: 1 kart çek | Kül / Yavru |
| Defter Tayfası | Piyon | 3 çip | 2/4 | Pot Oranı | Pottaki her 5 çip için +1 Saldırı | Tılsım |
| Kemik Köpek | Piyon | 2 et | 3/1 | — | — | Kupa |
| Ahdili Domuz | Piyon | 2 çip | 4/4 | — | Oynanınca: Borç +3 | Tılsım / Borç |
| Blöfcü | Piyon | 0 | */* | — | Sadece kapalı konur. Görülürse: yok olur, düşman −2 çip. Açıldığında hiçbir şey | Göz / Blöf |
| Gözlerin Uşağı | Piyon | 2 çip | 1/3 | Gözucu | Açılışta: bir düşman kapalı kartını gör | Göz |
| Ayna Tazısı | Piyon | 3 çip | */* | Taklit | Açılışta karşı kartın statlarını+mühürlerini kopyalar | Göz |
| Koro Sülüğü | Piyon | 2 çip | 1/3 | — | Çatıştığında: 1 çip iyileş | Kupa |
| Makaslı Rahibe | Piyon | 4 çip | 3/5 | — | Açılışta: karşı kapalı kartı açılmadan yok et | Kılıç |
| Leke Şövalye | Piyon | 3 çip | 4/3 | Keskin | Her öldürmede kalıcı +1 Saldırı (mutasyon hattı) | Kılıç / Kasap |
| Kader Örümceği | Piyon | 2 çip | 1/4 | Takas | Açılışta: rastgele boş bir kulvara taşınır | Göz / Şans |
| Kor Kurt | Piyon | 3 et | 5/4 | — | Çatışmada: karşı kartın mühürlerini yakar (İskelet'e) | Kupa / Kül |
| Lamba Hanımı | Piyon | 5 çip | 4/6 | — | İyileştiğinde: +1 Saldırı | Kupa |
| Borçlunun Çanı | Put | 3 çip | — | — | Her tur: iki ante de +1 | Tılsım / Borç |
| Kemik Banker | Put | 2 çip | — | Kabuk | Kurbanların +1 et üretir | Kupa |
| Kül Yapan | Put | 3 çip | — | — | Herhangi bir kart ölümünde (iki taraf): +1 et | Kupa / Kül |
| Krupiyenin Sol Eli | Put | 4 çip | — | — | Ante'lerin her tur 1 çipini iade eder | Tılsım |
| Solgun Tefeci | Hile | 0 | — | — | +4 çip. Borç +2 | Tılsım / Borç |
| Mezar Kazıcısının Adağı | Hile | 1 çip | — | — | Son ölen piyonu ele geri al | Kupa / Kül |
| Düz Ustura | Hile | 1 çip | — | — | Hedef piyon Keskin kazanır (sadece bu savaş) | Kılıç |
| Borçlu | Hile-lanet | — | — | — | Destede ölü kart; Sunak'ta ödenmesi gerekir | Borç |
| Şans'ın Rahibesi | Piyon | 4 çip | 3/4 | — | Her tur yazı-tura — yazı +3 çip / tura −1 çip (Şans'a ağırlıklı) | Göz / Şans |
| Pazarlıkçı | Piyon (nadir) | 3 çip | 2/5 | — | Oynanınca: Şeytan savaş ortasında teklif sunar | Tılsım / Borç |
| Fare Avcısı | Piyon | 1 çip | 2/1 | Delici | — | Kılıç |

---

# 10. ÖRNEK BUILD'LER

## Build A — "Kanayan" (Kupa kurban motoru)
Çekirdek: Küllü Güve ×2, Kemik Köpek, Kemik Banker, Kül Yapan, Kor Kurt, Mezar Kazıcısının Adağı.
Döngü: yem ölür → et bankası → et-yakıtlı büyük bedenler → Kül Yapan daha fazla et iade eder. İnce deste (12–14) tutarlılık için.
Zayıflık: Boşluklu Kral; sürgün etkileri; Mum Nöbeti masaları.

## Build B — "Kurnaz" (Göz bilgi oyunu)
Çekirdek: Gözlerin Uşağı, Blöfcü ×2, Ayna Tazısı, Kader Örümceği, Gözucu mühürleri, İşaretli Kartlar kozu.
Döngü: bilgi savaşını kazan — gerçek tehditleri gör, Blöfcü Görmeleri yesin, Ayna Tazısı büyük açılışları cezalandırır.
Zayıflık: Açık Masa ev kuralları; ne bildiğini umursamayan ham-stat desteleri.

## Build C — "Balina" (Tılsım pot ekonomisi)
Çekirdek: Defter Tayfası, Ahdili Domuz, Solgun Tefeci, Borçlunun Çanı, Krupiyenin Sol Eli, Pot Oranı graft'leri.
Döngü: yükseltmelerle potu şişir → patlamayla ya da Tahsildar-vari çıkışlarla nakde çevir; Borç tempoyu besler.
Zayıflık: katlanan Borç; Tahsildar olayları; Krupiye (senedi onda).

## Build D — "Kasa" (Kılıç tahta kontrolü)
Çekirdek: Leke Şövalye, Makaslı Rahibe, Fare Avcısı, Düz Ustura, Keskin/Delici graft'leri, Azgın bitiriciler.
Döngü: tahtanın hiç dengelenmesine izin verme — kapalı kartları vur, öldürme sayaçlarını Şövalye'ye yığ.
Zayıflık: korumalı raflar, Mum Derisi duvarları, Bahis Dul'u (ayna).

## Joker — "Cam Katedral" (yozlaşma/mutasyon kumarı)
Tek devasa birleşmiş+yozlaşmış+dövmeli beden (örn. Azgın+Siper graft'lı Kor Kurt, +2 Sal yozlaşması, dövmeli). Gerisi onu besleyen et bankası yemleri.
Zayıflık: kelimenin tam anlamıyla her şey — bir Çatlama, bir Musallat, bir Görülen blöf ve katedral küldür. "Bunu atlatmamalıydım" makinesi budur.

---

# 11. KOMBO KÜTÜPHANESİ

## 11.1 On başlangıç kombosu (2 kart, bariz, dilbilgisini öğretir)
1. **Küllü Güve + Kemik Banker** — güveyi kurban et, çek, +1 et kazan. Öğretir: ölüm bir kaynaktır.
2. **Adak İblisi + Ahdili Domuz** — iblisin çipleri domuzun faizini öder. Öğretir: gelir borcu yumuşatır.
3. **Fare Avcısı + Düz Ustura** — ucuz delici + önce vuruş = silinmiş kulvar. Öğretir: beden üstü mühür.
4. **Blöfcü + Gözlerin Uşağı** — sahte bahis yap, bedava göz at. Öğretir: bilgi de bir bahistir.
5. **Koro Sülüğü + Lamba Hanımı** — çatışma iyileşmesi onun saldırısını besler. Öğretir: motorlar iki kart derindir.
6. **Defter Tayfası + bir Yükseltme** — pot 10+ = tayfa her tur büyür. Öğretir: pot bir stattır.
7. **Kemik Köpek + Kül Yapan** — kurban et, toplam +2 et bankala. Öğretir: et katlanır.
8. **Ayna Tazısı + kulvar seçimi** — en büyük kapalı kartlarının karşısına park et. Öğretir: yerleşim = okuma.
9. **Borçlunun Çanı + Krupiyenin Sol Eli** — ante'lerin ikiye katlanır ama iade edilir — pot şişer, ödemeler kabarır. Öğretir: enflasyon stratejidir.
10. **Solgun Tefeci + Borçlunun Çanı** — potu da pompalayan borç-yakıtlı tempo. Öğretir: Şeytan'ın parası harcanır.

## 11.2 On ileri kombo (3+ kart / graft, deste şekillendiren)
1. **Adak İblisi'ne graft'lanmış Yavru + Kül Yapan** — iblis ölür, kurtçuk doğar, et ve çip iade eder: kendini yenileyen ekonomi motoru. Kira ödeyen yem.
2. **Ön safta Diriliş + Kabuk** — ölür, ele döner, daha fazla kurban için tekrar oynanır. Sadece sürgünle karşılanabilen yenilenebilir kurban döngüsü.
3. **Gözucu + Makaslı Rahibe + Kader Örümceği** — kapalı bombalarını gör, Rahibe ile vur, örümcek açılışı yeniden konumlandırır. Bilginin tempoya çevrimi.
4. **Pot Oranı ×3 arka sıra + Borçlunun Çanı** — ante'lerle beslenen pasif gelir kulesi. Yavaş ama Perdeler potu onun istediği yere iter.
5. **Mezar Kazıcısının Adağı + Leke Şövalye + kurban yemi** — Şövalye'yi öldürdükten sonra dirilt; iki hayat boyunca mutasyona uğrat. Şövalye iki ölümü de hatırlar.
6. **Blöfcü ×2 + İşaretli Kartlar + Yükseltme** — yükseltirken tahtayı üç kez sahtele; düşman Görmeleri boşa harcar (veya gerçek olan blöfü görünce sana öder). Tahta haline gelmiş poker gecesi.
7. **Kor Kurt + Pusu graft'i** — duvarın arkasındaki arka sıra motorunun mühürlerini yak. Rakibin güvende sandığı raf-desteğini siler.
8. **Kader Örümceği + Takas mührü + açık-kulvar matematiği** — rastgele-kulvar piyonları çatışmanın ulaşamayacağı yerlere inerken Menzilli müttefikler açıkta kalan kulvarları toplar. Örtü olarak kullanılan kaos.
9. **Ucuz piyona graft'lanmış Taklit + Bahis Dul'u savaşı** — ayna maçında taklidin *onun* en iyi kartına dönüşür — yansımasına karşı kendi destesini silahlaştırırsın.
10. **Ruh Çekimi gambiti: ince deste (10) + Adak motoru** — desteyi kasten boşalt, 2-çip çekimler öde ama motorun turda 4+ üretir. Yorgunluk, zaten kazandığın bir aritmetiğe dönüşür.

## 11.3 On yozlaşmış / yüksek-riskli kombo (yasal ama Şeytan izliyor)
1. **Bedava Kredi:** Solgun Tefeci + Borçlunun Çanı + Tahsildar-taklidi build'ler — borç-yakıtlı ante enflasyonu; pot patlama hızında soyacağın bir tasarruf hesabına dönüşür. Risk: Tahsildar olayları yol ortasında gelir.
2. **Sonsuzumsu çip motoru:** Diriliş+Adak+Yavru piyonu + kurban döngüsü → her çevrimde +çip/et/kart. **Masa Adabı** ile sert sınırlı (her mühür turda ≤3 kez çalışır) ve Perdeler — oyalanma değil, sprint.
3. **Cam Katedral** (bkz. Build'ler): kademe-3 Aşırı Yüklü + dövme + üçlü yozlaşma. Savaş başına bir mühür kaybeden ~40 statlık tek beden. Pot onu sever; çatlaklar onu geri sayar.
4. **Pot Aklama:** Borçlunun Çanı + her tur yükseltme + Pot Oranı ×3 + Defter Tayfası — tek karşılıksız turda kazanmayı planladığın potu yapay olarak şişir. Rest ayan beyan — düşman kuleyi görür, blöfü görür veya senle yarışır.
5. **Borçlu yığma:** destede 3 Borç laneti + Sunak ödemeleri + Şans manipülasyonu — 0 çip bedelli borç-fiyatlı motor kartları. Son boss defterini okur.
6. **Çift Ayna:** Bahis Dul'u'na karşı Ayna Tazısı + Taklit graft'i — aynanın aynası; birinin ekonomisi çökene dek senin yansımanı yansıtır. Yozlaşmış, spesifik, muhteşem.
7. **Kör rest:** 1. turda 5 yükseltme + kapalı Blöfcü tahtası + İşaretli Kartlar + Şans'ın Rahibesi — her turun rest olduğu Şans-eğimli yazı-tura turu. 4 turda kazanır ya da 5'te ölür.
8. **Sürgün Yiyen:** Boşluklu Kral'a karşı Kül Yapan + Kor Kurt + Mezar Kazıcısının Adağı döngüsü — dirilttiği çöpleri besle sonra hepsini yak; onun ordusu senin ocak yakıtın.
9. **Koz istifleme:** Krupiye için saklanan Kol Kozu + Soğuk Deste + Hileli Zar — sana aynalanarak döndüğü tek savaş için saklanan üç hile. Onu kendi oyununda yenersin — önce o oynamazsa.
10. **Şeytan Marjı:** Borcu tam 14'te tut (Tahsildar eşiğinin bir altı), Solgun Tefeci + Ahdili Domuz'u sonsuza dek sağ. Kumarhane gibi ödeyen bıçak sırtı ekonomi — ta ki bir Fısıltı node'u seni 15'e itene dek.

*Neden eğlenceliler:* her yozlaşmış hat **görünür, ayan beyan ve yenilebilir** — eğlence, oyunun aktif olarak salladığı bir telde yürüdüğünü izlemektir.

---

# 12. ÖRNEK 30 DAKİKALIK OYUN SEANSI

Çember I — Salon. Yeni tur, varsayılan persona. Çip = 40, deste = 10.

- **0:00–2:00 — Dağıtım.** Harita iki rota gösterir: sol — Masa (*Açık Masa*) sonra Ocak; sağ — Masa (*Geçiş Resmi*), Sunak, Derin Masa. Oyuncu ev kurallarını oran gibi okur ve sağı seçer: daha zor, daha zengin.
- **2:00–6:00 — Masa 1** (vs. **Mürekkep Borçlusu**, 26 çip). Fiiller ateş altında öğrenilir: Küllü Güve'yi kapalı koyar (bahis 0 — düşman hiçbir şey okuyamaz), arkasına Adak İblisi. Ante'ler işler. 3. tur: 2 çip ödeyip düşmanın kapalı kartını **Görür** — yem çıkar, bedavaya yok olur. Karşılıksız vuruşlar potu 14'e taşır → 6. turda ölüm. **14 kor** talep eder. Ödül ekranında üç sıradan kart yerine **Pas** (+3 kor) seçer — ilk ince-deste kararı.
- **6:00–8:00 — Ocak.** 15 kor'a Adak İblisi'ne **Kabuk** graft eder — iblis artık kendi bedelini ödemiş kurban yakıtı. Destenin omurgası kuruldu.
- **8:00–13:00 — Masa 2 (*Geçiş Resmi*)** (vs. **Dul'un Eli**, 32 çip). Her çekim bir çip — ev kuralı ısırır. Kilit keşif: **Kemik Köpek et bedelli, yani bahsi hiç görünmez** — et oyunları düşmanın okuyacağı bir iz bırakmaz. 22'lik potu kazanır ama 31 çiple biter; geçiş resmi bedelini aldı.
- **13:00–15:00 — Sunak.** Zayıf piyonu kurban eder: desteden çıkar + mührü sökülür + 4 kor. Deste 11'de, daha keskin.
- **15:00–22:00 — Derin Masa (*Yüksek Bahis*)** (vs. **Solgun Müdavim**, 55 çip). Ante ×2. Savaş ortasında oyuncu **Şeytan Kredisi +6** çekip Makaslı Rahibe'yi kapalı koyar — Rahibe açılıp düşmanın kapalı bombasını *açılmadan* siler. İmza vuruşu. Düşman yarışır; oyuncu 9 çipe iner; tayfanın çaresizlik mührü titrer. 9. tur: 4'lük rest → pot 47 → boş kulvar → ölüm. **47 kor** — seansın en büyük potu. Faizle Borç +8.
- **22:00–25:00 — Mola.** Seç: 12 iyileş / Borç öde / Dalavere. Borcu 8→3'e indirir, biraz iyileşir. Matematik kötü hissettirdi — tasarım tam da bu.
- **25:00–30:00 — Çukur Patronu: Tahsildar.** Kural ters: canı potun kendisi (Hırs Eşiği 40). Oyuncu pas diyemeyen bir balinayı beslemek için turda 5 yükseltir — saldırganlığın vurmak değil bahis olduğu tek savaş. Her yükseltmeyi karşılar; pot 41'e ulaşır → batar. Ödül: pot korları + bir **Nimet** ("Kor Adağı": tur boyunca masa başına +5 kor) + Göz nadir kartları ödül havuzuna açılır.
- **30:00 — Çember II açılır; seans bir kararın ortasında biter** — kanca tam da bu: tur hiç güvenli değildi ve oyuncu neyi farklı yapacağını şimdiden biliyor.

Yukarıdaki her vuruş §2'den bir fiil — gizle, gör, yükselt, kurban et, graft'la, borç al, batır. Hiçbiri hikâyeye yaslanmıyor: mekanikler dramanın ta kendisi.

---

# 13. OYUNCU PSİKOLOJİSİ — DUYGUSAL TASARIM

| Hedef duygu | Onu üreten sistem |
|---|---|
| "Güçlü bir şey buldum" | Gizli mühür sinerjileri; graft keşifleri; mutasyon açılışları |
| "Bunu ben kurdum" | Birleştir/graft/dövme desteyi *inşa edilmiş* kılar, tasarlanmamış değil |
| "Bunu atlatmamalıydım" | Pot-şişirmeli geri dönüşler; Son Bahis; çaresizlik mühürleri |
| "Önemli bir şeyi feda ettim" | Slot kaybı, iskelet kartlar, dövme rehineleri, sunak çıkarmaları |
| "Bir tur daha" | Borç yankıları, Defter açılımları, persona çeşitliliği, ev-kuralı varyantları |
| Dehşet | Perdelerin mumu; Krupiye'nin defterini sana geri okuması |
| Yenilginin sahipliği | Her ölüm seçtiğin bir bedele dayanır |

Tasarım dışı bırakılan anti-kalıplar: saf öğütme yok (Perdeler), haksız RNG ölümü yok (tüm atışlar Şans zarıyla gösterilir), anlamsız seçim yok (her ödülün bedeli ve geri çevirme hakkı belirtilir).

---

# 14. META İLERLEME — "ALTTAKİ DEFTER"

Kalıcı ilerleme olasılık alanını genişletir; sayıları asla doğrudan artırmaz.

- **Damgalar** (ascension tarzı antlaşma değiştiriciler): temizlenen her tur gelecek turlara bir Damga ekler (örn. "Çember I masalarının tümü Açık Masa", "Perdeler 1. turdan +1").
- **Personalar:** yeni başlangıç desteleri — Kurnaz (Göz), Kanayan (Kupa), Yeminbozan (Borç), Çit (karışık/Şans). Her birinin imza kartı var.
- **Külliyat:** kart havuzları, mühürler, arketipler ve Ev Kuralları ödül havuzuna açılır — yeni statlar değil, yeni *seçenekler*.
- **Şeytan'ın Hafızası:** sonraki-tur yankıları — kalan Borç bir Antlaşma talebi olarak geri dönebilir; yozlaşmış bir kart erken ödülde damgalı olarak çıkabilir. Masa yaptığını hatırlar.
- **Ev Varyantları:** alternatif ev-kuralı listeleri açılır, rota matematiğini değiştirir.
- **Günlük Masa:** tohumlu tur, ortak liderlik tablosu. Herkese aynı dağıtım — beceri tek değişken.
- **Yüksek Bahisçi modu** (temizleme sonrası): birikimli Ev Kurallarıyla sonsuz iniş; birleştirme kademe-5'in var olduğu tek yer.

**Katı kural:** hiçbir açılım +stat veya +can vermez. Açılımlar *kendini riske atmanın yeni yollarını* verir.

---

# 15. DENGE İLKELERİ

## 14.1 Beş regülatör
1. **Perdeler (ante saati)** — her savaş kendi kendini bitirir; hiçbir oyalanma stratejisi 16. turu atlatamaz.
2. **Masa Adabı** — her mühür/yetenek turda en fazla 3 kez tetiklenir. Sonsuz motorlar sprinttir.
3. **Kopya vergisi** — 3.+ kopyalar +1 çip ister. Tek kartlık deste taşması olmaz.
4. **Ruh Çekimi** — boş deste çekim başına 2 çip kanatır. İnce keskindir ama kırılgandır.
5. **Karşı vektör yasası** — her mühür adı konmuş bir karşı önlemle gelir. Hiçbir şey koşulsuz en iyi değildir.

## 14.2 Baskın-strateji savunması
- **Maça bağlılığı** ham gücü deste-şekli taahhüdünün arkasına koyar.
- **Bahis Dul'u** ve **uyarlanabilir Çukur masaları** tek-notalı build'leri meta seviyede cezalandırır.
- **Ödül Pası** "kartı almamayı" gerçek strateji yapar — deste entropisi kısıtlılıkla savaşılır.

## 14.3 Savunma-build savunması
- Boş-kulvar hasarı + Perdeler, saf duvarları saate karşı kaybettirir.
- Arka sıra ekonomi kuleleri yavaş öder; ante enflasyonu onları geçer.
- Savunma *dönüştürmek* zorunda (kurban yakıtına dönen Mum Derisi duvarları, Koro Sülüğü çip pilleri) — asla sadece direnmek değil.

## 14.4 Tek-kart-çözüm savunması
- Mühür slotları, birleştirme kademe tavanları, Çatlama riski, dövme Borcu — tek beden her şey olamaz.
- Boss kural değişiklikleri özellikle tek-eksenli destelere düşmandır (Krupiye tahtaları siler; Boşluklu Kral mezarları yer; Tahsildar statları umursamaz).

## 14.5 Sayı felsefesi
- Hep küçük tam sayılar: Saldırı 0–6, Savunma 1–8, çipler onluk. Büyük sayı enflasyonu okunabilir riski öldürür.
- Her bedel *hissedilebilir* olmalı: bir bedel duraksama olarak ifade edilemiyorsa — bir tereddüt — ya çok küçük ya çok karmaşıktır.

---

# 16. UZUN VADELİ TEKRAR OYNANABİLİRLİK PLANI

- **Sistemik derinlik:** kapalı yerleşim + pot + borç = her savaşta yeniden birleşen üç örtüşen karar katmanı; Ev Kuralları denklemi node başına yeniden karar.
- **İçerik pisti:** maçalar/arketipler modüler — yeni maçalar (Dikenler? Çanlar?) çerçeveyi yeniden dengelemeden yerleşir.
- **Tohumlar & Günlük Masa** yayın/yarışma oyunu için.
- **Damga merdiveni** (ascension) + veteranlar için **Yüksek Bahisçi** sonsuz mod.
- **Şeytan'ın Hafızası** hikâye kampanyası olmadan turlar arası anlatı kalıcılığı yaratır.
- **İçerik temposu:** çeyrek yıllık "Kasa Genişlemeleri" — yeni maça kümesi + boss + ev-kuralı paketi; çerçeve bunun için kuruldu.
- **Topluluk kancaları:** tohum paylaşımı, haftanın kombosu vitrinleri, liderlik çukurları — oyun hakkında *tartışılmak istenir*.

---

# 17. TEKNİK & SUNUM GEREKSİNİMLERİ (mekanikle ilişkili)

- **Motor:** Godot 4.x önerilir (proje ekosistemiyle uyumlu, güçlü 3D + Control UI, GLB hattı). Unity uygulanabilir alternatif. *(Aset tarama raporlarından sonra kesinleşir — doğrulama için işaretlendi.)*
- **Masa gerçek bir 3D sahnedir.** Kartlar, çipler, mum, terazi, objeler mesh'tir — asla arka plan resminin üstüne yapıştırılmış sprite değil. Çuha fizikseldir.
- **Her şey animasyonludur:** kart çevirmeleri (3D flip-açılış), çip dizme fiziği, mum titremesi shader'ları, kurban çözünme/yanma efektleri, açılış vurguları, pot dökme. Bu oyun için "basit kart oyunu" sunumu tasarım başarısızlığıdır.
- **İlk günden çift dil:** tüm kart metinleri, UI, ev kuralları, olaylar, ipuçları **TR + EN** — Godot çeviri (.po/.csv) ile; metin anahtarları şimdi tasarlanır, sonra değil.
- **Veri-odaklı kartlar:** kart = veri (anatomi alanları) + mühür scriptleri; tüm kart havuzu içerik-adreslenebilir ve mod'lanabilir.


---

# 18. OLAY & SENARYO ÇATISI — "ODAYI ŞEYTAN YAZAR"

> **Üretim ilkesi.** Bu oyunun gücü kaç hikâye olduğu değil — *aynı olayın farklı sonuçlar doğurması ve Şeytan'ın bunu kişiselleştirmesidir*. Yüzlerce senaryo yazmayız; küçük bir mekanik dil kurarız ve kombinasyonlar işi yapar (Inscryption dersi: az yazılmış parça, sonsuz keşfedilen kombo).
> **1 senaryo kartı = 1 içerik değil, değişken parametreli olay motoru.**

## 18.1 Olay Şablonu (Event Template)

Her senaryo bir **şablon**dur: bir iskelet + parametre havuzları. Motor yuvaları doldurur; tek yazılmış şablon oyuncuya düzinelerce farklı olay gibi görünür.

| Yuvalama | Havuz | Örnekler |
|---|---|---|
| **Tehlike tipi** | 5 | Fiziksel · Zihinsel · Ruhsal · Sosyal · Zamansal |
| **Tehdit** | ~20 | Düşme · Zehir · Lanet · İhanet · Hafıza kaybı |
| **Bedel** | ~20 | Çip kaybı · Kart kaybı · Günah artışı · Gelecek tur dezavantajı |
| **Kurtuluş yolu** | ~20 | Güç kartı · Fedakarlık · Blöf · Risk alma · Özel kombinasyon |
| **Sonuç/Çeşni** | ~20 | Temiz kaçış · Pirus zaferi · Şeytan'ın merhameti · İkiye katla |

Tek iskelet — "Kırık Köprü" — şunlara dönüşür: *Sisli Köprü* (zihinsel: blöfle geç), *Cehennem Köprüsü* (ruhsal: günah öde), *Ruh Köprüsü* (bedel: bir kart), *Zaman Köprüsü* (zamansal: perdeye karşı yarış). Oyuncu dört farklı olay algılar; biz bir tane yazarız.

**Üretim matematiği:** 50 şablon × yuva başına ~20 varyasyon = *farklı hissedilen* 1000+ olay — 50 yazıyla.

Kök arketipler (her şablonun türediği "fiiller"): **Tuzak · Pazarlık · Lanet · Test · Kurban · İhanet · Kumar · Son Tarih**.

## 18.2 Şeytan Psikolojisi — içerik üreten sistem

Şeytan'ın davranışları yazılmış replikler değil, ayrı bir sistemdir. Adı **Azrail** — "Şeytan" onun ne olduğu; Azrail kim olduğu ve kişilik sistemi onu *kişisel* hissettiren şeydir. Nasıl oynadığına göre mutasyona uğrayan beş kişilik ekseni:

| Eksen | Ne zaman yükselir | Şeytan'ın tepkisi |
|---|---|---|
| **Cruelty (Zalimlik)** | tereddüt, pas, korku | *"Seçmeyeceğini biliyordum."* — avantajı sıkar, korkaklığını yüzüne vurur |
| **Curiosity (Merak)** | alışılmadık hamleler | *"İlginç…"* — garip masa kurallarıyla seni yoklar |
| **Anger (Öfke)** | hile, Koz kullanımı | kart çalar, tur ortasında kuralı değiştirir, ante'yi kaçak artırır |
| **Respect (Saygı)** | temiz risk, iyi oyun | *"Hm."* — daha zor ama adil oynar; daha iyi pazarlıklar açar |
| **Boredom (Can sıkıntısı)** | kaplumbağa oyunu, tekrar | potu karıştırır, perdeleri erken sıçratır, sataşır |

**Gerçekleme:** ~20 temel davranış (kart çalma, yeniden ante, pasa gülme, blöfü ödüllendirme, sahte merhamet…) × beş eksenli durum × mevcut şablon = binlerce kişisel an. ~50 kişilik kuralı + ~30 özel Şeytan olayı yazarız; varyasyon motoru (platform izin verirse LLM ses katmanı) gerisini getirir. 1000 satırlık diyalog ağacı yok.

## 18.3 Yedi Günah — bölüm değil, sahneli boss'lar

Her Günah 3 perdelik bir yay, 50 ayrı olay değil:

| Perde | İçerik | Görevi |
|---|---|---|
| **Giriş** | 5 olay | Günahın mekaniğini öğretir |
| **Derinlik** | 5 olay | İter, adaptasyon ister |
| **Final** | 1 özel boss olayı | Günahın bedenlenişi — tek, yazılmış |

7 günah × 11 = boss omurgasının tamamı için **77 yazılmış içerik**.

## 18.4 Kart–senaryo bağlaşımı — asıl çeşitlilik motoru

Olaylar **desteyi, eli ve sahayı okur**. Genel cezalar kişiselleşir:

- "Yalnızlık" olayı: normalde kart çekmeyi kilitler — ama elinde **Sadık Ruh** varsa olay *kırılır*: ruh yoldaşlık eder, Şeytan kaşlarını çatar. Oyuncu hisseder: *"Bu kartı işte bunun için saklamıştım."*
- Bir **Tehdit** yuvası karta göre farklı çözülür: Kılıçlar (kanla öder), Tılsımlar (korla öder), Gözler (önceden görür — bedel düşer), Kadehler (kurban yakıtına çevirir).
- Kural: her şablon **kırıcı kartlar** (sonucunu doğrudan bozan) ve **manivela kartları** (bedelini düşüren) ilan eder. "Azrail bana güldü / son anda kurtuldum" anılarını üreten şey budur — olay sayısı değil.

## 18.5 Üretim bütçesi (tam sürüm)

| Katman | Yazılan | Efektif çeşitlilik |
|---|---|---|
| Olay şablonları | 50 | parametre havuzlarıyla 1000+ |
| Benzersiz özel olaylar | 70 | — |
| Boss olayları (günah finalleri + şeytan sahneleri) | 20 | — |
| Şeytan özel olayları | 30 | × kişilik eksenleri |
| **Toplam olay içeriği** | **~170** | **binlerce** |
| Kartlar | 120 ana + 30 özel + 20 lanetli + 20 joker = **190** | mühür/aşıyla |
| Şeytan AI | 50 kişilik kuralı | 1000+ varyasyon |

## 18.6 Mimari

```
                 ŞEYTAN (AI)
                       |
        --------------------------------
        |                              |
   Olay Üreteci                  Psikoloji Sistemi
   (şablon × havuzlar)           (5 eksen, 50 kural)
        |                              |
  Senaryo Şablonu              sataşma, ruh hali,
        |                      kural bükme
   Tehdit·Ödül·Bedel·Çeşni
        |
      Kartları okur (kırıcı/manivela)
        |
     Sonuç → hatırlanan an
```

**Turnusol testi:** Oyuncu asla *"350 olay gördüm"* dememeli; *"Şeytan bana güldü — sonra bir çiple kurtuldum"* demeli.

---

*İniş haritasındaki olay düğümleri (§7.1 — Covenant, Whisper, Wheel) bu motorla üretilir: Covenant = Bedeli Borç olan bir Pazarlık arketipi; Whisper = Şans'la açılan bir Test arketipi.*

---

*Tasarım dokümanı sonu.*
