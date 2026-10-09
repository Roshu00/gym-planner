# Chalkline — UX analiza: manje izbora, manje ekrana, manje pilula

Okt 2026 · @Uros

> Cilj: aplikacija koju početnik s TikToka razume bez objašnjenja. Svaki ekran ima jedan posao, svako pitanje se postavlja jednom, a sve što nije nužno je jedan dodir dalje.
> Analiza je urađena nad kodom grane `claude/new-session-1pqbhk` (commit `b99853d`) i snimcima ekrana sa simulatora.

---

## 1. Šta korisnici fitnes aplikacija vole

Ovo su opšte prihvaćeni UX principi i obrasci koje koriste aplikacije koje ljudi zaista svakodnevno otvaraju (Hevy, Strong, Apple Fitness, Duolingo za naviku). Nisu izmišljene brojke, već pravila kojima se proverava svaki ekran ispod.

| Princip | Šta znači za nas |
| --- | --- |
| **Jedno pitanje po ekranu** | Kad je jedno pitanje na ekranu, korisnik samo dodirne odgovor. Četiri pitanja na jednom ekranu traže da čita, upoređuje i proverava. |
| **Ne pitaj dvaput** | Ono što smo saznali u onboardingu nikad se ne pita ponovo. Prikazuje se kao rezime sa „Promeni“. |
| **Pametna podrazumevana vrednost** | Najbolji formular je onaj koji ne treba popunjavati. Predlažemo, korisnik samo potvrđuje. |
| **Manje opcija = brža odluka** (Hikov zakon) | Svaka dodatna opcija usporava odluku. Pokaži 2–3 najčešće, ostalo iza „Više“. |
| **Postepeno otkrivanje** | Početnik vidi osnovno. RIR, 1RM, pauze i ručne izmene postoje, ali ne na prvom ekranu. |
| **Lista, ne oblak** | Opcije jedna ispod druge, cela širina, veliki cilj za prst (56px). Oblak pilula u više redova se teže skenira i liči na tagove, ne na pitanje. |
| **Jedan dodir do treninga** | Najvažnija akcija (Počni trening, Završi set) je uvek dole, u zoni palca, i nikad nema konkurenciju. |
| **Pamti umesto mene** | Prošli rezultat je već upisan. Završen set = jedan dodir. (Ovo već radimo dobro.) |
| **Isti pojam, isto ime** | „Pomeri za sutra“ i „Pomeri za dan“ su za korisnika dve različite stvari. Jedan pojam, jedno ime, svuda. |
| **Pohvala, ne kazna** | Već je u našim principima. Zadržati. |

---

## 2. Zašto pilule deluju komplikovano

Ekran „Pronađi plan“ je najbolji primer. Problem nije boja, već pristup:

1. **Sve je pilula.** Dugmad, filteri, tagovi, akcije (`ClActionChip`), stikeri i izbor u formularu imaju isti oblik. Kad sve izgleda isto, oko ne zna šta je pitanje, šta odgovor, šta oznaka, a šta dugme.
2. **Četiri pitanja odjednom.** Korisnik mora da pročita 4 naslova i 17 opcija pre nego što stigne do dugmeta.
3. **Neravni redovi.** Pilule se prelamaju po dužini teksta („Opšta forma“ sama u drugom redu), pa nema reda u kom se čita.
4. **Već izabrano, a ipak pitano.** Sve četiri vrednosti su unapred popunjene iz profila. Korisnik gleda formular koji je već rešen i pita se šta treba da uradi.
5. **Mali ciljevi.** Filter je visok 36px, ispod preporučenih 44–48px.
6. **Nedosledno.** Onboarding ista pitanja (cilj, nivo, mesto) postavlja kao velike redove (`ClOptionRow`), a „Pronađi plan“ kao pilule.

