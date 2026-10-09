import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../domain/models.dart';
import '../ui/chalkline_ui.dart';
import 'common.dart';

/// How an exercise is done: its clip, looped without sound, or else its two
/// pictures (start and end of the movement) taking turns, or else its single
/// picture. The picture shows while the clip loads, and stays if it fails.
class ExerciseMedia extends StatefulWidget {
  const ExerciseMedia({super.key, required this.exercise, this.playing = true});

  final Exercise exercise;

  /// Off for a small thumbnail: the first picture only.
  final bool playing;

  @override
  State<ExerciseMedia> createState() => _ExerciseMediaState();
}

class _ExerciseMediaState extends State<ExerciseMedia> {
  VideoPlayerController? _video;
  bool _ready = false;
  Timer? _frames;
  int _frame = 0;

  /// free-exercise-db keeps the movement's end as `1.jpg` next to `0.jpg`.
  String? get _secondFrame {
    final image = widget.exercise.image;
    if (image == null || !image.endsWith('/0.jpg')) return null;
    return '${image.substring(0, image.length - 5)}1.jpg';
  }

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(ExerciseMedia old) {
    super.didUpdateWidget(old);
    if (old.exercise.id != widget.exercise.id || old.playing != widget.playing) {
      _stop();
      _start();
    }
  }

  void _start() {
    if (!widget.playing) return;
    final url = widget.exercise.video;
    if (url != null) {
      final video = VideoPlayerController.networkUrl(Uri.parse(url));
      _video = video;
      video
          .initialize()
          .then((_) async {
            if (!mounted || _video != video) return;
            await video.setVolume(0);
            await video.setLooping(true);
            await video.play();
            if (mounted) setState(() => _ready = true);
          })
          // No clip (offline, a test, a broken link): the pictures stay.
          .catchError((Object _) {
            _animatePictures();
          });
      return;
    }
    _animatePictures();
  }

  void _animatePictures() {
    if (!mounted || _secondFrame == null) return;
    _frames = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (mounted) setState(() => _frame = 1 - _frame);
    });
  }

  void _stop() {
    _frames?.cancel();
    _frames = null;
    _video?.dispose();
    _video = null;
    _ready = false;
    _frame = 0;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.clColors;
    final video = _video;
    if (video != null && _ready) {
      return ColoredBox(
        color: c.photoEmpty,
        child: Center(
          child: AspectRatio(aspectRatio: video.value.aspectRatio, child: VideoPlayer(video)),
        ),
      );
    }
    final first = photoOf(widget.exercise.image);
    if (first == null) {
      return ColoredBox(
        color: c.popFor(widget.exercise.id),
        child: Icon(ClIcons.barbell, color: c.onPop),
      );
    }
    final second = photoOf(_secondFrame);
    return AnimatedSwitcher(
      duration: context.motion(const Duration(milliseconds: 250)),
      child: ClPhoto(
        key: ValueKey(_frame),
        image: _frame == 1 && second != null ? second : first,
        placeholderLabel: '',
        semanticLabel: widget.exercise.name,
      ),
    );
  }
}
