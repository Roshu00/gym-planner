import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../ui/chalkline_ui.dart';
import 'common.dart';

/// Single-choice filter row for an enum.
class _Choice<T> extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.values,
    required this.selected,
    required this.name,
    required this.onChanged,
  });

  final String label;
  final List<T> values;
  final T selected;
  final String Function(T) name;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label.toUpperCase(), style: context.clText.label),
      const SizedBox(height: ClSpace.s1),
      Wrap(
        spacing: ClSpace.s2,
        children: [
          for (final v in values)
            ClFilter(label: name(v), selected: v == selected, onChanged: (_) => onChanged(v)),
        ],
      ),
    ],
  );
}

Widget _audienceChoice(Audience value, ValueChanged<Audience> onChanged) => _Choice<Audience>(
  label: 'Ko vidi',
  values: Audience.values,
  selected: value,
  name: (a) => a.label,
  onChanged: onChanged,
);

Future<void> _delete(BuildContext context, String what, VoidCallback onDelete) async {
  final ok = await confirmClSheet(
    context,
    title: 'Obriši?',
    message: '$what se uklanja iz tvoje biblioteke. Pratioci zadržavaju svoju istoriju treninga.',
    confirmLabel: 'Obriši',
    danger: true,
  );
  if (ok && context.mounted) {
    onDelete();
    Navigator.of(context).pop();
  }
}

// ───────────────────────── Creator profile

class CreatorProfileEditor extends StatefulWidget {
  const CreatorProfileEditor({super.key});

  @override
  State<CreatorProfileEditor> createState() => _CreatorProfileEditorState();
}

class _CreatorProfileEditorState extends State<CreatorProfileEditor> {
  late final _me = context.readStore.myCreator;
  late final _name = TextEditingController(text: _me?.name ?? context.readStore.profile?.name ?? '');
  late final _handle = TextEditingController(text: _me?.handle ?? '');
  late final _tagline = TextEditingController(text: _me?.tagline ?? '');
  late final _bio = TextEditingController(text: _me?.bio ?? '');

  static final _handlePattern = RegExp(r'^[a-z0-9._]{3,30}$');

