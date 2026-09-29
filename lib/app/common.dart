import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../domain/models.dart';
import '../ui/chalkline_ui.dart';

/// Makes [AppStore] available and rebuilds dependents when it changes.
class AppScope extends InheritedNotifier<AppStore> {
  const AppScope({super.key, required AppStore store, required super.child}) : super(notifier: store);

  static AppStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// For callbacks: reads without subscribing to rebuilds.
  static AppStore read(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

extension StoreContext on BuildContext {
  AppStore get store => AppScope.of(this);
  AppStore get readStore => AppScope.read(this);
}

/// Pushes [screen] in the theme DESIGN.md assigns to it.
Future<T?> pushScreen<T>(BuildContext context, Widget screen, {ClTheme? theme, bool replace = false}) {
  final route = MaterialPageRoute<T>(
    builder: (_) => ClThemeScope(theme: theme ?? ClTheme.dark, child: screen),
  );
  final nav = Navigator.of(context);
  return replace ? nav.pushReplacement(route) : nav.push(route);
}

/// Phone-width column on wide screens.
class AppWidth extends StatelessWidget {
  const AppWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: child),
  );
}

/// Standard screen: top bar, scrolling content with the 16px gutter, and an
/// optional action pinned to the bottom (the one primary button).
class AppScreen extends StatelessWidget {
  const AppScreen({
    super.key,
    required this.children,
    this.topBar,
    this.bottom,
    this.padding = const EdgeInsets.fromLTRB(ClSpace.s4, ClSpace.s2, ClSpace.s4, ClSpace.s12),
    this.header,
    this.safeTop = true,
  });

  final Widget? topBar;

  /// Full-bleed content above the padded list (e.g. a hero).
  final Widget? header;
  final List<Widget> children;
  final Widget? bottom;
  final EdgeInsets padding;
  final bool safeTop;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: safeTop,
        bottom: bottom == null,
        child: AppWidth(
          child: Column(
            children: [
              ?topBar,
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ?header,
                    Padding(
                      padding: padding,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
                    ),
                  ],
                ),
              ),
              if (bottom != null)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(ClSpace.s4, ClSpace.s2, ClSpace.s4, ClSpace.s3),
                    child: bottom,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vertical rhythm between blocks.
const gap = SizedBox(height: ClSpace.s8);
const gapS = SizedBox(height: ClSpace.s4);

// ───────────────────────── Copy helpers

String weeksLabel(int n) => '$n ${plural(n, 'nedelja', 'nedelje', 'nedelja')}';

String programMeta(Program p) => '${weeksLabel(p.weeks)} · ${p.daysPerWeek}× nedeljno';

String workoutMeta(Workout w) =>
    '${countLabel(w.exercises.length, 'vežba', 'vežbe', 'vežbi')} · ~${w.estimatedMinutes} min';

String followersLabel(int n) => '${formatCompact(n)} ${plural(n, 'pratilac', 'pratioca', 'pratilaca')}';

String restLabel(int seconds) => 'Odmor ${formatClock(Duration(seconds: seconds))}';

/// `4 × 6–8 · RIR 2 · Odmor 2:00`
String prescription(String target, int? rir, int restSeconds) =>
    [target, if (rir != null) 'RIR $rir', restLabel(restSeconds)].join(' · ');

/// `80 kg × 8`, or `12 pon.` for bodyweight without added load.
String setLabel(SetLog s) {
  final kg = s.kg ?? 0;
  final reps = s.reps ?? 0;
  return kg > 0 ? formatSet(kg, reps) : '$reps pon.';
}

String sessionMeta(Session s) =>
    '${formatDate(s.finishedAt ?? s.startedAt)} · ${formatDuration(s.duration)} · ${formatKg(s.volume)}';
