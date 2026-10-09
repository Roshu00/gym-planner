import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../ui/chalkline_ui.dart';

/// Turns the share card under [cardKey] into a 1080 × 1920 story picture
/// (the card centered on the app's background) and opens the phone's share
/// sheet, where Instagram stories, WhatsApp and saving to Photos are.
Future<void> shareStory(
  BuildContext context,
  GlobalKey cardKey, {
  Rect? origin,
  VoidCallback? onReady,
}) async {
  final boundary = cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) return;
  final background = context.clColors.bg;

  const width = 1080.0, height = 1920.0, margin = 96.0;
  final scale = (width - margin * 2) / boundary.size.width;
  final card = await boundary.toImage(pixelRatio: scale);

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..drawColor(background, BlendMode.src);
  canvas.drawImage(card, Offset(margin, ((height - card.height) / 2).roundToDouble()), Paint());
  final picture = await recorder.endRecording().toImage(width.toInt(), height.toInt());
  final png = await picture.toByteData(format: ui.ImageByteFormat.png);
  card.dispose();
  picture.dispose();
  if (png == null) return;
  onReady?.call();

  await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(png.buffer.asUint8List(), mimeType: 'image/png', name: 'chalkline-story.png')],
      // iPad shows the sheet next to the button.
      sharePositionOrigin: origin,
    ),
  );
}