  @override
  void dispose() {
    for (final c in [_name, _handle, _tagline, _bio]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _cleanHandle => _handle.text.trim().replaceFirst('@', '').toLowerCase();

  String? get _handleError {
    if (_handle.text.isEmpty) return null;
    if (!_handlePattern.hasMatch(_cleanHandle)) {
      return 'Od 3 do 30 znakova: slova, brojevi, tačka i donja crta.';
    }
    final taken = context.readStore.creatorByHandle(_cleanHandle);
    if (taken != null && !taken.isMine) return 'Ovo ime je zauzeto.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final valid = _name.text.trim().isNotEmpty && _cleanHandle.isNotEmpty && _handleError == null;
    return AppScreen(
      topBar: const ClTopBar(label: 'Profil trenera'),
      bottom: ClButton.block(
        label: _me == null ? 'Napravi profil' : 'Sačuvaj',
        onPressed: valid
            ? () {
                final wasNew = _me == null;
                context.readStore.saveMyCreator(
                  name: _name.text.trim(),
                  handle: _cleanHandle,
                  tagline: _tagline.text.trim(),
                  bio: _bio.text.trim(),
                );
                if (!wasNew) Navigator.of(context).pop();
              }
            : null,
      ),
      children: [
        ClScreenTitle(label: 'Režim kreatora', title: _me == null ? 'Tvoj profil.' : 'Uredi profil.'),
        const SizedBox(height: ClSpace.s3),
        Text(
          'Napravi sistem jednom: vežbe, treninge i programe. Pratioci ga pretvaraju u svoj plan.',
          style: context.clText.body.copyWith(color: context.clColors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s6),
        ClTextField(label: 'Ime', controller: _name, onChanged: (_) => setState(() {})),
        gapS,
        ClTextField(
          label: 'Korisničko ime',
          hint: 'npr. ana.trener',
          controller: _handle,
          error: _handleError,
          onChanged: (_) => setState(() {}),
        ),
        gapS,
        ClTextField(label: 'Opis u jednom redu', hint: 'npr. Snaga za početnike', controller: _tagline),
        gapS,
        ClTextField(label: 'O tebi', controller: _bio, maxLines: 4),
      ],
    );
  }
}

// ───────────────────────── Exercise

class ExerciseEditor extends StatefulWidget {
  const ExerciseEditor({super.key, this.exerciseId});

  final String? exerciseId;

  @override
  State<ExerciseEditor> createState() => _ExerciseEditorState();
}

class _ExerciseEditorState extends State<ExerciseEditor> {
  late final Exercise? _existing = widget.exerciseId == null
      ? null
      : context.readStore.exercisesById[widget.exerciseId];
  late final _name = TextEditingController(text: _existing?.name ?? '');
  late final _note = TextEditingController(text: _existing?.note ?? '');
  late Muscle _muscle = _existing?.muscle ?? Muscle.chest;
  late Set<Equipment> _equipment = {...?_existing?.equipment}..remove(Equipment.bodyweight);
  late Audience _audience = _existing?.visibility ?? Audience.public;

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    final store = context.readStore;
    store.saveExercise(
      Exercise(
        id: _existing?.id ?? store.newId('e'),
        creatorId: store.myCreator!.id,
        name: _name.text.trim(),
        muscle: _muscle,
        equipment: _equipment.isEmpty ? const {Equipment.bodyweight} : _equipment,
        note: _note.text.trim(),
        visibility: _audience,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      topBar: ClTopBar(label: _existing == null ? 'Nova vežba' : 'Uredi vežbu'),
      bottom: ClButton.block(label: 'Sačuvaj', onPressed: _name.text.trim().isEmpty ? null : _save),
      children: [
        ClTextField(
          label: 'Naziv',
          hint: 'npr. Bench press',
          controller: _name,
          onChanged: (_) => setState(() {}),
        ),
        gapS,
        _Choice<Muscle>(
          label: 'Mišićna grupa',
          values: Muscle.values,
          selected: _muscle,
          name: (m) => m.label,
          onChanged: (m) => setState(() => _muscle = m),
        ),
        gapS,
        Text('OPREMA · SVE ŠTO JE POTREBNO', style: context.clText.label),
        const SizedBox(height: ClSpace.s1),
        Wrap(
          spacing: ClSpace.s2,
          children: [
            for (final e in Equipment.values.where((e) => e != Equipment.bodyweight))
              ClFilter(
                label: e.label,
                selected: _equipment.contains(e),
                onChanged: (on) =>
                    setState(() => _equipment = on ? {..._equipment, e} : ({..._equipment}..remove(e))),
              ),
          ],
        ),
        const SizedBox(height: ClSpace.s1),
        ClNotice(
          _equipment.isEmpty
              ? 'Bez opreme: svi pratioci mogu da je rade.'
              : 'Pratioci bez ove opreme dobijaju zamenu.',
        ),
        gapS,
        ClTextField(label: 'Napomena', hint: 'Šta pratilac treba da zapamti', controller: _note, maxLines: 3),
        gapS,
        _audienceChoice(_audience, (a) => setState(() => _audience = a)),
        if (_existing != null) ...[
          gap,
          Align(
            alignment: Alignment.centerLeft,
            child: ClButton(
              label: 'Obriši vežbu',
              variant: ClButtonVariant.danger,
              onPressed: () =>
                  _delete(context, 'Vežba', () => context.readStore.deleteExercise(_existing.id)),
            ),
          ),
        ],
      ],
    );
  }
}

// ───────────────────────── Workout

class WorkoutEditor extends StatefulWidget {
  const WorkoutEditor({super.key, this.workoutId});

  final String? workoutId;

  @override
  State<WorkoutEditor> createState() => _WorkoutEditorState();
}

class _WorkoutEditorState extends State<WorkoutEditor> {
  late final Workout? _existing = widget.workoutId == null
      ? null
      : context.readStore.workoutsById[widget.workoutId];
  late final _name = TextEditingController(text: _existing?.name ?? '');
  late final _message = TextEditingController(text: _existing?.finishMessage ?? '');
  late List<WorkoutExercise> _items = [...?_existing?.exercises];
  late Audience _audience = _existing?.visibility ?? Audience.public;

  @override
  void dispose() {
    _name.dispose();
    _message.dispose();
    super.dispose();
  }

  void _update(int i, WorkoutExercise we) => setState(() => _items = [..._items]..[i] = we);

  Future<void> _add() async {
    final store = context.readStore;
    final id = await showClSheet<String>(
      context,
      title: 'Dodaj vežbu',
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (store.myExercises.isEmpty) const ClNotice('Nemaš vežbe. Napravi ih u režimu kreatora.'),
          for (final e in store.myExercises)
            ClListRow(
              title: e.name,
              meta: '${e.muscle.label} · ${e.equipmentLabel}',
              onPressed: () => Navigator.of(context).pop(e.id),
            ),
        ],
      ),
    );
    if (id != null) setState(() => _items = [..._items, WorkoutExercise(exerciseId: id)]);
  }

  void _save() {
    final store = context.readStore;
    store.saveWorkout(
      Workout(
        id: _existing?.id ?? store.newId('w'),
        creatorId: store.myCreator!.id,
        name: _name.text.trim(),
        exercises: _items,
        finishMessage: _message.text.trim(),
        visibility: _audience,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final cl = context.cl;
    final draft = Workout(id: '', creatorId: '', name: '', exercises: _items);
    return AppScreen(
      topBar: ClTopBar(label: _existing == null ? 'Novi trening' : 'Uredi trening'),
      bottom: ClButton.block(
        label: 'Sačuvaj',
        onPressed: _name.text.trim().isEmpty || _items.isEmpty ? null : _save,
      ),
      children: [
        ClTextField(
          label: 'Naziv',
          hint: 'npr. Push day',
          controller: _name,
          onChanged: (_) => setState(() {}),
        ),
        gapS,
        ClTextField(
          label: 'Poruka posle treninga',
          hint: 'npr. Sledeće je Pull. Isti ritam.',
          controller: _message,
          maxLines: 2,
        ),
        gapS,
        _audienceChoice(_audience, (a) => setState(() => _audience = a)),
        gap,
        ClSectionHeader(
          label: 'Vežbe · ${draft.totalSets} setova · ~${_items.isEmpty ? 0 : draft.estimatedMinutes} min',
        ),
        for (final (i, we) in _items.indexed) ...[
          Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '${i + 1}'.padLeft(2, '0'),
                  style: cl.text.data.copyWith(color: cl.colors.inkMuted),
                ),
              ),
              Expanded(
                child: Text(store.exercisesById[we.exerciseId]?.name ?? '—', style: cl.text.bodyStrong),
              ),
              ClButton(
                label: 'Ukloni',
                variant: ClButtonVariant.text,
                onPressed: () => setState(() => _items = [..._items]..removeAt(i)),
              ),
            ],
          ),
          ClStepper(
            label: 'Setovi',
            value: we.sets,
            min: 1,
            max: 10,
            onChanged: (v) => _update(i, we.copyWith(sets: v)),
          ),
          ClStepper(
            label: 'Ponavljanja od',
            value: we.repsMin,
            min: 1,
            max: 50,
            onChanged: (v) => _update(i, we.copyWith(repsMin: v, repsMax: v > we.repsMax ? v : null)),
          ),
          ClStepper(
            label: 'Ponavljanja do',
            value: we.repsMax,
            min: we.repsMin,
            max: 50,
            onChanged: (v) => _update(i, we.copyWith(repsMax: v)),
          ),
          ClStepper(
            label: 'Odmor',
            value: we.restSeconds,
            min: 15,
            max: 300,
            step: 15,
            format: (s) => formatClock(Duration(seconds: s)),
            onChanged: (v) => _update(i, we.copyWith(restSeconds: v)),
          ),
          const ClDivider(),
          gapS,
        ],
        ClButton(
          label: 'Dodaj vežbu',
          variant: ClButtonVariant.secondary,
          icon: ClIcons.add,
          expand: true,
          onPressed: _add,
        ),
        if (_existing != null) ...[
          gap,
          Align(
            alignment: Alignment.centerLeft,
            child: ClButton(
              label: 'Obriši trening',
              variant: ClButtonVariant.danger,
              onPressed: () =>
                  _delete(context, 'Trening', () => context.readStore.deleteWorkout(_existing.id)),
            ),
          ),
        ],
      ],
    );
  }
}

