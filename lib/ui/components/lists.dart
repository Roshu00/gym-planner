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
    this.titleBadge,
    this.badgeLabel,
  });

  final String title;

  /// Small mark right after the title (e.g. "you follow this creator").
  final Widget? titleBadge;

  /// What [titleBadge] means, for screen readers.
  final String? badgeLabel;
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
                  if (titleBadge == null)
                    Text(title, style: cl.text.bodyStrong)
                  else
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: cl.text.bodyStrong,
                          ),
                        ),
                        const SizedBox(width: 6),
                        ExcludeSemantics(child: titleBadge!),
                      ],
                    ),
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
        semanticLabel: [title, ?badgeLabel, ?meta].join(', '),
        builder: (context, pressed) => row(pressed),
      ),
    );
  }
}

/// How the user relates to a creator, shown on [ClCreatorRow].
enum ClFollowStatus { none, following, subscribed }

/// Discover row: avatar, name, followers (right-aligned label). A followed
/// creator gets a small `Pratiš` pill next to the name, a subscription a
/// filled `Pretplata` one, so every row keeps the same height.
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
      leading: ClAvatar(name: name, image: image, size: 44),
      titleBadge: switch (status) {
        ClFollowStatus.none => null,
        ClFollowStatus.following => const _MiniPill('Pratiš'),
        ClFollowStatus.subscribed => const _MiniPill('Pretplata', filled: true),
      },
      badgeLabel: switch (status) {
        ClFollowStatus.none => null,
        ClFollowStatus.following => 'pratiš',
        ClFollowStatus.subscribed => 'pretplaćen si',
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

/// A small pill next to a name: `Pratiš` outlined, `Pretplata` filled ink.
class _MiniPill extends StatelessWidget {
  const _MiniPill(this.label, {this.filled = false});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: filled ? c.ink : null,
        borderRadius: BorderRadius.circular(ClRadius.full),
        border: Border.all(color: c.ink, width: 1),
      ),
      child: Text(
        label,
        style: cl.text.label.copyWith(fontSize: 10, height: 14 / 10, color: filled ? c.bg : c.ink),
      ),
    );
  }
}

/// Exercise line in the Today preview and the Summary list.
/// `Bench press` · `4 × 8 · 80 kg` · optional PR tag. With [image], a small
/// picture of the movement leads the row instead of the number.
class ClExerciseRow extends StatelessWidget {
  const ClExerciseRow({
    super.key,
    required this.name,
    required this.detail,
    this.index,
    this.image,
    this.isPr = false,
    this.onPressed,
  });

  final ImageProvider? image;

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
      leading: image != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(ClRadius.xs),
              child: SizedBox.square(
                dimension: 52,
                child: ClPhoto(image: image, placeholderLabel: ''),
              ),
            )
          : index == null
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
  ClNavItem(label: 'Biblioteka', icon: ClIcons.library, activeIcon: ClIcons.libraryFilled),
  ClNavItem(label: 'Profil', icon: ClIcons.profile, activeIcon: ClIcons.profileFilled),
];

/// A quiet bar on `bg`: icons only, no line and no fill, so the screen's own
/// black button stays the strongest thing at the bottom. The selected icon is
/// solid ink, lifts a little and gets a dot below it; the others are muted.
/// Labels are for screen readers.
class ClBottomNav extends StatelessWidget {
  const ClBottomNav({super.key, required this.selected, required this.onChanged, this.items = clNavItems});

  final int selected;
  final ValueChanged<int> onChanged;
  final List<ClNavItem> items;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.clColors.bg,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: ClSpace.s2),
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavItem(item: items[i], selected: i == selected, onPressed: () => onChanged(i)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.item, required this.selected, required this.onPressed});

  final ClNavItem item;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.clColors;
    final duration = context.motion(ClMotion.tab);
    return ClPressable(
      selected: selected,
      semanticLabel: item.label,
      radius: ClRadius.sm,
      onPressed: onPressed,
      builder: (context, pressed) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSlide(
            duration: duration,
            curve: ClMotion.tabCurve,
            offset: Offset(0, selected ? -0.08 : 0),
            child: AnimatedScale(
              duration: context.motion(ClMotion.fast),
              curve: ClMotion.curve,
              scale: pressed ? 0.88 : 1,
              child: TweenAnimationBuilder<Color?>(
                duration: duration,
                curve: ClMotion.tabCurve,
                tween: ColorTween(end: selected || pressed ? c.ink : c.inkMuted),
                builder: (context, color, _) =>
                    Icon(selected ? item.activeIcon : item.icon, size: ClSize.icon, color: color),
              ),
            ),
          ),
          const SizedBox(height: ClSpace.s1),
          AnimatedScale(
            duration: duration,
            curve: selected ? Curves.easeOutBack : ClMotion.tabCurve,
            scale: selected ? 1 : 0,
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: c.ink, shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }
}
