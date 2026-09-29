import '../ui/chalkline_ui.dart';

const demoCreator = 'Marko Petrović';
const demoCreatorHandle = '@marko.lifts';

List<ClSetData> demoSets() => const [
  ClSetData(previousKg: 80, previousReps: 8, kg: '80', reps: '8', rir: '2', state: ClSetState.done),
  ClSetData(previousKg: 80, previousReps: 8, state: ClSetState.current),
  ClSetData(previousKg: 80, previousReps: 7),
  ClSetData(previousKg: 77.5, previousReps: 8),
];

double _e1rm(double kg, int reps) => kg * (1 + reps / 30);

/// Demo-only behavior: confirming a set fills empty fields from last time,
/// flags a PR when the estimated 1RM beats last time's, and moves "current"
/// to the next open set. Real rules belong in the domain layer.
List<ClSetData> toggleSet(List<ClSetData> sets, int i) {
  final next = [...sets];
  final s = next[i];
  if (s.isDone) {
    next[i] = s.copyWith(state: ClSetState.current, isPr: false);
  } else {
    final kgText = s.kg.isEmpty && s.previousKg != null ? formatNumber(s.previousKg!) : s.kg;
    final repsText = s.reps.isEmpty && s.previousReps != null ? '${s.previousReps}' : s.reps;
    final kg = parseDecimal(kgText);
    final reps = int.tryParse(repsText);
    final isPr =
        kg != null &&
        reps != null &&
        s.previousKg != null &&
        s.previousReps != null &&
        _e1rm(kg, reps) > _e1rm(s.previousKg!, s.previousReps!);
    next[i] = s.copyWith(kg: kgText, reps: repsText, state: ClSetState.done, isPr: isPr);
  }
  final hasCurrent = next.any((x) => x.state == ClSetState.current);
  for (var j = 0; j < next.length; j++) {
    if (next[j].state == ClSetState.current && j != next.indexWhere((x) => x.state == ClSetState.current)) {
      next[j] = next[j].copyWith(state: ClSetState.pending);
    }
  }
  if (!hasCurrent) {
    final open = next.indexWhere((x) => x.state == ClSetState.pending);
    if (open >= 0) next[open] = next[open].copyWith(state: ClSetState.current);
  }
  return next;
}
