import 'package:flutter/material.dart';

import '../config.dart';
import '../domain/models.dart';
import '../ui/chalkline_ui.dart';
import 'common.dart';

/// Name, goal, experience, where and how often the user trains. One question
/// per step; picking an answer moves on by itself. Equipment follows from the
/// place and gender is optional in Profile, so neither is asked here.
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
  bool _advancing = false;
  final _name = TextEditingController();
  Goal? _goal;
  Experience? _experience;
  Place? _place;
  int? _days;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

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
        daysPerWeek: _days!,
        equipment: {...(_place == Place.gym ? Equipment.gym : Equipment.home)},
      ),
    );
  }

  /// Shows the choice for a moment, then moves on.
  Future<void> _pick(VoidCallback select) async {
    if (_advancing) return;
    setState(() {
      select();
      _advancing = true;
    });
    await Future<void>.delayed(context.motion(const Duration(milliseconds: 220)));
    if (!mounted) return;
    _advancing = false;
    _next();
  }

  Widget _options<T>(List<(T, String, String?)> options, T? selected, ValueChanged<T> onSelect) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (value, title, meta) in options)
        ClOptionRow(
          title: title,
          meta: meta,
          selected: selected == value,
          onPressed: () => _pick(() => onSelect(value)),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final (String title, String? hint, Widget body) = switch (_step) {
      0 => ('Kako se zoveš?', null, _nameStep(cl)),
      1 => (
        'Šta ti je cilj?',
        null,
        _options(
          [
            (Goal.strength, 'Snaga', 'Da dižeš više'),
            (Goal.muscle, 'Mišićna masa', 'Da izgledaš jače'),
            (Goal.conditioning, 'Kondicija', 'Da imaš više daha i energije'),
            (Goal.general, 'Opšta forma', 'Da se osećaš bolje'),
          ],
          _goal,
          (g) => _goal = g,
        ),
      ),
      2 => (
        'Koliko dugo treniraš?',
        null,
        _options(
          [
            (Experience.beginner, 'Tek počinjem', 'Manje od 6 meseci redovnog treninga'),
            (Experience.intermediate, 'Neko vreme', 'Od 6 meseci do 2 godine'),
            (Experience.advanced, 'Dugo', 'Više od 2 godine'),
          ],
          _experience,
          (e) => _experience = e,
        ),
      ),
      3 => (
        'Gde treniraš?',
        'Prema tome biramo vežbe. Opremu menjaš u profilu.',
        _options(
          [
            (Place.gym, Place.gym.label, 'Šipka, mašine, sajla'),
            (Place.home, Place.home.label, 'Bučice, trake ili bez opreme'),
          ],
          _place,
          (p) => _place = p,
        ),
      ),
      _ => (
        'Koliko dana nedeljno?',
        'Plan to prati. Svaki dan možeš da pomeriš.',
        _options(
          [
            (2, '2 dana', 'Za početak, uz posao ili školu'),
            (3, '3 dana', 'Najčešći izbor'),
            (4, '4 dana', 'Za brži napredak'),
            (5, '5 i više', 'Ako već treniraš redovno'),
          ],
          _days,
          (d) => _days = d,
        ),
      ),
    };

    return AppScreen(
      topBar: ClTopBar(
        label: 'Korak ${_step + 1} / $_steps',
        onBack: _step == 0 || _advancing ? null : () => setState(() => _step--),
      ),
      // Choices move on by themselves; only the name needs a button.
      bottom: _step == 0
          ? ClButton.block(label: 'Dalje', onPressed: _name.text.trim().isEmpty ? null : _next)
          : null,
      children: [
        ClSegmentBar(total: _steps, done: _step + 1),
        const SizedBox(height: ClSpace.s6),
        if (_step == 0 && widget.invitedBy != null) ...[
          ClCreatorLine(
            name: widget.invitedBy!.name,
            image: photoOf(widget.invitedBy!.photo),
            trailing: 'Poziv',
          ),
          gapS,
        ],
        ClScreenTitle(title: title, label: _step == 0 ? appName : null),
        if (hint != null) ...[
          const SizedBox(height: ClSpace.s2),
          Text(hint, style: cl.text.body.copyWith(color: cl.colors.inkMuted)),
        ],
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
            : 'Treniraš po programu koji je ${widget.invitedBy!.name} objavio. Prvo četiri kratka pitanja.',
        style: cl.text.body.copyWith(color: cl.colors.inkMuted),
      ),
      const SizedBox(height: ClSpace.s6),
      ClTextField(label: 'Ime', hint: 'npr. Ana', controller: _name, onChanged: (_) => setState(() {})),
    ],
  );
}