**Pravilo za dalje:**
- Pilula ostaje samo za **dugme**.
- Izbor jedne opcije = **lista redova** (ceo red se dodiruje, kvačica desno). Kad je izbor jasan, odmah prelazi dalje, bez „Dalje“.
- Izbor više opcija (oprema) = **lista redova sa kvačicama**, ne oblak.
- Tag = **običan tekst u meta redu** („Snaga · 8 nedelja · 3×“), ne niz pilula. Najviše jedna istaknuta oznaka po kartici.
- Brze akcije nad danom = **jedno dugme „Promeni dan“** koje otvara listu, ne red od 6 pilula.

---

## 3. Analiza po delovima aplikacije

Za svaki deo: šta je sada, šta smeta, predlog. Prioritet: **P1** odmah (velika korist, malo posla), **P2** sledeće, **P3** kasnije.

### 3.1 Navigacija (5 tabova)

**Sada:** Danas · Plan · Otkrij · Napredak · Profil. Plan postoji na tri mesta: tab Plan, ekran „Moj plan“ (sa Danas) i „Program i zamene vežbi“ (sa Plana), i sve troje vode do sličnih stvari.

**Smeta:** pet tabova za aplikaciju čiji je glavni posao „uradi današnji trening“. Napredak i Profil su oba „ja i moji brojevi“.

**Predlog (P2):** četiri taba: **Danas · Plan · Otkrij · Ja**. „Ja“ = napredak na vrhu (niz, rekordi, grafikon), podešavanja ispod u meni grupama. Ekrane „Moj plan“ i „Program i zamene vežbi“ spojiti u jedan, dostupan samo iz taba Plan.

### 3.2 Onboarding (6 koraka)

**Sada:** Ime → Pol → Cilj → Iskustvo → Gde treniraš → Oprema. Tek posle toga korisnik vidi aplikaciju, a plana još nema. `daysPerWeek` je fiksno 3, pa se dani pitaju tek u „Pronađi plan“.

**Smeta:**
- Šest koraka pre prve vrednosti. Korisnik je došao s reela, motivacija mu traje kratko.
- **Pol** se pita samo zbog gramatike („stao/stala“). To je osetljivo pitanje bez vidljive koristi za korisnika.
- **Oprema** je oblak pilula, a za većinu je dovoljna podrazumevana vrednost iz „Teretana / Kod kuće“.
- Dani nedeljno nedostaju, iako su bitni za plan.
- Svaki korak traži i dodir na „Dalje“, iako je izbor jedan.

**Predlog (P1):** četiri koraka, svaki jedno pitanje, izbor odmah ide dalje:
1. **Ime** (tastatura, „Dalje“).
2. **Cilj** — 4 reda.
3. **Iskustvo** — 3 reda s kratkim objašnjenjem (već postoji).
4. **Gde i koliko** — „Teretana / Kod kuće“, pa „Koliko dana nedeljno?“ kao 3 reda (2–3 · 3–4 · 5+), ne 5 pilula.

Pa odmah **gotov plan** (vidi 3.3).
- **Pol:** izbaciti iz onboardinga. Tekstovi se pišu neutralno („Trening završen.“, „Nastavi gde je stalo.“), a pol ostaje opcioni u Profilu za one koji žele obraćanje u rodu.
- **Oprema:** ne pitati. Podrazumeva se po mestu, a menja se u Profilu ili kad zamena vežbe zatreba („Nemaš šipku? Izaberi šta imaš“).
- Ako je korisnik došao **linkom trenera**, preskočiti sve osim imena i odmah ponuditi program tog trenera.

### 3.3 Pronađi plan

**Sada:** formular sa 4 grupe pilula (cilj, nivo, mesto, dani), dugme „Pronađi“, pa lista programa sa procentom („87%“) i nizom tagova razloga.

**Smeta:** sve je već odgovoreno u onboardingu. Procenat bez objašnjenja ne znači ništa („87% čega?“). Lista bez jasnog pobednika vraća korisnika na upoređivanje.

