import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../tokens/spacing.dart';
import 'media.dart';
import 'pressable.dart';
import 'tag.dart';

/// Creator photo with rounded bottom corners, a `label` (creator · week X / Y)
/// above a display title on the scrim. Also used as the creator profile header.
class ClWorkoutHero extends StatelessWidget {
  const ClWorkoutHero({
    super.key,
    required this.title,
    required this.label,
    this.image,
    this.height = 460,
    this.compact = false,
    this.topBar,
    this.color,
    this.imageAlignment = Alignment.center,
  });

  final String title;
  final String label;
  final ImageProvider? image;
  final double height;

  /// Pop color shown instead of the dark photo frame while there is no
  /// [image]. Text turns ink.
  final Color? color;

  /// Uses `display-m` instead of `display-l` for tighter layouts.
  final bool compact;

  /// Optional row pinned to the top (back button, menu). Keep it on-photo white.
  final Widget? topBar;

  /// Which part of the photo stays when it is cropped; the top for a
  /// portrait, so the face is not cut off.
  final Alignment imageAlignment;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final pop = image == null ? color : null;
    final onPhoto = pop == null ? cl.colors.onPhoto : cl.colors.onPop;
    // Light status bar text over a photo, dark over a pop color.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: pop == null ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(ClRadius.lg)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (pop != null)
                ColoredBox(color: pop)
              else ...[
                ClPhoto(image: image, alignment: imageAlignment),
                const ClPhotoScrim(),
              ],
              if (topBar != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: IconTheme(
                      data: IconThemeData(color: onPhoto),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: ClSpace.s2),
                        child: topBar!,
                      ),
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
                      Text(label, style: cl.text.label.copyWith(color: onPhoto)),
                      const SizedBox(height: ClSpace.s1),
                      Text(
                        title,
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
        ),
      ),
    );
  }
}

/// Program card: a rounded 4:5 photo, like an Instagram post, with the title
/// on the scrim, then avatar + creator + followers, then tags.
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
    this.photoAspectRatio = 4 / 5,
    this.color,
  });

  /// Pop color shown instead of the dark photo frame while there is no [image].
  final Color? color;

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

  /// Width / height of the photo. 4:5 is Instagram's portrait post, so a
  /// trainer's existing posts fit as they are.
  final double photoAspectRatio;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final pop = image == null ? color : null;
    final onPhoto = pop == null ? cl.colors.onPhoto : cl.colors.onPop;
    return ClPressable(
      onPressed: onPressed,
      radius: ClRadius.lg,
      semanticLabel: '$title, $creatorName',
      builder: (context, pressed) => AnimatedOpacity(
        duration: context.motion(ClMotion.fast),
        opacity: pressed ? 0.8 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: photoAspectRatio,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(ClRadius.lg),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (pop != null)
                      ColoredBox(color: pop)
                    else ...[
                      ClPhoto(image: image),
                      const ClPhotoScrim(),
                    ],
                    Positioned(
                      left: ClSpace.s4,
                      right: ClSpace.s4,
                      bottom: ClSpace.s4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (meta != null) ...[
                            Text(meta!, style: cl.text.label.copyWith(color: onPhoto)),
                            const SizedBox(height: ClSpace.s1),
                          ],
                          Text(
                            title,
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
        if (trailing != null) ...[const SizedBox(width: ClSpace.s2), Text(trailing!, style: cl.text.label)],
      ],
    );
  }
}

/// A pop block with a photo behind it: a rounded cover with a scrim, a small
/// label, a big title and one line of meta in white. Without [image] (or
/// while it loads) it is a plain pop block in [color] with ink text, so
/// content that has no photo yet still looks finished.
class ClPhotoBlock extends StatelessWidget {
  const ClPhotoBlock({
    super.key,
    required this.title,
    required this.color,
    this.label,
    this.meta,
    this.image,
    this.height = 240,
    this.sticker,
    this.avatar,
    this.onPressed,
  });

  final String title;
  final Color color;
  final String? label;
  final String? meta;
  final ImageProvider? image;
  final double height;

  /// Optional [ClSticker] pinned over the top-right corner.
  final Widget? sticker;

  /// Optional [ClAvatar] shown before [label], for the creator.
  final Widget? avatar;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final ink = image == null ? cl.colors.onPop : cl.colors.onPhoto;
    Widget block(bool pressed) => AnimatedScale(
      duration: context.motion(ClMotion.fast),
      curve: ClMotion.curve,
      scale: pressed ? 0.98 : 1,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            height: height,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(ClRadius.lg),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: color),
                  if (image != null) ...[_FadeInPhoto(image: image!), const ClPhotoScrim(coverage: 0.7)],
                  Positioned(
                    left: ClSpace.s4,
                    right: ClSpace.s4,
                    bottom: ClSpace.s4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (label != null || avatar != null)
                          Row(
                            children: [
                              if (avatar != null) ...[avatar!, const SizedBox(width: ClSpace.s2)],
                              if (label != null)
                                Expanded(
                                  child: Text(
                                    label!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: cl.text.bodyStrong.copyWith(fontSize: 13, color: ink),
                                  ),
                                ),
                            ],
                          ),
                        const SizedBox(height: ClSpace.s1),
                        Semantics(
                          header: true,
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: cl.text.displayL.copyWith(color: ink),
                          ),
                        ),
                        if (meta != null) ...[
                          const SizedBox(height: ClSpace.s1),
                          Text(meta!, style: cl.text.body.copyWith(color: ink)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (sticker != null) Positioned(top: -ClSpace.s2, right: ClSpace.s3, child: sticker!),
        ],
      ),
    );
    if (onPressed == null) return block(false);
    return ClPressable(
      onPressed: onPressed,
      semanticLabel: title,
      radius: ClRadius.lg,
      builder: (context, pressed) => block(pressed),
    );
  }
}

/// A photo that fades in over whatever is behind it once it has loaded.
class _FadeInPhoto extends StatelessWidget {
  const _FadeInPhoto({required this.image});

  final ImageProvider image;

  @override
  Widget build(BuildContext context) {
    return Image(
      image: image,
      fit: BoxFit.cover,
      excludeFromSemantics: true,
      frameBuilder: (context, child, frame, sync) => sync
          ? child
          : AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: context.motion(ClMotion.sheet),
              curve: ClMotion.curve,
              child: child,
            ),
      errorBuilder: (context, error, stack) => const SizedBox.shrink(),
    );
  }
}
