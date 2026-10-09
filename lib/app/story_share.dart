import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/models.dart';
import '../ui/chalkline_ui.dart';
import 'common.dart';

/// "Podeli na story": the user's own photo (a gym shot, a form check) with the
/// workout as a sticker on top, like Strava. The sticker can be dragged up
/// and down. Shares the whole 1080 × 1920 picture, or the sticker alone on a
/// transparent background to place over any photo in Instagram.
class StoryComposerScreen extends StatefulWidget {
  const StoryComposerScreen({super.key, required this.session});

  final Session session;

  @override
  State<StoryComposerScreen> createState() => _StoryComposerScreenState();
}

class _StoryComposerScreenState extends State<StoryComposerScreen> {
  final _story = GlobalKey();
  final _sticker = GlobalKey();
  final _shareButton = GlobalKey();
  File? _photo;

  /// Sticker position from the top, 0–1 of the free space.
  double _y = 0.92;
  bool _busy = false;

  Future<void> _pickPhoto() async {
    final source = await showClSheet<ImageSource>(
      context,
      title: 'Tvoja slika',
      label: 'Iz teretane, posle treninga ili form check',
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClButton(
            label: 'Slikaj',
            variant: ClButtonVariant.secondary,
            icon: ClIcons.image,
            expand: true,
            onPressed: () => Navigator.of(context).pop(ImageSource.camera),
          ),
          const SizedBox(height: ClSpace.s3),
          ClButton(
            label: 'Izaberi iz galerije',
            variant: ClButtonVariant.secondary,
            icon: ClIcons.image,
            expand: true,
            onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
        ],
      ),
    );
    if (source == null || !mounted) return;
    try {
      final file = await ImagePicker().pickImage(source: source, maxWidth: 2160, imageQuality: 90);
      if (file != null && mounted) setState(() => _photo = File(file.path));
    } on Object {
      if (mounted) {
        showUndoToast(
          context,
          source == ImageSource.camera
              ? 'Kamera nije dostupna. Izaberi sliku iz galerije.'
              : 'Galerija nije dostupna. Dozvoli pristup u podešavanjima telefona.',
        );
      }
    }
  }

  Future<void> _share({required bool stickerOnly}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final box = _shareButton.currentContext?.findRenderObject() as RenderBox?;
    final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    try {
      final key = stickerOnly ? _sticker : _story;
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final storyWidth = (_story.currentContext!.findRenderObject()! as RenderBox).size.width;
      // The whole story is 1080 px wide; the sticker keeps the same scale.
      final image = await boundary.toImage(pixelRatio: 1080 / storyWidth);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (png == null) throw StateError('no image');
      if (mounted) setState(() => _busy = false);
      HapticFeedback.lightImpact();
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              png.buffer.asUint8List(),
              mimeType: 'image/png',
              name: stickerOnly ? 'chalkline-nalepnica.png' : 'chalkline-story.png',
            ),
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
    final s = widget.session;
    final cl = context.cl;
    final c = cl.colors;
    final workout = store.workoutsById[s.workoutId];
    final creator = store.creator(s.creatorId);

    return AppScreen(
      topBar: const ClTopBar(label: 'Podeli na story'),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: ClButton(
                  label: _photo == null ? 'Tvoja slika' : 'Druga slika',
                  variant: ClButtonVariant.secondary,
                  icon: ClIcons.image,
                  expand: true,
                  onPressed: _busy ? null : _pickPhoto,
                ),
              ),
              const SizedBox(width: ClSpace.s2),
              Expanded(
                child: ClButton(
                  key: _shareButton,
                  label: _busy ? 'Pripremam…' : 'Podeli',
                  variant: ClButtonVariant.pop,
                  expand: true,
                  onPressed: _busy ? null : () => _share(stickerOnly: false),
                ),
              ),
            ],
          ),
          Center(
            child: ClButton(
              label: 'Samo nalepnica, providna',
              variant: ClButtonVariant.text,
              onPressed: _busy ? null : () => _share(stickerOnly: true),
            ),
          ),
        ],
      ),
      children: [
        Center(
          child: ConstrainedBox(
            // The whole 9:16 story fits on screen above the buttons.
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: LayoutBuilder(
                builder: (context, box) {
                  final scale = box.maxWidth / 360;
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(ClRadius.lg),
                    child: RepaintBoundary(
                      key: _story,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ColoredBox(color: c.popFor(s.workoutId)),
                          if (_photo != null)
                            Image.file(_photo!, fit: BoxFit.cover)
                          else if (photoOf(workout?.image) case final cover?)
                            ClPhoto(image: cover, placeholderLabel: ''),
                          // Keeps white numbers readable on bright photos.
                          const ClPhotoScrim(coverage: 0.5),
                          Align(
                            alignment: Alignment(0, _y * 2 - 1),
                            child: GestureDetector(
                              onVerticalDragUpdate: (d) =>
                                  setState(() => _y = (_y + d.delta.dy / box.maxHeight).clamp(0.05, 0.95)),
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 8 * scale),
                                child: RepaintBoundary(
                                  key: _sticker,
                                  // Room for the text shadows in the saved sticker.
                                  child: Padding(
                                    padding: EdgeInsets.all(16 * scale),
                                    child: StorySticker(
                                      session: s,
                                      handle: creator?.handle,
                                      creatorPhoto: photoOf(creator?.photo),
                                      scale: scale,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: ClSpace.s2),
        Text(
          _photo == null
              ? 'Dodaj sliku iz teretane ili form check. Nalepnicu pomeraš prstom gore-dole.'
              : 'Nalepnicu pomeraš prstom gore-dole.',
          textAlign: TextAlign.center,
          style: cl.text.label,
        ),
      ],
    );
  }
}

/// The workout as white text without a background, readable over any photo:
/// its name, time, volume and records (or sets), the trainer and the app.
class StorySticker extends StatelessWidget {
  const StorySticker({super.key, required this.session, this.handle, this.creatorPhoto, this.scale = 1});

  final Session session;
  final String? handle;
  final ImageProvider? creatorPhoto;

  /// 1 at a 360 pt wide story.
  final double scale;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    const white = Color(0xFFFFFFFF);
    final shadow = [Shadow(color: const Color(0x66000000), blurRadius: 12 * scale)];
    Widget stat(String label, String value) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: cl.text.label.copyWith(color: white, fontSize: 11 * scale, shadows: shadow),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: cl.text.metric.copyWith(
                color: white,
                fontSize: 26 * scale,
                height: 1.1,
                shadows: shadow,
              ),
            ),
          ),
        ],
      ),
    );
    final s = session;
    final volume = s.volume >= 1000
        ? '${formatNumber(s.volume / 1000)} t'
        : '${formatNumber(s.volume, maxDecimals: 0)} kg';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.workoutName,
          maxLines: 2,
          style: cl.text.displayL.copyWith(color: white, fontSize: 40 * scale, height: 1, shadows: shadow),
        ),
        SizedBox(height: 12 * scale),
        Row(
          children: [
            stat('Vreme', formatDuration(s.duration)),
            stat('Volumen', volume),
            if (s.prCount > 0) stat('Rekordi', '${s.prCount}') else stat('Setova', '${s.doneSets}'),
          ],
        ),
        SizedBox(height: 14 * scale),
        Row(
          children: [
            ClAvatar(name: s.creatorName, image: creatorPhoto, size: 22 * scale),
            SizedBox(width: 8 * scale),
            Flexible(
              child: Text(
                '${handle == null ? s.creatorName : '@$handle'} · Chalkline',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: cl.text.bodyStrong.copyWith(color: white, fontSize: 13 * scale, shadows: shadow),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
