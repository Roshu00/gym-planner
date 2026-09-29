import 'package:flutter/material.dart';

import '../ui/chalkline_ui.dart';
import 'demo_data.dart';
import 'gallery_app.dart';

String _hex(Color c) {
  final argb = c.toARGB32();
  final rgb = (argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();
  final a = argb >> 24;
  return a == 0xFF ? '#$rgb' : '#$rgb · ${(a / 255 * 100).round()}%';
}

// ───────────────────────────── Foundations

class ColorsPage extends StatelessWidget {
  const ColorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return GalleryPage(
      title: 'Boje',
      rules: const [
        'Crna i bela čine 95% ekrana. Signal je jedina boja brenda.',
        'Signal najviše na 3 mesta po ekranu: glavna akcija, napredak, rekord.',
        'Na tamnoj pozadini tekst u signal boji je uvek signal-text.',
      ],
      children: [
        Specimen(
          label: 'Tokeni · ${cl.colors.brightness == Brightness.dark ? 'tamna' : 'svetla'} tema',
          child: Column(
            children: [
              for (final e in cl.colors.all.entries)
                Container(
                  height: ClSize.targetWorkout,
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: cl.colors.border)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: e.value,
                          border: Border.all(color: cl.colors.border),
                        ),
                      ),
                      const SizedBox(width: ClSpace.s3),
                      Expanded(child: Text(e.key, style: cl.text.bodyStrong)),
                      Text(
                        _hex(e.value),
                        style: cl.text.data.copyWith(fontSize: 12, color: cl.colors.inkMuted),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Specimen(
          label: 'Signal kao tekst',
          child: Wrap(
            spacing: ClSpace.s6,
            runSpacing: ClSpace.s3,
            children: [
              Text('3/4', style: cl.text.metric.copyWith(color: cl.colors.signalText)),
              Text('102,5 kg', style: cl.text.metric.copyWith(color: cl.colors.signalText)),
              Text('Danger', style: cl.text.bodyStrong.copyWith(color: cl.colors.danger)),
            ],
          ),
        ),
      ],
    );
  }
}

class TypographyPage extends StatelessWidget {
  const TypographyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.clText;
    Widget row(String name, String sample, TextStyle style) => Padding(
      padding: const EdgeInsets.only(bottom: ClSpace.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$name · ${style.fontSize!.toStringAsFixed(0)}/${(style.fontSize! * style.height!).round()}',
            style: t.label,
          ),
          const SizedBox(height: ClSpace.s2),
          Text(sample, style: style),
        ],
      ),
    );

    return GalleryPage(
      title: 'Tipografija',
      rules: const [
        'Jedna porodica, Archivo, u tri širine: 62% za naslove, 100% za tekst, 125% za brojeve.',
        'Svi brojevi su široki i tabularni. Naslovi su 1–3 reči, najviše 2 reda.',
      ],
      children: [
        Specimen(
          label: 'Condensed 62% · naslovi',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              row('display-xl', 'NOVA NEDELJA.', t.displayXl),
              row('display-l', 'PUSH DAY', t.displayL),
              row('display-m', 'POJAVIO SI SE.', t.displayM),
              row('button', 'POČNI TRENING', t.button),
            ],
          ),
        ),
        Specimen(
          label: 'Wide 125% · brojevi',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              row('metric-l', '8.240 kg', t.metricL),
              row('metric', '12 · 3/4 · 1:30', t.metric),
              row('data', '82,5 × 8   0123456789', t.data),
            ],
          ),
        ),
        Specimen(
          label: '100% · tekst',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              row('body', 'Sledeće je Pull B. Isti ritam. Čuvaj leđa ravna, šake ispod laktova.', t.body),
              row('body-strong', 'Bench press · Đorđe Šćepanović', t.bodyStrong),
              row('label', 'PROŠLI PUT · NEDELJA 3 / 8', t.label),
            ],
          ),
        ),
      ],
    );
  }
}

