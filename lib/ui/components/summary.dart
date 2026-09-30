import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens/spacing.dart';
import 'lists.dart';
import 'media.dart';
import 'pop.dart';
import 'rule.dart';
import 'stat_bar.dart';

/// Screen title: optional `label` above a `display-m` title (1–3 words).
class ClScreenTitle extends StatelessWidget {
  const ClScreenTitle({super.key, required this.title, this.label, this.large = false});

  final String title;
  final String? label;

  /// `display-l` instead of `display-m`, for a tab's own title.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[Text(label!, style: cl.text.label), const SizedBox(height: ClSpace.s1)],
          Text(title, maxLines: 2, style: large ? cl.text.displayL : cl.text.displayM),
        ],
      ),
    );
  }
}

/// The creator's words in their own voice: `Sledeće je Pull B. Isti ritam.`
class ClCreatorMessage extends StatelessWidget {
  const ClCreatorMessage({super.key, required this.name, required this.message, this.image});

  final String name;
  final String message;
  final ImageProvider? image;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      padding: const EdgeInsets.all(ClSpace.s4),
      decoration: BoxDecoration(color: cl.colors.surface, borderRadius: BorderRadius.circular(ClRadius.sm)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClAvatar(name: name, image: image, size: 36),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Poruka · $name', style: cl.text.label),
                const SizedBox(height: ClSpace.s1),
                Text(message, style: cl.text.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ClSummaryExercise {
  const ClSummaryExercise({required this.name, required this.detail, this.isPr = false});

  final String name;
  final String detail;
  final bool isPr;
}

/// Story card after a workout: lilac 4:5 block with the headline, the stats
/// as color blocks and the creator's handle. Made to be screenshotted and
/// shared. [stats] takes 2–3 values; the first is the big one.
class ClShareCard extends StatelessWidget {
  const ClShareCard({
    super.key,
    required this.label,
    required this.stats,
    required this.creatorName,
    this.headline = 'Pojavio si se.',
    this.creatorHandle,
    this.creatorImage,
    this.brand = 'Chalkline',
  });

  final String label;
  final String headline;
  final List<ClStat> stats;
  final String creatorName;
  final String? creatorHandle;
  final ImageProvider? creatorImage;
  final String brand;

  @override
  Widget build(BuildContext context) {
    assert(stats.length >= 2 && stats.length <= 3, 'ShareCard takes 2–3 stats');
    final cl = context.cl;
    final c = cl.colors;
    Widget tile(ClStat s, Color bg, {bool big = false}) {
      final fg = bg == c.onPop ? c.onPhoto : c.onPop;
      return Container(
        padding: const EdgeInsets.all(ClSpace.s3 + 2),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(ClRadius.sm)),
        child: Semantics(
          label: '${s.label}: ${s.value}${s.unit == null ? '' : ' ${s.unit}'}',
          excludeSemantics: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.label, style: cl.text.label.copyWith(color: fg)),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  s.unit == null ? s.value : '${s.value} ${s.unit}',
                  style: (big ? cl.text.metricL : cl.text.metric).copyWith(color: fg),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ClPopBlock(
      color: c.lilac,
      padding: const EdgeInsets.fromLTRB(ClSpace.s4 + 4, ClSpace.s6, ClSpace.s4 + 4, ClSpace.s4 + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: cl.text.bodyStrong.copyWith(fontSize: 13, color: c.onPop)),
          const SizedBox(height: ClSpace.s2),
          Semantics(
            header: true,
            child: Text(headline, style: cl.text.displayXl.copyWith(color: c.onPop)),
          ),
          const SizedBox(height: ClSpace.s6),
          tile(stats[0], c.lime, big: true),
          const SizedBox(height: ClSpace.s2),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tile(stats[1], c.peach)),
                if (stats.length > 2) ...[
                  const SizedBox(width: ClSpace.s2),
                  Expanded(child: tile(stats[2], c.onPop)),
                ],
              ],
            ),
          ),
          const SizedBox(height: ClSpace.s6),
          Row(
            children: [
              ClAvatar(name: creatorName, image: creatorImage, color: c.surface),
              const SizedBox(width: ClSpace.s2),
              Expanded(
                child: Text(
                  creatorHandle == null ? creatorName : '@$creatorHandle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: cl.text.bodyStrong.copyWith(fontSize: 13, color: c.onPop),
                ),
              ),
              Text(brand, style: cl.text.bodyStrong.copyWith(fontSize: 13, color: c.onPop)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Workout summary: the share card on top, then the exercise list and the
/// creator's message.
class ClSummary extends StatelessWidget {
  const ClSummary({
    super.key,
    required this.label,
    required this.stats,
    required this.exercises,
    required this.creatorName,
    required this.creatorMessage,
    this.headline = 'Pojavio si se.',
    this.creatorHandle,
    this.creatorImage,
  });

  /// `Trening završen · 1h 12m`
  final String label;
  final String headline;

  /// 2–3 values, e.g. volume, records, streak.
  final List<ClStat> stats;
  final List<ClSummaryExercise> exercises;
  final String creatorName;
  final String? creatorHandle;
  final String creatorMessage;
  final ImageProvider? creatorImage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClShareCard(
          label: label,
          headline: headline,
          stats: stats,
          creatorName: creatorName,
          creatorHandle: creatorHandle,
          creatorImage: creatorImage,
        ),
        const SizedBox(height: ClSpace.s4),
        ClCreatorMessage(name: creatorName, message: creatorMessage, image: creatorImage),
        const SizedBox(height: ClSpace.s6),
        const ClSectionHeader(label: 'Vežbe'),
        for (final e in exercises) ClExerciseRow(name: e.name, detail: e.detail, isPr: e.isPr),
      ],
    );
  }
}
