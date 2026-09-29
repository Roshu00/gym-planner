import 'package:flutter/widgets.dart';

const _light = 'PhosphorLight';
const _bold = 'PhosphorBold';

/// The only icon set: Phosphor Light (MIT), bundled in assets/icons, thin
/// outline, currentColor. Prefer a text label over an icon. To add one, copy
/// its codepoint from the Phosphor `style.css` and name it by purpose.
abstract final class ClIcons {
  static const IconData today = IconData(0xe472, fontFamily: _light);
  static const IconData library = IconData(0xe758, fontFamily: _light);
  static const IconData discover = IconData(0xe1c8, fontFamily: _light);
  static const IconData progress = IconData(0xe156, fontFamily: _light);
  static const IconData profile = IconData(0xe4c2, fontFamily: _light);
  static const IconData plan = IconData(0xe10a, fontFamily: _light);
  static const IconData rest = IconData(0xe330, fontFamily: _light);
  static const IconData find = IconData(0xe434, fontFamily: _light);

  /// Bold so the set-done check stays legible on a small signal square.
  static const IconData check = IconData(0xe182, fontFamily: _bold);
  static const IconData close = IconData(0xe4f6, fontFamily: _light);
  static const IconData add = IconData(0xe3d4, fontFamily: _light);
  static const IconData remove = IconData(0xe32a, fontFamily: _light);
  static const IconData arrowRight = IconData(0xe06c, fontFamily: _light);
  static const IconData back = IconData(0xe138, fontFamily: _light, matchTextDirection: true);
  static const IconData chevron = IconData(0xe13a, fontFamily: _light, matchTextDirection: true);
  static const IconData more = IconData(0xe1fe, fontFamily: _light);
  static const IconData swap = IconData(0xe0a0, fontFamily: _light);
  static const IconData timer = IconData(0xe492, fontFamily: _light);
  static const IconData play = IconData(0xe3d0, fontFamily: _light);
  static const IconData search = IconData(0xe30c, fontFamily: _light);
  static const IconData barbell = IconData(0xe0b6, fontFamily: _light);
  static const IconData lock = IconData(0xe308, fontFamily: _light);
  static const IconData image = IconData(0xe2ca, fontFamily: _light);

  static const Map<String, IconData> all = {
    'today': today,
    'library': library,
    'discover': discover,
    'progress': progress,
    'profile': profile,
    'plan': plan,
    'rest': rest,
    'find': find,
    'check': check,
    'close': close,
    'add': add,
    'remove': remove,
    'arrowRight': arrowRight,
    'back': back,
    'chevron': chevron,
    'more': more,
    'swap': swap,
    'timer': timer,
    'play': play,
    'search': search,
    'barbell': barbell,
    'lock': lock,
    'image': image,
  };
}
