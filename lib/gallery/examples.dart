import 'package:flutter/material.dart';

import '../ui/chalkline_ui.dart';
import 'demo_data.dart';
import 'gallery_app.dart';
import 'sections.dart';

/// Today: hero → stat bar + segments → exercise preview → block button → nav.
class TodayExample extends StatefulWidget {
  const TodayExample({super.key});

  @override
  State<TodayExample> createState() => _TodayExampleState();
}

class _TodayExampleState extends State<TodayExample> {
  int _nav = 0;

  @override
  Widget build(BuildContext context) {
    final onPhoto = context.clColors.onPhoto;
    return Scaffold(
      body: GalleryWidth(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ClWorkoutHero(
                    title: 'Push day',
                    label: '$demoCreator · Nedelja 3 / 8',
                    height: 420,
                    topBar: Row(
                      children: [
                        ClIconButton(
                          icon: ClIcons.back,
                          semanticLabel: 'Nazad u galeriju',
                          color: onPhoto,
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(ClSpace.s4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const ClStatBar(
                          stats: [
                            ClStat(label: 'Niz', value: '12', unit: 'ned.'),
                            ClStat(label: 'Ova nedelja', value: '2/4', highlight: true),
                            ClStat(label: 'Trajanje', value: '58', unit: 'min'),
                          ],
                          segments: ClSegmentBar(total: 4, done: 2),
                        ),
                        const SizedBox(height: ClSpace.s8),
                        const ClSectionHeader(label: '5 vežbi'),
                        ClExerciseRow(
                          index: 1,
                          name: 'Bench press',
                          detail: '4 × 6–8 · Prošli put ${formatSet(80, 8)}',
                        ),
                        ClExerciseRow(
                          index: 2,
                          name: 'Rameni potisak',
                          detail: '3 × 8–10 · Prošli put ${formatSet(42.5, 9)}',
                        ),
                        const ClExerciseRow(
                          index: 3,
                          name: 'Propadanja',
                          detail: '3 × 10 · Prošli put +10 kg',
                        ),
                        ClExerciseRow(
                          index: 4,
                          name: 'Odručenje',
                          detail: '3 × 12–15 · Prošli put ${formatSet(10, 14)}',
                        ),
                        ClExerciseRow(
                          index: 5,
                          name: 'Triceps sajla',
                          detail: '3 × 12 · Prošli put ${formatSet(25, 12)}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(ClSpace.s4, ClSpace.s2, ClSpace.s4, ClSpace.s3),
              child: ClButton.block(
                label: 'Počni trening',
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const ClThemeScopeDark(child: WorkoutExample())),
                ),
              ),
            ),
            ClBottomNav(selected: _nav, onChanged: (i) => setState(() => _nav = i)),
          ],
        ),
      ),
    );
  }
}

class ClThemeScopeDark extends StatelessWidget {
  const ClThemeScopeDark({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ClThemeScope(theme: ClTheme.dark, child: child);
}

/// Workout session: title + prescription → set table → rest timer → block button.
class WorkoutExample extends StatefulWidget {
  const WorkoutExample({super.key});

  @override
  State<WorkoutExample> createState() => _WorkoutExampleState();
}

class _WorkoutExampleState extends State<WorkoutExample> {
  var _sets = demoSets();
  int _restRun = 0;
  bool _resting = false;

  int get _current => _sets.indexWhere((s) => s.state == ClSetState.current);

  void _toggle(int i) {
    final wasDone = _sets[i].isDone;
    setState(() {
      _sets = toggleSet(_sets, i);
      if (!wasDone) {
        _resting = true;
        _restRun++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final done = _sets.where((s) => s.isDone).length;
    final allDone = _current < 0;
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
                    Expanded(child: Text('PUSH DAY · VEŽBA 1 / 5', style: cl.text.label)),
                    ClIconButton(icon: ClIcons.swap, semanticLabel: 'Zameni vežbu', onPressed: () {}),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(ClSpace.s4, ClSpace.s2, ClSpace.s4, ClSpace.s6),
                  children: [
                    const ClScreenTitle(label: '4 × 6–8 · RIR 2 · Odmor 2:00', title: 'Bench press'),
                    const SizedBox(height: ClSpace.s4),
                    const ClCreatorLine(name: demoCreator, trailing: 'Laktovi 45°'),
                    const SizedBox(height: ClSpace.s6),
                    ClSetTable(
                      sets: _sets,
                      onChanged: (i, d) => setState(() => _sets = [..._sets]..[i] = d),
                      onToggleDone: _toggle,
                    ),
                    const SizedBox(height: ClSpace.s2),
                    Text('Završeno $done / ${_sets.length}'.toUpperCase(), style: cl.text.label),
                    if (_resting) ...[
                      const SizedBox(height: ClSpace.s6),
                      ClRestTimer(
                        key: ValueKey(_restRun),
                        duration: const Duration(minutes: 2),
                        onSkip: () => setState(() => _resting = false),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(ClSpace.s4, ClSpace.s2, ClSpace.s4, ClSpace.s4),
                child: allDone
                    ? ClButton.block(
                        label: 'Završi trening',
                        onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => ClThemeScope(theme: ClTheme.light, child: const SummaryExample()),
                          ),
                        ),
                      )
                    : ClButton.block(label: 'Završi set', onPressed: () => _toggle(_current)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Workout summary in the light theme.
class SummaryExample extends StatelessWidget {
  const SummaryExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GalleryWidth(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: ClSpace.s1),
                  child: ClIconButton(
                    icon: ClIcons.close,
                    semanticLabel: 'Zatvori',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(ClSpace.s4, ClSpace.s4, ClSpace.s4, ClSpace.s6),
                  children: const [DemoSummary()],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(ClSpace.s4, ClSpace.s2, ClSpace.s4, ClSpace.s4),
                child: ClButton(
                  label: 'Gotovo',
                  variant: ClButtonVariant.ink,
                  expand: true,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
