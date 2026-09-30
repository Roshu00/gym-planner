# Chalkline

Flutter aplikacija u kojoj fitnes kreatori objavljuju svoj sistem treninga, a pratioci po njemu treniraju set po set i prate napredak.

- Vizija proizvoda: [docs/VISION.md](docs/VISION.md)
- Dizajn pravila (jedini izvor istine za UI): [docs/DESIGN.md](docs/DESIGN.md)

## Pokretanje

```bash
flutter pub get
flutter run -d chrome                                            # lokalni demo, bez servera
flutter run -d chrome --dart-define-from-file=supabase.json      # sa Supabase nalozima
flutter run -d chrome -t lib/main_gallery.dart                   # galerija komponenti
```

Bez `supabase.json` aplikacija radi u lokalnom demo režimu: bez naloga, podaci ostaju na uređaju, demo treneri su u kodu.

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

## Supabase

### Šta radi

- **Prijava:** email i kod od 6 cifara (bez lozinke i bez linkova koji se lome na telefonu), ili „Probaj bez naloga” (anonimni gost). Gost kasnije čuva nalog emailom i zadržava sve podatke.
- **Pristup (Row Level Security):** katalog trenera i stranice programa vide svi. Vežbe i treninzi „za pretplatnike” vide se samo uz pretplatu ili kao vlasnik. Profil, plan, treninzi, praćenja i pretplate vidi i menja samo vlasnik. Profil trenera može da napravi samo nalog sa emailom, ne gost.
- **Rad bez interneta:** svaka izmena se prvo primenjuje i čuva na uređaju, pa ide u red za slanje (`lib/data/sync.dart`). Red preživljava restart, šalje se po redu, a uzastopne izmene istog reda se spajaju. Trening radi i u teretani bez signala. Ako server odbije izmenu, ona se izbacuje iz reda i korisnik dobija poruku.
- **Istorija:** treninzi čuvaju snimak imena i propisa i nemaju strane ključeve ka sadržaju trenera, pa ostaju tačni i kad trener nešto izmeni ili obriše.

### Podešavanje projekta

1. Napravi projekat na [supabase.com](https://supabase.com).
2. Primeni šemu, demo sadržaj i podešavanja prijave (Supabase CLI):
   ```bash
   npx supabase login
   npx supabase link --project-ref <ref-projekta>
   npx supabase db push --include-seed   # supabase/migrations + supabase/seed.sql
   npx supabase config push              # uključuje gost prijavu i email šablone sa kodom
   ```
   Bez CLI-ja: u SQL editoru pokreni `supabase/migrations/*.sql`, pa `supabase/seed.sql`. U *Authentication → Sign In / Providers* uključi *Anonymous sign-ins*. U *Authentication → Email Templates* stavi sadržaj `supabase/templates/code.html` u *Magic Link* i *Confirm signup*, a `email_change.html` u *Change Email Address*. Šabloni moraju sadržati `{{ .Token }}`.
3. Kopiraj `supabase.example.json` u `supabase.json` (ne ide u git) i upiši *Project URL* i *Publishable key* iz *Project Settings → API Keys*.
4. Za produkciju podesi sopstveni SMTP (*Authentication → SMTP Settings*). Ugrađeni Supabase mejler šalje samo nekoliko poruka na sat.

### Provera baze

`tool/test_db.sh` pravi praznu Postgres bazu sa minimalnom zamenom za Supabase `auth` šemu, primenjuje migracije i seed, i pokreće `supabase/tests/rls_test.sql`. Ta skripta kao pravi korisnici proverava sva pravila pristupa, ograničenja i tačne upite koje šalje klijent.

```bash
PGHOST=... PGPORT=... PGUSER=postgres tool/test_db.sh
```

Demo sadržaj ima jedan izvor, `lib/data/seed.dart`. Posle izmene pokreni `dart run tool/gen_seed.dart`; test pada ako `supabase/seed.sql` zaostaje.

## Šta još nije tu

- **Plaćanje.** Pretplata se aktivira bez naplate, a ekran to jasno kaže. Korisnik sam upisuje red u `subscriptions`; to pravilo je u migraciji označeno kao privremeno i treba ga zameniti webhookom plaćanja sa service role ključem.
- **Brisanje naloga.** „Obriši moje podatke” briše sve redove korisnika. Sam nalog (`auth.users`) briše se service role ključem, npr. iz Edge funkcije.
- **Fotografije i video trenera.** Dok ih nema, zaglavlja i kartice programa su blokovi boja, po DESIGN.md.
- **Demo sadržaj.** Tri trenera bez naloga i pet programa (`lib/data/seed.dart` → `supabase/seed.sql`). Pravi treneri dolaze kroz režim kreatora.

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
    sync.dart               mutacije, red za slanje, interfejs prema serveru
    supabase_backend.dart   Supabase: podaci, prijava, mapiranje grešaka
    rows.dart               domen ↔ redovi baze
    auth.dart               prijava (interfejs)
    storage.dart            lokalni keš
    seed.dart               demo treneri i programi (izvor za supabase/seed.sql)
  app/                      ekrani (svaki u temi koju mu DESIGN.md dodeljuje)
  ui/                       dizajn sistem, uvozi se samo preko chalkline_ui.dart
  gallery/                  galerija komponenti i primeri ekrana
supabase/
  migrations/               šema, RLS pravila
  seed.sql                  generisan iz lib/data/seed.dart
  templates/                email šabloni sa kodom
  tests/                    RLS testovi za tool/test_db.sh
assets/
  fonts/                    Bricolage Grotesque (text i display rez), OFL
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
flutter test         # domen, stanje, sinhronizacija, prijava, svi ekrani u obe teme na 360px, celi tokovi
tool/test_db.sh      # šema i RLS pravila na pravom Postgresu
```
