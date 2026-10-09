import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../data/app_store.dart';
import '../data/sync.dart';
import '../domain/models.dart';
import '../ui/chalkline_ui.dart';
import 'common.dart';

/// A creator's highlights as circles under their name, like Instagram:
/// "O meni", "Rezultati", "Kako treniram". On a creator's own Studio the row
/// starts with "Nova" and a tap edits instead of playing.
class HighlightsRow extends StatelessWidget {
  const HighlightsRow({super.key, required this.creator, this.editable = false});

  final Creator creator;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    final highlights = creator.highlights.where((h) => h.items.isNotEmpty).toList();
    if (highlights.isEmpty && !editable) return const SizedBox.shrink();

    Widget circle({required String label, required Widget child, required VoidCallback onPressed}) =>
        ClPressable(
          onPressed: onPressed,
          semanticLabel: label,
          radius: ClRadius.sm,
          builder: (context, pressed) => SizedBox(
            width: 76,
            child: Column(
              children: [
                AnimatedScale(
                  duration: context.motion(ClMotion.fast),
                  scale: pressed ? 0.94 : 1,
                  child: child,
                ),
                const SizedBox(height: ClSpace.s1),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: cl.text.label.copyWith(color: c.ink, fontSize: 12),
                ),
              ],
            ),
          ),
        );

    return LayoutBuilder(
      builder: (context, box) => SizedBox(
        height: 96,
        // Edge to edge, so the circles scroll out under the screen's gutter.
        child: OverflowBox(
          minWidth: box.maxWidth + ClSpace.s4 * 2,
          maxWidth: box.maxWidth + ClSpace.s4 * 2,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: ClSpace.s3),
            children: [
              if (editable)
                circle(
                  label: 'Nova',
                  onPressed: () => pushScreen(context, const HighlightEditor(), theme: ClTheme.light),
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: c.borderStrong, width: 1.5),
                    ),
                    child: Icon(ClIcons.add, color: c.ink, size: 26),
                  ),
                ),
              for (final (i, h) in highlights.indexed)
                circle(
                  label: h.title,
                  onPressed: editable
                      ? () => pushScreen(context, HighlightEditor(highlightId: h.id), theme: ClTheme.light)
                      : () => openHighlights(context, creator: creator, highlights: highlights, initial: i),
                  child: ClAvatar(name: h.title, image: photoOf(h.cover), size: 68, ring: true),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Plays [highlights] full screen, starting at [initial].
Future<void> openHighlights(
  BuildContext context, {
  required Creator creator,
  required List<Highlight> highlights,
  int initial = 0,
}) {
  HapticFeedback.selectionClick();
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: context.motion(const Duration(milliseconds: 220)),
      reverseTransitionDuration: context.motion(const Duration(milliseconds: 180)),
      pageBuilder: (_, _, _) => ClThemeScope(
        theme: ClTheme.dark,
        child: HighlightViewer(creator: creator, highlights: highlights, initial: initial),
      ),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(
            begin: 0.94,
            end: 1.0,
          ).animate(CurvedAnimation(parent: animation, curve: ClMotion.curve)),
          child: child,
        ),
      ),
    ),
  );
}

/// One highlight's photos and videos full screen, then the next highlight.
/// Tap right for the next story, left for the previous; hold to pause; pull
/// down to close.
class HighlightViewer extends StatefulWidget {
  const HighlightViewer({super.key, required this.creator, required this.highlights, this.initial = 0});

  final Creator creator;
  final List<Highlight> highlights;
  final int initial;

  /// How long a photo stays.
  static const photoTime = Duration(seconds: 5);

  @override
  State<HighlightViewer> createState() => _HighlightViewerState();
}

class _HighlightViewerState extends State<HighlightViewer> with SingleTickerProviderStateMixin {
  late int _h = widget.initial;
  int _i = 0;
  late final AnimationController _photo =
      AnimationController(vsync: this, duration: HighlightViewer.photoTime)..addStatusListener((s) {
        if (s == AnimationStatus.completed) _next();
      });
  VideoPlayerController? _video;
  bool _videoFailed = false;
  bool _photoShown = false;
  bool _paused = false;
  bool _ending = false;
  double _drag = 0;

  Highlight get _highlight => widget.highlights[_h];
  HighlightItem get _item => _highlight.items[_i];

  @override
  void initState() {
    super.initState();
    _show();
  }

