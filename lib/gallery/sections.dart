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
        'Topla svetla osnova, crni tekst i tri jarke boje: limeta, lila, breskva.',
        'Boje su veliki zaobljeni blokovi, ne tanki detalji. Tekst na boji je uvek on-pop.',
        'Limeta znači urađeno, trenutno i rekord. Lila i breskva nose sadržaj.',
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
                          borderRadius: BorderRadius.circular(ClRadius.xs),
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
          label: 'Pop boje',
          child: Row(
            children: [
              for (final (color, name) in [
                (cl.colors.lime, 'Limeta'),
                (cl.colors.lilac, 'Lila'),
                (cl.colors.peach, 'Breskva'),
              ]) ...[
                Expanded(
                  child: ClPopBlock(
                    color: color,
                    child: SizedBox(height: 72, child: Text(name, style: cl.text.bodyStrong)),
                  ),
                ),
                if (name != 'Breskva') const SizedBox(width: ClSpace.s2),
              ],
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
        'Bricolage Grotesque u dve optičke veličine: display za naslove i velike brojeve, text za sve ostalo.',
        'Sve je obična rečenica, bez velikih slova. Brojevi su tabularni. Naslovi su 1–3 reči.',
      ],
      children: [
        Specimen(
          label: 'Display · naslovi',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              row('display-xl', 'Nova nedelja.', t.displayXl),
              row('display-l', 'Push day', t.displayL),
              row('display-m', 'Pojavio si se.', t.displayM),
              row('button', 'Počni trening', t.button),
            ],
          ),
        ),
        Specimen(
          label: 'Display · brojevi',
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
          label: 'Text · tekst',
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
        Text(label, style: cl.text.label),
      ],
    );
    return GalleryPage(
      title: 'Razmaci i oblici',
      rules: const [
        'Sve je zaobljeno: polja 12, redovi i kartice 20, blokovi boja 28. Dugmad i tagovi su pilule.',
        'Struktura dolazi od blokova na toploj osnovi, ne od linija. Bez senki.',
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
                      SizedBox(width: 80, child: Text(e.key, style: cl.text.label)),
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
              shape('12 polja', ClRadius.xs),
              shape('20 redovi', ClRadius.sm),
              shape('28 blokovi', ClRadius.lg),
              shape('pilula', ClRadius.full),
            ],
          ),
        ),
        Specimen(
          label: 'Linija',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Border · 1px, retko', style: cl.text.label),
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
      rules: const ['Phosphor Regular, 24px, boja teksta. Puna verzija samo za aktivnu stavku navigacije.'],
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
        'Jedno primary dugme po ekranu: crna pilula. 1–2 reči, glagol prvi.',
        'Pop (limeta) samo za akciju koja mora da iskoči. Text je običan crn link, bez podvlačenja.',
        'Dugme samo s ikonom mora imati opis za čitač ekrana.',
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
          label: 'pop',
          child: pair(
            ClButton(label: 'Pretplati se', variant: ClButtonVariant.pop, onPressed: _tap),
            const ClButton(label: 'Pretplati se', variant: ClButtonVariant.pop, onPressed: null),
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
          label: 'danger',
          child: pair(
            ClButton(label: 'Prekini trening', variant: ClButtonVariant.danger, onPressed: _tap),
            const ClButton(label: 'Obriši', variant: ClButtonVariant.danger, onPressed: null),
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
        'PR je crna nalepnica sa limeta tekstom, uvek sa tekstom.',
        'Filter je pilula. Izabran je limeta sa crnom ivicom.',
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
        'Fotografija trenera je glavni motiv. Dok je nema, zaglavlja i kartice koriste boju umesto tamnog okvira.',
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
        'Preko cele širine, donji uglovi 28. Bez fotografije je blok boje sa crnim tekstom.',
        'Label (kreator · nedelja X / Y) iznad display-l naslova.',
      ],
      children: [
        const Specimen(
          label: 'Trening · display-l',
          bleed: true,
          child: ClWorkoutHero(title: 'Push day', label: '$demoCreator · Nedelja 3 / 8'),
        ),
        Specimen(
          label: 'Bez fotografije · blok boje, dva reda',
          bleed: true,
          child: ClWorkoutHero(
            title: 'Donji deo tela',
            label: '$demoCreator · Nedelja 3 / 8',
            height: 320,
            color: context.clColors.lilac,
          ),
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
        Specimen(
          label: 'Kompaktno · display-m',
          bleed: true,
          child: ClWorkoutHero(
            title: 'Pull B',
            label: 'Sledeći trening',
            height: 240,
            compact: true,
            color: context.clColors.peach,
          ),
        ),
      ],
    );
  }
}

