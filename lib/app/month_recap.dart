import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/rules.dart';
import '../ui/chalkline_ui.dart';
import 'common.dart';
import 'progress.dart';

/// The Napredak tab: the month as a story to open, the month's ring, then
/// every number and the history below.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final cl = context.cl;
    final c = cl.colors;
    final now = store.now;
    final thisMonth = monthRecap(store.sessions, now);
    final last = monthRecap(store.sessions, DateTime(now.year, now.month - 1));
    // Early in a month the one just closed is the story; later, this one.
    final story = last.workouts > 0 && now.day <= 10 ? last : thisMonth;
    final storyName = monthNames[story.month.month - 1];
    final goal = store.weeklyGoal == 0 ? 12 : store.weeklyGoal * 4;

    return AppScreen(
      children: [
        const SizedBox(height: ClSpace.s4),
        const ClScreenTitle(title: 'Napredak', large: true),
        gap,
        if (story.workouts > 0) ...[
          ClPressable(
            onPressed: () => pushScreen(context, MonthRecapScreen(recap: story)),
            semanticLabel: 'Tvoj $storyName',
            radius: ClRadius.lg,
            builder: (context, pressed) => AnimatedScale(
              duration: context.motion(ClMotion.fast),
              scale: pressed ? 0.98 : 1,
              child: Container(
                padding: const EdgeInsets.all(ClSpace.s4),
                decoration: BoxDecoration(color: c.signal, borderRadius: BorderRadius.circular(ClRadius.lg)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            story == last ? 'Novo' : 'Do sada',
                            style: cl.text.label.copyWith(color: c.onSignal.withValues(alpha: 0.7)),
                          ),
                          Text(
                            story == last ? 'Tvoj $storyName je spreman' : 'Tvoj $storyName',
                            style: cl.text.displayM.copyWith(color: c.onSignal, fontSize: 24, height: 1.1),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: c.onSignal, shape: BoxShape.circle),
                      child: Icon(ClIcons.play, color: c.signal, size: 22),
                    ),
                  ],
                ),
              ),
            ),
          ),
          gapS,
        ],
        // The month as a ring: workouts against what the plan asks.
        Container(
          padding: const EdgeInsets.all(ClSpace.s4),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(ClRadius.lg)),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 92,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: (thisMonth.workouts / goal).clamp(0.0, 1.0),
                      strokeWidth: 10,
                      strokeCap: StrokeCap.round,
                      color: c.signal,
                      backgroundColor: c.border,
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${thisMonth.workouts}', style: cl.text.metric),
                          Text('od $goal', style: cl.text.label),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: ClSpace.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _capitalized(monthNames[now.month - 1]),
                      style: cl.text.bodyStrong.copyWith(fontSize: 17),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        countLabel(thisMonth.workouts, 'trening', 'treninga', 'treninga'),
                        if (store.streak > 0) '${store.streak} ned. zaredom',
                        if (thisMonth.records > 0)
                          countLabel(thisMonth.records, 'rekord', 'rekorda', 'rekorda'),
                      ].join(' · '),
                      style: cl.text.body.copyWith(color: c.inkMuted, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        gap,
        const ProgressContent(),
      ],
    );
  }
}

