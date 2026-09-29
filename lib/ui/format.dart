/// Serbian number formatting: decimal comma, thousands dot, `×` for sets.
/// `formatNumber(8240)` → `8.240`, `formatNumber(82.5)` → `82,5`.
String formatNumber(num value, {int maxDecimals = 1}) {
  final negative = value < 0;
  final fixed = value.abs().toStringAsFixed(maxDecimals);
  var parts = fixed.split('.');
  var intPart = parts[0];
  var decPart = parts.length > 1 ? parts[1].replaceFirst(RegExp(r'0+$'), '') : '';

  final grouped = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) grouped.write('.');
    grouped.write(intPart[i]);
  }
  final sign = negative && (intPart != '0' || decPart.isNotEmpty) ? '−' : '';
  return decPart.isEmpty ? '$sign$grouped' : '$sign$grouped,$decPart';
}

/// Follower counts: `940`, `12,4K`, `480K`, `1,2M`.
String formatCompact(int value) {
  String scaled(double v, String suffix) =>
      '${formatNumber(v >= 100 ? v.roundToDouble() : v, maxDecimals: 1)}$suffix';
  if (value >= 1000000) return scaled(value / 1000000, 'M');
  if (value >= 10000) return scaled(value / 1000, 'K');
  return formatNumber(value);
}

/// `82,5 kg`
String formatKg(num kg) => '${formatNumber(kg)} kg';

/// `80 kg × 8`
String formatSet(num kg, int reps) => '${formatKg(kg)} × $reps';

/// `1h 12m`, `45m`, `0m`
String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  return h > 0 ? '${h}h ${m}m' : '${m}m';
}

/// Rest timer clock: `1:30`, `0:05`.
String formatClock(Duration d) {
  final s = d.inSeconds.abs();
  return '${d.isNegative ? '−' : ''}${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// Parses weight/rep input; accepts a decimal comma or dot: `82,5` → 82.5.
double? parseDecimal(String input) => double.tryParse(input.trim().replaceAll(',', '.'));
