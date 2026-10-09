import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../data/app_store.dart';
import '../domain/models.dart';
import '../ui/chalkline_ui.dart';

/// Makes [AppStore] available and rebuilds dependents when it changes.
class AppScope extends InheritedNotifier<AppStore> {
  const AppScope({super.key, required AppStore store, required super.child}) : super(notifier: store);

  static AppStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// For callbacks: reads without subscribing to rebuilds.
  static AppStore read(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

extension StoreContext on BuildContext {
  AppStore get store => AppScope.of(this);
  AppStore get readStore => AppScope.read(this);
}

/// Pushes [screen] in the theme DESIGN.md assigns to it.
Future<T?> pushScreen<T>(BuildContext context, Widget screen, {ClTheme? theme, bool replace = false}) {
  final route = MaterialPageRoute<T>(
    builder: (_) => ClThemeScope(theme: theme ?? ClTheme.light, child: screen),
  );
  final nav = Navigator.of(context);
  return replace ? nav.pushReplacement(route) : nav.push(route);
}

/// Phone-width column on wide screens.
class AppWidth extends StatelessWidget {
  const AppWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: child),
  );
}

/// Standard screen: top bar, scrolling content with the 16px gutter, and an
/// optional action pinned to the bottom (the one primary button).
///
/// Without a bottom action the list runs to the very bottom of the screen and
/// only its last item keeps clear of the home indicator. With a [header],
/// pulling down at the top stretches the header instead of showing the
/// background above it.
class AppScreen extends StatefulWidget {
  const AppScreen({
    super.key,
    required this.children,
    this.topBar,
    this.bottom,
    this.padding = const EdgeInsets.fromLTRB(ClSpace.s4, ClSpace.s2, ClSpace.s4, ClSpace.s12),
    this.header,
    this.safeTop = true,
    this.collapsed,
  });

  final Widget? topBar;

  /// Full-bleed content above the padded list (e.g. a hero).
  final Widget? header;
  final List<Widget> children;
  final Widget? bottom;
  final EdgeInsets padding;
  final bool safeTop;

  /// With a [header]: what the pinned bar shows once the header has scrolled
  /// away, next to a back button (e.g. the creator's avatar and name).
  final Widget? collapsed;