  @override
  void dispose() {
    _photo.dispose();
    _disposeVideo();
    super.dispose();
  }

  void _disposeVideo() {
    _video?.removeListener(_onVideo);
    _video?.dispose();
    _video = null;
  }

  void _show() {
    _photo.stop();
    _photo.value = 0;
    _disposeVideo();
    _videoFailed = false;
    _photoShown = false;
    _ending = false;
    final item = _item;
    if (item.video) {
      final uri = Uri.parse(item.url);
      final video = uri.isScheme('file')
          ? VideoPlayerController.file(File(uri.toFilePath()))
          : VideoPlayerController.networkUrl(uri);
      _video = video;
      video
          .initialize()
          .then((_) {
            if (!mounted || _video != video) return;
            video.addListener(_onVideo);
            if (!_paused) video.play();
            setState(() {});
          })
          // A broken link: say so for a few seconds, then move on.
          .catchError((Object _) {
            if (!mounted || _video != video) return;
            setState(() => _videoFailed = true);
            if (!_paused) _photo.forward(from: 0);
          });
    }
    // The next photo loads while this one shows.
    final following = _following;
    if (following != null && !following.video) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final next = photoOf(following.url);
        if (mounted && next != null) precacheImage(next, context, onError: (_, _) {}).ignore();
      });
    }
    setState(() {});
  }

  HighlightItem? get _following {
    if (_i + 1 < _highlight.items.length) return _highlight.items[_i + 1];
    if (_h + 1 < widget.highlights.length) return widget.highlights[_h + 1].items.firstOrNull;
    return null;
  }

  void _onVideo() {
    final video = _video;
    if (video == null || _ending) return;
    if (video.value.isCompleted) {
      _ending = true;
      // Not while the controller is still notifying its listeners.
      scheduleMicrotask(_next);
    }
  }

  /// A photo starts its time once it is on screen, not while it loads.
  void _onPhotoShown() {
    if (_photoShown) return;
    _photoShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_paused) _photo.forward();
    });
  }

  void _next() {
    if (!mounted) return;
    if (_i + 1 < _highlight.items.length) {
      _i++;
    } else if (_h + 1 < widget.highlights.length) {
      _h++;
      _i = 0;
    } else {
      Navigator.of(context).maybePop();
      return;
    }
    _show();
  }

  void _previous() {
    if (_i > 0) {
      _i--;
    } else if (_h > 0) {
      _h--;
      _i = 0;
    }
    _show();
  }

  void _pause() {
    _paused = true;
    _photo.stop();
    _video?.pause();
  }

  void _resume() {
    _paused = false;
    final video = _video;
    if (video != null && video.value.isInitialized) {
      video.play();
    } else if (_photoShown || _videoFailed) {
      _photo.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    const white = Color(0xFFFFFFFF);
    final item = _item;
    final video = _video;

    final Widget media;
    if (item.video) {
      media = video != null && video.value.isInitialized
          // Fills the screen like a story; the edges of a wider clip are cut.
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: video.value.size.width,
                  height: video.value.size.height,
                  child: VideoPlayer(video),
                ),
              ),
            )
          : Center(
              child: _videoFailed
                  ? Text('Video nije dostupan.', style: cl.text.body.copyWith(color: white))
                  : const CircularProgressIndicator(color: white, strokeWidth: 2),
            );
    } else {
      media = Image(
        key: ValueKey(item.url),
        image: photoOf(item.url)!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        frameBuilder: (context, child, frame, _) {
          if (frame == null) {
            return const Center(child: CircularProgressIndicator(color: white, strokeWidth: 2));
          }
          _onPhotoShown();
          return child;
        },
        errorBuilder: (context, _, _) {
          _onPhotoShown();
          return Center(
            child: Text('Slika nije dostupna.', style: cl.text.body.copyWith(color: white)),
          );
        },
      );
    }

    Widget bar(int index) {
      if (index < _i) return _Bar(value: 1);
      if (index > _i) return _Bar(value: 0);
      if (video != null && video.value.isInitialized && !_videoFailed) {
        return ValueListenableBuilder(
          valueListenable: video,
          builder: (_, v, _) => _Bar(
            value: v.duration.inMilliseconds == 0 ? 0 : v.position.inMilliseconds / v.duration.inMilliseconds,
          ),
        );
      }
      return AnimatedBuilder(
        animation: _photo,
        builder: (_, _) => _Bar(value: _photo.value),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF000000),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => d.localPosition.dx < MediaQuery.sizeOf(context).width / 3 ? _previous() : _next(),
          onLongPressStart: (_) => _pause(),
          onLongPressEnd: (_) => _resume(),
          onVerticalDragUpdate: (d) => setState(() => _drag = (_drag + d.delta.dy).clamp(0, double.infinity)),
          onVerticalDragEnd: (d) {
            if (_drag > 120 || (d.primaryVelocity ?? 0) > 700) {
              Navigator.of(context).maybePop();
            } else {
              setState(() => _drag = 0);
            }
          },
          child: Transform.translate(
            offset: Offset(0, _drag),
            child: Opacity(
              opacity: (1 - _drag / 600).clamp(0.4, 1),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_drag > 0 ? ClRadius.lg : 0),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    media,
                    // Keeps the bars and the title readable over bright photos.
                    const Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: 160,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x80000000), Color(0x00000000)],
                          ),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(ClSpace.s3, ClSpace.s2, ClSpace.s2, 0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                for (var k = 0; k < _highlight.items.length; k++) ...[
                                  if (k > 0) const SizedBox(width: 3),
                                  Expanded(child: bar(k)),
                                ],
                              ],
                            ),
                            const SizedBox(height: ClSpace.s2),
                            Row(
                              children: [
                                ClAvatar(
                                  name: widget.creator.name,
                                  image: photoOf(widget.creator.photo),
                                  size: 32,
                                ),
                                const SizedBox(width: ClSpace.s2),
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(text: widget.creator.handle),
                                        TextSpan(
                                          text: '  ${_highlight.title}',
                                          style: cl.text.body.copyWith(color: white.withValues(alpha: 0.8)),
                                        ),
                                      ],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: cl.text.bodyStrong.copyWith(color: white),
                                  ),
                                ),
                                ClIconButton.onMedia(
                                  icon: ClIcons.close,
                                  semanticLabel: 'Zatvori',
                                  onPressed: () => Navigator.of(context).maybePop(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(2),
    child: LinearProgressIndicator(
      value: value.clamp(0, 1),
      minHeight: 2.5,
      backgroundColor: const Color(0x59FFFFFF),
      valueColor: const AlwaysStoppedAnimation(Color(0xFFFFFFFF)),
    ),
  );
}

