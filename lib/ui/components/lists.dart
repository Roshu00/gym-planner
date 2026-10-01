import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens/spacing.dart';
import 'icons.dart';
import 'media.dart';
import 'pressable.dart';
import 'rule.dart';
import 'tag.dart';

/// Row card: name, meta, tags on a rounded `surface`. [divider] keeps the
/// gap below it.
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
      constraints: const BoxConstraints(minHeight: ClSize.targetWorkout + ClSpace.s2),
      padding: const EdgeInsets.fromLTRB(ClSpace.s4, ClSpace.s3, ClSpace.s3, ClSpace.s3),
      decoration: BoxDecoration(
        color: pressed ? c.surfaceRaised : c.surface,
        borderRadius: BorderRadius.circular(ClRadius.sm),
        boxShadow: ClElevation.card(c.shadow),
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

    final gap = EdgeInsets.only(bottom: divider ? ClSpace.s2 : 0);
    // Information rows are not buttons; their trailing controls stay reachable.
    if (onPressed == null) return Padding(padding: gap, child: row(false));
    return Padding(
      padding: gap,
      child: ClPressable(
        onPressed: onPressed,
        radius: ClRadius.sm,
        semanticLabel: meta == null ? title : '$title, $meta',
        builder: (context, pressed) => row(pressed),
      ),
    );
  }
}

/// How the user relates to a creator, shown on [ClCreatorRow].
enum ClFollowStatus { none, following, subscribed }

/// Discover row: avatar, name, followers (right-aligned label). A followed
/// creator gets a ring on the avatar and a `Pratiš` tag; a subscription
/// shows `Pretplata` instead.
class ClCreatorRow extends StatelessWidget {
  const ClCreatorRow({
    super.key,
    required this.name,
    required this.followers,
    this.handle,
    this.image,
    this.onPressed,
    this.status = ClFollowStatus.none,
  });

  final String name;

  /// Pre-formatted, e.g. `48,2K`.
  final String followers;
  final String? handle;
  final ImageProvider? image;
  final VoidCallback? onPressed;
  final ClFollowStatus status;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClListRow(
      title: name,
      meta: handle,
      onPressed: onPressed,
      leading: ClAvatar(name: name, image: image, size: 44, ring: status != ClFollowStatus.none),
      tags: switch (status) {
        ClFollowStatus.none => const [],
        ClFollowStatus.following => const [
          ClTag('Pratiš', variant: ClTagVariant.active, icon: ClIcons.check),
        ],
        ClFollowStatus.subscribed => const [
          ClTag('Pretplata', variant: ClTagVariant.pr, icon: ClIcons.subscriptions),
        ],
      },
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(followers, style: cl.text.data),
          Text('pratilaca', style: cl.text.label),
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

/// Settings-style group: one white card holding [ClMenuRow]s separated by
/// hairlines, with an optional section title above. Use it to keep secondary
/// things one tap away instead of spreading them over the screen.
class ClMenuGroup extends StatelessWidget {
  const ClMenuGroup({super.key, required this.children, this.title});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.clColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) ClSectionHeader(label: title!),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ClRadius.sm),
            boxShadow: ClElevation.card(c.shadow),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ClRadius.sm),
            child: ColoredBox(
              color: c.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: ClSpace.s4 + ClSize.icon + ClSpace.s3),
                        child: Container(height: ClSize.hairline, color: c.border),
                      ),
                    children[i],
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// One row of a [ClMenuGroup]: icon, title, optional value on the right,
/// chevron. Opens a sheet or a screen.
class ClMenuRow extends StatelessWidget {
  const ClMenuRow({
    super.key,
    required this.icon,
    required this.title,
    required this.onPressed,
    this.value,
    this.danger = false,
  });

  final IconData icon;
  final String title;

  /// Short current state, e.g. `Početak`, `3`, `Gost`.
  final String? value;
  final VoidCallback? onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    final fg = danger ? c.danger : c.ink;
    return ClPressable(
      onPressed: onPressed,
      radius: 0,
      semanticLabel: value == null ? title : '$title, $value',
      builder: (context, pressed) => AnimatedContainer(
        duration: context.motion(ClMotion.fast),
        color: pressed ? c.surfaceRaised : c.surface,
        constraints: const BoxConstraints(minHeight: ClSize.targetWorkout),
        padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4, vertical: ClSpace.s3),
        child: Row(
          children: [
            Icon(icon, size: ClSize.icon, color: fg),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: Text(title, style: cl.text.bodyStrong.copyWith(color: fg)),
            ),
            if (value != null) ...[
              const SizedBox(width: ClSpace.s2),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 170),
                child: Text(
                  value!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: cl.text.body.copyWith(color: c.inkMuted),
                ),
              ),
            ],
            const SizedBox(width: ClSpace.s1),
            Icon(ClIcons.chevron, size: 18, color: c.inkMuted),
          ],
        ),
      ),
    );
  }
}

/// Pill segmented tabs. Selected = ink pill with bg text.
class ClTabs extends StatelessWidget {
  const ClTabs({super.key, required this.tabs, required this.selected, required this.onChanged});

  final List<String> tabs;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: BorderRadius.circular(ClRadius.full)),
        child: Row(
          children: [
            for (var i = 0; i < tabs.length; i++)
              ClPressable(
                selected: i == selected,
                semanticLabel: tabs[i],
                radius: ClRadius.full,
                onPressed: () => onChanged(i),
                builder: (context, pressed) => AnimatedContainer(
                  duration: context.motion(ClMotion.fast),
                  curve: ClMotion.curve,
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selected ? c.ink : Colors.transparent,
                    borderRadius: BorderRadius.circular(ClRadius.full),
                  ),
                  child: Text(
                    tabs[i],
                    style: cl.text.filter.copyWith(
                      color: i == selected ? c.bg : (pressed ? c.ink : c.inkMuted),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ClNavItem {
  const ClNavItem({required this.label, required this.icon, required this.activeIcon});

  final String label;
  final IconData icon;

  /// Solid version shown while the item is selected.
  final IconData activeIcon;
}

const clNavItems = [
  ClNavItem(label: 'Danas', icon: ClIcons.today, activeIcon: ClIcons.todayFilled),
  ClNavItem(label: 'Plan', icon: ClIcons.plan, activeIcon: ClIcons.planFilled),
  ClNavItem(label: 'Otkrij', icon: ClIcons.discover, activeIcon: ClIcons.discoverFilled),
  ClNavItem(label: 'Napredak', icon: ClIcons.progress, activeIcon: ClIcons.progressFilled),
  ClNavItem(label: 'Profil', icon: ClIcons.profile, activeIcon: ClIcons.profileFilled),
];

/// Quiet bar on `bg` with a hairline on top, 5 items. Active = solid icon and
/// an ink label; inactive = outline icon in `ink-muted`. No color, so the
/// screen above keeps the attention.
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
                    radius: ClRadius.xs,
                    onPressed: () => onChanged(i),
                    builder: (context, pressed) {
                      final active = i == selected;
                      final color = active || pressed ? c.ink : c.inkMuted;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(active ? items[i].activeIcon : items[i].icon, size: ClSize.icon, color: color),
                          const SizedBox(height: 3),
                          Text(
                            items[i].label,
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            style: cl.text.label.copyWith(
                              fontSize: 11,
                              height: 1.2,
                              color: color,
                              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                            ),
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
