import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens/spacing.dart';
import 'button.dart';
import 'icons.dart';
import 'pressable.dart';

enum ClDayMark {
  none,

  /// A finished workout. Lime day with a check.
  done,

  /// A workout the plan expects on this day. Lilac day with a barbell.
  planned,

  /// A rest day: a quiet moon. Never styled as a failure.
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

/// Day cell height: compact, and with the cell width still a comfortable target.
const _cell = 42.0;
const _weekdayNames = ['ponedeljak', 'utorak', 'sreda', 'četvrtak', 'petak', 'subota', 'nedelja'];

String _markLabel(ClDayMark m) => switch (m) {
  ClDayMark.done => 'urađen trening',
  ClDayMark.planned => 'planiran trening',
  ClDayMark.rest => 'odmor',
  ClDayMark.none => '',
};

/// Compact month calendar on a white card, Monday first. Each day shows its
/// number and a small icon: done (lime), planned (lilac) or rest. Selected = ink.
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

    return Container(
      padding: const EdgeInsets.fromLTRB(ClSpace.s2, ClSpace.s1, ClSpace.s2, ClSpace.s2),
      decoration: BoxDecoration(
        color: cl.colors.surface,
        borderRadius: BorderRadius.circular(ClRadius.lg),
        boxShadow: ClElevation.card(cl.colors.shadow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SizedBox(width: ClSpace.s2),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    '${_months[month.month - 1]} ${month.year}',
                    style: cl.text.bodyStrong.copyWith(fontSize: 17),
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
          const SizedBox(height: ClSpace.s1),
          for (var r = 0; r < rows; r++)
            Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final n = r * 7 + c - leading + 1;
                        if (n < 1 || n > daysInMonth) return const SizedBox(height: _cell + 2);
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
      ),
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
    final (IconData? icon, Color? fill) = switch (mark) {
      ClDayMark.done => (ClIcons.check, c.lime),
      ClDayMark.planned => (ClIcons.barbell, c.lilac),
      ClDayMark.rest => (ClIcons.rest, null),
      ClDayMark.none => (null, null),
    };
    final bg = isSelected ? c.ink : (fill ?? Colors.transparent);
    final fg = isSelected ? c.bg : (fill != null ? c.onPop : c.ink);
    final iconColor = isSelected || fill != null ? fg : c.inkMuted;
    final label = [
      '${day.day}. ${day.month}.',
      _weekdayNames[day.weekday - 1],
      if (isToday) 'danas',
      if (mark != ClDayMark.none) _markLabel(mark),
    ].join(', ');

    return Padding(
      padding: const EdgeInsets.all(1),
      child: ClPressable(
        onPressed: onTap,
        selected: isSelected,
        semanticLabel: label,
        builder: (context, pressed) => AnimatedContainer(
          duration: context.motion(ClMotion.fast),
          curve: ClMotion.curve,
          height: _cell,
          decoration: BoxDecoration(
            color: pressed && fill == null && !isSelected ? c.surfaceRaised : bg,
            borderRadius: BorderRadius.circular(ClRadius.xs + 4),
            border: isToday && !isSelected ? Border.all(color: c.ink, width: 2) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${day.day}', style: cl.text.data.copyWith(color: fg, fontSize: 13, height: 1.1)),
              const SizedBox(height: 1),
              SizedBox(height: 13, child: icon == null ? null : Icon(icon, size: 13, color: iconColor)),
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
    Widget item(IconData icon, Color? fill, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(6)),
          child: Icon(icon, size: 12, color: fill == null ? c.inkMuted : c.onPop),
        ),
        const SizedBox(width: ClSpace.s1 + 2),
        Text(text, style: cl.text.label),
      ],
    );
    return ExcludeSemantics(
      child: Wrap(
        spacing: ClSpace.s4,
        runSpacing: ClSpace.s2,
        children: [
          item(ClIcons.check, c.lime, 'Urađeno'),
          item(ClIcons.barbell, c.lilac, 'Planirano'),
          item(ClIcons.rest, null, 'Odmor'),
        ],
      ),
    );
  }
}
