import 'package:flutter/widgets.dart';

const _regular = 'PhosphorRegular';
const _fill = 'PhosphorFill';
const _bold = 'PhosphorBold';

/// The only icon set: Phosphor Regular (MIT), bundled in assets/icons,
/// outline, currentColor. The `…Filled` icons are the solid versions for the
/// active navigation item. Prefer a text label over an icon. To add one, copy its
/// codepoint from the Phosphor `style.css`, add it to the font subset and
/// name it by purpose.
abstract final class ClIcons {
  static const IconData today = IconData(0xe472, fontFamily: _regular);
  static const IconData library = IconData(0xe758, fontFamily: _regular);
  static const IconData discover = IconData(0xe1c8, fontFamily: _regular);
  static const IconData progress = IconData(0xe156, fontFamily: _regular);
  static const IconData profile = IconData(0xe4c2, fontFamily: _regular);
  static const IconData plan = IconData(0xe10a, fontFamily: _regular);
  static const IconData rest = IconData(0xe330, fontFamily: _regular);
  static const IconData find = IconData(0xe434, fontFamily: _regular);

  /// Bold so the set-done check stays legible on a small lime circle.
  static const IconData check = IconData(0xe182, fontFamily: _bold);
  static const IconData close = IconData(0xe4f6, fontFamily: _regular);
  static const IconData add = IconData(0xe3d4, fontFamily: _regular);
  static const IconData remove = IconData(0xe32a, fontFamily: _regular);
  static const IconData arrowRight = IconData(0xe06c, fontFamily: _regular);
  static const IconData back = IconData(0xe138, fontFamily: _regular, matchTextDirection: true);
  static const IconData chevron = IconData(0xe13a, fontFamily: _regular, matchTextDirection: true);
  static const IconData expand = IconData(0xe136, fontFamily: _regular);
  static const IconData collapse = IconData(0xe13c, fontFamily: _regular);
  static const IconData more = IconData(0xe1fe, fontFamily: _regular);
  static const IconData swap = IconData(0xe0a0, fontFamily: _regular);
  static const IconData timer = IconData(0xe492, fontFamily: _regular);
  static const IconData play = IconData(0xe3d0, fontFamily: _regular);
  static const IconData search = IconData(0xe30c, fontFamily: _regular);
  static const IconData barbell = IconData(0xe0b6, fontFamily: _regular);
  static const IconData lock = IconData(0xe308, fontFamily: _regular);
  static const IconData image = IconData(0xe2ca, fontFamily: _regular);
  static const IconData settings = IconData(0xe272, fontFamily: _regular);
  static const IconData account = IconData(0xe4c4, fontFamily: _regular);
  static const IconData subscriptions = IconData(0xe614, fontFamily: _regular);
  static const IconData sync = IconData(0xe094, fontFamily: _regular);
  static const IconData info = IconData(0xe2ce, fontFamily: _regular);
  static const IconData days = IconData(0xe7b4, fontFamily: _regular);
  static const IconData streak = IconData(0xe242, fontFamily: _regular);
  static const IconData sparkle = IconData(0xe6a2, fontFamily: _regular);
  static const IconData energy = IconData(0xe2de, fontFamily: _regular);
  static const IconData signOut = IconData(0xe42a, fontFamily: _regular);
  static const IconData creators = IconData(0xe68e, fontFamily: _regular);
  static const IconData heart = IconData(0xe2a8, fontFamily: _regular);
  static const IconData record = IconData(0xe67e, fontFamily: _regular);
  static const IconData star = IconData(0xe46a, fontFamily: _regular);

  /// Solid versions for the active navigation item. Constants, so icon
  /// font tree shaking keeps working.
  static const IconData todayFilled = IconData(0xe472, fontFamily: _fill);
  static const IconData planFilled = IconData(0xe10a, fontFamily: _fill);
  static const IconData discoverFilled = IconData(0xe1c8, fontFamily: _fill);
  static const IconData progressFilled = IconData(0xe156, fontFamily: _fill);
  static const IconData libraryFilled = IconData(0xe758, fontFamily: _fill);
  static const IconData creatorsFilled = IconData(0xe68e, fontFamily: _fill);
  static const IconData profileFilled = IconData(0xe4c2, fontFamily: _fill);

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
    'expand': expand,
    'collapse': collapse,
    'more': more,
    'swap': swap,
    'timer': timer,
    'play': play,
    'search': search,
    'barbell': barbell,
    'lock': lock,
    'image': image,
    'settings': settings,
    'account': account,
    'subscriptions': subscriptions,
    'sync': sync,
    'info': info,
    'days': days,
    'streak': streak,
    'sparkle': sparkle,
    'energy': energy,
    'signOut': signOut,
    'creators': creators,
    'heart': heart,
    'record': record,
    'star': star,
  };
}
