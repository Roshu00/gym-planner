import 'package:chalkline/ui/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatNumber uses decimal comma and thousands dot', () {
    expect(formatNumber(8240), '8.240');
    expect(formatNumber(82.5), '82,5');
    expect(formatNumber(80), '80');
    expect(formatNumber(1234567.25, maxDecimals: 2), '1.234.567,25');
    expect(formatNumber(0), '0');
    expect(formatNumber(-2.5), '−2,5');
  });

  test('formatSet and formatKg', () {
    expect(formatKg(82.5), '82,5 kg');
    expect(formatSet(80, 8), '80 kg × 8');
  });

  test('formatCompact', () {
    expect(formatCompact(940), '940');
    expect(formatCompact(9400), '9.400');
    expect(formatCompact(12400), '12,4K');
    expect(formatCompact(48200), '48,2K');
    expect(formatCompact(480000), '480K');
    expect(formatCompact(1200000), '1,2M');
  });

  test('formatDuration and formatClock', () {
    expect(formatDuration(const Duration(minutes: 72)), '1h 12m');
    expect(formatDuration(const Duration(minutes: 45)), '45m');
    expect(formatClock(const Duration(seconds: 90)), '1:30');
    expect(formatClock(const Duration(seconds: 5)), '0:05');
    expect(formatClock(const Duration(seconds: -12)), '−0:12');
  });

  test('parseDecimal accepts comma or dot', () {
    expect(parseDecimal('82,5'), 82.5);
    expect(parseDecimal('82.5'), 82.5);
    expect(parseDecimal(' 100 '), 100);
    expect(parseDecimal(''), isNull);
  });
}