String _capitalized(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// A month as one orange story: kilograms lifted and what that compares to,
/// workouts, the biggest gain. Shares as a picture.
class MonthRecapScreen extends StatefulWidget {
  const MonthRecapScreen({super.key, required this.recap});

  final MonthRecap recap;

  @override
  State<MonthRecapScreen> createState() => _MonthRecapScreenState();
}

class _MonthRecapScreenState extends State<MonthRecapScreen> {
  final _card = GlobalKey();
  final _shareButton = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    final box = _shareButton.currentContext?.findRenderObject() as RenderBox?;
    final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    try {
      final boundary = _card.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final width = boundary.size.width;
      final image = await boundary.toImage(pixelRatio: 1080 / width);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (png == null) throw StateError('no image');
      HapticFeedback.lightImpact();
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(png.buffer.asUint8List(), mimeType: 'image/png', name: 'chalkline-mesec.png'),
          ],
          sharePositionOrigin: origin,
        ),
      );
    } on Object {
      if (mounted) showUndoToast(context, 'Slika nije napravljena. Pokušaj ponovo.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final cl = context.cl;
    final c = cl.colors;
    final r = widget.recap;
    final ink = c.onSignal;
    final tons = r.volume / 1000;
    final big = tons >= 1
        ? '${formatNumber(tons, maxDecimals: tons >= 10 ? 0 : 1)} t'
        : '${formatNumber(r.volume, maxDecimals: 0)} kg';
    final creator = store.plan == null ? null : store.creator(store.plan!.creatorId);
    final lifted =
        store.profile?.says('Ovog meseca si podigao', 'Ovog meseca si podigla', 'Ovog meseca ukupno') ??
        'Ovog meseca ukupno';

    Widget tile(String value, String label, {Widget? leading, int span = 1}) => Container(
      padding: const EdgeInsets.all(ClSpace.s3 + 2),
      decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(ClRadius.sm + 2)),
      child: Row(
        children: [
          if (leading != null) ...[leading, const SizedBox(width: ClSpace.s3)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: cl.text.metric.copyWith(color: c.ink)),
                ),
                Text(label, style: cl.text.label),
              ],
            ),
          ),
        ],
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: c.signal,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(ClSpace.s4, ClSpace.s2, ClSpace.s4, ClSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: ClIconButton(
                    icon: ClIcons.close,
                    semanticLabel: 'Zatvori',
                    color: ink,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                Expanded(
                  child: RepaintBoundary(
                    key: _card,
                    child: ColoredBox(
                      color: c.signal,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Tvoj ${monthNames[r.month.month - 1]}${creator == null ? '' : ' · ${creator.name}'}',
                            style: cl.text.bodyStrong.copyWith(color: ink),
                          ),
                          const Spacer(),
                          Text(lifted, style: cl.text.bodyStrong.copyWith(color: ink, fontSize: 20)),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              big,
                              style: cl.text.displayXl.copyWith(
                                color: ink,
                                fontSize: 112,
                                height: 1,
                                letterSpacing: -6,
                              ),
                            ),
                          ),
                          Text(
                            volumeComparison(r.volume),
                            style: cl.text.bodyStrong.copyWith(
                              color: ink,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: ClSpace.s6),
                          Row(
                            children: [
                              Expanded(
                                child: tile(
                                  '${r.workouts}',
                                  countLabel(r.workouts, 'trening', 'treninga', 'treninga').split(' ').last,
                                ),
                              ),
                              if (r.biggestGain != null || r.records > 0) ...[
                                const SizedBox(width: ClSpace.s2),
                                Expanded(
                                  child: r.biggestGain == null
                                      ? tile(
                                          '${r.records}',
                                          countLabel(
                                            r.records,
                                            'rekord',
                                            'rekorda',
                                            'rekorda',
                                          ).split(' ').last,
                                        )
                                      : tile(
                                          '+${formatNumber(r.biggestGain!.to - r.biggestGain!.from)} kg',
                                          r.biggestGain!.name.toLowerCase(),
                                        ),
                                ),
                              ],
                            ],
                          ),
                          if (r.bestStreakDays > 1) ...[
                            const SizedBox(height: ClSpace.s2),
                            tile(
                              '${r.bestStreakDays} dana zaredom',
                              'najduži niz ovog meseca',
                              leading: creator == null
                                  ? null
                                  : ClAvatar(name: creator.name, image: photoOf(creator.photo), size: 40),
                            ),
                          ],
                          const Spacer(),
                          Text(
                            'Chalkline',
                            style: cl.text.bodyStrong.copyWith(color: ink.withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: ClSpace.s4),
                ClThemeScope(
                  theme: ClTheme.dark,
                  child: Builder(
                    builder: (context) => _InkButton(
                      key: _shareButton,
                      label: _busy ? 'Pripremam…' : 'Podeli na story',
                      onPressed: _busy ? null : _share,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The dark pill on the orange story.
class _InkButton extends StatelessWidget {
  const _InkButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    return ClPressable(
      onPressed: onPressed,
      semanticLabel: label,
      radius: ClRadius.full,
      builder: (context, pressed) => Container(
        height: ClSize.targetWorkout,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: pressed ? c.surface : c.onSignal,
          borderRadius: BorderRadius.circular(ClRadius.full),
        ),
        child: Text(label, style: cl.text.buttonBlock.copyWith(color: c.ink)),
      ),
    );
  }
}
