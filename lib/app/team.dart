import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/models.dart';
import '../domain/rules.dart';
import '../domain/team.dart';
import '../ui/chalkline_ui.dart';
import 'common.dart';

/// A creator's team: who trained, their records, "Bravo", and the
/// creator's answers. The creator sees the same feed and answers from it.
class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key, required this.creatorId});

  final String creatorId;

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  @override
  void initState() {
    super.initState();
    context.readStore.loadTeam(widget.creatorId, force: true);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final creator = store.creator(widget.creatorId);
    final team = store.team(widget.creatorId);
    final isMine = creator?.isMine ?? false;

    return AppScreen(
      topBar: const ClTopBar(),
      children: [
        Row(
          children: [
            if (creator != null) ...[
              ClAvatar(name: creator.name, image: photoOf(creator.photo), size: 48, ring: true),
              const SizedBox(width: ClSpace.s3),
            ],
            Expanded(
              child: ClScreenTitle(
                label: team == null
                    ? null
                    : '${formatCompact(team.members)} u timu · ${team.activeToday} danas',
                title: isMine ? 'Tvoj tim' : 'Tim · ${creator?.name ?? ''}',
              ),
            ),
          ],
        ),
        gap,
        if (team == null)
          const ClNotice('Tim se učitava.')
        else if (team.posts.isEmpty)
          ClEmptyState(
            title: 'Budi prvi danas.',
            message: isMine
                ? 'Kad tvoji pratioci završe trening, ovde vidiš njihove rezultate i odgovaraš im.'
                : 'Posle treninga dodirni „Pokaži timu” i tvoj trening se pojavljuje ovde.',
          )
        else
          for (final p in team.posts) ...[_PostCard(post: p, creator: creator, canReply: isMine), gapS],
      ],
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.creator, required this.canReply});

  final TeamPost post;
  final Creator? creator;
  final bool canReply;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final cl = context.cl;
    final c = cl.colors;
    final mine = post.userId == (store.remote?.userId ?? 'me');
    return Container(
      padding: const EdgeInsets.all(ClSpace.s4),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(ClRadius.lg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ClAvatar(name: post.authorName, size: 40, color: mine ? c.signal : c.popFor(post.authorName)),
              const SizedBox(width: ClSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mine ? '${post.authorName} · ti' : post.authorName, style: cl.text.bodyStrong),
                    Text(
                      '${_when(post.createdAt, store.now)} · ${post.workoutName}',
                      style: cl.text.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (post.records.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.signal,
                    borderRadius: BorderRadius.circular(ClRadius.full),
                  ),
                  child: Text('Rekord', style: cl.text.tag.copyWith(color: c.onSignal)),
                ),
            ],
          ),
          if (post.records.isNotEmpty || post.streakWeeks > 1) ...[
            const SizedBox(height: ClSpace.s3),
            Wrap(
              spacing: ClSpace.s2,
              runSpacing: ClSpace.s2,
              children: [
                for (final r in post.records) _Fact(label: 'Rekord', value: r),
                if (post.streakWeeks > 1) _Fact(label: 'Niz', value: '${post.streakWeeks} ned.'),
              ],
            ),
          ],
          if (post.reply != null && creator != null) ...[
            const SizedBox(height: ClSpace.s3),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: c.signalSoft,
                borderRadius: BorderRadius.circular(ClRadius.sm),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClAvatar(name: creator!.name, image: photoOf(creator!.photo), size: 28),
                  const SizedBox(width: ClSpace.s2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          creator!.name.split(' ').first,
                          style: cl.text.label.copyWith(color: c.signalText),
                        ),
                        Text(post.reply!, style: cl.text.body.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: ClSpace.s3),
          Row(
            children: [
              _CheerButton(post: post, own: mine),
              const Spacer(),
              if (canReply && !mine)
                ClButton(
                  label: post.reply == null ? 'Odgovori' : 'Izmeni odgovor',
                  variant: ClButtonVariant.text,
                  onPressed: () => _reply(context, post),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static Future<void> _reply(BuildContext context, TeamPost post) async {
    final store = context.readStore;
    final text = await showClSheet<String>(
      context,
      title: 'Odgovor za ${post.authorName}',
      label: post.workoutName,
      builder: (context) => _ReplySheet(initial: post.reply ?? ''),
    );
    if (text == null || text.trim().isEmpty) return;
    store.replyToPost(post, text);
  }

  static String _when(DateTime t, DateTime now) {
    final minutes = now.difference(t).inMinutes;
    if (minutes < 1) return 'upravo';
    if (minutes < 60) return 'pre $minutes min';
    if (dateOnly(t) == dateOnly(now)) return 'danas ${t.hour}:${t.minute.toString().padLeft(2, '0')}';
    if (dateOnly(t) == dateOnly(now).subtract(const Duration(days: 1))) return 'juče';
    return formatDate(t, now: now);
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cl.colors.surfaceRaised,
        borderRadius: BorderRadius.circular(ClRadius.xs),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: cl.text.label),
          Text(value, style: cl.text.bodyStrong),
        ],
      ),
    );
  }
}

/// "Bravo · 38": a tap cheers, another takes it back. Your own post shows
/// the count only.
class _CheerButton extends StatelessWidget {
  const _CheerButton({required this.post, required this.own});

  final TeamPost post;
  final bool own;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    final on = post.cheeredByMe;
    final label = post.cheers == 0 ? 'Bravo' : 'Bravo · ${post.cheers}';
    return ClPressable(
      onPressed: own
          ? null
          : () {
              HapticFeedback.lightImpact();
              context.readStore.toggleCheer(post);
            },
      selected: on,
      semanticLabel: own ? '${post.cheers} bravo' : (on ? 'Povuci bravo' : 'Bravo'),
      radius: ClRadius.full,
      builder: (context, pressed) => AnimatedScale(
        duration: context.motion(ClMotion.fast),
        scale: pressed ? 0.94 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: on ? c.signal : c.surfaceRaised,
            borderRadius: BorderRadius.circular(ClRadius.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(ClIcons.streak, size: 16, color: on ? c.onSignal : c.signal),
              const SizedBox(width: 6),
              Text(label, style: cl.text.bodyStrong.copyWith(color: on ? c.onSignal : c.ink, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

/// One answer; owns its field so it outlives the sheet's close.
class _ReplySheet extends StatefulWidget {
  const _ReplySheet({required this.initial});

  final String initial;

  @override
  State<_ReplySheet> createState() => _ReplySheetState();
}

class _ReplySheetState extends State<_ReplySheet> {
  late final _text = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ClTextField(
        hint: 'npr. Svaka čast, sledeće nedelje probaj 2,5 kg više.',
        controller: _text,
        maxLines: 3,
      ),
      gapS,
      ClButton(label: 'Pošalji', expand: true, onPressed: () => Navigator.of(context).pop(_text.text)),
    ],
  );
}
