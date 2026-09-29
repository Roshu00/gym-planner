import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens/spacing.dart';

/// Photo/video frame with radius 0. Without media (or while loading) it shows
/// the dark `photo-empty` frame with a small label, never a color block.
class ClPhoto extends StatelessWidget {
  const ClPhoto({
    super.key,
    this.image,
    this.placeholderLabel = 'Foto trenera',
    this.semanticLabel,
    this.alignment = Alignment.center,
  });

  final ImageProvider? image;
  final String placeholderLabel;
  final String? semanticLabel;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final c = context.clColors;
    final empty = ColoredBox(
      color: c.photoEmpty,
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(ClSpace.s4),
          child: Text(
            placeholderLabel.toUpperCase(),
            style: context.clText.label.copyWith(color: c.onPhoto.withValues(alpha: 0.6)),
          ),
        ),
      ),
    );
    if (image == null) return SizedBox.expand(child: empty);
    return SizedBox.expand(
      child: Image(
        image: image!,
        fit: BoxFit.cover,
        alignment: alignment,
        semanticLabel: semanticLabel,
        excludeFromSemantics: semanticLabel == null,
        frameBuilder: (context, child, frame, sync) => frame == null && !sync ? empty : child,
        errorBuilder: (context, error, stack) => empty,
      ),
    );
  }
}

/// Bottom scrim so white text stays readable on any photo.
/// The only gradient allowed in the system.
class ClPhotoScrim extends StatelessWidget {
  const ClPhotoScrim({super.key, this.coverage = 0.6});

  /// Fraction of the height, from the bottom, covered by the scrim.
  final double coverage;

  @override
  Widget build(BuildContext context) {
    final scrim = context.clColors.photoScrim;
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: coverage,
        widthFactor: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [scrim.withValues(alpha: 0), scrim, scrim],
              stops: const [0, 0.55, 1],
            ),
          ),
        ),
      ),
    );
  }
}

/// Circle: the only round element. 28px in lists, 56px on the profile.
/// No story rings, no colored outlines.
class ClAvatar extends StatelessWidget {
  const ClAvatar({super.key, required this.name, this.image, this.size = ClSize.avatarList});

  const ClAvatar.profile({super.key, required this.name, this.image}) : size = ClSize.avatarProfile;

  final String name;
  final ImageProvider? image;
  final double size;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    final first = parts.first.characters.first;
    final last = parts.length > 1 ? parts.last.characters.first : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final initials = Center(
      child: Text(
        _initials,
        style: cl.text.label.copyWith(
          fontSize: size * 0.36,
          height: 1,
          letterSpacing: 0,
          color: cl.colors.ink,
        ),
      ),
    );
    return Semantics(
      label: name,
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: ClipOval(
          child: ColoredBox(
            color: cl.colors.surfaceRaised,
            child: image == null
                ? initials
                : Image(image: image!, fit: BoxFit.cover, errorBuilder: (context, e, s) => initials),
          ),
        ),
      ),
    );
  }
}
