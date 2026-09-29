// Writes supabase/seed.sql from lib/data/seed.dart, so the demo catalog has
// one source. Run: dart run tool/gen_seed.dart
import 'dart:io';

import 'package:chalkline/data/seed_sql.dart';

void main() {
  File('supabase/seed.sql').writeAsStringSync(buildSeedSql());
  stdout.writeln('Wrote supabase/seed.sql');
}