/// A creator makes or changes one highlight: a name and its photos and
/// videos, in order.
class HighlightEditor extends StatefulWidget {
  const HighlightEditor({super.key, this.highlightId});

  final String? highlightId;

  @override
  State<HighlightEditor> createState() => _HighlightEditorState();
}

class _HighlightEditorState extends State<HighlightEditor> {
  final _title = TextEditingController();
  List<HighlightItem> _items = [];
  Highlight? _existing;
  int _uploading = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    final store = context.readStore;
    _existing = store.myCreator?.highlights.where((h) => h.id == widget.highlightId).firstOrNull;
    _title.text = _existing?.title ?? '';
    _items = [...?_existing?.items];
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  static bool _isVideo(String path) =>
      const {'mov', 'mp4', 'm4v'}.contains(path.split('.').last.toLowerCase());

  Highlight get _draft =>
      Highlight(id: _existing?.id ?? context.readStore.newId('h'), title: _title.text.trim(), items: _items);

  Future<void> _add() async {
    final fromCamera = await showClSheet<bool>(
      context,
      title: 'Dodaj u priču',
      label: 'Uspravne slike i video do 60 sekundi izgledaju najbolje',
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClButton(
            label: 'Izaberi iz galerije',
            variant: ClButtonVariant.secondary,
            icon: ClIcons.image,
            expand: true,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          const SizedBox(height: ClSpace.s3),
          ClButton(
            label: 'Slikaj',
            variant: ClButtonVariant.secondary,
            icon: ClIcons.image,
            expand: true,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (fromCamera == null || !mounted) return;
    final List<XFile> files;
    try {
      final picker = ImagePicker();
      if (fromCamera) {
        final photo = await picker.pickImage(source: ImageSource.camera, maxWidth: 1440, imageQuality: 85);
        files = [?photo];
      } else {
        files = await picker.pickMultipleMedia(maxWidth: 1440, imageQuality: 85);
      }
    } on Object {
      setState(
        () => _error = fromCamera
            ? 'Kamera nije dostupna. Izaberi iz galerije.'
            : 'Galerija nije dostupna. Dozvoli pristup u podešavanjima telefona.',
      );
      return;
    }
    if (files.isEmpty || !mounted) return;
    final store = context.readStore;
    setState(() {
      _error = null;
      _uploading = files.length;
    });
    for (final file in files) {
      try {
        final video = _isVideo(file.path);
        if (video && await file.length() > AppStore.maxVideoBytes) {
          if (mounted) setState(() => _error = 'Video je veći od 50 MB. Skrati ga ili izaberi kraći.');
          continue;
        }
        final url = await store.uploadHighlightMedia(file.path);
        if (mounted) setState(() => _items = [..._items, HighlightItem(url: url, video: video)]);
      } on RemoteError catch (e) {
        if (mounted) setState(() => _error = e.message);
      } finally {
        if (mounted) setState(() => _uploading--);
      }
    }
  }

  void _save() {
    context.readStore.saveHighlight(_draft);
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final existing = _existing;
    if (existing == null) return;
    final ok = await confirmClSheet(
      context,
      title: 'Obriši priču?',
      message: 'Nestaje sa tvog profila za sve pratioce.',
      confirmLabel: 'Obriši',
      danger: true,
    );
    if (!ok || !mounted) return;
    context.readStore.deleteHighlight(existing.id);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    final me = context.store.myCreator;
    final ready = _title.text.trim().isNotEmpty && _items.isNotEmpty && _uploading == 0;

    Widget tile({required Widget child, VoidCallback? onRemove}) => ClipRRect(
      borderRadius: BorderRadius.circular(ClRadius.sm),
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          if (onRemove != null)
            Positioned(
              top: 2,
              right: 2,
              child: ClIconButton.onMedia(icon: ClIcons.close, semanticLabel: 'Ukloni', onPressed: onRemove),
            ),
        ],
      ),
    );

    return AppScreen(
      topBar: ClTopBar(label: _existing == null ? 'Nova priča' : 'Uredi priču'),
      bottom: ClButton.block(label: 'Sačuvaj', onPressed: ready ? _save : null),
      children: [
        ClTextField(
          label: 'Naziv',
          hint: 'npr. O meni',
          controller: _title,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: ClSpace.s2),
        Text('O meni, Rezultati, Kako treniram, Ishrana, Pitanja', style: cl.text.label),
        gap,
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: ClSpace.s2,
          crossAxisSpacing: ClSpace.s2,
          childAspectRatio: 9 / 16,
          children: [
            for (final (i, item) in _items.indexed)
              tile(
                onRemove: () => setState(() => _items = [..._items]..removeAt(i)),
                child: item.video
                    ? ColoredBox(
                        color: c.popFor(item.url),
                        child: Icon(ClIcons.play, color: c.onPop, size: 32),
                      )
                    : ClPhoto(image: photoOf(item.url)!, placeholderLabel: ''),
              ),
            for (var k = 0; k < _uploading; k++)
              tile(
                child: ColoredBox(
                  color: c.surfaceRaised,
                  child: Center(child: CircularProgressIndicator(color: c.ink, strokeWidth: 2)),
                ),
              ),
            ClPressable(
              onPressed: _add,
              semanticLabel: 'Dodaj sliku ili video',
              radius: ClRadius.sm,
              builder: (context, pressed) => Container(
                decoration: BoxDecoration(
                  color: pressed ? c.surfaceRaised : c.surface,
                  borderRadius: BorderRadius.circular(ClRadius.sm),
                  border: Border.all(color: c.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(ClIcons.add, color: c.ink, size: 28),
                    const SizedBox(height: ClSpace.s1),
                    Text('Dodaj', style: cl.text.label.copyWith(color: c.ink)),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_error != null) ...[gapS, ClNotice(_error!, danger: true)],
        gapS,
        const ClNotice('Priče su javne. Za slike klijenata traži njihovu dozvolu.'),
        if (_items.isNotEmpty && me != null) ...[
          gapS,
          ClButton(
            label: 'Pogledaj kao pratilac',
            variant: ClButtonVariant.secondary,
            icon: ClIcons.play,
            expand: true,
            onPressed: () => openHighlights(context, creator: me, highlights: [_draft]),
          ),
        ],
        if (_existing != null) ...[
          gapS,
          ClButton(label: 'Obriši priču', variant: ClButtonVariant.danger, expand: true, onPressed: _delete),
        ],
      ],
    );
  }
}