  @override
  State<AppScreen> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {
  final _scroll = ScrollController();

  /// Measured after layout; read while scrolling.
  double _headerHeight = 300;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final insetBottom = w.bottom == null ? MediaQuery.paddingOf(context).bottom : 0.0;
    final header = w.header == null
        ? null
        : AnimatedBuilder(
            animation: _scroll,
            child: _MeasureHeight(
              // Only the resting height counts, not a stretched one.
              onHeight: (h) {
                if (!_scroll.hasClients || _scroll.offset >= 0) _headerHeight = h;
              },
              child: w.header!,
            ),
            builder: (context, child) {
              // Pulled past the top: the header gets taller upwards, so its
              // photo zooms to fill the gap while the text at its bottom stays
              // the same size. The list itself does not move.
              final pulled = _scroll.hasClients ? math.max(0.0, -_scroll.offset) : 0.0;
              final stretched = pulled > 0;
              return SizedBox(
                height: stretched ? _headerHeight : null,
                child: OverflowBox(
                  alignment: Alignment.bottomCenter,
                  // At rest the header keeps its own height.
                  fit: stretched ? OverflowBoxFit.max : OverflowBoxFit.deferToChild,
                  minHeight: stretched ? _headerHeight + pulled : null,
                  maxHeight: stretched ? _headerHeight + pulled : null,
                  child: child,
                ),
              );
            },
          );
    // Dark status bar text on the light screens; a photo header switches it
    // to light while it sits under the status bar.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          top: w.safeTop,
          bottom: false,
          child: AppWidth(
            child: Column(
              children: [
                ?w.topBar,
                Expanded(
                  child: Stack(
                    children: [
                      ListView(
                        controller: _scroll,
                        padding: EdgeInsets.zero,
                        children: [
                          ?header,
                          Padding(
                            padding: w.padding.copyWith(bottom: w.padding.bottom + insetBottom),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: w.children,
                            ),
                          ),
                        ],
                      ),
                      // Once the header has scrolled away, a bar with the
                      // screen's background takes over the top: the status bar
                      // gets dark text back and, with [collapsed], a back button
                      // and a short title stay in reach.
                      if (header != null && !w.safeTop)
                        AnimatedBuilder(
                          animation: _scroll,
                          builder: (context, _) {
                            final top = MediaQuery.paddingOf(context).top;
                            final barHeight = w.collapsed == null ? 0.0 : ClSize.target + ClSpace.s2;
                            final covered =
                                _scroll.hasClients && _scroll.offset > _headerHeight - top - barHeight;
                            final duration = context.motion(ClMotion.base);
                            final bar = Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: top + barHeight,
                              child: IgnorePointer(
                                ignoring: !covered,
                                child: AnimatedOpacity(
                                  opacity: covered ? 1 : 0,
                                  duration: duration,
                                  curve: ClMotion.curve,
                                  child: ColoredBox(
                                    color: context.clColors.bg,
                                    child: w.collapsed == null
                                        ? null
                                        : Padding(
                                            padding: EdgeInsets.only(
                                              top: top,
                                              left: ClSpace.s1,
                                              right: ClSpace.s4,
                                            ),
                                            child: Row(
                                              children: [
                                                ClIconButton(
                                                  icon: ClIcons.back,
                                                  semanticLabel: 'Nazad',
                                                  onPressed: () => Navigator.of(context).maybePop(),
                                                ),
                                                Expanded(
                                                  child: AnimatedSlide(
                                                    offset: Offset(0, covered ? 0 : 0.4),
                                                    duration: duration,
                                                    curve: ClMotion.tabCurve,
                                                    child: w.collapsed,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            );
                            return covered
                                ? AnnotatedRegion<SystemUiOverlayStyle>(
                                    value: SystemUiOverlayStyle.dark,
                                    child: Stack(children: [bar]),
                                  )
                                : Stack(children: [bar]);
                          },
                        ),
                    ],
                  ),
                ),
                if (w.bottom != null)
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(ClSpace.s4, ClSpace.s2, ClSpace.s4, ClSpace.s3),
                      child: w.bottom,
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

/// Reports its child's height after each layout that changes it.
class _MeasureHeight extends SingleChildRenderObjectWidget {
  const _MeasureHeight({required this.onHeight, required super.child});

  final ValueChanged<double> onHeight;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderMeasureHeight(onHeight);

  @override
  void updateRenderObject(BuildContext context, _RenderMeasureHeight renderObject) =>
      renderObject.onHeight = onHeight;
}

class _RenderMeasureHeight extends RenderProxyBox {
  _RenderMeasureHeight(this.onHeight);

  ValueChanged<double> onHeight;
  double? _last;

  @override
  void performLayout() {
    super.performLayout();
    if (size.height != _last) {
      _last = size.height;
      onHeight(size.height);
    }
  }
}

/// Whether the user follows or subscribes to a creator, for creator rows.
ClFollowStatus followStatus(AppStore store, String creatorId) => store.subscriptions.contains(creatorId)
    ? ClFollowStatus.subscribed
    : store.follows.contains(creatorId)
    ? ClFollowStatus.following
    : ClFollowStatus.none;

/// Vertical rhythm between blocks.
const gap = SizedBox(height: ClSpace.s6);
const gapS = SizedBox(height: ClSpace.s4);

// ───────────────────────── Copy helpers

String weeksLabel(int n) => '$n ${plural(n, 'nedelja', 'nedelje', 'nedelja')}';

String programMeta(Program p) => '${weeksLabel(p.weeks)} · ${p.daysPerWeek}× nedeljno';

String workoutMeta(Workout w) =>
    '${countLabel(w.exercises.length, 'vežba', 'vežbe', 'vežbi')} · ~${w.estimatedMinutes} min';

String followersLabel(int n) => '${formatCompact(n)} ${plural(n, 'pratilac', 'pratioca', 'pratilaca')}';

String restLabel(int seconds) => 'Odmor ${formatClock(Duration(seconds: seconds))}';

/// `4 × 6–8 · RIR 2 · Odmor 2:00`
String prescription(String target, int? rir, int restSeconds) =>
    [target, if (rir != null) 'RIR $rir', restLabel(restSeconds)].join(' · ');

/// `80 kg × 8`, or `12 pon.` for bodyweight without added load.
String setLabel(SetLog s) {
  final kg = s.kg ?? 0;
  final reps = s.reps ?? 0;
  return kg > 0 ? formatSet(kg, reps) : '$reps pon.';
}

String sessionMeta(Session s) =>
    '${formatDate(s.finishedAt ?? s.startedAt)} · ${formatDuration(s.duration)} · ${formatKg(s.volume)}';

/// A picture from a link, or null when there is none.
ImageProvider? photoOf(String? url) {
  if (url == null || url.isEmpty) return null;
  // A creator's own photo in local mode is a file on this phone.
  // Real trainers' photos ship inside the app (see SeedCatalog).
  if (url.startsWith('asset:')) return AssetImage(url.substring('asset:'.length));
  final uri = Uri.parse(url);
  return uri.isScheme('file') ? FileImage(File(uri.toFilePath())) : NetworkImage(url);
}

/// What just changed, as a dark message near the bottom with "Poništi". It
/// goes away by itself after a few seconds, so it never pushes content down.
void showUndoToast(BuildContext context, String message, {VoidCallback? onUndo}) {
  final cl = context.cl;
  final c = cl.colors;
  final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      // Clear of the navigation bar on the tabs.
      margin: const EdgeInsets.fromLTRB(ClSpace.s4, 0, ClSpace.s4, ClSpace.s12 + ClSpace.s8),
      backgroundColor: c.ink,
      elevation: 0,
      duration: const Duration(seconds: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ClRadius.sm)),
      content: Text(message, style: cl.text.body.copyWith(color: c.bg, fontSize: 14)),
      action: onUndo == null ? null : SnackBarAction(label: 'Poništi', textColor: c.bg, onPressed: onUndo),
    ),
  );
}