class PopPage extends StatelessWidget {
  const PopPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    return GalleryPage(
      title: 'Blokovi boja',
      rules: const [
        'Glavna površina aplikacije: veliki zaobljeni blok u limeti, lila ili breskvi.',
        'Unutra je uvek crn tekst, u obe teme. Najviše dva bloka na ekranu.',
        'Nalepnica je jedna po bloku: nedelja programa, novi rekord.',
      ],
      children: [
        Specimen(
          label: 'ClPopBlock · sa nalepnicom',
          child: ClPopBlock(
            color: c.lime,
            sticker: const ClSticker('Nedelja 3/8'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Danas · $demoCreator', style: cl.text.bodyStrong.copyWith(fontSize: 13)),
                const SizedBox(height: ClSpace.s2),
                Text('Push day', style: cl.text.displayL),
                const SizedBox(height: ClSpace.s1),
                Text('5 vežbi · ~58 min', style: cl.text.body),
                const SizedBox(height: ClSpace.s6),
              ],
            ),
          ),
        ),
        Specimen(
          label: 'Nedelja · segmenti na boji',
          child: ClPopBlock(
            color: c.lilac,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('2 od 4 ove nedelje', style: cl.text.bodyStrong.copyWith(fontSize: 17)),
                const SizedBox(height: ClSpace.s3),
                const ClSegmentBar(total: 4, done: 2, onPop: true),
              ],
            ),
          ),
        ),
        const Specimen(
          label: 'ClSticker',
          child: Wrap(
            spacing: ClSpace.s4,
            runSpacing: ClSpace.s4,
            children: [
              ClSticker('Nedelja 3/8'),
              ClSticker('Novi PR', angle: -5),
              ClSticker('Niz 12', angle: 0),
            ],
          ),
        ),
        Specimen(
          label: 'ClShareCard · kartica za story',
          child: ClShareCard(
            label: 'Push day · ${formatDuration(const Duration(minutes: 58))}',
            stats: const [
              ClStat(label: 'Volumen', value: '8.240', unit: 'kg'),
              ClStat(label: 'Rekordi', value: '2', unit: 'PR'),
              ClStat(label: 'Niz', value: '12', unit: 'ned.'),
            ],
            creatorName: demoCreator,
            creatorHandle: 'marko.lifts',
          ),
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
        '2–3 zaobljene pločice. Samo pločica napretka ili rekorda je limeta.',
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
        'Kolone: # · prethodno · kg · ponavljanja · RIR · potvrda. Svaki set je zaobljen red.',
        'Trenutni red ima crnu ivicu. Završen set je limeta sa kvačicom.',
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
        'Kreće kad se potvrdi set. Blok breskve, veliki broj i linija napretka.',
        'Posle nule blok postaje lila i broji dalje.',
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
        'Zaobljena fotografija (ili blok boje) sa naslovom, pa kreator i tagovi.',
        'Bez senke. Kreator je uvek imenovan.',
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
            color: context.clColors.lime,
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
      rules: const [
        'Svaki red je bela zaobljena kartica sa razmakom od 8px.',
        'Sporedne stvari idu u meni grupu: jedan red otvara panel ili ekran.',
      ],
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
          label: 'ClCreatorRow · ne pratiš, pratiš, pretplata',
          child: Column(
            children: [
              ClCreatorRow(
                name: demoCreator,
                handle: demoCreatorHandle,
                followers: formatCompact(48200),
                onPressed: () {},
              ),
              ClCreatorRow(
                status: ClFollowStatus.following,
                name: 'Jelena Ilić',
                handle: '@jelena.moves',
                followers: formatCompact(126000),
                onPressed: () {},
              ),
              ClCreatorRow(
                status: ClFollowStatus.subscribed,
                name: 'Nikola Jovanović',
                handle: '@nikola.fit',
                followers: formatCompact(9400),
                onPressed: () {},
              ),
            ],
          ),
        ),
        Specimen(
          label: 'ClMenuGroup · ClMenuRow',
          child: ClMenuGroup(
            title: 'Treniranje',
            children: [
              ClMenuRow(icon: ClIcons.plan, title: 'Moj plan', value: 'Snaga 8', onPressed: () {}),
              ClMenuRow(icon: ClIcons.subscriptions, title: 'Pretplate', value: '2', onPressed: () {}),
              ClMenuRow(icon: ClIcons.barbell, title: 'Oprema', value: '6 komada', onPressed: () {}),
              ClMenuRow(icon: ClIcons.signOut, title: 'Odjavi se', danger: true, onPressed: () {}),
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
        'Popunjeno polje, radius 12, bez ivice. Fokus je crni okvir od 2px.',
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
        'Gornji deo je kartica za story: lila blok sa brojevima u bojama i imenom trenera.',
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
      label: 'Push day · ${formatDuration(const Duration(minutes: 72))}',
      stats: const [
        ClStat(label: 'Volumen', value: '8.240', unit: 'kg'),
        ClStat(label: 'Rekordi', value: '2', unit: 'PR', highlight: true),
        ClStat(label: 'Niz', value: '12', unit: 'ned.'),
      ],
      exercises: [
        ClSummaryExercise(name: 'Bench press', detail: '4 × ${formatSet(85, 8)}', isPr: true),
        ClSummaryExercise(name: 'Rameni potisak', detail: '3 × ${formatSet(42.5, 10)}'),
        ClSummaryExercise(name: 'Propadanja', detail: '3 × 10 · +12,5 kg', isPr: true),
        ClSummaryExercise(name: 'Triceps sajla', detail: '3 × ${formatSet(25, 12)}'),
      ],
      creatorName: demoCreator,
      creatorHandle: 'marko.lifts',
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
      rules: const [
        'Zaobljena crna linija na beloj kartici. Limeta tačka i pilula za trenutnu ili najbolju vrednost.',
      ],
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
      rules: const ['Mirna traka na pozadini, 5 stavki. Aktivna ima punu ikonu i crn tekst, bez boje.'],
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

class StructurePage extends StatefulWidget {
  const StructurePage({super.key});

  @override
  State<StructurePage> createState() => _StructurePageState();
}

class _StructurePageState extends State<StructurePage> {
  String _goal = 'Snaga';
  int _sets = 4;
  int _rest = 90;
  String? _result;

  @override
  Widget build(BuildContext context) {
    return GalleryPage(
      title: 'Struktura',
      rules: const [
        'Gornja traka: nazad, label, najviše dve radnje.',
        'Potvrda je deo stranice (donji panel), nikad sistemski dijalog.',
      ],
      children: [
        Specimen(
          label: 'ClTopBar',
          bleed: true,
          child: ClTopBar(
            label: 'Push day · Vežba 1 / 5',
            onBack: () {},
            actions: [
              ClIconButton(icon: ClIcons.swap, semanticLabel: 'Zameni vežbu', onPressed: () {}),
              ClIconButton(icon: ClIcons.more, semanticLabel: 'Opcije', onPressed: () {}),
            ],
          ),
        ),
        Specimen(
          label: 'ClOptionRow · $_goal',
          child: Column(
            children: [
              for (final (g, meta) in [
                ('Snaga', null),
                ('Mišićna masa', null),
                ('Početnik', 'Manje od 6 meseci redovnog treninga'),
              ])
                ClOptionRow(
                  title: g,
                  meta: meta,
                  selected: _goal == g,
                  onPressed: () => setState(() => _goal = g),
                ),
            ],
          ),
        ),
        Specimen(
          label: 'ClStepper',
          child: Column(
            children: [
              ClStepper(
                label: 'Setovi',
                value: _sets,
                min: 1,
                max: 10,
                onChanged: (v) => setState(() => _sets = v),
              ),
              ClStepper(
                label: 'Odmor',
                value: _rest,
                min: 15,
                max: 300,
                step: 15,
                format: (s) => formatClock(Duration(seconds: s)),
                onChanged: (v) => setState(() => _rest = v),
              ),
            ],
          ),
        ),
        const Specimen(
          label: 'ClNotice',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClNotice('Plan ne zavisi od datuma. Sledeći trening te čeka dok ga ne uradiš.'),
              SizedBox(height: ClSpace.s2),
              ClNotice('Upiši težinu za set 2.', danger: true),
            ],
          ),
        ),
        Specimen(
          label: 'ClEmptyState',
          child: ClEmptyState(
            label: 'Tvoji brojevi',
            title: 'Prvi trening.',
            message: 'Posle prvog treninga ovde su volumen, rekordi i sva istorija.',
            action: ClButton(label: 'Otkrij trenere', variant: ClButtonVariant.secondary, onPressed: () {}),
          ),
        ),
        Specimen(
          label: 'Panel i potvrda${_result == null ? '' : ' · $_result'}',
          child: Wrap(
            spacing: ClSpace.s3,
            runSpacing: ClSpace.s3,
            children: [
              ClButton(
                label: 'Otvori panel',
                variant: ClButtonVariant.secondary,
                onPressed: () => showClSheet<void>(
                  context,
                  title: 'Zameni vežbu',
                  label: 'Bench press · Grudi',
                  builder: (context) => Column(
                    children: [
                      for (final n in ['Kosi potisak bučicama', 'Sklekovi', 'Propadanja'])
                        ClListRow(
                          title: n,
                          meta: 'Marko Petrović',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                    ],
                  ),
                ),
              ),
              ClButton(
                label: 'Obriši',
                variant: ClButtonVariant.danger,
                onPressed: () async {
                  final ok = await confirmClSheet(
                    context,
                    title: 'Obriši?',
                    message: 'Vežba se uklanja iz biblioteke. Pratioci zadržavaju istoriju.',
                    confirmLabel: 'Obriši',
                    danger: true,
                  );
                  setState(() => _result = ok ? 'potvrđeno' : 'odustao');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  static final _today = DateTime(2026, 9, 30);
  DateTime _selected = _today;
  DateTime _month = DateTime(2026, 9);

  ClDayMark _mark(DateTime d) {
    final training = {1, 3, 5}.contains(d.weekday);
    if (d.isBefore(DateTime(2026, 9, 7))) return ClDayMark.none;
    if (d.isBefore(_today)) return training ? ClDayMark.done : ClDayMark.rest;
    return training ? ClDayMark.planned : ClDayMark.rest;
  }

  @override
  Widget build(BuildContext context) {
    return GalleryPage(
      title: 'Kalendar',
      rules: const [
        'Danas je unapred izabran i ima okvir. Izabran dan je crn.',
        'Kompaktan: urađen trening je limeta sa kvačicom, planiran lila sa šipkom, odmor mesec.',
        'Propušten dan je samo odmor. Statistika ne stoji iznad kalendara.',
      ],
      children: [
        Specimen(
          label: 'ClCalendar · ${_selected.day}. ${_selected.month}. · ${_mark(_selected).name}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClCalendar(
                month: _month,
                selected: _selected,
                today: _today,
                markFor: _mark,
                onSelect: (d) => setState(() => _selected = d),
                onMonthChanged: (m) => setState(() => _month = m),
              ),
              const SizedBox(height: ClSpace.s3),
              const ClCalendarLegend(),
            ],
          ),
        ),
      ],
    );
  }
}