class SpacingPage extends StatelessWidget {
  const SpacingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    const spaces = {
      'space-1': ClSpace.s1,
      'space-2': ClSpace.s2,
      'space-3': ClSpace.s3,
      'space-4': ClSpace.s4,
      'space-6': ClSpace.s6,
      'space-8': ClSpace.s8,
      'space-12': ClSpace.s12,
    };
    Widget shape(String label, double radius, {bool circle = false}) => Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            border: Border.all(color: cl.colors.ink, width: 1.5),
            borderRadius: circle ? null : BorderRadius.circular(radius),
            shape: circle ? BoxShape.circle : BoxShape.rectangle,
          ),
        ),
        const SizedBox(height: ClSpace.s2),
        Text(label.toUpperCase(), style: cl.text.label),
      ],
    );
    return GalleryPage(
      title: 'Razmaci i oblici',
      rules: const [
        'Oštri oblici: foto i sekcije 0, dugmad i polja 4, tagovi 2. Jedini krug je avatar.',
        'Struktura dolazi od linija, ne kutija. Bez senki.',
      ],
      children: [
        Specimen(
          label: 'Razmaci',
          child: Column(
            children: [
              for (final e in spaces.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: ClSpace.s2),
                  child: Row(
                    children: [
                      SizedBox(width: 80, child: Text(e.key.toUpperCase(), style: cl.text.label)),
                      Container(width: e.value, height: 16, color: cl.colors.ink),
                      const SizedBox(width: ClSpace.s2),
                      Text('${e.value.toInt()}', style: cl.text.data),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Specimen(
          label: 'Radijusi',
          child: Wrap(
            spacing: ClSpace.s4,
            runSpacing: ClSpace.s4,
            children: [
              shape('0 foto', ClRadius.none),
              shape('2 tag', ClRadius.xs),
              shape('4 kontrole', ClRadius.sm),
              shape('avatar', 0, circle: true),
            ],
          ),
        ),
        Specimen(
          label: 'Linije',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('RULE · 2PX IZNAD BLOKOVA PODATAKA', style: cl.text.label),
              const SizedBox(height: ClSpace.s2),
              const ClRule(),
              const SizedBox(height: ClSpace.s6),
              Text('BORDER · 1PX IZMEĐU REDOVA', style: cl.text.label),
              const SizedBox(height: ClSpace.s2),
              const ClDivider(),
            ],
          ),
        ),
        Specimen(
          label: 'Mete za dodir',
          child: Wrap(
            spacing: ClSpace.s6,
            runSpacing: ClSpace.s3,
            children: [
              for (final (size, text) in [
                (ClSize.target, '48 · minimum'),
                (ClSize.targetWorkout, '56 · trening'),
              ])
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: size, height: size, color: cl.colors.surfaceRaised),
                    const SizedBox(width: ClSpace.s3),
                    Text(text, style: cl.text.body),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class IconsPage extends StatelessWidget {
  const IconsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return GalleryPage(
      title: 'Ikone',
      rules: const ['Tanke, 24px, boja teksta. Koristi retko: tekst je bolji od ikone.'],
      children: [
        Specimen(
          label: 'ClIcons',
          child: Wrap(
            spacing: ClSpace.s2,
            runSpacing: ClSpace.s4,
            children: [
              for (final e in ClIcons.all.entries)
                SizedBox(
                  width: 72,
                  child: Column(
                    children: [
                      Icon(e.value, size: ClSize.icon, color: cl.colors.ink),
                      const SizedBox(height: ClSpace.s2),
                      Text(e.key, style: cl.text.label.copyWith(letterSpacing: 0, fontSize: 10)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ───────────────────────────── Components

class ButtonsPage extends StatefulWidget {
  const ButtonsPage({super.key});

  @override
  State<ButtonsPage> createState() => _ButtonsPageState();
}

class _ButtonsPageState extends State<ButtonsPage> {
  int _taps = 0;

  void _tap() => setState(() => _taps++);

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    Widget pair(Widget a, Widget b) => Wrap(spacing: ClSpace.s3, runSpacing: ClSpace.s3, children: [a, b]);
    return GalleryPage(
      title: 'Button',
      rules: const [
        'Jedno primary dugme po ekranu. 1–2 reči, glagol prvi.',
        'Bez pilula. Dugme samo s ikonom mora imati opis za čitač ekrana.',
      ],
      children: [
        Specimen(
          label: 'Pritisnuto: $_taps',
          child: Text('Dodirni bilo koje dugme.', style: cl.text.body.copyWith(color: cl.colors.inkMuted)),
        ),
        Specimen(
          label: 'primary',
          child: pair(
            ClButton(label: 'Počni trening', onPressed: _tap),
            const ClButton(label: 'Počni trening', onPressed: null),
          ),
        ),
        Specimen(
          label: 'ink',
          child: pair(
            ClButton(label: 'Pretplati se', variant: ClButtonVariant.ink, onPressed: _tap),
            const ClButton(label: 'Pretplati se', variant: ClButtonVariant.ink, onPressed: null),
          ),
        ),
        Specimen(
          label: 'secondary',
          child: pair(
            ClButton(label: 'Zaprati', variant: ClButtonVariant.secondary, onPressed: _tap),
            ClButton(
              label: 'Zameni vežbu',
              variant: ClButtonVariant.secondary,
              icon: ClIcons.swap,
              onPressed: _tap,
            ),
          ),
        ),
        Specimen(
          label: 'text',
          child: pair(
            ClButton(label: 'Preskoči odmor', variant: ClButtonVariant.text, onPressed: _tap),
            const ClButton(label: 'Nedostupno', variant: ClButtonVariant.text, onPressed: null),
          ),
        ),
        Specimen(
          label: 'block · 56px, na dnu ekrana',
          child: Column(
            children: [
              ClButton.block(label: 'Počni trening', icon: ClIcons.arrowRight, onPressed: _tap),
              const SizedBox(height: ClSpace.s3),
              ClButton.block(label: 'Završi set', onPressed: _tap),
            ],
          ),
        ),
        Specimen(
          label: 'Samo ikona · 48px, uvek sa opisom',
          child: Row(
            children: [
              ClIconButton(icon: ClIcons.back, semanticLabel: 'Nazad', onPressed: _tap),
              ClIconButton(icon: ClIcons.more, semanticLabel: 'Još opcija', onPressed: _tap),
              ClIconButton(icon: ClIcons.swap, semanticLabel: 'Zameni vežbu', onPressed: _tap),
              const ClIconButton(icon: ClIcons.close, semanticLabel: 'Zatvori', onPressed: null),
            ],
          ),
        ),
      ],
    );
  }
}

class TagsPage extends StatefulWidget {
  const TagsPage({super.key});

  @override
  State<TagsPage> createState() => _TagsPageState();
}

class _TagsPageState extends State<TagsPage> {
  Set<String> _selected = {'Snaga'};
  int _prKey = 0;

  @override
  Widget build(BuildContext context) {
    return GalleryPage(
      title: 'Tag i Filter',
      rules: const [
        'PR uvek ima tekst, nikad samo boju.',
        'Filter je pravougaonik (radius 4), izabran je pun ink.',
      ],
      children: [
        const Specimen(
          label: 'Tag',
          child: Wrap(
            spacing: ClSpace.s2,
            runSpacing: ClSpace.s2,
            children: [
              ClTag.pr(),
              ClTag('Teretana'),
              ClTag('8 nedelja'),
              ClTag('Za pretplatnike'),
              ClTag('Bol u ramenu', variant: ClTagVariant.danger),
            ],
          ),
        ),
        Specimen(
          label: 'Novi rekord · animacija',
          child: Row(
            children: [
              ClTag.pr(key: ValueKey(_prKey), animateIn: true),
              const SizedBox(width: ClSpace.s4),
              ClButton(
                label: 'Ponovi',
                variant: ClButtonVariant.text,
                onPressed: () => setState(() => _prKey++),
              ),
            ],
          ),
        ),
        Specimen(
          label: 'Filter · ${_selected.length} izabrano',
          bleed: true,
          child: ClFilterRow(
            options: const ['Snaga', 'Hipertrofija', 'Kod kuće', 'Teretana', 'Početnik', '3× nedeljno'],
            selected: _selected,
            onChanged: (s) => setState(() => _selected = s),
          ),
        ),
      ],
    );
  }
}

class MediaPage extends StatelessWidget {
  const MediaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return GalleryPage(
      title: 'Avatar i foto',
      rules: const [
        'Fotografija trenera je glavni motiv. Bez medija prikaži tamni photo-empty okvir, nikad blok boje.',
        'Beli tekst preko fotografije uvek stoji na scrim-u.',
      ],
      children: [
        Specimen(
          label: 'Avatar · 28 lista, 40 red, 56 profil',
          child: Row(
            children: [
              const ClAvatar(name: demoCreator),
              const SizedBox(width: ClSpace.s4),
              const ClAvatar(name: 'Jelena Ilić', size: 40),
              const SizedBox(width: ClSpace.s4),
              const ClAvatar.profile(name: 'Đorđe Šćepanović'),
              const SizedBox(width: ClSpace.s4),
              Expanded(
                child: Text(
                  'Inicijali dok se slika učitava ili kad je nema.',
                  style: cl.text.body.copyWith(color: cl.colors.inkMuted),
                ),
              ),
            ],
          ),
        ),
        const Specimen(
          label: 'ClCreatorLine',
          child: ClCreatorLine(name: demoCreator, trailing: '48,2K pratilaca'),
        ),
        const Specimen(
          label: 'ClPhoto · photo-empty',
          bleed: true,
          child: SizedBox(height: 200, child: ClPhoto()),
        ),
        Specimen(
          label: 'ClPhoto + ClPhotoScrim',
          bleed: true,
          child: SizedBox(
            height: 200,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ClPhoto(placeholderLabel: 'Foto · 9:16'),
                const ClPhotoScrim(),
                Positioned(
                  left: ClSpace.s4,
                  bottom: ClSpace.s4,
                  child: Text(
                    'BELI TEKST NA SCRIM-U',
                    style: cl.text.label.copyWith(color: cl.colors.onPhoto),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class HeroPage extends StatelessWidget {
  const HeroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GalleryPage(
      title: 'WorkoutHero',
      rules: const [
        'Fotografija preko cele širine, radius 0, scrim na donjih 60%.',
        'Label (kreator · nedelja X / Y) iznad display-l naslova.',
      ],
      children: [
        const Specimen(
          label: 'Trening · display-l',
          bleed: true,
          child: ClWorkoutHero(title: 'Push day', label: '$demoCreator · Nedelja 3 / 8'),
        ),
        const Specimen(
          label: 'Dva reda naslova',
          bleed: true,
          child: ClWorkoutHero(title: 'Donji deo tela', label: '$demoCreator · Nedelja 3 / 8', height: 400),
        ),
        Specimen(
          label: 'Profil kreatora · sa gornjom trakom',
          bleed: true,
          child: Builder(
            builder: (context) {
              final onPhoto = context.clColors.onPhoto;
              return ClWorkoutHero(
                title: demoCreator,
                label: '$demoCreatorHandle · Snaga i hipertrofija',
                height: 380,
                topBar: Row(
                  children: [
                    ClIconButton(
                      icon: ClIcons.back,
                      semanticLabel: 'Nazad',
                      color: onPhoto,
                      onPressed: () {},
                    ),
                    const Spacer(),
                    ClIconButton(
                      icon: ClIcons.more,
                      semanticLabel: 'Još opcija',
                      color: onPhoto,
                      onPressed: () {},
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const Specimen(
          label: 'Kompaktno · display-m',
          bleed: true,
          child: ClWorkoutHero(title: 'Pull B', label: 'Sledeći trening', height: 240, compact: true),
        ),
      ],
    );
  }
}

class StatBarPage extends StatefulWidget {
  const StatBarPage({super.key});

  @override
  State<StatBarPage> createState() => _StatBarPageState();
}

class _StatBarPageState extends State<StatBarPage> {
  int _done = 2;
  static const _goal = 4;

  @override
  Widget build(BuildContext context) {
    return GalleryPage(
      title: 'StatBar',
      rules: const [
        '2–3 kolone ispod rule linije. Samo broj napretka ili rekorda je u signal-text.',
        'Svaki ekran pokazuje bar jedan broj koji dokazuje napredak.',
      ],
      children: [
        Specimen(
          label: 'Tri kolone + segmenti',
          child: ClStatBar(
            stats: [
              const ClStat(label: 'Niz', value: '12', unit: 'ned.'),
              ClStat(label: 'Ova nedelja', value: '$_done/$_goal', highlight: true),
              const ClStat(label: 'Trajanje', value: '58', unit: 'min'),
            ],
            segments: ClSegmentBar(total: _goal, done: _done),
          ),
        ),
        Specimen(
          label: 'Isprobaj segmente',
          child: Row(
            children: [
              ClButton(
                label: '−1',
                variant: ClButtonVariant.secondary,
                onPressed: _done > 0 ? () => setState(() => _done--) : null,
              ),
              const SizedBox(width: ClSpace.s3),
              ClButton(
                label: '+1',
                variant: ClButtonVariant.secondary,
                onPressed: _done < _goal ? () => setState(() => _done++) : null,
              ),
            ],
          ),
        ),
        const Specimen(
          label: 'Dve kolone · large (Summary)',
          child: ClStatBar(
            large: true,
            stats: [
              ClStat(label: 'Volumen', value: '8.240', unit: 'kg'),
              ClStat(label: 'Rekordi', value: '2', unit: 'PR', highlight: true),
            ],
          ),
        ),
        const Specimen(
          label: 'Profil kreatora',
          child: ClStatBar(
            stats: [
              ClStat(label: 'Pratioci', value: '48,2K'),
              ClStat(label: 'Programi', value: '6'),
              ClStat(label: 'Vežbe', value: '142'),
            ],
          ),
        ),
        const Specimen(label: 'ClProgressLine · 65%', child: ClProgressLine(value: 0.65)),
      ],
    );
  }
}

class SetTablePage extends StatefulWidget {
  const SetTablePage({super.key});

  @override
  State<SetTablePage> createState() => _SetTablePageState();
}

class _SetTablePageState extends State<SetTablePage> {
  var _sets = demoSets();

  @override
  Widget build(BuildContext context) {
    return GalleryPage(
      title: 'SetTable',
      rules: const [
        'Kolone: # · prethodno · kg · ponavljanja · RIR · potvrda. Redovi 56px.',
        'Trenutni red ima surface pozadinu. Završen set ima punu kvačicu i broj u signal-text.',
        'Probaj: upiši 85 kg u set 2 i potvrdi, dobićeš PR. Prazno polje uzima prošli rezultat.',
      ],
      children: [
        Specimen(
          label: 'Bench press · 4 × 6–8',
          child: ClSetTable(
            sets: _sets,
            onChanged: (i, d) => setState(() => _sets = [..._sets]..[i] = d),
            onToggleDone: (i) => setState(() => _sets = toggleSet(_sets, i)),
          ),
        ),
        Specimen(
          label: 'Bez RIR kolone',
          child: ClSetTable(
            showRir: false,
            sets: const [
              ClSetData(
                previousKg: 100,
                previousReps: 5,
                kg: '105',
                reps: '5',
                state: ClSetState.done,
                isPr: true,
              ),
              ClSetData(previousKg: 100, previousReps: 5, state: ClSetState.current),
            ],
            onChanged: (_, _) {},
            onToggleDone: (_) {},
          ),
        ),
        Specimen(
          label: 'ClSetCheck',
          child: Row(
            children: [
              ClSetCheck(done: false, onPressed: () {}),
              ClSetCheck(done: true, onPressed: () {}),
            ],
          ),
        ),
      ],
    );
  }
}

class RestTimerPage extends StatefulWidget {
  const RestTimerPage({super.key});

  @override
  State<RestTimerPage> createState() => _RestTimerPageState();
}

class _RestTimerPageState extends State<RestTimerPage> {
  int _run = 0;
  Duration _duration = const Duration(seconds: 90);

  @override
  Widget build(BuildContext context) {
    return GalleryPage(
      title: 'RestTimer',
      rules: const [
        'Kreće kad se potvrdi set. Veliki metric-l broj i tanka linija napretka.',
        'Posle nule nastavlja da broji u danger boji.',
      ],
      children: [
        Specimen(
          label: 'Odmor ${formatClock(_duration)}',
          child: ClRestTimer(key: ValueKey(_run), duration: _duration, onSkip: () => setState(() => _run++)),
        ),
        Specimen(
          label: 'Pokreni ponovo',
          child: Wrap(
            spacing: ClSpace.s3,
            runSpacing: ClSpace.s3,
            children: [
              for (final s in [5, 60, 90, 180])
                ClButton(
                  label: formatClock(Duration(seconds: s)),
                  variant: ClButtonVariant.secondary,
                  onPressed: () => setState(() {
                    _duration = Duration(seconds: s);
                    _run++;
                  }),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class ProgramCardPage extends StatelessWidget {
  const ProgramCardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GalleryPage(
      title: 'ProgramCard',
      rules: const [
        'Kao naslovna strana časopisa: foto, naslov na scrim-u, pa kreator i tagovi.',
        'Bez okvira i bez senke. Kreator je uvek imenovan.',
      ],
      children: [
        Specimen(
          label: 'Javni program',
          child: ClProgramCard(
            title: 'Snaga 8',
            meta: '8 nedelja · 4× nedeljno',
            creatorName: demoCreator,
            followers: '${formatCompact(48200)} pratilaca',
            tags: const ['Teretana', 'Srednji nivo'],
            onPressed: () {},
          ),
        ),
        Specimen(
          label: 'Za pretplatnike · dugačak naslov',
          child: ClProgramCard(
            title: 'Hipertrofija gornjeg dela',
            meta: '12 nedelja · 5× nedeljno',
            creatorName: 'Jelena Ilić',
            followers: '${formatCompact(126000)} pratilaca',
            tags: const ['Teretana'],
            locked: true,
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}

class ListsPage extends StatefulWidget {
  const ListsPage({super.key});

  @override
  State<ListsPage> createState() => _ListsPageState();
}

class _ListsPageState extends State<ListsPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    const tabs = ['Vežbe', 'Treninzi', 'Programi'];
    return GalleryPage(
      title: 'Liste i tabovi',
      rules: const ['Redovi su odvojeni linijom od 1px, bez kutija.'],
      children: [
        Specimen(
          label: 'ClTabs',
          child: ClTabs(tabs: tabs, selected: _tab, onChanged: (i) => setState(() => _tab = i)),
        ),
        Specimen(
          label: 'ClListRow · ${tabs[_tab]}',
          child: Column(
            children: [
              ClListRow(
                title: 'Bench press',
                meta: 'Grudi · Šipka',
                tags: const [ClTag('Teretana')],
                onPressed: () {},
              ),
              ClListRow(
                title: 'Sklekovi',
                meta: 'Grudi · Bez opreme',
                tags: const [ClTag('Kod kuće')],
                onPressed: () {},
              ),
              ClListRow(
                title: 'Kosi potisak',
                meta: 'Grudi · Bučice',
                tags: const [ClTag('Nemaš opremu', variant: ClTagVariant.danger)],
                onPressed: () {},
              ),
            ],
          ),
        ),
        Specimen(
          label: 'ClExerciseRow',
          child: Column(
            children: [
              ClExerciseRow(
                index: 1,
                name: 'Bench press',
                detail: '4 × 6–8 · Prošli put ${formatSet(80, 8)}',
                onPressed: () {},
              ),
              ClExerciseRow(
                index: 2,
                name: 'Rameni potisak',
                detail: '3 × 8–10 · Prošli put ${formatSet(42.5, 9)}',
                onPressed: () {},
              ),
              const ClExerciseRow(name: 'Propadanja', detail: '3 × 10 · +10 kg', isPr: true),
            ],
          ),
        ),
        Specimen(
          label: 'ClCreatorRow',
          child: Column(
            children: [
              ClCreatorRow(
                name: demoCreator,
                handle: demoCreatorHandle,
                followers: formatCompact(48200),
                onPressed: () {},
              ),
              ClCreatorRow(
                name: 'Jelena Ilić',
                handle: '@jelena.moves',
                followers: formatCompact(126000),
                onPressed: () {},
              ),
              ClCreatorRow(
                name: 'Nikola Jovanović',
                handle: '@nikola.fit',
                followers: formatCompact(9400),
                onPressed: () {},
              ),
            ],
          ),
        ),
        const Specimen(
          label: 'ClSectionHeader',
          child: ClSectionHeader(label: 'Današnje vežbe'),
        ),
      ],
    );
  }
}

class InputsPage extends StatefulWidget {
  const InputsPage({super.key});

  @override
  State<InputsPage> createState() => _InputsPageState();
}

class _InputsPageState extends State<InputsPage> {
  String _kg = '';
  String _reps = '';

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final kg = parseDecimal(_kg);
    return GalleryPage(
      title: 'Polja za unos',
      rules: const [
        'Radius 4, ivica border-strong, fokus je 2px okvir.',
        'Decimalni zarez: 82,5 kg. Greške su obične rečenice.',
      ],
      children: [
        const Specimen(
          label: 'ClTextField',
          child: ClTextField(label: 'Ime programa', hint: 'npr. Snaga 8'),
        ),
        const Specimen(
          label: 'Pretraga',
          child: ClTextField(hint: 'Traži vežbu ili trenera', icon: ClIcons.search),
        ),
        const Specimen(
          label: 'Greška',
          child: ClTextField(label: 'Težina', hint: '0', error: 'Set nije sačuvan. Pokušaj ponovo.'),
        ),
        const Specimen(
          label: 'Onemogućeno',
          child: ClTextField(label: 'Email', hint: 'marko@primer.rs', enabled: false),
        ),
        Specimen(
          label: 'ClNumberField',
          child: Row(
            children: [
              SizedBox(
                width: 88,
                child: ClNumberField(
                  value: _kg,
                  hint: '80',
                  decimal: true,
                  onChanged: (v) => setState(() => _kg = v),
                ),
              ),
              const SizedBox(width: ClSpace.s2),
              Text('×', style: cl.text.data),
              const SizedBox(width: ClSpace.s2),
              SizedBox(
                width: 64,
                child: ClNumberField(value: _reps, hint: '8', onChanged: (v) => setState(() => _reps = v)),
              ),
              const SizedBox(width: ClSpace.s4),
              Expanded(
                child: Text(
                  kg == null ? '—' : formatSet(kg, int.tryParse(_reps) ?? 0),
                  style: cl.text.data.copyWith(color: cl.colors.inkMuted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SummaryPage extends StatelessWidget {
  const SummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GalleryPage(
      title: 'Summary',
      rules: const [
        'Hvali pojavljivanje, ne rezultat. Bez uzvičnika i emodžija.',
        'U aplikaciji je rezime uvek u svetloj temi.',
      ],
      children: const [Specimen(label: 'Trenutna tema', child: DemoSummary())],
    );
  }
}

class DemoSummary extends StatelessWidget {
  const DemoSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return ClSummary(
      label: 'Trening završen · ${formatDuration(const Duration(minutes: 72))} · 2 PR',
      stats: const [
        ClStat(label: 'Volumen', value: '8.240', unit: 'kg'),
        ClStat(label: 'Rekordi', value: '2', unit: 'PR', highlight: true),
      ],
      exercises: [
        ClSummaryExercise(name: 'Bench press', detail: '4 × ${formatSet(85, 8)}', isPr: true),
        ClSummaryExercise(name: 'Rameni potisak', detail: '3 × ${formatSet(42.5, 10)}'),
        ClSummaryExercise(name: 'Propadanja', detail: '3 × 10 · +12,5 kg', isPr: true),
        ClSummaryExercise(name: 'Triceps sajla', detail: '3 × ${formatSet(25, 12)}'),
      ],
      creatorName: demoCreator,
      creatorMessage: 'Sledeće je Pull B. Isti ritam.',
    );
  }
}

class ChartPage extends StatelessWidget {
  const ChartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GalleryPage(
      title: 'Grafikon',
      rules: const ['Linija 2px u ink boji, bez popune. Signal samo za trenutnu ili najbolju vrednost.'],
      children: const [
        Specimen(
          label: 'Trenutna vrednost',
          child: ClLineChart(
            title: 'Bench press · procenjeni 1RM',
            unit: 'kg',
            points: [
              ClChartPoint('N1', 96),
              ClChartPoint('N2', 98.5),
              ClChartPoint('N3', 98),
              ClChartPoint('N4', 101),
              ClChartPoint('N5', 103.5),
              ClChartPoint('N6', 106),
            ],
          ),
        ),
        Specimen(
          label: 'Najbolja vrednost',
          child: ClLineChart(
            title: 'Nedeljni volumen',
            unit: 'kg',
            highlightIndex: 3,
            height: 140,
            points: [
              ClChartPoint('Jul', 24100),
              ClChartPoint('Avg', 26800),
              ClChartPoint('Sep', 25200),
              ClChartPoint('Okt', 31900),
              ClChartPoint('Nov', 29400),
            ],
          ),
        ),
      ],
    );
  }
}

class NavPage extends StatefulWidget {
  const NavPage({super.key});

  @override
  State<NavPage> createState() => _NavPageState();
}

class _NavPageState extends State<NavPage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return GalleryPage(
      title: 'Navigacija',
      rules: const ['5 stavki. Aktivna je ink, ostale ink-muted. Nikad signal u navigaciji.'],
      children: [
        Specimen(
          label: 'ClBottomNav · ${clNavItems[_index].label}',
          bleed: true,
          child: ClBottomNav(selected: _index, onChanged: (i) => setState(() => _index = i)),
        ),
      ],
    );
  }
}
