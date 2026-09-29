import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens/spacing.dart';
import 'button.dart';
import 'icons.dart';
import 'pressable.dart';

enum ClDayMark {
  none,

  /// A finished workout. Shown with a check in `signal-text` (progress).
  done,

  /// A workout the plan expects on this day.
  planned,

  /// A rest day. Never styled as a failure.
  rest,
}

const _months = [
  'Januar',
  'Februar',
  'Mart',
  'April',
  'Maj',
  'Jun',
  'Jul',
  'Avgust',
  'Septembar',
  'Oktobar',
  'Novembar',
  'Decembar',
];
const _weekdays = ['P', 'U', 'S', 'Č', 'P', 'S', 'N'];
const _weekdayNames = ['ponedeljak', 'utorak', 'sreda', 'četvrtak', 'petak', 'subota', 'nedelja'];

String _markLabel(ClDayMark m) => switch (m) {
  ClDayMark.done => 'urađen trening',
  ClDayMark.planned => 'planiran trening',
  ClDayMark.rest => 'odmor',
  ClDayMark.none => '',
};

/// Month calendar, Monday first. Each day shows its number and one icon:
/// done, planned or rest. The selected day is filled with `ink`.
class ClCalendar extends StatelessWidget {
  const ClCalendar({
    super.key,
    required this.month,
    required this.selected,
    required this.today,
    required this.markFor,
    required this.onSelect,
    required this.onMonthChanged,
  });

  /// Any day in the month to show.
  final DateTime month;
  final DateTime selected;
  final DateTime today;
  final ClDayMark Function(DateTime day) markFor;
  final ValueChanged<DateTime> onSelect;
  final ValueChanged<DateTime> onMonthChanged;

  static bool _same(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final first = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = first.weekday - 1;
    final rows = ((leading + daysInMonth) / 7).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  '${_months[month.month - 1]} ${month.year}'.toUpperCase(),
                  style: cl.text.displayM.copyWith(fontSize: 32, height: 1),
                ),
              ),
            ),
            ClIconButton(
              icon: ClIcons.back,
              semanticLabel: 'Prethodni mesec',
              onPressed: () => onMonthChanged(DateTime(month.year, month.month - 1)),
            ),
            ClIconButton(
              icon: ClIcons.chevron,
              semanticLabel: 'Sledeći mesec',
              onPressed: () => onMonthChanged(DateTime(month.year, month.month + 1)),
            ),
          ],
        ),
        const SizedBox(height: ClSpace.s3),
        ExcludeSemantics(
          child: Row(
            children: [
              for (final d in _weekdays)
                Expanded(
                  child: Text(d, textAlign: TextAlign.center, style: cl.text.label),
                ),
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s2),
        for (var r = 0; r < rows; r++)
          Row(
            children: [
              for (var c = 0; c < 7; c++)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final n = r * 7 + c - leading + 1;
                      if (n < 1 || n > daysInMonth) return const SizedBox(height: ClSize.targetWorkout);
                      final day = DateTime(month.year, month.month, n);
                      return _DayCell(
                        day: day,
                        mark: markFor(day),
                        isToday: _same(day, today),
                        isSelected: _same(day, selected),
                        onTap: () => onSelect(day),
                      );
                    },
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.mark,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime day;
  final ClDayMark mark;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    final fg = isSelected ? c.bg : c.ink;
    final (IconData? icon, Color iconColor) = switch (mark) {
      ClDayMark.done => (ClIcons.check, isSelected ? c.bg : c.signalText),
      ClDayMark.planned => (ClIcons.barbell, isSelected ? c.bg : c.ink),
      ClDayMark.rest => (ClIcons.rest, isSelected ? c.bg : c.inkMuted),
      ClDayMark.none => (null, c.inkMuted),
    };
    final label = [
      '${day.day}. ${day.month}.',
      _weekdayNames[day.weekday - 1],
      if (isToday) 'danas',
      if (mark != ClDayMark.none) _markLabel(mark),
    ].join(', ');

    return Padding(
      padding: const EdgeInsets.all(2),
      child: ClPressable(
        onPressed: onTap,
        selected: isSelected,
        semanticLabel: label,
        builder: (context, pressed) => AnimatedContainer(
          duration: context.motion(ClMotion.fast),
          curve: ClMotion.curve,
          height: ClSize.targetWorkout,
          decoration: BoxDecoration(
            color: isSelected ? c.ink : (pressed ? c.surfaceRaised : Colors.transparent),
            borderRadius: BorderRadius.circular(ClRadius.sm),
            border: isToday && !isSelected ? Border.all(color: c.ink, width: ClSize.rule) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${day.day}', style: cl.text.data.copyWith(color: fg, fontSize: 14)),
              const SizedBox(height: 2),
              SizedBox(height: 16, child: icon == null ? null : Icon(icon, size: 16, color: iconColor)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Explains the day icons, under the calendar.
class ClCalendarLegend extends StatelessWidget {
  const ClCalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    Widget item(IconData icon, Color color, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: ClSpace.s1),
        Text(text.toUpperCase(), style: cl.text.label),
      ],
    );
    return ExcludeSemantics(
      child: Wrap(
        spacing: ClSpace.s4,
        runSpacing: ClSpace.s2,
        children: [
          item(ClIcons.check, c.signalText, 'Urađeno'),
          item(ClIcons.barbell, c.ink, 'Planirano'),
          item(ClIcons.rest, c.inkMuted, 'Odmor'),
        ],
      ),
    );
  }
}
