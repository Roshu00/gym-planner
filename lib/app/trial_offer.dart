import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../ui/chalkline_ui.dart';
import 'common.dart';
import 'program_detail.dart';
import 'subscribe_sheet.dart';

/// After a workout tried from another trainer's program: the program it
/// came from, and one button to switch to it (or subscribe, when it is for
/// subscribers). Nothing for a workout of the user's own plan.
class TrialOffer extends StatelessWidget {
  const TrialOffer({super.key, required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final p = store.trialProgramOf(session);
    if (p == null) return const SizedBox.shrink();
    final cl = context.cl;
    final c = cl.colors;
    final creator = store.creator(p.creatorId);
    final locked = !store.canAccess(p.visibility, p.creatorId);
    final weeks = countLabel(p.weeks, 'nedelja', 'nedelje', 'nedelja');
    return Container(
      padding: const EdgeInsets.all(ClSpace.s4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(ClRadius.lg),
        boxShadow: ClElevation.card(c.shadow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClPressable(
            onPressed: () => pushScreen(context, ProgramDetailScreen(programId: p.id)),
            semanticLabel: p.name,
            radius: ClRadius.sm,
            builder: (context, pressed) => Row(
              children: [
                ListThumb(image: photoOf(p.image), color: c.popFor(p.id), label: ''),
                const SizedBox(width: ClSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Svideo ti se trening?', style: cl.text.label),
                      const SizedBox(height: 2),
                      Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: cl.text.bodyStrong.copyWith(fontSize: 17),
                      ),
                      Text(
                        [weeks, '${p.daysPerWeek}× nedeljno', ?creator?.name].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: cl.text.label,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ClSpace.s3),
          if (locked && creator != null)
            ClButton(
              label: 'Pretplati se i počni',
              variant: ClButtonVariant.pop,
              expand: true,
              onPressed: () => showSubscribeSheet(context, creator),
            )
          else
            ClButton(
              label: 'Pređi na ovaj program',
              expand: true,
              onPressed: () => startProgramFlow(context, p.id),
            ),
        ],
      ),
    );
  }
}
