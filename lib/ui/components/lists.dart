import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens/spacing.dart';
import 'icons.dart';
import 'media.dart';
import 'pressable.dart';
import 'tag.dart';

/// Library row: name, meta, tags. Separated by a 1px `border`.
class ClListRow extends StatelessWidget {
  const ClListRow({
    super.key,
    required this.title,
    this.meta,
    this.tags = const [],
    this.leading,
    this.trailing,
    this.onPressed,
    this.divider = true,
  });

  final String title;
  final String? meta;
  final List<Widget> tags;
  final Widget? leading;

  /// Defaults to a chevron when tappable.
  final Widget? trailing;
  final VoidCallback? onPressed;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    Widget row(bool pressed) => AnimatedContainer(
      duration: context.motion(ClMotion.fast),
      constraints: const BoxConstraints(minHeight: ClSize.targetWorkout),
      padding: const EdgeInsets.symmetric(vertical: ClSpace.s3),
      decoration: BoxDecoration(
        color: pressed ? c.surfaceRaised : c.bg,
        border: divider ? Border(bottom: BorderSide(color: c.border)) : null,
      ),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: ClSpace.s3)],
          Expanded(
            child: MergeSemantics(
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
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: ClSpace.s2),
                    Wrap(spacing: 6, runSpacing: 6, children: tags),
                  ],
                ],
              ),
            ),
          ),
          if (trailing != null)
            trailing!
          else if (onPressed != null)
            ExcludeSemantics(child: Icon(ClIcons.chevron, size: 20, color: c.inkMuted)),
        ],
      ),
    );

    // Information rows are not buttons; their trailing controls stay reachable.
    if (onPressed == null) return row(false);
    return ClPressable(
      onPressed: onPressed,
      radius: 0,
      semanticLabel: meta == null ? title : '$title, $meta',
      builder: (context, pressed) => row(pressed),
    );
  }
}

/// Discover row: avatar, name, followers (right-aligned label).
class ClCreatorRow extends StatelessWidget {
  const ClCreatorRow({
    super.key,
    required this.name,
    required this.followers,
    this.handle,
    this.image,
    this.onPressed,
  });

  final String name;

  /// Pre-formatted, e.g. `48,2K`.
  final String followers;
  final String? handle;
  final ImageProvider? image;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClListRow(
      title: name,
      meta: handle,
      onPressed: onPressed,
      leading: ClAvatar(name: name, image: image, size: 40),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(followers, style: cl.text.data),
          Text('PRATIOCA', style: cl.text.label),
        ],
      ),
    );
  }
}

/// Exercise line in the Today preview and the Summary list.
/// `Bench press` · `4 × 8 · 80 kg` · optional PR tag.
class ClExerciseRow extends StatelessWidget {
  const ClExerciseRow({
    super.key,
    required this.name,
    required this.detail,
    this.index,
    this.isPr = false,
    this.onPressed,
  });

  final String name;

  /// Numbers are the proof: `4 × 8 · Prošli put 80 kg × 8`.
  final String detail;
  final int? index;
  final bool isPr;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClListRow(
      title: name,
      meta: detail,
      onPressed: onPressed,
      leading: index == null
          ? null
          : SizedBox(
              width: 24,
              child: Text(
                index!.toString().padLeft(2, '0'),
                style: cl.text.data.copyWith(color: cl.colors.inkMuted),
              ),
            ),
      trailing: isPr ? const ClTag.pr() : null,
    );
  }
}

class ClTabs extends StatelessWidget {
  const ClTabs({super.key, required this.tabs, required this.selected, required this.onChanged});

  final List<String> tabs;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < tabs.length; i++) ...[
              ClPressable(
                selected: i == selected,
                semanticLabel: tabs[i],
                radius: 0,
                onPressed: () => onChanged(i),
                builder: (context, pressed) => AnimatedContainer(
                  duration: context.motion(ClMotion.fast),
                  height: ClSize.target,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: i == selected ? c.ink : Colors.transparent,
                        width: ClSize.rule,
                      ),
                    ),
                  ),
                  child: Text(
                    tabs[i].toUpperCase(),
                    style: cl.text.label.copyWith(
                      fontSize: 12,
                      color: i == selected || pressed ? c.ink : c.inkMuted,
                    ),
                  ),
                ),
              ),
              if (i < tabs.length - 1) const SizedBox(width: ClSpace.s6),
            ],
          ],
        ),
      ),
    );
  }
}

class ClNavItem {
  const ClNavItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

const clNavItems = [
  ClNavItem(label: 'Danas', icon: ClIcons.today),
  ClNavItem(label: 'Plan', icon: ClIcons.plan),
  ClNavItem(label: 'Otkrij', icon: ClIcons.discover),
  ClNavItem(label: 'Napredak', icon: ClIcons.progress),
  ClNavItem(label: 'Profil', icon: ClIcons.profile),
];

/// 5 items, thin icons + `label`. Active = `ink`, inactive = `ink-muted`.
/// Never signal in navigation.
class ClBottomNav extends StatelessWidget {
  const ClBottomNav({super.key, required this.selected, required this.onChanged, this.items = clNavItems});

  final int selected;
  final ValueChanged<int> onChanged;
  final List<ClNavItem> items;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: ClPressable(
                    selected: i == selected,
                    semanticLabel: items[i].label,
                    radius: 0,
                    onPressed: () => onChanged(i),
                    builder: (context, pressed) {
                      final color = i == selected ? c.ink : c.inkMuted;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(items[i].icon, size: ClSize.icon, color: color),
                          const SizedBox(height: 2),
                          Text(
                            items[i].label.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            style: cl.text.label.copyWith(fontSize: 9.5, color: color),
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