// ───────────────────────── Program

class ProgramEditor extends StatefulWidget {
  const ProgramEditor({super.key, this.programId});

  final String? programId;

  @override
  State<ProgramEditor> createState() => _ProgramEditorState();
}

class _ProgramEditorState extends State<ProgramEditor> {
  late final Program? _existing = widget.programId == null
      ? null
      : context.readStore.programsById[widget.programId];
  late final _name = TextEditingController(text: _existing?.name ?? '');
  late final _description = TextEditingController(text: _existing?.description ?? '');
  late List<String> _workoutIds = [...?_existing?.workoutIds];
  late int _weeks = _existing?.weeks ?? 6;
  late int _days = _existing?.daysPerWeek ?? 3;
  late Experience _level = _existing?.level ?? Experience.beginner;
  late Goal _goal = _existing?.goal ?? Goal.general;
  late Place _place = _existing?.place ?? Place.gym;
  late Audience _audience = _existing?.visibility ?? Audience.public;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final store = context.readStore;
    final id = await showClSheet<String>(
      context,
      title: 'Dodaj trening',
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (store.myWorkouts.isEmpty) const ClNotice('Nemaš treninge. Napravi ih u režimu kreatora.'),
          for (final w in store.myWorkouts)
            ClListRow(title: w.name, meta: workoutMeta(w), onPressed: () => Navigator.of(context).pop(w.id)),
        ],
      ),
    );
    if (id != null) setState(() => _workoutIds = [..._workoutIds, id]);
  }

  void _save() {
    final store = context.readStore;
    store.saveProgram(
      Program(
        id: _existing?.id ?? store.newId('p'),
        creatorId: store.myCreator!.id,
        name: _name.text.trim(),
        description: _description.text.trim(),
        workoutIds: _workoutIds,
        weeks: _weeks,
        daysPerWeek: _days,
        level: _level,
        goal: _goal,
        place: _place,
        visibility: _audience,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final cl = context.cl;
    return AppScreen(
      topBar: ClTopBar(label: _existing == null ? 'Novi program' : 'Uredi program'),
      bottom: ClButton.block(
        label: 'Sačuvaj',
        onPressed: _name.text.trim().isEmpty || _workoutIds.isEmpty ? null : _save,
      ),
      children: [
        ClTextField(
          label: 'Naziv',
          hint: 'npr. Snaga 8',
          controller: _name,
          onChanged: (_) => setState(() {}),
        ),
        gapS,
        ClTextField(label: 'Opis', controller: _description, maxLines: 3),
        gapS,
        ClStepper(
          label: 'Nedelje',
          value: _weeks,
          min: 1,
          max: 24,
          onChanged: (v) => setState(() => _weeks = v),
        ),
        ClStepper(
          label: 'Treninga nedeljno',
          value: _days,
          min: 1,
          max: 7,
          onChanged: (v) => setState(() => _days = v),
        ),
        gapS,
        _Choice<Experience>(
          label: 'Nivo',
          values: Experience.values,
          selected: _level,
          name: (e) => e.label,
          onChanged: (e) => setState(() => _level = e),
        ),
        gapS,
        _Choice<Goal>(
          label: 'Cilj',
          values: Goal.values,
          selected: _goal,
          name: (g) => g.label,
          onChanged: (g) => setState(() => _goal = g),
        ),
        gapS,
        _Choice<Place>(
          label: 'Mesto',
          values: Place.values,
          selected: _place,
          name: (p) => p.label,
          onChanged: (p) => setState(() => _place = p),
        ),
        gapS,
        _audienceChoice(_audience, (a) => setState(() => _audience = a)),
        gap,
        const ClSectionHeader(label: 'Rotacija treninga'),
        if (_workoutIds.isEmpty) const ClNotice('Treninzi se smenjuju ovim redom, bez obzira na datum.'),
        for (final (i, id) in _workoutIds.indexed)
          ClListRow(
            leading: SizedBox(
              width: 24,
              child: Text(
                '${i + 1}'.padLeft(2, '0'),
                style: cl.text.data.copyWith(color: cl.colors.inkMuted),
              ),
            ),
            title: store.workoutsById[id]?.name ?? '—',
            meta: store.workoutsById[id] == null ? null : workoutMeta(store.workoutsById[id]!),
            trailing: ClIconButton(
              icon: ClIcons.close,
              semanticLabel: 'Ukloni iz rotacije',
              onPressed: () => setState(() => _workoutIds = [..._workoutIds]..removeAt(i)),
            ),
          ),
        gapS,
        ClButton(
          label: 'Dodaj trening',
          variant: ClButtonVariant.secondary,
          icon: ClIcons.add,
          expand: true,
          onPressed: _add,
        ),
        if (_existing != null) ...[
          gap,
          Align(
            alignment: Alignment.centerLeft,
            child: ClButton(
              label: 'Obriši program',
              variant: ClButtonVariant.danger,
              onPressed: () =>
                  _delete(context, 'Program', () => context.readStore.deleteProgram(_existing.id)),
            ),
          ),
        ],
      ],
    );
  }
}