**Predlog (P1):**
- **Bez formulara.** Ekran se otvara odmah sa rezultatom.
- Na vrhu jedan red-rezime: „Snaga · Početnik · Teretana · 3× nedeljno“ i tekstualno dugme **Promeni**. Ono otvara sheet sa istim pitanjima kao onboarding, jedno ispod drugog, kao liste.
- **Jedna preporuka velika** (kartica programa, trener, 1 rečenica zašto: „Za početnike, 3 dana, sve vežbe možeš u teretani“) i dugme **Počni ovaj plan**.
- Ispod „Još 2 opcije“ kao obični redovi. Bez procenata. Ako je rangiranje potrebno, reč umesto broja („Najbolje se uklapa“).

### 3.4 Danas

**Sada (sa planom):** pozdrav, velika pop kartica treninga sa stikerom, red od 3–4 akcija (Kraća verzija, Pomeri za sutra, Odmor danas, Vrati na plan), druga pop kartica sa nedeljom i nizom, naslov plana + „Moj plan“, lista vežbi, dugme Počni trening.

**Dobro:** jedan jasan dan, prošli rezultat uz svaku vežbu, „Počni trening“ dole.

**Smeta:**
- Tri-četiri pilule akcija odmah ispod treninga. Većinu dana niko ih ne koristi, a svakog dana ih čita.
- Dve pop kartice jedna ispod druge plus stiker. Pažnja se deli.
- „Niz 3 ned.“ je skraćenica koju treba dešifrovati.

**Predlog (P1):**
- Akcije zameniti jednim tekstualnim dugmetom **Promeni današnji dan** → sheet sa listom (vidi 3.5). „Vrati na plan“ se pojavljuje samo kad je dan izmenjen, kao poruka u kartici („Kraća verzija · Vrati“).
- Nedelju i niz spustiti u **jedan red** ispod kartice treninga: „2 od 3 ove nedelje · 4 nedelje zaredom“ sa tankim segmentima, bez druge pop kartice.

**Prvo otvaranje (bez plana)** — **P1:** sada su tu pop kartica, karusel programa, karusel trenera i „Kako radi“. Ako onboarding završi gotovim planom (3.2), ovo stanje skoro nestaje. Ako ostane: jedna kartica „Tvoj plan je spreman“ + dugme, a trenere i programe pustiti u Otkrij.

### 3.5 Plan (kalendar i izmene dana)

**Sada:** mesečni kalendar sa 5 vrsta dana i legendom. Ispod izabranog dana je do 6 pilula: Odmor, Pomeri za dan, Kraća verzija, Drugi trening, Izmeni vežbe, Pauza. Na Danas su iste akcije pod drugim imenima. Na dnu su meni „Dani treninga“ i „Program i zamene vežbi“.

**Smeta:**
- Šest ravnopravnih opcija. „Odmor“ i „Pomeri za dan“ zvuče slično, a rade različito (jedno gura ceo plan, drugo menja samo ovu nedelju). Razliku korisnik ne može da nasluti iz dva reči.
- Mesec je previše za „šta radim ove nedelje“. Legenda je znak da kalendar sam nije dovoljno jasan.
- Imena se razlikuju od Danas („Pomeri za sutra“ / „Pomeri za dan“, „Odmor danas“ / „Odmor“).

**Predlog:**
- **P1:** jedno dugme **Promeni dan** → sheet sa listom. Na vrhu su 3 najčešće opcije, svaka sa jednom rečenicom šta se dešava:
  - **Danas ne mogu** → pomera trening na sledeći slobodan dan (spaja „Odmor“ i „Pomeri za dan“; aplikacija bira pametniji ishod).
  - **Kraći trening** → ~30 min.
  - **Drugi trening**.
  - Ispod „Više“: Izmeni vežbe, Pauza (više dana).
- **P1:** ista imena na Danas i na Planu.
- **P2:** podrazumevani prikaz je **nedelja** (7 dana u redu, ispod lista dana sa imenom treninga). Mesec se otvara dugmetom „Mesec“. Legenda nestaje jer je ime treninga upisano uz dan.

### 3.6 Trening (set po set)

