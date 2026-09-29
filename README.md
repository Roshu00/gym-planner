# Chalkline

Flutter aplikacija u kojoj fitnes kreatori objavljuju svoj sistem treninga, a pratioci po njemu treniraju set po set i prate napredak.

- Vizija proizvoda: [docs/VISION.md](docs/VISION.md)
- Dizajn pravila (jedini izvor istine za UI): [docs/DESIGN.md](docs/DESIGN.md)

## Pokretanje

```bash
flutter pub get
flutter run -d chrome                           # aplikacija u browseru
flutter run                                     # na telefonu ili emulatoru
flutter run -d chrome -t lib/main_gallery.dart  # galerija komponenti
```

Link trenera `/c/<korisnicko.ime>` (npr. `/c/jelena.moves`) otvara profil tog trenera posle onboardinga.

## Šta MVP radi

**Pratilac**
- Onboarding: ime, cilj, iskustvo, gde trenira, oprema, dani nedeljno.
- **Danas:** sledeći trening iz plana, niz nedelja, nedeljni cilj, pregled vežbi, jedno dugme.
- **Trening set po set:** prošli rezultat, unos kg / ponavljanja / RIR, prazna polja uzimaju prošli rezultat ili prethodni set, tajmer odmora posle potvrde, PR odmah, zamena vežbe, dodavanje setova.
- **Rezime:** „Pojavio si se.”, volumen, rekordi, poruka trenera.
- **Otkrij:** treneri i programi sa filterima (mesto, nivo, cilj) i uklapanjem u opremu.
- **Profil trenera i pretplata:** javni sadržaj je slobodan, sadržaj za pretplatnike se otključava pretplatom.
- **Moj plan:** kopija programa; vežbe za koje korisnik nema opremu automatski dobijaju zamenu, koja se može promeniti; plan ne zavisi od datuma.
- **Biblioteka:** programi, treninzi i vežbe trenera koje korisnik prati.
- **Napredak:** nedeljni volumen, napredak po vežbi (procenjeni 1RM), cela istorija.
- **Profil:** nedeljni cilj, oprema, pretplate, plan, brisanje podataka.

**Kreator**
- Profil trenera i link za biografiju.
- Vežbe (mišićna grupa, oprema, napomena), treninzi (setovi, ponavljanja, odmor, poruka posle treninga), programi (nedelje, rotacija treninga, nivo, cilj, mesto).
- Svaki sadržaj je javan ili samo za pretplatnike.

## Šta još nije tu

- **Backend i nalozi.** Podaci se čuvaju na uređaju (`shared_preferences`). `KeyValueStore` u `lib/data/storage.dart` je mesto gde se kači server.
- **Plaćanje.** Pretplata se aktivira bez naplate, a ekran to jasno kaže.
- **Fotografije i video trenera.** Svuda je tamni okvir „FOTO TRENERA”, po DESIGN.md.
- **Demo sadržaj.** Tri trenera i pet programa u `lib/data/seed.dart`, dok ne postoji backend.

## Struktura

```
lib/
  main.dart                 aplikacija
  main_gallery.dart         galerija komponenti
  config.dart               appName, jedino mesto gde piše "Chalkline"
  domain/
    models.dart             Exercise → Workout → Program → UserPlan → Session
    rules.dart              niz nedelja, rekordi, prošli rezultat, oprema, zamene (čiste funkcije)
  data/
    app_store.dart          stanje aplikacije i sve radnje
    storage.dart            gde se stanje čuva
    seed.dart               demo treneri i programi
  app/                      ekrani (svaki u temi koju mu DESIGN.md dodeljuje)
  ui/                       dizajn sistem, uvozi se samo preko chalkline_ui.dart
  gallery/                  galerija komponenti i primeri ekrana
assets/
  fonts/                    Archivo variable (wdth 62–125, wght 100–900), OFL
  icons/                    Phosphor Light i Bold, MIT
```

## Pravila za kod

- Ekrani koriste samo komponente i tokene dizajn sistema, nikad hex vrednosti.
- Pravila domena (rekordi, niz, zamene) žive u `domain/rules.dart` i imaju testove.
- Sesija treninga čuva snimak imena i propisa, pa istorija ostaje tačna kad trener promeni sadržaj.
- Svaka nova komponenta dobija stranicu u galeriji; svaki novi ekran ulazi u `test/app_test.dart`.
- Pre PR-a prođi kontrolnu listu iz `docs/DESIGN.md` §10.

## Provera

```bash
flutter analyze
flutter test    # domen, stanje, svi ekrani u obe teme na 360px, ceo tok od onboardinga do rezimea
```
