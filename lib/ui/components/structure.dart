import 'package:flutter/material.dart';

import '../format.dart';
import '../theme.dart';
import '../tokens/spacing.dart';
import 'button.dart';
import 'icons.dart';
import 'pressable.dart';
import 'rule.dart';
import 'summary.dart';

/// Screen top bar: back, a `label`, optional trailing actions. 48px targets.
class ClTopBar extends StatelessWidget {
  const ClTopBar({super.key, this.label, this.onBack, this.actions = const [], this.backLabel = 'Nazad'});

  final String? label;

  /// Defaults to popping the route when one can be popped.
  final VoidCallback? onBack;
  final List<Widget> actions;
  final String backLabel;

  @override
  Widget build(BuildContext context) {
    final canPop = onBack != null || Navigator.of(context).canPop();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ClSpace.s1),
      child: SizedBox(
        height: ClSize.target,
        child: Row(
          children: [
            if (canPop)
              ClIconButton(
                icon: ClIcons.back,
                semanticLabel: backLabel,
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              )
            else
              const SizedBox(width: ClSpace.s3),
            Expanded(
              child: label == null
                  ? const SizedBox()
                  : Text(
                      label!.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.clText.label,
                    ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}

/// Selectable row for single or multiple choice. Selected = 2px ink border
/// and a check; never color alone.
class ClOptionRow extends StatelessWidget {
  const ClOptionRow({
    super.key,
    required this.title,
    required this.selected,
    required this.onPressed,
    this.meta,
  });

  final String title;
  final String? meta;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: ClSpace.s2),
      child: ClPressable(
        onPressed: onPressed,
        selected: selected,
        semanticLabel: meta == null ? title : '$title, $meta',
        builder: (context, pressed) => AnimatedContainer(
          duration: context.motion(ClMotion.fast),
          curve: ClMotion.curve,
          constraints: const BoxConstraints(minHeight: ClSize.targetWorkout),
          padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4, vertical: ClSpace.s3),
          decoration: BoxDecoration(
            color: pressed ? c.surfaceRaised : (selected ? c.surface : Colors.transparent),
            borderRadius: BorderRadius.circular(ClRadius.sm),
            border: Border.all(color: selected ? c.ink : c.borderStrong, width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: cl.text.bodyStrong),
                    if (meta != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        meta!,
                        style: cl.text.body.copyWith(color: c.inkMuted, fontSize: 13, height: 18 / 13),
                      ),
                    ],
                  ],
                ),
              ),
              AnimatedOpacity(
                duration: context.motion(ClMotion.fast),
                opacity: selected ? 1 : 0,
                child: Icon(ClIcons.check, size: 20, color: c.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Number with − and + buttons: sets, reps, weeks.
class ClStepper extends StatelessWidget {
  const ClStepper({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 99,
    this.step = 1,
    this.format,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final int step;
  final String Function(int)? format;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Semantics(
      label: label,
      value: format?.call(value) ?? '$value',
      child: Row(
        children: [
          Expanded(child: Text(label.toUpperCase(), style: cl.text.label)),
          ClIconButton(
            icon: ClIcons.remove,
            semanticLabel: 'Smanji $label',
            onPressed: value - step >= min ? () => onChanged(value - step) : null,
          ),
          SizedBox(
            width: 64,
            child: Text(format?.call(value) ?? '$value', textAlign: TextAlign.center, style: cl.text.data),
          ),
          ClIconButton(
            icon: ClIcons.add,
            semanticLabel: 'Povećaj $label',
            onPressed: value + step <= max ? () => onChanged(value + step) : null,
          ),
        ],
      ),
    );
  }
}

/// Empty state: a condensed title, one sentence, one action.
/// Keeps a number on screen when there is one to show.
class ClEmptyState extends StatelessWidget {
  const ClEmptyState({super.key, required this.title, required this.message, this.label, this.action});

  final String title;
  final String message;
  final String? label;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ClRule(),
        const SizedBox(height: ClSpace.s6),
        ClScreenTitle(title: title, label: label),
        const SizedBox(height: ClSpace.s3),
        Text(message, style: cl.text.body.copyWith(color: cl.colors.inkMuted)),
        if (action != null) ...[const SizedBox(height: ClSpace.s6), action!],
      ],
    );
  }
}

/// Inline message under a control, e.g. why a set couldn't be confirmed.
class ClNotice extends StatelessWidget {
  const ClNotice(this.message, {super.key, this.danger = false});

  final String message;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Semantics(
      liveRegion: true,
      child: Text(
        message,
        style: cl.text.body.copyWith(color: danger ? cl.colors.danger : cl.colors.inkMuted),
      ),
    );
  }
}

/// Bottom sheet: square top, 2px rule, `display-m` title. 250 ms.
Future<T?> showClSheet<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
  String? label,
}) {
  final theme = context.cl;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: theme.colors.bg,
    barrierColor: theme.colors.photoScrim,
    elevation: 0,
    shape: const RoundedRectangleBorder(),
    sheetAnimationStyle: const AnimationStyle(duration: ClMotion.sheet, reverseDuration: ClMotion.sheet),
    builder: (context) => ClThemeScope(
      theme: theme,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ClRule(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(ClSpace.s4, ClSpace.s4, ClSpace.s1, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClScreenTitle(title: title, label: label),
                        ),
                        ClIconButton(
                          icon: ClIcons.close,
                          semanticLabel: 'Zatvori',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(ClSpace.s4, ClSpace.s4, ClSpace.s4, ClSpace.s6),
                      child: builder(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Confirmation built into the page (no system dialogs). Returns true on confirm.
Future<bool> confirmClSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool danger = false,
}) async {
  final result = await showClSheet<bool>(
    context,
    title: title,
    builder: (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(message, style: context.clText.body),
        const SizedBox(height: ClSpace.s6),
        ClButton(
          label: confirmLabel,
          variant: danger ? ClButtonVariant.danger : ClButtonVariant.primary,
          expand: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: ClSpace.s2),
        Center(
          child: ClButton(
            label: 'Odustani',
            variant: ClButtonVariant.text,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// `3 pratioca`, `1 trening`: number + Serbian plural, for meta lines.
String countLabel(int n, String one, String few, String many) =>
    '${formatNumber(n)} ${plural(n, one, few, many)}';