**Sada:** naslov vežbe + propis, kreator, tabela setova (# · prošli put · kg · pon. · RIR · ✓), tajmer odmora, lista svih vežbi, dugme dole koje se menja (Završi set → Sledeća vežba → Završi trening). Zamena vežbe je na dva mesta (ikona + meni).

**Dobro:** prazno polje uzima prošli rezultat, pa je set jedan dodir. Odmor kreće sam. PR se vidi odmah. Ovo je srce aplikacije i najbolji deo.

**Smeta:**
- **RIR kolona** za početnika je nepoznat pojam i jedno polje više u svakom redu.
- Prvi put na vežbi kg je prazno i aplikacija javlja grešku „Upiši težinu“ tek posle dodira.
- „Završi trening“ se vidi na dva mesta dok trening traje.
- Gornja traka je duga („Push A · Vežba 2 / 6“) i ima dve ikone sa preklapajućim akcijama.

**Predlog:**
- **P1:** RIR sakriti za početnike (`showRir: false`), a uključiti u Profilu („Napredno beleženje“) ili automatski za napredne.
- **P1:** zamena vežbe samo u meniju „⋯“ (jedna ikona gore).
- **P2:** prvi put na vežbi predložiti početnu težinu po nivou i opremi (ili „Prazna šipka“), tako da ni prvi set ne traži kucanje.
- **P2:** gornja traka = samo „2 / 6“ i progres segmenti. Ime treninga je ionako na prethodnom ekranu.
- **P3:** listu svih vežbi skupiti ispod dugmeta „Sve vežbe (6)“; sada gura sadržaj i takmiči se sa tabelom.

### 3.7 Kraj treninga (rezime)

**Sada:** share kartica („Pojavio si se.“, volumen, rekordi, niz), poruka trenera, vežbe, dugme „Gotovo“.

**Smeta:** kartica je napravljena za Instagram story, ali dugme za deljenje ne postoji. Korisnik mora sam da napravi snimak ekrana. Volumen u kg početniku malo znači.

**Predlog:**
- **P1:** dugme **Podeli na story** pored „Gotovo“. Ovo je naša petlja rasta (pratilac taguje trenera → novi pratioci).
- **P2:** umesto volumena za početnike prikazati „Trajanje“ ili „Setova“. Volumen ostaje za napredne.

### 3.8 Otkrij

**Sada:** tabovi „Otkrij / Biblioteka“, dugme „Pronađi plan za sebe“, filteri u sheetu, karusel trenera, mreža programa sa tagovima („Oprema 80%“).

**Smeta:** dve stvari na jednom tabu (tuđe i moje). Filteri + „Pronađi plan“ + tabovi = tri načina da se traži isto.

**Predlog:**
- **P2:** Otkrij = samo **treneri**, pa njihovi programi. „Pronađi plan“ i filteri se spajaju: jedan red-rezime sa profila (kao 3.3) koji sortira listu.
- **P2:** „Biblioteka“ (programi, treninzi i vežbe praćenih trenera) prelazi na profil svakog trenera. Pratilac ide „trener → sadržaj“, ne „sav sadržaj u jednoj polici“.
- **P2:** na kartici programa najviše trener + 1 meta red. Bez nizova tagova.

### 3.9 Program i trener (detalji)

**Sada:** program ima statistike, procenat opreme, tagove „Zamena opreme“ u crvenoj (danger) boji i objašnjenje zamena. Trener ima statistike, pretplatu i Zaprati, programe.

**Smeta:** crvena boja za „Zamena opreme“ zvuči kao greška, a zapravo je funkcija koja pomaže.

**Predlog:**
- **P1:** neutralan tekst bez crvene: „Prilagođeno tvojoj opremi“. Crvena samo za brisanje i greške.
- **P2:** na trenerovom profilu jedno glavno dugme: „Pretplati se“ ako nije pretplaćen, inače „Počni program“. „Zaprati“ kao sekundarno.

### 3.10 Napredak

**Sada:** niz, treninzi, rekordi, grafikon nedeljnog volumena, grafikon po vežbi („procenjeni 1RM“), istorija.

**Smeta:** „1RM“ i „volumen“ su žargon. Za početnika je najbitnije „da li dižem više nego pre mesec dana“.

**Predlog (P2):** na vrhu jedna rečenica napretka („Čučanj: +10 kg od početka“), pa niz. Grafikoni sa jednostavnim imenima („Najteži set“ umesto „Procenjeni 1RM“). 1RM i volumen ostaju za napredne.

### 3.11 Profil

**Dobro:** podešavanja su već u meni grupama i sheetovima, a ekran je pregledan.

**Predlog (P3):** kad se spoji sa Napretkom (3.1), dodati „Napredno beleženje (RIR)“ i „Obraćanje (pol)“ u Podešavanja.

### 3.12 Prijava

**Dobro:** email + kod, bez lozinke, i „Probaj bez naloga“. To je najjednostavniji mogući tok, zadržati.

**Predlog (P3):** „Sačuvaj nalog“ ponuditi u pravom trenutku (posle 1. ili 3. treninga, na rezimeu), ne samo u Profilu.

### 3.13 Režim kreatora

Ova publika je drugačija (trener na telefonu). Tok je već vođen („Počni od vežbi → treninzi → program“).

**Predlog (P3):** kasnije razmotriti da trener prvo napravi **program**, a vežbe i treninzi nastaju usput, jer tako trener razmišlja. Za sada van fokusa pratilačkog UX-a.

---

## 4. Rečnik: jedan pojam, jedno ime

| Umesto | Koristiti |
| --- | --- |
| program / plan (mešano) | **Program** = trenerov. **Plan** = moj (program + moji dani i izmene). |
| kreator / trener | Korisniku uvek **trener**. „Kreator“ samo u režimu kreatora. |
| Odmor / Odmor danas / Pomeri za dan / Pomeri za sutra | **Danas ne mogu** (jedna akcija) |
| Kraća verzija | **Kraći trening** |
| Niz 3 ned. | **3 nedelje zaredom** |
| RIR | Sakriveno za početnike. Za ostale: „Još ponavljanja (RIR)“ sa objašnjenjem na dodir. |
| Procenjeni 1RM | **Najteži set** ili „Snaga“ |
| 87% za tebe | **Najbolje se uklapa** (samo kod prvog) |

---

## 5. Redosled rada

**P1 — brze pobede (bez nove arhitekture):**
1. Pronađi plan bez formulara: rezime iz profila + jedna preporuka.
2. Onboarding sa 4 koraka, izbor odmah ide dalje, bez pola i opreme, sa danima nedeljno.
3. „Promeni dan“ kao jedan sheet, sa istim imenima na Danas i Planu.
4. RIR sakriven za početnike, zamena vežbe na jednom mestu.
5. Dugme „Podeli na story“ na rezimeu.
6. „Zamena opreme“ bez crvene boje.
7. Pravilo dizajna: pilula samo za dugme, izbor = lista redova (dopuniti `DESIGN.md`).

**P2 — struktura:**
4 taba (Ja = Napredak + Profil), nedeljni prikaz plana, Otkrij samo treneri, Biblioteka na profilu trenera, jednostavniji Napredak, predlog prve težine.

**P3 — kasnije:**
Sačuvaj nalog u pravom trenutku, režim kreatora od programa, sklopiva lista vežbi u treningu.

## 6. Kako merimo da je jednostavnije

Veže se na metrike iz `VISION.md`:
- **Vreme od otvaranja do prvog „Počni trening“** (cilj: ispod 60 s).
- Broj dodira u onboardingu (sada ~12 sa poljem i „Dalje“; cilj ~6).
- Udeo korisnika koji završe prvi trening u 48 h.
- Koliko se „Promeni dan“ koristi i koje opcije: ako se „Više“ skoro ne otvara, opcije iza njega se mogu izbaciti.
