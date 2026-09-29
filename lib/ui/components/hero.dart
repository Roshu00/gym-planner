import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens/spacing.dart';
import 'media.dart';
import 'pressable.dart';
import 'tag.dart';

/// Full-bleed creator photo with a `label` (creator · week X / Y) above a
/// `display-l` title, both anchored `space-4` from the bottom-left on the scrim.
/// Also used as the creator profile header.
class ClWorkoutHero extends StatelessWidget {
  const ClWorkoutHero({
    super.key,
    required this.title,
    required this.label,
    this.image,
    this.height = 460,
    this.compact = false,
    this.topBar,
  });

  final String title;
  final String label;
  final ImageProvider? image;
  final double height;

  /// Uses `display-m` instead of `display-l` for tighter layouts.
  final bool compact;

  /// Optional row pinned to the top (back button, menu). Keep it on-photo white.
  final Widget? topBar;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final onPhoto = cl.colors.onPhoto;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClPhoto(image: image, semanticLabel: null),
          const ClPhotoScrim(),
          if (topBar != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: IconTheme(
                  data: IconThemeData(color: onPhoto),
                  child: topBar!,
                ),
              ),
            ),
          Positioned(
            left: ClSpace.s4,
            right: ClSpace.s4,
            bottom: ClSpace.s4,
            child: Semantics(
              header: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label.toUpperCase(), style: cl.text.label.copyWith(color: onPhoto)),
                  const SizedBox(height: ClSpace.s2),
                  Text(
                    title.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: (compact ? cl.text.displayM : cl.text.displayL).copyWith(color: onPhoto),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Magazine-cover card: photo (radius 0, ~220px) with a condensed title on the
/// scrim, then avatar + creator + followers, then outline tags. No border, no shadow.
class ClProgramCard extends StatelessWidget {
  const ClProgramCard({
    super.key,
    required this.title,
    required this.creatorName,
    required this.followers,
    this.meta,
    this.image,
    this.creatorImage,
    this.tags = const [],
    this.locked = false,
    this.onPressed,
    this.photoHeight = 220,
  });

  final String title;
  final String creatorName;

  /// Pre-formatted, e.g. `48,2K pratilaca`.
  final String followers;

  /// Label above the title, e.g. `8 nedelja · 4× nedeljno`.
  final String? meta;
  final ImageProvider? image;
  final ImageProvider? creatorImage;
  final List<String> tags;

  /// Subscribers-only content.
  final bool locked;
  final VoidCallback? onPressed;
  final double photoHeight;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final onPhoto = cl.colors.onPhoto;
    return ClPressable(
      onPressed: onPressed,
      radius: 0,
      semanticLabel: '$title, $creatorName',
      builder: (context, pressed) => AnimatedOpacity(
        duration: context.motion(ClMotion.fast),
        opacity: pressed ? 0.8 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: photoHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClPhoto(image: image),
                  const ClPhotoScrim(),
                  Positioned(
                    left: ClSpace.s4,
                    right: ClSpace.s4,
                    bottom: ClSpace.s4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (meta != null) ...[
                          Text(meta!.toUpperCase(), style: cl.text.label.copyWith(color: onPhoto)),
                          const SizedBox(height: ClSpace.s2),
                        ],
                        Text(
                          title.toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: cl.text.displayM.copyWith(color: onPhoto),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ClSpace.s3),
            ClCreatorLine(name: creatorName, image: creatorImage, trailing: followers),
            if (tags.isNotEmpty || locked) ...[
              const SizedBox(height: ClSpace.s2),
              Wrap(
                spacing: ClSpace.s1 + 2,
                runSpacing: ClSpace.s1 + 2,
                children: [if (locked) const ClTag('Za pretplatnike'), for (final t in tags) ClTag(t)],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Avatar + creator name, optional right-aligned `label`. The creator is
/// always named next to their content.
class ClCreatorLine extends StatelessWidget {
  const ClCreatorLine({super.key, required this.name, this.image, this.trailing});

  final String name;
  final ImageProvider? image;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Row(
      children: [
        ClAvatar(name: name, image: image),
        const SizedBox(width: ClSpace.s2),
        Expanded(
          child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: cl.text.bodyStrong),
        ),
        if (trailing != null) ...[
          const SizedBox(width: ClSpace.s2),
          Text(trailing!.toUpperCase(), style: cl.text.label),
        ],
      ],
    );
  }
}
