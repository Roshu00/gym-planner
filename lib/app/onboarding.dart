import 'package:flutter/material.dart';

import '../config.dart';
import '../domain/models.dart';
import '../ui/chalkline_ui.dart';
import 'common.dart';

/// Name, goal, experience, where the user trains and their equipment.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.invitedBy});

  /// Creator whose link brought the user here.
  final Creator? invitedBy;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _steps = 5;
  int _step = 0;
  final _name = TextEditingController();
  Goal? _goal;
  Experience? _experience;
  Place? _place;
  Set<Equipment> _equipment = {};

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _valid => switch (_step) {
    0 => _name.text.trim().isNotEmpty,
    1 => _goal != null,
    2 => _experience != null,
    3 => _place != null,
    _ => true,
  };

  void _next() {
    FocusScope.of(context).unfocus();
    if (_step < _steps - 1) {
      setState(() => _step++);
      return;
    }
    context.readStore.completeOnboarding(
      UserProfile(
        name: _name.text.trim(),
        goal: _goal!,
        experience: _experience!,
        place: _place!,
        // How often to train comes from the plan the user picks.
        daysPerWeek: 3,
        equipment: _equipment,
      ),
    );
  }

  void _setPlace(Place p) => setState(() {
    if (_place != p) _equipment = {...p == Place.gym ? Equipment.gym : Equipment.home};
    _place = p;
  });

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final (String title, Widget body) = switch (_step) {
      0 => ('Kako se zoveš?', _nameStep(cl)),
      1 => (
        'Tvoj cilj.',
        Column(
          children: [
            for (final g in Goal.values)
              ClOptionRow(title: g.label, selected: _goal == g, onPressed: () => setState(() => _goal = g)),
          ],
        ),
      ),
      2 => (
        'Iskustvo.',
        Column(
          children: [
            for (final (e, meta) in [
              (Experience.beginner, 'Manje od 6 meseci redovnog treninga'),
              (Experience.intermediate, 'Od 6 meseci do 2 godine'),
              (Experience.advanced, 'Više od 2 godine'),
            ])
              ClOptionRow(
                title: e.label,
                meta: meta,
                selected: _experience == e,
                onPressed: () => setState(() => _experience = e),
              ),
          ],
        ),
      ),
      3 => (
        'Gde treniraš?',
        Column(
          children: [
            ClOptionRow(
              title: Place.gym.label,
              meta: 'Šipka, mašine, sajla',
              selected: _place == Place.gym,
              onPressed: () => _setPlace(Place.gym),
            ),
            ClOptionRow(
              title: Place.home.label,
              meta: 'Bučice, trake ili bez opreme',
              selected: _place == Place.home,
              onPressed: () => _setPlace(Place.home),
            ),
          ],
        ),
      ),
      _ => ('Tvoja oprema.', _equipmentStep(cl)),
    };

    return AppScreen(
      topBar: ClTopBar(
        label: 'Korak ${_step + 1} / $_steps',
        onBack: _step == 0 ? null : () => setState(() => _step--),
      ),
      bottom: ClButton.block(
        label: _step == _steps - 1 ? 'Počni' : 'Dalje',
        onPressed: _valid ? _next : null,
      ),
      children: [
        ClSegmentBar(total: _steps, done: _step + 1),
        const SizedBox(height: ClSpace.s6),
        if (_step == 0 && widget.invitedBy != null) ...[
          ClCreatorLine(name: widget.invitedBy!.name, trailing: 'Poziv'),
          gapS,
        ],
        ClScreenTitle(title: title, label: _step == 0 ? appName : null),
        const SizedBox(height: ClSpace.s6),
        body,
      ],
    );
  }

  Widget _nameStep(ClTheme cl) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        widget.invitedBy == null
            ? 'Treniraš po programu trenera kog pratiš. Aplikacija beleži svaki set i pokazuje napredak.'
            : 'Treniraš po programu koji je ${widget.invitedBy!.name} objavio. Prvo nekoliko pitanja.',
        style: cl.text.body.copyWith(color: cl.colors.inkMuted),
      ),
      const SizedBox(height: ClSpace.s6),
      ClTextField(label: 'Ime', hint: 'npr. Ana', controller: _name, onChanged: (_) => setState(() {})),
    ],
  );

  Widget _equipmentStep(ClTheme cl) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Programi pokazuju koliko ti odgovaraju, a vežbe za koje nemaš opremu dobijaju zamenu. Bez opreme se uvek podrazumeva.',
        style: cl.text.body.copyWith(color: cl.colors.inkMuted),
      ),
      gapS,
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
    ],
  );
}
