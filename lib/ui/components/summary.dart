import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens/spacing.dart';
import 'lists.dart';
import 'media.dart';
import 'rule.dart';
import 'stat_bar.dart';

/// Screen title: optional `label` above a `display-m` title (1–3 words).
class ClScreenTitle extends StatelessWidget {
  const ClScreenTitle({super.key, required this.title, this.label});

  final String title;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(label!.toUpperCase(), style: cl.text.label),
            const SizedBox(height: ClSpace.s2),
          ],
          Text(title.toUpperCase(), maxLines: 2, style: cl.text.displayM),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ClRule(),
        const SizedBox(height: ClSpace.s3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClAvatar(name: name, image: image),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PORUKA · ${name.toUpperCase()}', style: cl.text.label),
                  const SizedBox(height: ClSpace.s1),
                  Text(message, style: cl.text.body),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ClSummaryExercise {
  const ClSummaryExercise({required this.name, required this.detail, this.isPr = false});

  final String name;
  final String detail;
  final bool isPr;
}

/// Workout summary: label, a headline praising showing up, a 2-column stat
/// grid (records in `signal-text`), the exercise list, the creator's message.
/// Designed for the light theme.
class ClSummary extends StatelessWidget {
  const ClSummary({
    super.key,
    required this.label,
    required this.stats,
    required this.exercises,
    required this.creatorName,
    required this.creatorMessage,
    this.headline = 'Pojavio si se.',
    this.creatorImage,
  });

  /// `Trening završen · 1h 12m`
  final String label;
  final String headline;

  /// Two cells, e.g. volume and records.
  final List<ClStat> stats;
  final List<ClSummaryExercise> exercises;
  final String creatorName;
  final String creatorMessage;
  final ImageProvider? creatorImage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClScreenTitle(label: label, title: headline),
        const SizedBox(height: ClSpace.s6),
        ClStatBar(stats: stats, large: true),
        const SizedBox(height: ClSpace.s6),
        const ClSectionHeader(label: 'Vežbe'),
        for (final e in exercises) ClExerciseRow(name: e.name, detail: e.detail, isPr: e.isPr),
        const SizedBox(height: ClSpace.s8),
        ClCreatorMessage(name: creatorName, message: creatorMessage, image: creatorImage),
      ],
    );
  }
}
