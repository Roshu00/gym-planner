import 'package:flutter/material.dart';

import '../config.dart';
import '../ui/chalkline_ui.dart';
import 'examples.dart';
import 'sections.dart';

final galleryTheme = ValueNotifier<Brightness>(Brightness.light);

class GalleryApp extends StatelessWidget {
  const GalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: galleryTheme,
      builder: (context, brightness, _) {
        final theme = brightness == Brightness.dark ? ClTheme.dark : ClTheme.light;
        return MaterialApp(
          title: '$appName · Dizajn sistem',
          debugShowCheckedModeBanner: false,
          theme: theme.toThemeData(),
          home: const GalleryHome(),
        );
      },
    );
  }
}

class GallerySection {
  const GallerySection(this.title, this.meta, this.builder, {this.theme});

  final String title;
  final String meta;
  final WidgetBuilder builder;

  /// Examples render in the theme DESIGN.md assigns to that screen.
  final ClTheme? theme;
}

final _foundations = [
  GallerySection('Boje', 'Tokeni, tamna i svetla tema', (_) => const ColorsPage()),
  GallerySection('Tipografija', 'Bricolage Grotesque', (_) => const TypographyPage()),
  GallerySection('Razmaci i oblici', 'Space, radius, veličine', (_) => const SpacingPage()),
  GallerySection('Ikone', 'Phosphor Regular i Fill', (_) => const IconsPage()),
];

final _components = [
  GallerySection('Button', 'Primary, ink, secondary, text, block', (_) => const ButtonsPage()),
  GallerySection('Tag i Filter', 'PR, outline, danger, filteri', (_) => const TagsPage()),
  GallerySection('Avatar i foto', 'Avatar, photo-empty, scrim', (_) => const MediaPage()),
  GallerySection('Blokovi boja', 'PopBlock, Sticker, kartica za story', (_) => const PopPage()),
  GallerySection('WorkoutHero', 'Fotografija trenera s naslovom', (_) => const HeroPage()),
  GallerySection('StatBar', 'Brojevi, segmenti, linija napretka', (_) => const StatBarPage()),
  GallerySection('SetTable', 'Unos setova, stanja, PR', (_) => const SetTablePage()),
  GallerySection('RestTimer', 'Odbrojavanje odmora', (_) => const RestTimerPage()),
  GallerySection('Kalendar', 'Urađeno, planirano, odmor', (_) => const CalendarPage()),
  GallerySection('ProgramCard', 'Program i kreator', (_) => const ProgramCardPage()),
  GallerySection('Liste i tabovi', 'ListRow, ExerciseRow, CreatorRow, Tabs', (_) => const ListsPage()),
  GallerySection('Polja za unos', 'TextField, NumberField', (_) => const InputsPage()),
  GallerySection('Summary', 'Rezime treninga', (_) => const SummaryPage()),
  GallerySection('Grafikon', 'Napredak kroz vreme', (_) => const ChartPage()),
  GallerySection('Navigacija', 'Donja navigacija', (_) => const NavPage()),
  GallerySection('Struktura', 'TopBar, OptionRow, Stepper, EmptyState, panel', (_) => const StructurePage()),
];

final _examples = [
  GallerySection('Danas', 'Blok boje za današnji trening', (_) => const TodayExample(), theme: ClTheme.light),
  GallerySection('Trening', 'Isprobaj unos', (_) => const WorkoutExample(), theme: ClTheme.light),
  GallerySection('Rezime', 'Kartica za story', (_) => const SummaryExample(), theme: ClTheme.light),
];

class GalleryHome extends StatelessWidget {
  const GalleryHome({super.key});

  void _open(BuildContext context, GallerySection s) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          final page = s.builder(context);
          return s.theme == null ? page : ClThemeScope(theme: s.theme!, child: page);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    Widget group(String label, List<GallerySection> items) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: ClSpace.s8),
        ClSectionHeader(
          label: label,
          trailing: Text('${items.length}', style: cl.text.label),
        ),
        for (final s in items) ClListRow(title: s.title, meta: s.meta, onPressed: () => _open(context, s)),
      ],
    );

    return Scaffold(
      body: SafeArea(
        child: GalleryWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(ClSpace.s4, ClSpace.s6, ClSpace.s4, ClSpace.s12),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClScreenTitle(label: 'Dizajn sistem · v0.2', title: appName),
                  ),
                  const ThemeToggle(),
                ],
              ),
              const SizedBox(height: ClSpace.s4),
              Text(
                'Svaka komponenta aplikacije, sa svim varijantama i stanjima. '
                'Prebaci temu gore desno. Primeri ekrana pokazuju kako se komponente slažu.',
                style: cl.text.body.copyWith(color: cl.colors.inkMuted),
              ),
              group('Osnove', _foundations),
              group('Komponente', _components),
              group('Primeri ekrana', _examples),
            ],
          ),
        ),
      ),
    );
  }
}

/// Keeps the gallery phone-width on large screens so it reads like the app.
class GalleryWidth extends StatelessWidget {
  const GalleryWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: child),
  );
}

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: galleryTheme,
      builder: (context, brightness, _) {
        final dark = brightness == Brightness.dark;
        return ClFilter(
          label: dark ? 'Tamna' : 'Svetla',
          selected: false,
          onChanged: (_) => galleryTheme.value = dark ? Brightness.light : Brightness.dark,
        );
      },
    );
  }
}

/// Scaffold for one gallery section: back, title, theme toggle, content.
class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key, required this.title, required this.children, this.rules});

  final String title;
  final List<Widget> children;

  /// Short usage rules from DESIGN.md, shown at the top.
  final List<String>? rules;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Scaffold(
      body: SafeArea(
        child: GalleryWidth(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: ClSpace.s1),
                child: Row(
                  children: [
                    ClIconButton(
                      icon: ClIcons.back,
                      semanticLabel: 'Nazad',
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    const ThemeToggle(),
                    const SizedBox(width: ClSpace.s3),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: ClSpace.s2, bottom: ClSpace.s12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
                      child: ClScreenTitle(title: title),
                    ),
                    if (rules != null) ...[
                      const SizedBox(height: ClSpace.s4),
                      for (final r in rules!)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(ClSpace.s4, 0, ClSpace.s4, ClSpace.s1),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('—  ', style: cl.text.body.copyWith(color: cl.colors.inkMuted)),
                              Expanded(
                                child: Text(r, style: cl.text.body.copyWith(color: cl.colors.inkMuted)),
                              ),
                            ],
                          ),
                        ),
                    ],
                    ...children,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One labeled specimen inside a gallery page.
class Specimen extends StatelessWidget {
  const Specimen({super.key, required this.label, required this.child, this.bleed = false});

  final String label;
  final Widget child;

  /// Break out of the 16px gutter for full-bleed components.
  final bool bleed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: ClSpace.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
            child: Text(label, style: context.clText.label),
          ),
          const SizedBox(height: ClSpace.s3),
          bleed
              ? child
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
                  child: child,
                ),
        ],
      ),
    );
  }
}
