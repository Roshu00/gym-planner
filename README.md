# Chalkline

Flutter aplikacija za kreatore treninga i njihove pratioce. Za sada sadrži **dizajn sistem** i **galeriju komponenti** u kojoj se sve komponente mogu isprobati pre izrade ekrana.

- Vizija proizvoda: [docs/VISION.md](docs/VISION.md)
- Dizajn pravila (jedini izvor istine za UI): [docs/DESIGN.md](docs/DESIGN.md)

## Pokretanje galerije

```bash
flutter pub get
flutter run -d chrome        # u browseru
flutter run                  # na telefonu ili emulatoru
```

Galerija ima prekidač za tamnu i svetlu temu, stranicu za svaku komponentu (sve varijante i stanja) i tri primera ekrana: **Danas**, **Trening** (unos setova, PR, tajmer odmora) i **Rezime**.

## Struktura

```
lib/
  config.dart               appName, jedino mesto gde piše "Chalkline"
  ui/                       dizajn sistem, uvozi se samo preko chalkline_ui.dart
    tokens/                 boje (jedini fajl sa hex vrednostima), tipografija, razmaci
    theme.dart              ClTheme, context.cl / context.clColors / context.clText
    format.dart             brojevi na srpskom: 82,5 kg · 8.240 · 80 kg × 8
    components/             ClButton, ClWorkoutHero, ClStatBar, ClSetTable, ClProgramCard, ...
  gallery/                  galerija komponenti i primeri ekrana (nije deo aplikacije)
assets/
  fonts/                    Archivo variable (wdth 62–125, wght 100–900), OFL
  icons/                    Phosphor Light i Bold, MIT
```

## Pravila za kod

- Komponente koriste samo tokene (`context.clColors`, `context.clText`, `ClSpace`, `ClRadius`), nikad hex vrednosti.
- Novu ikonu dodaj u `ClIcons` (kodna tačka iz Phosphor `style.css`), ne direktno u ekran.
- Svaka nova komponenta dobija stranicu u galeriji i ulazi u `test/gallery_test.dart`.
- Pre PR-a prođi kontrolnu listu iz `docs/DESIGN.md` §10.

## Provera

```bash
flutter analyze
flutter test                 # formatiranje + render svake stranice u obe teme na 360px
```
